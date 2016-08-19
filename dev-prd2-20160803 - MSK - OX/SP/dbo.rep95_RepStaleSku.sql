/* список товаров (кабель) которые невозможно отгрузить цельным куском */
ALTER PROCEDURE [dbo].[rep95_RepStaleSku](
 	@wh  varchar (10),
	@QtyDate decimal(22, 5)
) as
declare @sql varchar(max)

/* список заказов ################################################################################### */
set @sql =
'select st.company, st.vat, lli.lot, lli.loc, lli.id, sk.sku, sk.descr, dateadd(dy,sk.stdordercost,la.lottable04) dcost, lli.adddate, datediff(day,lli.adddate,getdate()) dstore, lli.qty
from '+@wh+'.lotxlocxid lli join '+@wh+'.sku sk on lli.sku = sk.sku and lli.storerkey = sk.storerkey
join '+@wh+'.lotattribute la on lli.lot = la.lot
join '+@wh+'.receipt r on la.lottable06 = r.receiptkey
join '+@wh+'.storer st on r.carrierkey = st.storerkey
where datediff(day,lli.adddate,getdate()) > '+cast(@QtyDate as varchar(15))+' and lli.qty > 0 order by dstore desc'
/* ################################################################################################## */

exec (@sql)

