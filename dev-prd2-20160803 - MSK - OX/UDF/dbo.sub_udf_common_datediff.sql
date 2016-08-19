/*
Вычисление разницы между датами по системному справочнику
*/
ALTER FUNCTION dbo.sub_udf_common_datediff (
	@datepart_id tinyint, -- SimpleDictionary = 72
	@start_datetime datetime, -- начальная дата
	@end_datetime datetime -- конечная дата
)
RETURNS int
AS
BEGIN
	
	return case @datepart_id
			when 1 then datediff(yy,@start_datetime,@end_datetime)
			when 2 then datediff(qq,@start_datetime,@end_datetime)
			when 3 then datediff(mm,@start_datetime,@end_datetime)
			when 4 then datediff(wk,@start_datetime,@end_datetime)
			when 5 then datediff(dd,@start_datetime,@end_datetime)
			when 6 then datediff(hh,@start_datetime,@end_datetime)
			when 7 then datediff(mi,@start_datetime,@end_datetime)
			when 8 then datediff(ss,@start_datetime,@end_datetime)
			else NULL
		end
	
END

