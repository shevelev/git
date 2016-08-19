/*
Вычисление конечной даты по системному справочнику
*/
ALTER FUNCTION dbo.sub_udf_common_dateadd (
	@datepart_id tinyint, -- SimpleDictionary = 72
	@number numeric(18,8), -- количество единиц времени
	@datetime datetime
)
RETURNS datetime
AS
BEGIN
	declare
		@shift numeric(18,8),
		@result datetime
	
	set @shift = round(@number,0,1) -- усечение
	
	set @result = case @datepart_id
			when 1 then dateadd(yy,@shift,@datetime)
			when 2 then dateadd(qq,@shift,@datetime)
			when 3 then dateadd(mm,@shift,@datetime)
			when 4 then dateadd(wk,@shift,@datetime)
			when 5 then dateadd(dd,@shift,@datetime)
			when 6 then dateadd(hh,@shift,@datetime)
			when 7 then dateadd(mi,@shift,@datetime)
			when 8 then dateadd(ss,@shift,@datetime)
			else NULL
		end
	
	if @datepart_id < 8
	begin
		set @shift = @number - convert(numeric(18,8),dbo.sub_udf_common_datediff(@datepart_id,@datetime,@result))
		if @shift <> 0
		begin
			set @shift = convert(float,@shift)
					* case @datepart_id
							when 1 then 4
							when 2 then 3
							when 3 then dbo.sub_udf_common_get_days_count_in_month(@result) / 7
							when 4 then 7
							when 5 then 24
							when 6 then 60
							when 7 then 60
						end
			-- возвращаем скорректированные дату-время
			return dbo.sub_udf_common_dateadd(@datepart_id + 1, @shift, @result)
		end
	end
	
	return @result
	
END

