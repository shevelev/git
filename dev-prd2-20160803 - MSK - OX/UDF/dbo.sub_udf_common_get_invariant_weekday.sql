/*
Возвращает номер дня недели независимо от настроек БД (1=ПН,7=ВС)
*/
ALTER FUNCTION dbo.sub_udf_common_get_invariant_weekday (
	@datetime datetime
)
RETURNS tinyint
AS
BEGIN
	return (5 + @@datefirst + datepart(weekday,@datetime)) % 7 + 1
END

