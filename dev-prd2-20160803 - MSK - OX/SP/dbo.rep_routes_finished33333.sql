/*
Отчет о просроченных маршрутах.
*/
ALTER PROCEDURE [dbo].[rep_routes_finished33333]
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
	
	select xo.ROUTEID, xo.PLAN_ROUTE_DATETIME, COUNT(o.SERIALKEY)
	
	
	from #ORDERS xo 
	join wh1.ORDERDETAIL o on o.ORDERKEY = xo.ORDERKEY
	group by xo.ROUTEID, xo.PLAN_ROUTE_DATETIME
	order by 1

	
end



