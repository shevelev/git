-- =============================================
-- Author:		Сандаков В.В.
-- Create date: 08.09.08
-- Description:	товары в STAGE
-- =============================================
ALTER PROCEDURE [dbo].[rep_SKU_in_STAGE] (
	@wh varchar(10),
	@date1 smalldatetime=null,
	@date2 smalldatetime=null,
	@sku varchar(20)
)
AS
/*----------test----------*/
--declare @wh varchar(10),
--	@date1 smalldatetime,
--	@date2 smalldatetime,
--	@sku varchar(20)
--
--set @wh = 'wh40'
--set @date2 = getdate()
--set @date1 = dateadd(dy, -10, @date2)
--set @sku = ''
/*------------------------*/

declare @sql varchar(max)

set @sql = '
select  distinct lli.sku, sum(lli.qty) qty,rd.RECEIPTKEY, max(rd.EXTERNRECEIPTKEY) EXTERNRECEIPTKEY, rd.carriername,s.vat, rd.editdate, sk.descr, rd.editwho
from '+@wh+'.lotxlocxid lli
left join '+@wh+'.lotattribute l on l.lot = lli.lot
left join '+@wh+'.receipt rd on rd.receiptkey = l.lottable06
left join '+@wh+'.storer s on s.STORERKEY = rd.carrierkey
left join '+@wh+'.sku sk on sk.sku = lli.sku
where 1=1
	and lli.loc = ''stage'' 
	and lli.qty <> 0'+
	case when @date1 is null  then '' else ' AND lli.adddate >= '''+convert(varchar(10),@date1,112)+''' ' end +
	case when @date2 is null then '' else ' AND lli.adddate < '''+convert(varchar(10),@date2,112)+''' ' end +
	case when isnull(@sku,'')='' then '' else ' AND lli.sku = '''+@sku+''' ' end+
' group by lli.sku, rd.RECEIPTKEY, rd.carriername, s.vat, rd.editdate, sk.descr,rd.editwho
 order by lli.sku'
exec (@sql)

