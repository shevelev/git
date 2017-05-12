-- =============================================
-- Author:		Сандаков В.В.
-- Create date: 15.07.2008
-- Description:	отчет для операторов "список заказов по номеру заказа"
-- =============================================
ALTER PROCEDURE [dbo].[rep_SKU_by_order] (
	@sku varchar(20), 
	@wh varchar(20), 
	@STORERKEY varchar(20),
	@orderdatemin datetime = null,
	@orderdatemax datetime = null,
	@orderkey varchar(10) = null,
	@externorderkey varchar(10) = null,
	@status varchar(10) = null,
	@susr1 varchar(30) = null
)
AS

--set @storerkey = 'ST6661018350'
set @orderdatemax = dateadd(dy,1,@orderdatemax)

declare @sql varchar(max)

set @sql = 'select distinct pd.orderkey, o.adddate, o.susr1, o.EXTERNORDERKEY, pd.sku, oss.description, o.STORERKEY
from '+@wh+'.pickdetail pd
join '+@wh+'.ORDERS o on o.ORDERKEY = pd.orderkey
join '+@WH+'.ORDERSTATUSSETUP oss on o.status = oss.code
where ' +
' o.STORERKEY = '''+@STORERKEY+''' ' +
case when @sku is null  then '' else ' and pd.sku = '''+@sku+''' ' end +
case when @orderdatemin is null  then '' else ' and o.orderdate >= '''+convert(varchar(10),@orderdatemin,112)+''' ' end +
case when @orderdatemax is null  then '' else ' and o.orderdate < '''+convert(varchar(10),@orderdatemax,112)+''' ' end +
case when @orderkey is null  then '' else ' and o.orderkey like ''' + @orderkey + ''' ' end +
case when @externorderkey is null  then '' else ' and o.externorderkey like ''' + @externorderkey + ''' ' end +
case when @status is null  then '' else ' and o.status = ''' + @status + ''' ' end +
case when @susr1 is null  then '' else ' and o.susr1 like ''' + @susr1 + ''' ' end

exec(@sql)

