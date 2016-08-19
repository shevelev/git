ALTER PROCEDURE [dbo].[rep45_ZakazTransitCommodity](
	@wh varchar(10),
	@manager varchar(10)=null, 
	@sku varchar(10)=null, 
	@skuName varchar(45)=null, 
	@loc varchar(10)=null
)
as
--declare @manager varchar(10), @sku varchar(10), @skuName varchar(45), @loc varchar(10)
--select  @manager ='', @sku ='', @skuName ='', @loc =''

declare @sql varchar(max)


	select s.sku, s.storerkey, s.Descr skuName, s.class zakaz, 
		la.lottable07 transit, qty, loc, lli.adddate, datediff(mi,lli.adddate,getdate()) tm, 
		cast(0 as int) hh, cast(0 as int) mm, la.lottable07 manager 
	into #tmp
	from wh40.lotxlocxid lli
		join wh40.sku s on s.sku=lli.sku and s.storerkey = lli.storerkey
		join wh40.lotattribute la on lli.lot = la.lot
	where 1=2--(la.lottable07 != 'STD' or s.class = '1') and qty > 0

	set @sql = 'insert into #tmp select s.sku, s.storerkey, s.Descr skuName, s.class zakaz, 
		la.lottable07 transit, qty, loc, lli.adddate, datediff(mi,lli.adddate,getdate()) tm, 
		cast(0 as int) hh, cast(0 as int) mm, la.lottable07 manager 
	from '+@wh+'.lotxlocxid lli
		join '+@wh+'.sku s on s.sku=lli.sku and s.storerkey = lli.storerkey
		join '+@wh+'.lotattribute la on lli.lot = la.lot
	where (la.lottable07 != ''STD'' or s.class = ''1'') and qty > 0 '
		+ case when isnull(@manager,'')='' then '' else ' and la.lottable07 like '''+@manager+''' ' end
		+ case when isnull(@sku,'')='' then '' else ' and s.sku like '''+@sku+''' ' end
		+ case when isnull(@skuName,'')='' then '' else ' and s.descr like '''+@skuName+''' ' end
		+ case when isnull(@loc,'')='' then '' else ' and lli.loc like '''+@loc+''' ' end
	exec (@sql)


update #tmp set hh=floor(tm/60)
update #tmp set mm=tm-hh*60

select sku, storerkey, skuName, zakaz, 
		transit, qty, loc, adddate, tm, 
		cast (hh as varchar(10)) hh, cast(mm as varchar(2)) mm, 
		manager  
from #tmp order by sku

drop table #tmp

--select * from wh40.

