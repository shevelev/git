ALTER PROCEDURE [dbo].[proc_DA_Transferfinalized](
	@wh varchar(10),
	@transmitlogkey varchar (10)
)as

	insert into DA_InboundErrorsLog (source,msg_errdetails) 
	values ('proc_DA_Transferfinalized','������� ������: ' +@wh)

	if @wh = 'WH1'
		exec [WH1].[proc_DA_Transferfinalized] @wh, @transmitlogkey
	else if @wh = 'WH2'
		exec [WH2].[proc_DA_Transferfinalized] @wh, @transmitlogkey
