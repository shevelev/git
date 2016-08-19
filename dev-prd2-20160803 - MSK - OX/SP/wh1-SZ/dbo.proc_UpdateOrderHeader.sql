--################################################################################################
-- Процедура обновляет дополнительные поля шапки ЗО
--################################################################################################
ALTER PROCEDURE [dbo].[proc_UpdateOrderHeader]
	@orderkey				varchar(10),
	@TRANSPORTATIONSERVICE	varchar(30)		--зона упаковки

AS

update wh1.orders
set TRANSPORTATIONSERVICE=isnull(@TRANSPORTATIONSERVICE,'')
where orderkey=@orderkey

