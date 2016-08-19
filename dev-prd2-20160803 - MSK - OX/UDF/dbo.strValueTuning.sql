ALTER FUNCTION [dbo].[strValueTuning] (@value varchar(max))
returns varchar(max)
begin
	set @value = upper(@value)
	set @value = replace(@value,';','_')
	set @value = replace(@value,'''','_')
	set @value = ltrim(rtrim(@value))
	return @value
end

