/*
��������� ����� ��������
*/
ALTER FUNCTION dbo.udf_common_get_number_as_string (
	@number bigint,
	@gender tinyint = 1 -- 1=�, 2=�, 3=��
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

	if @number=0 return '����'
	
	if @number < 0 select @sign = '�����', @number = - @number

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
					when 1 then ' ���'
					when 2 then ' ������'
					when 3 then ' ������'
					when 4 then ' ���������'
					when 5 then ' �������'
					when 6 then ' ��������'
					when 7 then ' �������'
					when 8 then ' ���������'
					when 9 then ' ���������'
					else '' end
				+case @d2
					when 2 then ' ��������'
					when 3 then ' ��������'
					when 4 then ' �����'
					when 5 then ' ���������'
					when 6 then ' ����������'
					when 7 then ' ���������'
					when 8 then ' �����������'
					when 9 then ' ���������'
					else '' end
				+case @d1
					when 1 then case
									when @th=2 or (@th=1 and @gender=2) then ' ����'
									when (@th=1 and @gender=3) then ' ����'
									else ' ����'
								end
					when 2 then (case when @th=2 or (@th=1 and @gender=2) then ' ���' else ' ���' end)
					when 3 then ' ���'
					when 4 then ' ������'
					when 5 then ' ����'
					when 6 then ' �����'
					when 7 then ' ����'
					when 8 then ' ������'
					when 9 then ' ������'
					when 10 then ' ������'
					when 11 then ' �����������'
					when 12 then ' ����������'
					when 13 then ' ����������'
					when 14 then ' ������������'
					when 15 then ' ����������'
					when 16 then ' �����������'
					when 17 then ' ����������'
					when 18 then ' ������������'
					when 19 then ' ������������'
					else '' end
				+case @th
					when 2 then ' �����' + (case when @d1=1 then '�' when @d1 in (2,3,4) then '�' else '' end)
					when 3 then ' �������'
					when 4 then ' ��������'
					when 5 then ' ��������'
					when 6 then ' �����������'
					when 7 then ' �����������'
					else '' end
				+case when @th in (3,4,5,6,7) then (case when @d1=1 then '' when @d1 in (2,3,4) then '�' else '��' end) else '' end
				+isnull(@nword,'')
		end
	end
	set @nword = ltrim(isnull(@sign,'') + @nword)
	--return upper(left(@nword,1)) + right(@nword,len(@nword)-1)
	return @nword;
END

