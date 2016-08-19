

ALTER PROCEDURE [dbo].[proc_DA_FizOstatki](
	@wh varchar(10),
	@transmitlogkey varchar (10)
)as

	if @wh = 'WH1'
		exec [WH1].[proc_DA_FizOstatki] @wh, @transmitlogkey
	else
		exec [WH2].[proc_DA_FizOstatki] @wh, @transmitlogkey

