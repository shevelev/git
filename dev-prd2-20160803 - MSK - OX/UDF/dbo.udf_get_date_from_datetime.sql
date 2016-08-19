ALTER FUNCTION dbo.udf_get_date_from_datetime (
	@datetime datetime
)
RETURNS datetime
AS
BEGIN
	return cast(round(cast(@datetime as real), 0, 1) as datetime)
END

