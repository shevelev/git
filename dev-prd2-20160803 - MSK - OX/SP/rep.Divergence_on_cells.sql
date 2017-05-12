/* Расхождения по ячейкам */

ALTER PROCEDURE [rep].[Divergence_on_cells] (

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
SUSR1 varchar(30),	--серия
SUSR4 datetime,		--произведен
SUSR5 datetime,		--годен до
qtyf DECIMAL,
qtyi DECIMAL);

create table #test (
loc varchar(30),
sku varchar(30),
SUSR1 varchar(30),	--серия
SUSR4 datetime,		--произведен
SUSR5 datetime,		--годен до
mig int);

insert into #test
select LOC,SKU, SUSR1,SUSR4,SUSR5, max(inventorytag) mig
from wh1.physical 
where STATUS='0' 
group by LOC, SKU, SUSR1,SUSR4,SUSR5;


insert into #invtt (loc, sku, SUSR1,SUSR4,SUSR5, qtyf, qtyi)
select t.LOC, t.SKU, t.SUSR1,t.SUSR4,t.SUSR5, 0, p.qty 
from #test t join wh1.physical p 
			ON  t.LOC=p.LOC  
			and t.SKU=p.SKU 
			and t.mig=p.INVENTORYTAG
			and t.SUSR1 = p.SUSR1
			and t.SUSR4 = p.SUSR4
			and t.SUSR5 = p.SUSR5;

insert into #invtt  (loc, sku, SUSR1,SUSR4,SUSR5, qtyf, qtyi)
select	lxlx.LOC, 
		lxlx.SKU, 
		atr.LOTTABLE02,
		atr.LOTTABLE04,
		atr.LOTTABLE05,
		lxlx.QTY, 
		0 
from wh1.lotxlocxid lxlx JOIN wh1.LOTATTRIBUTE atr
	ON lxlx.LOT = atr.LOT
where lxlx.QTY>0

select loc, sku, SUSR1,SUSR4,SUSR5, sum(qtyf) fact, sum(qtyi)inv
into #itogi
from #invtt 
group by loc, sku, SUSR1,SUSR4,SUSR5;

set @sql='
select i.loc, i.sku, i.SUSR1, i.SUSR4, i.SUSR5 ,i.fact, i.inv, s.notes1 
from #itogi i join wh1.SKU s on i.sku=s.sku'
set @sql=@sql+ case when isnull(''+@loc1+'','') = '' then '' else ' and i.loc between '''+@loc1+''' and '''+@loc2+'''' end
print (@sql)
exec(@sql)

drop table #test;
drop table #invtt;
drop table #itogi;

