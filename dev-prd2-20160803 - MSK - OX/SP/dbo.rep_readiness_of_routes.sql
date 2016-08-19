/*
6. ќтчет о готовности маршрутов к погрузке
*/
ALTER PROCEDURE dbo.rep_readiness_of_routes
	@date_from datetime = NULL,
	@time_from varchar(5) = NULL,
	@date_to datetime = NULL,
	@time_to varchar(5) = NULL,
	@routes varchar(4000) = NULL
as
begin
	set NOCOUNT on
	
	set @date_from = dbo.udf_get_date_from_datetime(isnull(@date_from,getdate()))
	set @date_to = dbo.udf_get_date_from_datetime(isnull(@date_to,getdate()))
	set @routes = nullif(rtrim(@routes),'')
	
	if dbo.sub_udf_common_regex_is_match(@time_from,'^([01][0-9]|2[0-3]):[0-5][0-9]$') = 1
		set @date_from = convert(datetime, convert(varchar(10),@date_from,120) + ' ' + @time_from + ':00',120)
	
	if dbo.sub_udf_common_regex_is_match(@time_to,'^([01][0-9]|2[0-3]):[0-5][0-9]$') = 1
		set @date_to = convert(datetime, convert(varchar(10),@date_to,120) + ' ' + @time_to + ':59',120)
	else
		set @date_to = @date_to + convert(time,'23:59:59.997')
	
	-- -- 8< -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	
	-- необходимы даты отсечени€ заказов, вылезающих за первую границу, но попадающих в первую отгрузку.
	
	declare
		@date_from_tmp datetime,
		@max_datetime datetime
	
	set @date_from_tmp = dateadd(dd,-7,@date_from)
	set @max_datetime = '99991231 23:59:59.997'
	
	select r.ROUTEID, max(dateadd(hh,-r.ORDER_DEADLINE,r.ROUTE_DATETIME)) as MIN_ORDER_DATETIME
	into #MIN_ORDER_DATETIME
	from dbo.sub_udf_get_routes_between_dates(@date_from_tmp,@date_from,@routes) r
	group by r.ROUTEID
	
	-- -- 8< -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	
	select
		r.ROUTEID,
		o.ORDERKEY,
		min(r.ROUTE_DATETIME) as PLAN_ROUTE_DATETIME
	into #ORDERS
	from dbo.sub_udf_get_routes_between_dates(@date_from,@date_to,@routes) r
		left join #MIN_ORDER_DATETIME m on m.ROUTEID = r.ROUTEID
		join wh1.ORDERS o with (NOLOCK,NOWAIT) on o.[ROUTE] = r.ROUTEID
			and (o.ADDDATE > m.MIN_ORDER_DATETIME or m.MIN_ORDER_DATETIME is NULL)
			and o.ADDDATE <= dateadd(hh,-r.ORDER_DEADLINE,r.ROUTE_DATETIME)
	group by
		r.ROUTEID,
		o.ORDERKEY
	
	--select * from #ORDERS xo join wh1.ORDERS o on o.ORDERKEY = xo.ORDERKEY
	
	-- -- 8< -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	
	;with TREE (ORDERKEY,DROPID,CHILDID) as (
		select distinct o.ORDERKEY,convert(varchar(20),p.CASEID),convert(varchar(20),p.CASEID)
		from wh1.PICKDETAIL p
			join #ORDERS o on o.ORDERKEY = p.ORDERKEY
		union all
		select t.ORDERKEY,convert(varchar(20),d.DROPID),convert(varchar(20),d.CHILDID)
		from wh1.DROPIDDETAIL d
			join TREE t on t.DROPID = d.CHILDID
	)
	select t.ORDERKEY, count(distinct t.CHILDID) as DROPS
	into #DROPS
	from TREE t
	where t.DROPID like 'TS%'
	group by t.ORDERKEY
	
	--;with TREE (ORDERKEY,DROPID,CHILDID) as (
	--	select distinct o.ORDERKEY,convert(varchar(20),p.CASEID),convert(varchar(20),p.CASEID)
	--	from wh1.PICKDETAIL p
	--		join #ORDERS o on o.ORDERKEY = p.ORDERKEY
	--	union all
	--	select t.ORDERKEY,convert(varchar(20),d.DROPID),convert(varchar(20),d.CHILDID)
	--	from wh1.DROPIDDETAIL d
	--		join TREE t on t.DROPID = d.CHILDID
	--)
	--select *
	--from TREE t
	----where t.DROPID like 'TS%'
	
	-- -- 8< -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	
	set ANSI_WARNINGS off -- NULLs в игнор
	
	select
		o.ROUTEID,
		--o.ORDERKEY,
		o.PLAN_ROUTE_DATETIME,
		sum(d.DROPS) as DROPS,
		nullif(max(isnull(sh.ADDDATE,@max_datetime)),@max_datetime) as FACT_ORDER_FINISH,
		datediff(mi,max(isnull(sh.ADDDATE,getdate())),o.PLAN_ROUTE_DATETIME) as ORDER_DEVIATION
	into #DEVIATIONS
	from #ORDERS o
		left join #DROPS d on o.ORDERKEY = d.ORDERKEY
		left join wh1.ORDERSTATUSHISTORY sh with (NOLOCK,NOWAIT) on sh.ORDERKEY = o.ORDERKEY and sh.ORDERLINENUMBER = ''
			and sh.[STATUS] between '68' and '78' -- ”паковка завершена/контроль пройден
	group by
		o.ROUTEID,
		--o.ORDERKEY,
		o.PLAN_ROUTE_DATETIME
	
	set ANSI_WARNINGS on
		
	--select * from #DEVIATIONS
	
	--select * from wh1.ORDERSTATUSSETUP o
	--select * from wh1.ORDERSTATUSHISTORY o where o.ORDERKEY = '0000037129' and o.ORDERLINENUMBER = '' order by o.ADDDATE desc
	
	select
		*,
		dbo.udf_common_get_datepart_suffix('n',d.ORDER_DEVIATION,d.PLAN_ROUTE_DATETIME,4) as ORDER_DEVIATION_DESCRIPTION
	from #DEVIATIONS d
	order by
		right('000' + d.ROUTEID,3), d.PLAN_ROUTE_DATETIME
	
end

