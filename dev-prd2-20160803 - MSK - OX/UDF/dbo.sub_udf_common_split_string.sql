/*Функция возвращает таблицу кусков строки*/
ALTER FUNCTION dbo.sub_udf_common_split_string (
	@string varchar(7998),
	@delim char(1)
)
RETURNS TABLE
AS
RETURN (
	with PIECES(START, STOP, RN) as (
		select 1, charindex(@delim, @string), 1
		union all
		select STOP + 1, charindex(@delim, @string, STOP + 1), RN + 1
		from PIECES
		where STOP > 0
	)
	select
		substring(@string, start, case when STOP > 0 then STOP-START else 7998 end) as SLICE,
		RN
	from PIECES
)

