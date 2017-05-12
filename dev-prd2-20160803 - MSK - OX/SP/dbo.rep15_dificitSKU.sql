-- =============================================
-- Author:		Сандаков В.В.
-- Create date: 19.06.08
-- Description:	отчет по дефициту продукции на склад
-- =============================================
ALTER PROCEDURE [dbo].[rep15_dificitSKU]
	@orderkey varchar(20),
	@wh varchar(20),
	@EXTERNORDERKEY varchar(20)
AS

declare @sql varchar(max)

----нанные для проверки
--declare @orderkey varchar(30)
--declare @wh varchar(10)
--declare @EXTERNORDERKEY varchar(30)
----set @orderkey = '0000002381'
--set @wh = 'WH40'
----set @EXTERNORDERKEY = '5000619407'

set @sql = ' select identity (int,1,1) id, o.ORDERKEY, o.EXTERNORDERKEY
into #t
from '+@wh+'.ORDERS o
where (o.STATUS >= 14 and o.STATUS <= 53)'+ 
	case when isnull(@orderkey,'')= '' then '' else ' and o.ORDERKEY = '''+@orderkey+''' ' end +
	case when isnull(@EXTERNORDERKEY,'')= '' then '' else ' and o.EXTERNORDERKEY = '''+@EXTERNORDERKEY+''' ' end +
'group by o.ORDERKEY, o.EXTERNORDERKEY, o.PRIORITY, o.REQUESTEDSHIPDATE
order by o.PRIORITY, o.REQUESTEDSHIPDATE

select od.sku, od.STORERKEY, sum(lld.QTY)qty, sum(lld.QTYALLOCATED)QTYALLOCATED, sum((isnull(lld.QTY,0) - isnull(lld.QTYALLOCATED,0))) as DostOst
into #tm 
from '+@wh+'.LOTXLOCXID lld
join '+@wh+'.ORDERDETAIL od on (lld.SKU = od.SKU) and (lld.STORERKEY = od.STORERKEY) 
where od.orderkey in (select ORDERKEY from #t)
group by od.STORERKEY, od.SKU--, od.ORDERKEY



select cast(0 as int) id, t.orderkey, t.EXTERNORDERKEY, od.sku, s.descr, od.openqty, tm.DostOst, 0 Raznost, 0 Deficit
	into #result
	from '+@wh+'.ORDERDETAIL od
	join #tm tm on tm.SKU = od.SKU and tm.STORERKEY = od.STORERKEY 
	join #t t on  od.orderkey = t.orderkey
	join '+@wh+'.SKU s on od.sku = s.sku and od.STORERKEY = s.STORERKEY
 	where 1=2

--select od.orderkey, od.sku, s.descr, od.openqty, tm.DostOst, 0 Raznost, 0 Deficit
--	into #preresult
--	from '+@wh+'.ORDERDETAIL od
--	join #tm tm on tm.SKU = od.SKU and tm.STORERKEY = od.STORERKEY 
--	join #t t on  od.orderkey = t.orderkey
--	join '+@wh+'.SKU s on od.sku = s.sku and od.STORERKEY = s.STORERKEY
--	where 1=2

declare @i varchar(20)
set @i = 1

while (@i <= (select count(t.id) from #t t))
	begin

		select cast(0 as int) id, t.orderkey, t.EXTERNORDERKEY, od.sku, s.descr, od.openqty, tm.DostOst, 0 Raznost, 0 Deficit
			into #preresult
			from '+@wh+'.ORDERDETAIL od
			join #tm tm on tm.SKU = od.SKU and tm.STORERKEY = od.STORERKEY 
			join #t t on  od.orderkey = t.orderkey
			join '+@wh+'.SKU s on od.sku = s.sku and od.STORERKEY = s.STORERKEY
 			where 1=2

		insert into #preresult
			select @i, od.orderkey, t.EXTERNORDERKEY,  od.sku, s.descr, od.openqty, tm.DostOst, (tm.DostOst - od.openqty) Raznost, 0 Deficit
			from '+@wh+'.ORDERDETAIL od
			join #tm tm on tm.SKU = od.SKU and tm.STORERKEY = od.STORERKEY 
			join #t t on  od.orderkey = t.orderkey
			join '+@wh+'.SKU s on od.sku = s.sku and od.STORERKEY = s.STORERKEY
 			where (od.STATUS >= 14 and od.STATUS <= 53) 
				and (t.id = @i)
--			order by t.id
			
--		update tm
--		set DostOst = Raznost 
--		from #tm as tm join  #preresult pr on tm.sku = pr.sku and tm.STORERKEY = pr.STORERKEY
--		where (Raznost >= 0)

			
--		update #tm
--		set DostOst = 0
--		from #tm as tm join  #preresult pr on tm.sku = pr.sku and tm.STORERKEY = pr.STORERKEY
--		where (Raznost < 0)
			
		update #preresult
		set Deficit = abs(Raznost)
		where (Raznost < 0)
			
		insert into #result select id, pr.orderkey, pr.EXTERNORDERKEY, pr.sku, pr.descr, pr.openqty, pr.DostOst, pr.Raznost, pr.Deficit 
		from #preresult pr 
				
		drop table #preresult

		set @i = @i + 1

	end



--select * from #t
--select * from #tm
--select * from #preresult
select * from #result order by id'
print (@sql)
exec (@sql)
--drop table #t
--drop table #tm
--drop table #result
--drop table #preresult

