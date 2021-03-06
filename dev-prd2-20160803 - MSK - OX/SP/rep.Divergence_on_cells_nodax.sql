/* ����������� �� ������� */
ALTER PROCEDURE [rep].[Divergence_on_cells_nodax] (
	@loc1 varchar(20),
	@loc2 varchar(20)
)
AS
declare @sql varchar(max)

--declare @loc1 varchar(10)
--declare @loc2 varchar(10)
--set @loc1 = 'PTV'
--set @loc2 = 'PTV'

create table #invtt (
loc varchar(30),
sku varchar(30),
lot varchar(30),
lot02 varchar(30),
lot04 datetime,
lot05 datetime,
qtyf DECIMAL,
qtyi DECIMAL)


select LOC,SKU, LOT, max(inventorytag) mig
into #test
from wh1.physical 
where STATUS='0'  and SKU !='EMPTY'
group by LOC, SKU, LOT


insert into #invtt (loc, sku, lot, qtyf, qtyi)
select t.LOC, t.SKU, t.LOT, 0, p.qty 
from #test t
join wh1.physical p on t.LOC=p.LOC and t.LOT=p.LOT and t.SKU=p.SKU and t.mig=p.INVENTORYTAG

insert into #invtt  (loc, sku, lot, qtyf, qtyi)
select lxlx.LOC, lxlx.SKU, lxlx.LOT, lxlx.QTY, 0 from wh1.lotxlocxid lxlx
where lxlx.QTY>0

update t set t.lot02=la.LOTTABLE02, t.lot04=la.LOTTABLE04, t.lot05=la.LOTTABLE05
from #invtt t
join wh1.LOTATTRIBUTE la on t.lot=la.lot



select loc, sku, lot02,lot04,lot05 /*lot*/, sum(qtyf) fact, sum(qtyi)inv
into #itogi
from #invtt 
group by loc, sku, lot02,lot04,lot05
having sum(qtyf) <> sum(qtyi)

set @sql='select i.loc, i.sku, i.lot02, i.lot04, i.lot05 ,i.fact, i.inv, s.notes1 
from #itogi i
join wh1.SKU s on i.sku=s.sku'
set @sql=@sql+ case when isnull(''+@loc1+'','') = '' then '' else ' and i.loc between '''+@loc1+''' and '''+@loc2+'''' end

print (@sql)
exec(@sql)

drop table #invtt
drop table #itogi
drop table #test
