ALTER PROCEDURE [dbo].[DA_STORER_DAX] 
AS
BEGIN

	select storer, 
		case					
			when folder='SZ' then 'Северо-Запад' 
			when folder='MSK' then 'МОФ' 
			when folder='MUR' then 'Мурманск' 
		end folder
	from [dbo].[DA_StorerFolder]

end
