ALTER PROCEDURE [dbo].[rep_CableIncorrect] as

select lli.lot, lli.loc, lli.sku, s.descr, qty, lottable03, lli.id from wh40.lotxlocxid lli
	join wh40.lotattribute la on lli.lot=la.lot
	join wh40.sku s on s.sku=lli.sku and s.storerkey = lli.storerkey
where lottable03 like 'C%'
and lli.id = '' and qty > 0

