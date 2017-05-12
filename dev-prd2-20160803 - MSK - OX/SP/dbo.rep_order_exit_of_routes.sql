/*
Отчет: Отчеты склада/Аналитические/Выход заказов по маршрутам
Дата: 08.05.2014
Автор: Шевелев С.С.
*/
ALTER PROCEDURE [dbo].[rep_order_exit_of_routes]
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

insert into DA_InboundErrorsLog (source,msg_errdetails) values ('route','маршруты: '+@routes)

select ROUTE, ADDDATE, ORDERKEY, EXTERNORDERKEY
from wh1.ORDERS
where @routes is NULL or ROUTE in (select SLICE from dbo.sub_udf_common_split_string(@routes,',')) and ADDDATE between @date_from and @date_to
order by 1,2
	
end

