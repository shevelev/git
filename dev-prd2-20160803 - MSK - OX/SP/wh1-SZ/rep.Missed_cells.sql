/* Проверка лист */
ALTER PROCEDURE [rep].[Missed_cells] (
	@loc1 varchar(20),
	@loc2 varchar(20)
)
AS

declare @sql varchar(max)

--declare @loc1 varchar(10)
--declare @loc2 varchar(10)
--set @loc1 = 'D1C01.2.01'
--set @loc2 = 'D1C05.2.02'

create table #invtt (
loc varchar(30),
sku varchar(30),
lot varchar(30),
la2 varchar(30),
la4 datetime,
la5 datetime,
qtyf varchar(30),
qtyi varchar(30))


set @sql='insert into #invtt select lxlx.loc,lxlx.sku, lxlx.LOT,la.LOTTABLE02, la.LOTTABLE04, la.LOTTABLE05 ,lxlx.qty, '''' 
from wh1.LOTXLOCXID lxlx
join wh1.LOTATTRIBUTE la on la.LOT=lxlx.lot
where lxlx.QTY>0'
set @sql=@sql+ case when isnull(''+@loc1+'','') = '' then '' else ' and lxlx.loc between '''+@loc1+''' and '''+@loc2+'''' end
set @sql=@sql+ ' order by lxlx.loc'
print (@sql)
exec(@sql)



select SKU, LOC, LOT, max(inventorytag) mig
into #test
 from wh1.physical 
 where STATUS='0' 
 group by SKU, LOC, LOT

select p.* 
into #ph
from wh1.physical p
join #test t on p.SKU = t.SKU and p.LOC=t.LOC and p.LOT=t.LOT and p.INVENTORYTAG=t.mig


update #invtt set qtyi = p.qty
from #invtt tt 
left join #ph p on tt.sku=p.SKU and tt.loc=p.LOC and tt.lot=p.LOT


delete from #invtt where /* qtyf='0.00000' and */ qtyi is not null

select tt.*, s.notes1 from #invtt tt
join wh1.SKU s on tt.sku=s.sku

drop table #invtt
drop table #test
drop table #ph

