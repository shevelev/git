
ALTER PROCEDURE [dbo].[proc_DA_CancelSO](
	@wh varchar(10),
	@transmitlogkey varchar (10)
)as

	if @wh = 'WH1'
		exec [WH1].[proc_DA_CancelSO] @wh, @transmitlogkey
	else if @wh = 'WH2'
		exec [WH2].[proc_DA_CancelSO] @wh, @transmitlogkey

