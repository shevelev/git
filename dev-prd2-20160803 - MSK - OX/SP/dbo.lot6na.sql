ALTER PROCEDURE [dbo].[lot6na] 
AS

set NOCOUNT on


declare @lot varchar(10)
declare @receipt varchar(10)
declare @line varchar(10)
declare @id varchar(10)


select serialkey
into #id from wh1.lot6na where [status]=5

while (exists (select serialkey from #id))
	begin
			--Берем 1 партию по добавлению
		select  top 1 @id=serialkey from #id order by serialkey
			-- Находим партию инфора
		select @lot=lot from wh1.lot6na where serialkey=@id
			-- Находим заказ на приемку по партии
		select @receipt=RECEIPTKEY, @line=RECEIPTLINENUMBER from wh1.RECEIPTDETAIL where TOLOT=@lot
			-- Обновляем партию в инфоре
		update wh1.LOTATTRIBUTE set LOTTABLE06=@receipt+'-'+@line where LOT=@lot
			-- Обновляем данные заказа
		update wh1.RECEIPTDETAIL set LOTTABLE06=@receipt+'-'+@line where RECEIPTKEY=@receipt and TOLOT=@lot
		
		update wh1.lot6na set receipt=@receipt, line=@line, status=10 where serialkey=@id
		
		select @lot, @receipt, @line

	
		delete #id where serialkey=@id
	end
	
drop table #id


