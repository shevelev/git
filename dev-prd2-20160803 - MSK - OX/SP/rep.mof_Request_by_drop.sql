/*
* Определение по DROP_ID или CASE_ID номера заказа «Инфора», номера внешнего заказа,
* входящих в него CASE_ID и DROP_ID и их статуса на текущий момент, и их содержимого.
*/
ALTER PROCEDURE [rep].[mof_Request_by_drop](

	@dropid varchar(18) = '',
	@caseid varchar(18) = ''
	)
as


begin
	create table #orders (
		ORDERKEY varchar(18),
		EXTERNORDERKEY varchar(200),
		[ROUTE] varchar(50),
		CASEID varchar(18),
		DROPID varchar(18),
		ORDER_STATUS varchar(200),
		LOTS int NULL
	)
	
	create table #drops (DROPID varchar(18), ORDERKEY varchar(18))
	
	select
		@dropid = nullif(rtrim(@dropid),''),
		@caseid = nullif(rtrim(@caseid),'')
	
	if @caseid is NOT NULL set @dropid = NULL
	
	if @dropid is NOT NULL
	or @caseid is NOT NULL
	begin
		;with tree (DROPID, CHILDID) as (
			select d.DROPID, d.CHILDID
			from wh2.DROPIDDETAIL d
				left join wh2.PICKDETAIL p on p.CASEID = d.CHILDID
			where ( d.DROPID = @dropid or @dropid is NULL )
				and ( p.CASEID = @caseid or @caseid is NULL )
			union all
			select d.DROPID,d.CHILDID
			from wh2.DROPIDDETAIL d
				join tree t on d.DROPID = t.CHILDID
		)
		insert into #drops
		select distinct
			t.CHILDID,
			p.ORDERKEY
			--,p.ORDERLINENUMBER
			--,p.SKU
		from tree t
			left join wh2.PICKDETAIL p on t.CHILDID = p.CASEID
		
		--select * from #orders
		
		;with tree (DROPID, CHILDID, THREAD, LEVEL) as (
			select d.DROPID, d.CHILDID, d.CHILDID, 1
			from #drops o
				join wh2.PICKDETAIL p on p.ORDERKEY = o.ORDERKEY
				join wh2.DROPIDDETAIL d on d.CHILDID = p.CASEID
			union all
			select d.DROPID, d.CHILDID, t.THREAD, t.LEVEL + 1
			from wh2.DROPIDDETAIL d
				join tree t on d.CHILDID = t.DROPID
		)
		insert into #orders
		select
			o.ORDERKEY,
			o.EXTERNORDERKEY,
			o.[ROUTE],
			x.CASEID,
			x.DROPID,
			s.[DESCRIPTION] as ORDER_STATUS,
			count(distinct p.LOT) as LOTS
		from (select THREAD as CASEID, DROPID, row_number() over (partition by THREAD order by LEVEL desc) as RN from tree) x
			join wh2.PICKDETAIL p on x.CASEID = p.CASEID
			join wh2.ORDERS o
				join wh2.ORDERSTATUSSETUP s on o.[STATUS] = s.CODE
			on o.ORDERKEY = p.ORDERKEY
		where x.RN = 1
		group by
			o.ORDERKEY,
			o.EXTERNORDERKEY,
			o.[ROUTE],
			x.DROPID,
			x.CASEID,
			s.[DESCRIPTION]
	end
	
	--select * from #orders
	
		select o.ORDERKEY, o.EXTERNORDERKEY, o.ROUTE, o.CASEID, o.DROPID, o.ORDER_STATUS, o.LOTS,
sum(ceiling(case when p.casecnt=0 then pd.qty/1 else pd.qty/p.casecnt end)) yashik, pc.boxnum
into #test
from #orders o
join wh2.PICKDETAIL pd on pd.ORDERKEY=o.ORDERKEY and o.CASEID=pd.CASEID 
join wh2.LOTATTRIBUTE lot on pd.LOT=lot.lot
join wh2.PACK p on lot.LOTTABLE01=p.packkey
left join wh2.PICKCONTROL_LABEL pc on pc.CASEID=pd.caseid
--where pd.CASEID='0000475929'
group by o.ORDERKEY, o.EXTERNORDERKEY, o.ROUTE, o.CASEID, o.DROPID, o.ORDER_STATUS, o.LOTS, pc.boxnum
order by o.ORDERKEY
	
	
	select t.ORDERKEY, t.EXTERNORDERKEY, t.ROUTE, t.CASEID, t.DROPID, t.ORDER_STATUS, t.LOTS,
	CASE when isnull(t.BOXNUM,'')='' then t.yashik else t.BOXNUM end as box from #test t
	drop table #orders
	drop table #drops
end


