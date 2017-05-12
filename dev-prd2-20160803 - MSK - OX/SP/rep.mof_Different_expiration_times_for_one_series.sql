ALTER PROCEDURE [rep].[mof_Different_expiration_times_for_one_series] 
	/*   разные сроки годности по одной серии */
AS

select sku +'_'+ LOTTABLE02 as tt, LOTTABLE04, LOTTABLE05--, LOTTABLE06 --
into #qwe1
from wh2.LOTATTRIBUTE 
where LOT in (select distinct lot from wh2.LOTXLOCXID where QTY>0 and LOC not in ('LOST','OVER')) and lottable02!=''
group by  SKU, LOTTABLE02, LOTTABLE04, LOTTABLE05--, LOTTABLE06 --

select sku +'_'+ LOTTABLE02 as tt, LOT, LOTTABLE04, LOTTABLE05, LOTTABLE06 --
into #qwe2
from wh2.LOTATTRIBUTE 
where LOT in (select distinct lot from wh2.LOTXLOCXID where QTY>0 and LOC not in ('LOST','OVER')) and lottable02!=''
group by  SKU, LOTTABLE02, LOT, LOTTABLE04, LOTTABLE05, LOTTABLE06 --


--select * from #qwe1 where tt='11135_AM70093'
--select * from #qwe2 where tt='11135_AM70093'
--select * from wh2.LOTATTRIBUTE where SKU='11135' and LOTTABLE02='AM70093'
--select * from wh2.LOTXLOCXID where LOT='0000093597'

update #qwe1 set LOTTABLE04='3333-11-11 22:22:00.000' where LOTTABLE04 is null
update #qwe1 set LOTTABLE05='3333-11-11 22:22:00.000' where LOTTABLE05 is null
update #qwe2 set LOTTABLE04='3333-11-11 22:22:00.000' where LOTTABLE04 is null
update #qwe2 set LOTTABLE05='3333-11-11 22:22:00.000' where LOTTABLE05 is null


select lxlx.loc, lxlx.qty, 
q2.lot,SUBSTRING(q1.tt,0,CHARINDEX('_',q1.tt)) sku,
s.NOTES1, 
SUBSTRING(q1.tt,CHARINDEX('_',q1.tt)+1,LEN(q1.tt)) LOTTABLE02, CONVERT(VARCHAR,q1.LOTTABLE04,104) LOTTABLE04,CONVERT(VARCHAR,q1.LOTTABLE05,104) LOTTABLE05,q2.LOTTABLE06
into #qwe3
from #qwe1 q1 
join #qwe2 q2 on q1.tt=q2.tt and q1.LOTTABLE04=q2.LOTTABLE04 and q1.LOTTABLE05=q2.LOTTABLE05-- and q1.LOTTABLE06 = q2.LOTTABLE06
join wh2.LOTXLOCXID lxlx on lxlx.LOT=q2.LOT and lxlx.SKU=SUBSTRING(q1.tt,0,CHARINDEX('_',q1.tt))
join wh2.SKU s on s.SKU=SUBSTRING(q1.tt,0,CHARINDEX('_',q1.tt))
where q1.tt in (select  tt from #qwe1 group by tt having COUNT(tt)>=2) and lxlx.QTY>0 and lxlx.LOC not in ('LOST','OVER')

update #qwe3 set LOTTABLE04=null where LOTTABLE04='3333-11-11 22:22:00.000'
update #qwe3 set LOTTABLE05=null where LOTTABLE05='3333-11-11 22:22:00.000'

select * from #qwe3

drop table #qwe1
drop table #qwe2
drop table #qwe3

