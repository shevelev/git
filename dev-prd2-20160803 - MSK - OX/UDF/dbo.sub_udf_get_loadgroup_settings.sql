/*
Возвращает ДЕЙСТВУЮЩИЕ на дату @report_date настройки маршрутов (транспонированную таблицу)
если @report_date = NULL, то возвращается ВСЯ ИСТОРИЯ
WEEK_DAY = номер дня недели независимо от настроек БД (1=ПН,7=ВС)
*/
ALTER FUNCTION dbo.sub_udf_get_loadgroup_settings(
	@routeid varchar(50) = NULL,
	@report_date datetime = NULL
)
RETURNS @RESULT table (
	ROUTEID varchar(50) NOT NULL,
	ROUTENAME varchar(255) NULL,
	LOCEXPEDITION varchar(20) NULL,
	START_BEFORE int NULL,
	WEEK_DAY tinyint NOT NULL,
	DEPARTURE_TIME time NOT NULL,
	ORDER_DEADLINE int NOT NULL,
	DATE_FROM datetime NOT NULL,
	DATE_TO datetime NULL
)
AS
BEGIN
	
	declare @LOAD_GROUP table (
		ROUTEID varchar(50) NOT NULL,
		ROUTENAME varchar(500) NULL,
		LOCEXPEDITION varchar(20) NULL,
		[1] time NULL, [10] int NULL,
		[2] time NULL, [20] int NULL,
		[3] time NULL, [30] int NULL,
		[4] time NULL, [40] int NULL,
		[5] time NULL, [50] int NULL,
		[6] time NULL, [60] int NULL,
		[7] time NULL, [70] int NULL,
		[START] int NULL,
		ADDDATE datetime NOT NULL,
		RN int NOT NULL
	)
	
	insert into @LOAD_GROUP
	select
		lg.ROUTEID,
		lg.ROUTENAME,
		lg.LOCEXPEDITION,
		lg.[1], lg.[10],
		lg.[2], lg.[20],
		lg.[3], lg.[30],
		lg.[4], lg.[40],
		lg.[5], lg.[50],
		lg.[6], lg.[60],
		lg.[7], lg.[70],
		lg.[START], lg.ADDDATE,
		row_number() over (partition by lg.ROUTEID order by lg.ADDDATE desc) as RN
	from dbo.LoadGroupHistory lg
	where ( @routeid is NULL or lg.ROUTEID = @routeid )
		and ( @report_date is NULL or lg.ADDDATE <= @report_date )
	
	-- -- 8< -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	
	insert into @RESULT
	select
		lg.ROUTEID,
		lg.ROUTENAME,
		lg.LOCEXPEDITION,
		lg.[start] as START_BEFORE,
		1 as WEEK_DAY,
		lg.[1] as DEPARTURE_TIME,
		lg.[10] as ORDER_DEADLINE,
		lg.ADDDATE as DATE_FROM,
		dt.ADDDATE as DATE_TO
	from @LOAD_GROUP lg
		left join @LOAD_GROUP dt on dt.ROUTEID = lg.ROUTEID and dt.RN = lg.RN - 1
	where lg.[1] is NOT NULL
		and ( @report_date is NULL or lg.RN = 1 )
	union all
	select
		lg.ROUTEID,
		lg.ROUTENAME,
		lg.LOCEXPEDITION,
		lg.[start] as START_BEFORE,
		2 as WEEK_DAY,
		lg.[2] as DEPARTURE_TIME,
		lg.[20] as ORDER_DEADLINE,
		lg.ADDDATE as DATE_FROM,
		dt.ADDDATE as DATE_TO
	from @LOAD_GROUP lg
		left join @LOAD_GROUP dt on dt.ROUTEID = lg.ROUTEID and dt.RN = lg.RN - 1
	where lg.[2] is NOT NULL
		and ( @report_date is NULL or lg.RN = 1 )
	union all
	select
		lg.ROUTEID,
		lg.ROUTENAME,
		lg.LOCEXPEDITION,
		lg.[start] as START_BEFORE,
		3 as WEEK_DAY,
		lg.[3] as DEPARTURE_TIME,
		lg.[30] as ORDER_DEADLINE,
		lg.ADDDATE as DATE_FROM,
		dt.ADDDATE as DATE_TO
	from @LOAD_GROUP lg
		left join @LOAD_GROUP dt on dt.ROUTEID = lg.ROUTEID and dt.RN = lg.RN - 1
	where lg.[3] is NOT NULL
		and ( @report_date is NULL or lg.RN = 1 )
	union all
	select
		lg.ROUTEID,
		lg.ROUTENAME,
		lg.LOCEXPEDITION,
		lg.[start] as START_BEFORE,
		4 as WEEK_DAY,
		lg.[4] as DEPARTURE_TIME,
		lg.[40] as ORDER_DEADLINE,
		lg.ADDDATE as DATE_FROM,
		dt.ADDDATE as DATE_TO
	from @LOAD_GROUP lg
		left join @LOAD_GROUP dt on dt.ROUTEID = lg.ROUTEID and dt.RN = lg.RN - 1
	where lg.[4] is NOT NULL
		and ( @report_date is NULL or lg.RN = 1 )
	union all
	select
		lg.ROUTEID,
		lg.ROUTENAME,
		lg.LOCEXPEDITION,
		lg.[start] as START_BEFORE,
		5 as WEEK_DAY,
		lg.[5] as DEPARTURE_TIME,
		lg.[50] as ORDER_DEADLINE,
		lg.ADDDATE as DATE_FROM,
		dt.ADDDATE as DATE_TO
	from @LOAD_GROUP lg
		left join @LOAD_GROUP dt on dt.ROUTEID = lg.ROUTEID and dt.RN = lg.RN - 1
	where lg.[5] is NOT NULL
		and ( @report_date is NULL or lg.RN = 1 )
	union all
	select
		lg.ROUTEID,
		lg.ROUTENAME,
		lg.LOCEXPEDITION,
		lg.[start] as START_BEFORE,
		6 as WEEK_DAY,
		lg.[6] as DEPARTURE_TIME,
		lg.[60] as ORDER_DEADLINE,
		lg.ADDDATE as DATE_FROM,
		dt.ADDDATE as DATE_TO
	from @LOAD_GROUP lg
		left join @LOAD_GROUP dt on dt.ROUTEID = lg.ROUTEID and dt.RN = lg.RN - 1
	where lg.[6] is NOT NULL
		and ( @report_date is NULL or lg.RN = 1 )
	union all
	select
		lg.ROUTEID,
		lg.ROUTENAME,
		lg.LOCEXPEDITION,
		lg.[start] as START_BEFORE,
		7 as WEEK_DAY,
		lg.[7] as DEPARTURE_TIME,
		lg.[70] as ORDER_DEADLINE,
		lg.ADDDATE as DATE_FROM,
		dt.ADDDATE as DATE_TO
	from @LOAD_GROUP lg
		left join @LOAD_GROUP dt on dt.ROUTEID = lg.ROUTEID and dt.RN = lg.RN - 1
	where lg.[7] is NOT NULL
		and ( @report_date is NULL or lg.RN = 1 )
	
	return
END

