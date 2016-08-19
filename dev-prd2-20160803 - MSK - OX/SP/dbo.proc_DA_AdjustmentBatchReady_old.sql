-- ÎÒÏĞÀÂÊÀ ÎÁÚÅÄÈÍÅÍÍÎÉ ÊÎĞĞÅÊÒÈĞÎÂÊÈ Â ÕÎÑÒ-ÑÈÑÒÅÌÓ

ALTER PROCEDURE [dbo].[proc_DA_AdjustmentBatchReady_old](
	@wh varchar(10),
	@transmitlogkey varchar (10) )
AS

SET NOCOUNT ON

declare @batchkey varchar(10)

select @batchkey = key1 from wh1.transmitlog 
where transmitlogkey = @transmitlogkey

-- âåğíóòü ğåçóëüòàò
select 'ADJUSTMENT' filetype, 
		storerkey, sku, deltaqty, 
		convert(varchar(10),da.editdate,112) as editdate, zone 
from DA_Adjustment da where da.whseid = @wh and da.batchkey = @batchkey

