ALTER PROCEDURE [rep].[inv_7_loc] 
( 
@sku varchar(10),
@l02 varchar(40),
@l04 datetime,
@l05 datetime,
@l06 varchar(40),
@skl int,
@lot varchar(10)
)
as


if @skl=1
	begin
	
		select lx.SKU, la.LOTTABLE01, la.LOTTABLE02, la.LOTTABLE04, la.LOTTABLE05, la.LOTTABLE06, lx.loc, lx.qty
from wh1.lotxlocxid lx
join wh1.LOTATTRIBUTE la on lx.LOT=la.lot
join wh1.loc l on lx.LOC=l.loc
where lx.QTY>0 and lx.SKU=@sku and la.LOTTABLE02=@l02 and la.LOTTABLE04=@l04 and la.LOTTABLE05=@l05 and la.LOTTABLE06=@l06 and l.PUTAWAYZONE in ('MED_PL','PAMP_PL','STEKLO_PL') and lx.LOT=@lot
order by lx.loc
	
	end
	
if @skl=0
	begin
	
		select lx.SKU, la.LOTTABLE01, la.LOTTABLE02, la.LOTTABLE04, la.LOTTABLE05, la.LOTTABLE06, lx.loc, lx.qty
from wh1.lotxlocxid lx
join wh1.LOTATTRIBUTE la on lx.LOT=la.lot
join wh1.loc l on lx.LOC=l.loc
where lx.QTY>0 and lx.SKU=@sku and la.LOTTABLE02=@l02 and la.LOTTABLE04=@l04 and la.LOTTABLE05=@l05 and la.LOTTABLE06=@l06 and l.PUTAWAYZONE not in ('MED_PL','PAMP_PL','STEKLO_PL')  and lx.LOT=@lot
order by lx.loc
	
	end
