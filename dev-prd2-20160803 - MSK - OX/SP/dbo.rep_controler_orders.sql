/*
Отчет: Отчеты склада/Аналитические/Какие заказы проверяли контролеры в определенный промежуток времени
Дата: 28.05.2014
Автор: Шевелев С.С.
*/
ALTER PROCEDURE [dbo].[rep_controler_orders]
	@date_from datetime = NULL,
	@time_from varchar(5) = NULL,
	@date_to datetime = NULL,
	@time_to varchar(5) = NULL
as
begin
	set NOCOUNT on
	
	set @date_from = dbo.udf_get_date_from_datetime(isnull(@date_from,getdate()))
	set @date_to = dbo.udf_get_date_from_datetime(isnull(@date_to,getdate()))
	
	
	if dbo.sub_udf_common_regex_is_match(@time_from,'^([01][0-9]|2[0-3]):[0-5][0-9]$') = 1
		set @date_from = convert(datetime, convert(varchar(10),@date_from,120) + ' ' + @time_from + ':00',120)
	
	if dbo.sub_udf_common_regex_is_match(@time_to,'^([01][0-9]|2[0-3]):[0-5][0-9]$') = 1
		set @date_to = convert(datetime, convert(varchar(10),@date_to,120) + ' ' + @time_to + ':59',120)
	else
		set @date_to = @date_to + convert(time,'23:59:59.997')
	
	-- -- 8< -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	
	select usr.usr_lname + ' ' + usr.usr_fname name, pl.orderkey  
	from wh1.PICKCONTROL_LABEL pl
		join ssaadmin.pl_usr usr on pl.ADDWHO=usr.usr_login
	where pl.ADDDATE between @date_from and @date_to
	group by usr.usr_lname + ' ' + usr.usr_fname, pl.orderkey
	order by 1,2

end


--exec [dbo].[rep_controler_orders] '20140520',null, '20140521',null
