/*
Возвращает БЛИЖАЙШУЮ к @datetime дату отгрузки по маршруту с учетом настроенного DEADLINE
*/
ALTER FUNCTION dbo.udf_get_nearest_departure_datetime(
	@routeid varchar(50),
	@datetime datetime = NULL -- Если NULL, то ближайший к текущему моменту
)
RETURNS datetime
--WITH RETURNS NULL ON NULL INPUT
AS
BEGIN
	
	set @datetime = isnull(@datetime,getdate())
	
	declare @nearest_departure_datetime datetime
	
	--select dbo.sub_udf_common_get_invariant_weekday(@datetime),@datetime
	
	declare @DEPARTURES table(
		ORDER_DEADLINE int,
		DEPARTURE_TIME datetime
	)
	
	insert into @DEPARTURES
	select
		x.ORDER_DEADLINE,
		--(7 + x.WEEK_DAY - dbo.sub_udf_common_get_invariant_weekday(@datetime)) % 7 as ADD_DAYS, -- плюс к ДНЮ (создания) заказа, чтобы получить ДЕНЬ отгрузки
		dateadd(dd,(7 + x.WEEK_DAY - dbo.sub_udf_common_get_invariant_weekday(@datetime)) % 7,dbo.udf_get_date_from_datetime(@datetime)) + x.DEPARTURE_TIME as DEPARTURE_TIME -- ближайшие БУДУЩИЕ отгрузки без учета DEADLINE
		--,*
	from dbo.sub_udf_get_loadgroup_settings(@routeid,@datetime) x
	
	
	select top 1
		@nearest_departure_datetime = d.DEPARTURE_TIME
	from @DEPARTURES d
	where dateadd(hh,-d.ORDER_DEADLINE,d.DEPARTURE_TIME) >= @datetime
	order by d.DEPARTURE_TIME
	
	return @nearest_departure_datetime
END

