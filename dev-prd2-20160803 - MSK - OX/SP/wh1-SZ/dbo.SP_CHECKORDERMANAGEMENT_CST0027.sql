ALTER PROCEDURE [dbo].[SP_CHECKORDERMANAGEMENT_CST0027] 
@wh        varchar(10),
@orderkey  varchar(18)
AS
BEGIN

-- Процедура возвращает 0, если резервирование заказа надо запретить
SET NOCOUNT ON

--IF 78 <= (select STATUS from wh1.ORDERS where ORDERKEY = @orderkey)
--	RETURN 0

--RETURN 1

declare @result int

create table #case (
	caseid varchar (20),
	pickdetailkey varchar(20),
	locpd varchar (20) null,
	loci varchar (20) null,
	loc varchar (20) null,
	statuspd varchar (20) null,
	zone varchar(50) null,
	control varchar(50) null,
	status varchar(50) null
)

print 'выборка отборов по заказу'
insert into #case
	select caseid, PICKDETAILKEY, LOC,  null, null,status, null, null, null
	from wh1.PICKDETAIL where ORDERKEY = @orderkey  

if 0 = @@ROWCOUNT
begin
	print 'в заказе НЕТ отборов'
	drop table #case
	set @result = 1
	return @result
end  

-- если есть запись в ITRN то заполняем ячейку ИЗ
update C set loci = i.fromloc
	from #case c left join wh1.ITRN i on i.SOURCEKEY = c.pickdetailkey
	where TRANTYPE = 'MV'

-- обновляем ячейку ОТКУДА
update C set c.loc = case when c.loci IS null then c.locpd else c.loci end
	from #case c

-- определяем зоны для ячеек
update C set c.zone = pz.PUTAWAYZONE, c.control = pz.CARTONIZEAREA
	from #case c join wh1.LOC l on c.loc = l.LOC
		join wh1.PUTAWAYZONE pz on pz.PUTAWAYZONE = l.PUTAWAYZONE

-- статус проконтроллированности кейса.
update C set c.status = 
	case when (p.status=1 and p.RUN_ALLOCATION=0 and p.RUN_CC=0) then '1' else '0' end
	from #case c left join wh1.pickcontrol p on c.caseid = p.caseid

print 'проверка заказа'
if (select COUNT(*) from #case where control = 'K' and status != '1') != 0
	begin
		print 'заказ НЕ проверен'
		set @result = 3
	end
else
	begin
		print 'заказ проверен или проверка не требуется'
		-- если кейс проконтролирован - он уже упакован (иначе контроль не может быть выполнен)
		-- если контроль не требуется, надо проверить, все ли дропы отобраны и упакованы
		if (select COUNT(*) from #case where control != 'K' and statuspd < '6') != 0
			begin
				print 'заказ НЕ упакован'
				set @result = 2
			end
		else
			begin
				print 'заказ упакован'
				set @result = 0
			end		
	end

drop table #case
		
return @result

END
