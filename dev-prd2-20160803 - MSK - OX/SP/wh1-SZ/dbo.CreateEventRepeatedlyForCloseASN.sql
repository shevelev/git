ALTER PROCEDURE [dbo].[CreateEventRepeatedlyForCloseASN]
AS
DECLARE @table table 
	(receiptkey varchar(10), --ПУО
	qtyOpened int,			 --Кол-во открытых ЗЗ
	qtyClosed int);			 --закрытых ЗЗ для данного ПУО


INSERT INTO @table(receiptkey,qtyOpened,qtyClosed)
SELECT 
	r.RECEIPTKEY, 
	COUNT(CASE WHEN p.STATUS!=11 THEN 1 ELSE NULL END) [Open],
	COUNT(CASE p.STATUS WHEN 11 THEN 1 ELSE NULL END) [Close]
	
FROM  wh1.RECEIPT r join wh1.po p 
	  on r.RECEIPTKEY=p.OTHERREFERENCE
WHERE 
	r.STATUS = 11 
	and r.EDITDATE > DATEADD(DAY,-7,GETDATE())
GROUP BY r.RECEIPTKEY
HAVING COUNT(CASE WHEN p.STATUS!=11 THEN 1 ELSE NULL END)!=0 --где есть открытые ЗЗ

DECLARE @receiptkey varchar(10),
		@qtyOpened int,
		@qtyClosed int;

SELECT *
FROM @table

WHILE (EXISTS(SELECT top 1 receiptkey from @table))
 BEGIN
	SELECT top 1 @receiptkey=receiptkey, @qtyOpened=qtyOpened, @qtyClosed=qtyClosed
	from @table
	
	IF(@qtyOpened = @qtyClosed + @qtyOpened)--Если все ЗЗ не закрыты
	BEGIN
		print @receiptkey
		declare @transmitlogkey varchar(10)
		exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output

		insert wh1.transmitlog (whseid, transmitlogkey, tablename, ADDWHO, key1) 
		values ('WH1', @transmitlogkey, 'asnclosed', 'infor',@receiptkey)
		
		exec app_DA_SendMail 'СКРИПТ - Закрытие ПУО: ', @receiptkey
		
		--print @transmitlogkey;
	END
		
	
	DELETE FROM @table
	WHERE receiptkey=@receiptkey
 END






