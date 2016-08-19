/* Погрузочный лист */
ALTER PROCEDURE [dbo].[rep_ShippedListMAR4] (
	@dat1 datetime,
	@dat2 datetime,
	@mar varchar(12)
)
AS
--declare @dat1 datetime, @dat2 datetime, @mar varchar(12)
--set @dat1='01.06.2011'
--set @dat2='07.07.2011'
--set @mar='8'

declare @date1 varchar(10),
		@date2 varchar(10)
	
	set @date1 = convert(varchar(10),@dat1,112)
	set @date2 = convert(varchar(10),dateadd(dy,1,@dat2),112)
	
	/* Переменная для машины */
declare @ts varchar(15)
exec dbo.DA_GetNewKey 'wh1','TS',@ts output
set @ts='TSA'+right(@ts,7)

create table #case (
	orderkey varchar (20),
	caseid varchar (20),
	pickdetailkey varchar(20),
	locpd varchar (20) null,
	loci varchar (20) null,
	loc varchar (20) null,
	statuspd varchar (20) null,
	zone varchar(50) null,
	control varchar(50) null,
	status varchar(50) null,
	DEPARTURETIME datetime,
	loadid varchar(50)
)
print 'выборка отборов по заказу'
insert into #case
	select pd.orderkey, pd.caseid, pd.PICKDETAILKEY, pd.LOC,  null, null,pd.status, null, null, null, lh.DEPARTURETIME, lh.loadid
from	wh1.loadhdr lh
join wh1.loadstop ls on lh.LOADID=ls.LOADID
join wh1.LOADORDERDETAIL lod on ls.LOADSTOPID=lod.LOADSTOPID
join wh1.PICKDETAIL pd on pd.ORDERKEY=lod.SHIPMENTORDERID
where lh.ROUTE=@mar and  lh.DEPARTURETIME between ''+ @date1+'' and ''+@date2+'' 

-- если есть запись в ITRN то заполняем ячейку ИЗ
print 'если есть запись в ITRN то заполняем ячейку ИЗ'
update C set loci = i.fromloc
	from #case c left join wh1.ITRN i on i.SOURCEKEY = c.pickdetailkey
	where TRANTYPE = 'MV'
	
-- обновляем ячейку ОТКУДА
print 'обновляем ячейку ОТКУДА'
update C set c.loc = case when c.loci IS null then c.locpd else c.loci end
	from #case c
	
-- определяем зоны для ячеек
print 'определяем зоны для ячеек'
update C set c.zone = pz.PUTAWAYZONE, c.control = pz.CARTONIZEAREA
	from #case c join wh1.LOC l on c.loc = l.LOC
		join wh1.PUTAWAYZONE pz on pz.PUTAWAYZONE = l.PUTAWAYZONE
	
-- статус проконтроллированности кейса.
print 'статус проконтроллированности кейса.'
update C set c.status = isnull(p.status,0)
	from #case c left join wh1.pickcontrol p on c.caseid = p.caseid and p.RUN_ALLOCATION='0' and p.RUN_CC='0'

print 'Выводим #заказа, кейс, статус-кейса, контроль, статус контроля'
select orderkey, caseid, statuspd,control, status, DEPARTURETIME, loadid
into #case1 from #case
group by orderkey, caseid, statuspd,control, status, DEPARTURETIME, loadid

print 'Формируем список заказов которые не полностью собраны'
select distinct c1.orderkey
into #case2 
from #case1 c1
where c1.STATUSpd!=6

print 'удаляем заказы которые не собраны из общего списка'
delete from t1 from #case1 t1 join #case2 t2 on t1.orderkey=t2.orderkey


print 'из упакованных заказов убираем заказы которые не прошли контроль'
select distinct orderkey
into #case3
from #case1
where (control='K' and status='0')

print 'из общего списка удаляем непроконтролированные заказы'
delete from t1 from #case1 t1 join #case3 t3 on t1.orderkey=t3.orderkey

print 'из общего списка удаляем заказы на которые не нужно резервирования'
select distinct c1.orderkey
into #case5
from #case1 c1
join wh1.PICKCONTROL pc on c1.caseid=pc.CASEID
where pc.RUN_ALLOCATION!='0' or pc.RUN_CC!='0'

print 'из общего списка удаляем непроконтролированные заказы'
delete from t1 from #case1 t1 join #case5 t3 on t1.orderkey=t3.orderkey

print 'делаем только заказы которые упакованы и проконтролированы'
select distinct orderkey, DEPARTURETIME, loadid into #case4 from #case1

print 'делаем список ящиков+коробки по упаковки и коробки с контроля и статус контроля'
select c1.caseid,
sum(ceiling(case when p.casecnt=0 then pd.qty/1 else pd.qty/p.casecnt end)) yashik, pc.boxnum
into #t3
from #case1 c1
join wh1.PICKDETAIL pd on c1.caseid=pd.CASEID and c1.orderkey=pd.ORDERKEY
join wh1.LOTATTRIBUTE lot on pd.LOT=lot.lot
join wh1.PACK p on lot.LOTTABLE01=p.packkey
left join wh1.PICKCONTROL_LABEL pc on pc.CASEID=pd.caseid
group by c1.caseid, pc.boxnum
order by c1.caseid



/* Вытаскиваем данные по заказам для шапки */
select @ts ts,dbo.getean128(@ts)bcts, c4.orderkey,oss.DESCRIPTION descOrder,o.EXTERNORDERKEY ,pd.caseid,
 ck.DESCRIPTION descCase,pd.dropid, d.droploc, pd.ROUTE, s.COMPANY, s.ADDRESS1, s.address2,
CASE when isnull(t3.BOXNUM,'')='' then t3.yashik else t3.BOXNUM end as tt, c4.DEPARTURETIME, c4.loadid
 from #case4 c4
join wh1.pickdetail pd on c4.orderkey=pd.ORDERKEY
left join #t3 t3 on t3.CASEID=pd.CASEID
join wh1.DROPID d on d.DROPID=pd.dropid
join wh1.CODELKUP ck on pd.STATUS=ck.CODE and LISTNAME='ordrstatus'
join wh1.ORDERS o on pd.orderkey=o.orderkey
join wh1.ORDERSTATUSSETUP oss on o.STATUS=oss.CODE
join wh1.storer s on o.CONSIGNEEKEY=s.storerkey
group by c4.orderkey, oss.DESCRIPTION,o.EXTERNORDERKEY ,pd.caseid, ck.DESCRIPTION,pd.dropid, d.droploc, pd.ROUTE,
s.COMPANY, s.ADDRESS1,s.ADDRESS2, t3.yashik, t3.boxnum, c4.DEPARTURETIME, c4.loadid

drop table #case
drop table #case1
drop table #case2
drop table #case3
drop table #case4
drop table #case5
drop table #t3




