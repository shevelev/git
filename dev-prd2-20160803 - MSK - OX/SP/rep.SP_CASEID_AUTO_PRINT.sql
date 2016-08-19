

/*
Отчет: Автоматическая печать этикеток caseID в зависимости от фирмы отгрузки.
Автор: Шевелев С.С.
Дата: 12.05.2014
*/

ALTER PROCEDURE [rep].[SP_CASEID_AUTO_PRINT] 
@user varchar(20),
@area varchar(20)
AS

--declare @queryid varchar(15)
	-- новый номер queryid
--	exec dbo.DA_GetNewKey 'wh1','queryid',@queryid output
-- выбор прав пользователя
--select * into #userright from wh1.TASKMANAGERUSERDETAIL where USERKEY = @user and AREAKEY = @area
declare @allowpiece varchar (10)
declare @ALLOWPALLET varchar (10)
declare @ALLOWCASE varchar (10)

select top 1
	@ALLOWCASE = case when ALLOWCASE = 1 then 'CASE' else '' end,
	@ALLOWPALLET = case when ALLOWPALLET = 1 then 'OTHER' else '' end,
	@allowpiece = case when allowpiece = 1 then 'PICK' else '' end
from wh1.TASKMANAGERUSERDETAIL
where PERMISSIONTYPE = 'pk'
	and AREAKEY = case when isnull(@area, '') = '' then AREAKEY else @area end
--	and USERKEY = @user
	and PERMISSION = 1

print 'выбираем свободные кейсы'

select distinct
	pd.CASEID, dbo.GetEAN128(pd.CASEID) SH, o.c_zip STATUS, pd.ORDERKEY, o.EXTERNORDERKEY,
	ad.AREAKEY, l.LOCATIONTYPE, c.COMPANY, c.ADDRESS1, c.ADDRESS2, c.ADDRESS3, lh.DEPARTURETIME, lh.[ROUTE], o.PRIORITY, 
	sum(
		ceiling(
			case when pa.casecnt = 0
					then pd.qty / 1
					else pd.qty / pa.casecnt
				end
		)
	) as eww
into #tmpc
from WH1.PICKDETAIL as pd
	join WH1.LOC as l on pd.LOC = l.LOC
	join WH1.AREADETAIL as ad on ad.PUTAWAYZONE = l.PUTAWAYZONE
	join WH1.ORDERS as o on o.ORDERKEY = pd.ORDERKEY
	left join wh1.STORER c on o.CONSIGNEEKEY = c.STORERKEY
	left join WH1.LOADHDR as lh on o.LOADID = lh.LOADID
	join wh1.LOTATTRIBUTE la on pd.LOT = la.lot
	join wh1.PACK pa on la.LOTTABLE01 = pa.packkey
where pd.[STATUS] = 1
	and ad.areakey = case when isnull(@area, '') = '' then ad.areakey else @area end
	and isnull(pd.PDUDF3, '') = ''
	and o.STATUS < '92'
	and dateadd(mi, 3, pd.GIVEDATE) < getdate()
group by
	pd.CASEID,
	o.c_zip,
	pd.ORDERKEY,
	o.EXTERNORDERKEY,
	ad.AREAKEY,
	l.LOCATIONTYPE,
	c.COMPANY,
	c.ADDRESS1,
	c.ADDRESS2,
	c.ADDRESS3,
	lh.DEPARTURETIME,
	lh.[ROUTE],
	o.PRIORITY


print 'выбираем кейсы в работе'
--по таскдетейл
select td.caseid 
into #tmpcw
from wh1.taskdetail td
	join #tmpc t on td.CASEID = t.CASEID
where td.STATUS != '0'


print 'удаляем кейсы в работе'

delete t
from #tmpc t join #tmpcw tw on t.CASEID = tw.CASEID

if (select COUNT(caseid) from #tmpc) != 0  --нет кейсов для работы
	begin
		select top(1)
			CASEID,
			SH,
			status,
			ORDERKEY,
			EXTERNORDERKEY,
			AREAKEY,
			LOCATIONTYPE,
			COMPANY,
			ADDRESS1,
			ADDRESS2,
			ADDRESS3,
			DEPARTURETIME,
			[ROUTE],
			PRIORITY,
			eww
		from #tmpc t
		order by
			t.PRIORITY asc
	end
else
	begin
		print''
	end	
	
	
	


drop table #tmpc
drop table #tmpcw



