/* Расхождения по ячейкам, по архивным инвентаркам */
ALTER PROCEDURE [dbo].[rep_inv_sv3] (
	@asd varchar(20)
)
AS

declare @sql varchar(max)

--declare @asd varchar(20)
--set @asd = '6'

create table #invtt (
loc varchar(30),
sku varchar(30),
lot varchar(30),
qtyf DECIMAL,
qtyi DECIMAL)


select LOC,SKU, LOT, max(inventorytag) mig
into #test
from wh1.physical_CST0030
where STATUS='0'  and physical_030=@asd
group by LOC, SKU, LOT

insert into #invtt (loc, sku, lot, qtyf, qtyi)
select t.LOC, t.SKU, t.LOT, 0, p.qty 
from #test t
join wh1.physical p on t.LOC=p.LOC and t.LOT=p.LOT and t.SKU=p.SKU and t.mig=p.INVENTORYTAG

insert into #invtt  (loc, sku, lot, qtyf, qtyi)
select lxlx.LOC, lxlx.SKU, lxlx.LOT, lxlx.QTY, 0 from wh1.lotxlocxid_CST0030 lxlx
where lxlx.QTY>0 and lxlx.inventoryid_030=@asd

select loc, sku, lot, sum(qtyf) fact, sum(qtyi)inv
into #itogi
from #invtt 
group by loc, sku, lot

set @sql='select i.loc, i.sku, i.lot, l.LOTTABLE02, l.LOTTABLE04, l.LOTTABLE05 ,i.fact, i.inv, s.notes1 
from #itogi i
join wh1.LOTATTRIBUTE l on l.LOT=i.lot
join wh1.SKU s on i.sku=s.sku'
print (@sql)
exec(@sql)

drop table #invtt
drop table #itogi
drop table #test
 


