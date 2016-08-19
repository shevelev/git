/*
Возвращает список ПЛАНОВЫХ маршрутов между указанными датами
WEEK_DAY = номер дня недели независимо от настроек БД (1=ПН,7=ВС)
*/
ALTER FUNCTION dbo.sub_udf_get_routes_between_dates(
	@datetime_from datetime = NULL,
	@datetime_to datetime = NULL,
	@routes varchar(4000) = NULL
)
RETURNS @PLAN_ROUTES table (
	ROUTE_DATETIME datetime NOT NULL,
	ROUTEID varchar(50) NOT NULL,
	ROUTENAME varchar(255) NULL,
	LOCEXPEDITION varchar(20) NULL,
	START_BEFORE int NULL,
	WEEK_DAY tinyint NOT NULL,
	DEPARTURE_TIME time NOT NULL,
	ORDER_DEADLINE int NOT NULL
)
AS
BEGIN
	
	declare
		@date_from datetime,
		@date_to datetime,
		@days int
	
	set @date_from = dbo.udf_get_date_from_datetime(@datetime_from)
	set @date_to = dbo.udf_get_date_from_datetime(@datetime_to)
	set @routes = nullif(rtrim(@routes),'')
	set @days = datediff(dd,@date_from,@date_to) + 1
	
	insert into @PLAN_ROUTES
	select
		dateadd(dd,n.NUMBER-1,@date_from) + lg.DEPARTURE_TIME as ROUTE_DATETIME,
		lg.ROUTEID, lg.ROUTENAME, lg.LOCEXPEDITION, lg.START_BEFORE, lg.WEEK_DAY,
		lg.DEPARTURE_TIME, lg.ORDER_DEADLINE
	from dbo.sub_udf_common_get_natural_numbers(@days) n
		join dbo.sub_udf_get_loadgroup_settings(NULL,NULL) lg
		on ( @routes is NULL or lg.ROUTEID in (select SLICE from dbo.sub_udf_common_split_string(@routes,',')) )
			and lg.WEEK_DAY = dbo.sub_udf_common_get_invariant_weekday(dateadd(dd,n.NUMBER-1,@date_from))
			and dateadd(dd,n.NUMBER-1,@date_from) + lg.DEPARTURE_TIME >= lg.DATE_FROM
			and ( lg.DATE_TO is NULL or dateadd(dd,n.NUMBER-1,@date_from) + lg.DEPARTURE_TIME < lg.DATE_TO )
	where
		dateadd(dd,n.NUMBER-1,@date_from) + lg.DEPARTURE_TIME between @datetime_from and @datetime_to
	order by
		n.NUMBER,
		lg.DEPARTURE_TIME,
		lg.ROUTEID
	
	return
END

