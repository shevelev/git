
/*
Отчет: Просроченный товар.
Автор: Шевелев С.С.
Дата: 12.05.2014
*/

ALTER PROCEDURE [dbo].[mof_SP_LOSTSROK] 
@date datetime
AS


select lx.SKU, s.DESCR, la.LOTTABLE02, la.LOTTABLE04, la.LOTTABLE05, lx.LOC, lx.qty from wh2.lotxlocxid lx
join wh2.sku s on lx.SKU=s.sku
join wh2.LOTATTRIBUTE la on lx.LOT=la.lot
where lx.QTY>0 and la.LOTTABLE05 <= @date
