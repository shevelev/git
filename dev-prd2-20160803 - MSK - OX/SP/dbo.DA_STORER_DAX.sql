ALTER PROCEDURE [dbo].[DA_STORER_DAX] 
AS
BEGIN

	select storer, 
		case					
			when folder='SZ' then '������-�����' 
			when folder='MSK' then '���' 
			when folder='MUR' then '��������' 
		end folder
	from [dbo].[DA_StorerFolder]

end
