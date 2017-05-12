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
			--����� 1 ������ �� ����������
		select  top 1 @id=serialkey from #id order by serialkey
			-- ������� ������ ������
		select @lot=lot from wh1.lot6na where serialkey=@id
			-- ������� ����� �� ������� �� ������
		select @receipt=RECEIPTKEY, @line=RECEIPTLINENUMBER from wh1.RECEIPTDETAIL where TOLOT=@lot
			-- ��������� ������ � ������
		update wh1.LOTATTRIBUTE set LOTTABLE06=@receipt+'-'+@line where LOT=@lot
			-- ��������� ������ ������
		update wh1.RECEIPTDETAIL set LOTTABLE06=@receipt+'-'+@line where RECEIPTKEY=@receipt and TOLOT=@lot
		
		update wh1.lot6na set receipt=@receipt, line=@line, status=10 where serialkey=@id
		
		select @lot, @receipt, @line

	
		delete #id where serialkey=@id
	end
	
drop table #id


