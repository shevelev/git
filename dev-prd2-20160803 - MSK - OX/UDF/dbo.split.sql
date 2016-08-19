ALTER FUNCTION [dbo].[split] (
	@string varchar(max),
	@delimiter varchar(10)
)
returns @table table (
	[Value] varchar(8000)
)

begin
	declare
		@nextString varchar(4000),
		@pos int,
		@nextPos int,
		@commaCheck varchar(1)
	
	set @nextString = ''
	set @commaCheck = right(@string, 1)
	set @string = @string + @delimiter
	set @pos = charindex(@delimiter, @string)
	set @nextPos = 1
	
	while (@pos <> 0)
	begin
		set @nextString = substring(@string, 1, @pos - 1)
		insert into @table ([Value]) values (@nextString)
		set @string = substring(@string, @pos + 1, len(@string))
		set @nextPos = @pos
		set @pos = charindex(@delimiter, @string)
	end
	return
end


