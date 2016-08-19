
ALTER PROCEDURE [rep].[mof_CaseID_labels] 
@user varchar(20),
@area varchar(20)
AS

--declare @queryid varchar(15)
	-- новый номер queryid
--	exec dbo.DA_GetNewKey 'wh2','queryid',@queryid output
-- выбор прав пользователя
--select * into #userright from wh2.TASKMANAGERUSERDETAIL where USERKEY = @user and AREAKEY = @area
declare @allowpiece varchar (10)
declare @ALLOWPALLET varchar (10)
declare @ALLOWCASE varchar (10)


select top 1
	@ALLOWCASE = case when ALLOWCASE = 1 then 'CASE' else '' end,
	@ALLOWPALLET = case when ALLOWPALLET = 1 then 'OTHER' else '' end,
	@allowpiece = case when allowpiece = 1 then 'PICK' else '' end
from wh2.TASKMANAGERUSERDETAIL
where PERMISSIONTYPE = 'pk'
	and AREAKEY = case when isnull(@area, '') = '' then AREAKEY else @area end
--	and USERKEY = @user
	and PERMISSION = 1

--print @ALLOWCASE+ @ALLOWPALLET+ @allowpiece

print 'выбираем свободные кейсы'

select distinct
	pd.CASEID, dbo.GetEAN128(pd.CASEID) SH, right(o.EXTERNORDERKEY,1) STATUS, pd.ORDERKEY, o.EXTERNORDERKEY,
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
from wh2.PICKDETAIL as pd
	join wh2.LOC as l on pd.LOC = l.LOC
	join wh2.AREADETAIL as ad on ad.PUTAWAYZONE = l.PUTAWAYZONE
	join wh2.ORDERS as o on o.ORDERKEY = pd.ORDERKEY
	left join wh2.STORER c on o.CONSIGNEEKEY = c.STORERKEY
	left join wh2.LOADHDR as lh on o.LOADID = lh.LOADID
	join wh2.LOTATTRIBUTE la on pd.LOT = la.lot
	join wh2.PACK pa on la.LOTTABLE01 = pa.packkey
where pd.[STATUS] = 1
	and ad.areakey = case when isnull(@area, '') = '' then ad.areakey else @area end
	and isnull(pd.PDUDF3, '') = ''
	and o.STATUS < '92'
	and dateadd(mi, 3, pd.GIVEDATE) < getdate()
group by
	pd.CASEID,
	pd.STATUS,
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
from wh2.taskdetail td
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



