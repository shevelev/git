ALTER PROCEDURE [dbo].[proc_DA_ReceiptConfirm](
	@wh varchar(10),
	@transmitlogkey varchar (10)
)as

			
	insert into DA_InboundErrorsLog (source,msg_errdetails) 
	values ('proc_DA_ReceiptConfirm','входные данные: ' +@wh)

	if @wh = 'WH1'
		exec [WH1].[proc_DA_ReceiptConfirm_DAX] @wh, @transmitlogkey
	else
		exec [WH2].[proc_DA_ReceiptConfirm] @wh, @transmitlogkey

