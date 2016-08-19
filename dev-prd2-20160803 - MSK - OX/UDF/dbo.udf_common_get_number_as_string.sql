/*
Получение числа прописью
*/
ALTER FUNCTION dbo.udf_common_get_number_as_string (
	@number bigint,
	@gender tinyint = 1 -- 1=М, 2=Ж, 3=Ср
)
RETURNS varchar(2000)
AS
BEGIN
	declare
		@nword varchar(2000),
		@sign varchar(5),
		@th tinyint,
		@gr smallint,
		@d3 tinyint,
		@d2 tinyint,
		@d1 tinyint

	if @number=0 return 'ноль'
	
	if @number < 0 select @sign = 'минус', @number = - @number

	while @number > 0
	begin
		set @th = isnull(@th,0)+1
		set @gr = @number % 1000
		set @number = ( @number - @gr ) / 1000
		if @gr > 0
		begin
			set @d3 = (@gr-@gr%100)/100
			set @d1 = @gr % 10
			set @d2 = (@gr-@d3*100-@d1)/10
			if @d2=1 set @d1=10+@d1
			set @nword =
				case @d3
					when 1 then ' сто'
					when 2 then ' двести'
					when 3 then ' триста'
					when 4 then ' четыреста'
					when 5 then ' пятьсот'
					when 6 then ' шестьсот'
					when 7 then ' семьсот'
					when 8 then ' восемьсот'
					when 9 then ' девятьсот'
					else '' end
				+case @d2
					when 2 then ' двадцать'
					when 3 then ' тридцать'
					when 4 then ' сорок'
					when 5 then ' пятьдесят'
					when 6 then ' шестьдесят'
					when 7 then ' семьдесят'
					when 8 then ' восемьдесят'
					when 9 then ' девяносто'
					else '' end
				+case @d1
					when 1 then case
									when @th=2 or (@th=1 and @gender=2) then ' одна'
									when (@th=1 and @gender=3) then ' одно'
									else ' один'
								end
					when 2 then (case when @th=2 or (@th=1 and @gender=2) then ' две' else ' два' end)
					when 3 then ' три'
					when 4 then ' четыре'
					when 5 then ' пять'
					when 6 then ' шесть'
					when 7 then ' семь'
					when 8 then ' восемь'
					when 9 then ' девять'
					when 10 then ' десять'
					when 11 then ' одиннадцать'
					when 12 then ' двенадцать'
					when 13 then ' тринадцать'
					when 14 then ' четырнадцать'
					when 15 then ' пятнадцать'
					when 16 then ' шестнадцать'
					when 17 then ' семнадцать'
					when 18 then ' восемнадцать'
					when 19 then ' девятнадцать'
					else '' end
				+case @th
					when 2 then ' тысяч' + (case when @d1=1 then 'а' when @d1 in (2,3,4) then 'и' else '' end)
					when 3 then ' миллион'
					when 4 then ' миллиард'
					when 5 then ' триллион'
					when 6 then ' квадриллион'
					when 7 then ' квинтиллион'
					else '' end
				+case when @th in (3,4,5,6,7) then (case when @d1=1 then '' when @d1 in (2,3,4) then 'а' else 'ов' end) else '' end
				+isnull(@nword,'')
		end
	end
	set @nword = ltrim(isnull(@sign,'') + @nword)
	--return upper(left(@nword,1)) + right(@nword,len(@nword)-1)
	return @nword;
END

