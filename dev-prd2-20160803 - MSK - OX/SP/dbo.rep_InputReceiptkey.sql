-- =============================================
-- Author:		Сандаков В.В.
-- Create date: 11.06.2008
-- Description:	ввод в таблицы WH40.RECEIPT и WH40.RECEIPTDETAIL внутр и внеш номера ПУО
-- =============================================
ALTER PROCEDURE [dbo].[rep_InputReceiptkey]
	@rec varchar(30),
	@ext varchar(30)
AS
--set @rec = null
--	@ext = null

if (exists (select r.receiptkey from WH40.RECEIPT r where r.TYPE = 20 and r.receiptkey = @rec))
	begin
		update WH40.RECEIPT
			set EXTERNRECEIPTKEY = @ext
			where RECEIPTKEY = @rec
		update WH40.RECEIPTDETAIL
			set EXTERNRECEIPTKEY = @ext
			where (RECEIPTKEY = @rec) and (QTYRECEIVED = 0) and (QTYEXPECTED > 0)
		select 'В ПУО №' + @rec + ' номер Scala заменен на '+@ext  
	end
else
select 'Тип ПУО не правильный!!!'

