ALTER PROCEDURE [dbo].[mof_rep_sku_lot_loc]
	 @descr varchar(20) = null,
	 @sku varchar(20) = null,
	 @company varchar(20) = null,
	 @serial varchar(20) = null 
as
begin




select lx.sku,s.NOTES1, st.COMPANY, la.LOTTABLE02, la.LOTTABLE04, la.LOTTABLE05,lx.LOC, lx.qty

from wh2.lotxlocxid lx 
join wh2.SKU s on s.SKU= lx.sku
join wh2.storer st on st.STORERKEY=s.busr1
join wh2.LOTATTRIBUTE la on la.LOT=lx.LOT and la.SKU=lx.sku


where	lx.QTY>0 
		and( @sku is NULL or lx.sku = @sku )
		and( @company is NULL or st.company like '%'+@company+'%' )
		and( @descr is NULL or s.notes1 like '%'+@descr+'%' )
		and( @serial is NULL or la.LOTTABLE02 = @serial )
		
end


