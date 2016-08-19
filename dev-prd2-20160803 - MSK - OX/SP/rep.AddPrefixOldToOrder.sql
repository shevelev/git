ALTER PROCEDURE [rep].[AddPrefixOldToOrder]
(
	@externOrderKey varchar(32)--='0039706'
)
AS

IF(EXISTS(SELECT * FROM wh1.ORDERS where EXTERNORDERKEY=@externOrderKey and STATUS = '95'))
BEGIN
	UPDATE wh1.ORDERS
	SET EXTERNORDERKEY = 'OLD'+ EXTERNORDERKEY
	WHERE EXTERNORDERKEY = @externOrderKey;
	SELECT 'ОК' AS Status
END
ELSE BEGIN
	SELECT 'Такого заказа нет или его статус отличен от статуса "Отгрузка завершена"' AS Status
END

