/*
Отчет о просроченных маршрутах.
*/
ALTER PROCEDURE [rep].[Deviation_routes_from_reference_time]
	@date_from datetime = NULL,
	@time_from varchar(5) = NULL,
	@date_to datetime = NULL,
	@time_to varchar(5) = NULL,
	@routes varchar(4000) = NULL,
	@order varchar(255) = NULL
as
begin
	set NOCOUNT on
	
	declare @CRLF char(2)
	set @CRLF = char(13)+char(10)
	
	set @date_to = dbo.udf_get_date_from_datetime(isnull(@date_to,getdate()))
	set @date_from = dbo.udf_get_date_from_datetime(isnull(@date_from,@date_to))
	
	if dbo.sub_udf_common_regex_is_match(@time_from,'^([01][0-9]|2[0-3]):[0-5][0-9]$') = 1
		set @date_from = convert(datetime, convert(varchar(10),@date_from,120) + ' ' + @time_from + ':00',120)
	
	if dbo.sub_udf_common_regex_is_match(@time_to,'^([01][0-9]|2[0-3]):[0-5][0-9]$') = 1
		set @date_to = convert(datetime, convert(varchar(10),@date_to,120) + ' ' + @time_to + ':59',120)
	else
		set @date_to = @date_to + convert(time,'23:59:59.997')
	
	set @routes = nullif(rtrim(@routes),'')
	
	declare @ORDERS_FILTERED table (
		ORDERKEY varchar(10) NULL
	)
	
	set @order = nullif(rtrim(@order),'')
	
	if @order is NOT NULL
	begin
		set @order = replace(@order,'_','[_]')
		
		insert into @ORDERS_FILTERED
		select o.ORDERKEY
		from wh1.ORDERS o
		where o.EXTERNORDERKEY like '%' + @order + '%'
	end
	
	-- -- 8< -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	
	-- необходимы даты отсечения заказов, вылезающих за первую границу, но попадающих в первую отгрузку.
	
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
	
	--select * from dbo.sub_udf_get_loadgroup_settings(3) x
	
	select
		'№' + r.ROUTEID + @CRLF + r.ROUTENAME as ROUTEID,
		o.ORDERKEY,
		o.EXTERNORDERKEY,
		min(r.ROUTE_DATETIME) as PLAN_ROUTE_DATETIME,
		f.ORDERKEY as FILTERED_ORDERKEY
	into #ORDERS
	from dbo.sub_udf_get_routes_between_dates(@date_from,@date_to,@routes) r
		join #MIN_ORDER_DATETIME m on m.ROUTEID = r.ROUTEID
		join wh1.ORDERS o with (NOLOCK,NOWAIT) on o.[ROUTE] = r.ROUTEID
			and o.ADDDATE between m.MIN_ORDER_DATETIME and dateadd(hh,-r.ORDER_DEADLINE,r.ROUTE_DATETIME)
		left join @ORDERS_FILTERED f on f.ORDERKEY = o.ORDERKEY
	group by
		r.ROUTEID, r.ROUTENAME,
		o.ORDERKEY, o.EXTERNORDERKEY,
		f.ORDERKEY
	
	--select * from #ORDERS xo join wh1.ORDERS o on o.ORDERKEY = xo.ORDERKEY
	
	-- -- 8< -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	
	set ANSI_WARNINGS off -- NULLs в игнор
	
	select
		o.ROUTEID,
		--o.ORDERKEY,
		o.PLAN_ROUTE_DATETIME,
		nullif(max(isnull(op.ADDDATE,@max_datetime)),@max_datetime) as FACT_ORDER_PACKED,
		datediff(mi,max(isnull(op.ADDDATE,getdate())),o.PLAN_ROUTE_DATETIME) as ORDER_PACKED_DEVIATION,
		nullif(max(isnull(oe.ADDDATE,@max_datetime)),@max_datetime) as FACT_ORDER_FINISH,
		datediff(mi,max(isnull(oe.ADDDATE,getdate())),o.PLAN_ROUTE_DATETIME) as ORDER_FINISH_DEVIATION
	into #DEVIATIONS
	from #ORDERS o
		left join wh1.ORDERSTATUSHISTORY op with (NOLOCK,NOWAIT) on op.ORDERKEY = o.ORDERKEY and op.ORDERLINENUMBER = ''
			and op.[STATUS] between '68' and '78' -- Упаковка завершена/контроль пройден
		left join wh1.ORDERSTATUSHISTORY oe with (NOLOCK,NOWAIT) on oe.ORDERKEY = o.ORDERKEY and oe.ORDERLINENUMBER = ''
			and oe.[STATUS] between '92' and '95' -- Част. отгружен/Отгрузка завершена
	group by
		o.ROUTEID,
		--o.ORDERKEY,
		o.PLAN_ROUTE_DATETIME
	having ( @order is NULL or max(o.FILTERED_ORDERKEY) is NOT NULL )
	
	set ANSI_WARNINGS on
		
	--select * from #DEVIATIONS
	
	--select * from wh1.ORDERSTATUSSETUP o
	--select * from wh1.ORDERSTATUSHISTORY o where o.ORDERKEY = '0000037129' and o.ORDERLINENUMBER = '' order by o.ADDDATE desc
	
	select
		*,
		(
			select xo.EXTERNORDERKEY as 'data()'
			from #ORDERS xo
			where xo.ROUTEID = d.ROUTEID and xo.PLAN_ROUTE_DATETIME = d.PLAN_ROUTE_DATETIME
			order by xo.EXTERNORDERKEY
			for xml path('')
		) as ORDERS,
		dbo.udf_common_get_datepart_suffix('n',d.ORDER_PACKED_DEVIATION,d.PLAN_ROUTE_DATETIME,4) as ORDER_PACKED_DEVIATION_DESCRIPTION,
		dbo.udf_common_get_datepart_suffix('n',d.ORDER_FINISH_DEVIATION,d.PLAN_ROUTE_DATETIME,4) as ORDER_FINISH_DEVIATION_DESCRIPTION
	from #DEVIATIONS d
	order by
		right('000' + d.ROUTEID,3), d.PLAN_ROUTE_DATETIME
	
end

