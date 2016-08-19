/*
Таблица натуральных чисел от 1 до 1млн. (ограничение для скорости)
*/
ALTER FUNCTION dbo.sub_udf_common_get_natural_numbers (
	@limit int = 2048
)
RETURNS @NUMBERS table ( NUMBER int NOT NULL )
AS
BEGIN
	declare
		@max smallint,
		@multiply smallint
	
	select @max = max(number) + 1 from master.dbo.spt_values sv with (NOLOCK) where type = 'P'
	
	set @limit = isnull(@limit-1,@max-1)
	if @limit > 1000000 set @limit = 1000000
	
	set @multiply = @limit / @max
	
	insert into @NUMBERS
	select sv.number + x.number * @max + 1
	from ( select number from master.dbo.spt_values with (NOLOCK) where type = 'P' ) sv
		cross join ( select number from master.dbo.spt_values with (NOLOCK) where type = 'P' and number <= @multiply ) x
	where sv.number + x.number * @max <= @limit
	order by x.number, sv.number
	
	return
END

