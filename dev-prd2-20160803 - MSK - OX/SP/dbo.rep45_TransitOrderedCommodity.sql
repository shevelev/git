ALTER PROCEDURE [dbo].[rep45_TransitOrderedCommodity] (
	@wh varchar(10),
	@sku varchar(10),
	@skuName varchar(45),
	@manager varchar(10),
	@isTZ int
	)
AS

--declare 
--	@wh varchar(10),
--	@sku varchar(10),
--	@skuName varchar(45),
--	@manager varchar(10),
--	@isTZ int
--select @wh='wh40',	@sku='',	@skuName ='',	@manager ='',	
--	@isTZ=2--,	@isZakaz=0

declare
	@sql varchar(max) 

--CREATE TABLE [dbo].[#lots](
--	[lot] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[sku] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[storerkey] [varchar](15) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[lottable07] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL)
--
--CREATE TABLE [dbo].[#transitSKU](
--	[lot] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[sku] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[storerkey] [varchar](15) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[descr] [varchar](60) COLLATE Cyrillic_General_CI_AS NULL,
--	[qty] [decimal](22, 5) NOT NULL,
--	[loc] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[type] [int] NOT NULL,
--	[adddate] [datetime] NOT NULL,
--	[Manager] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL)
--
--CREATE TABLE [dbo].[#zakazSku](
--	[lot] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[sku] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[storerkey] [varchar](15) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[descr] [varchar](60) COLLATE Cyrillic_General_CI_AS NULL,
--	[qty] [decimal](22, 5) NOT NULL,
--	[loc] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[type] [int] NOT NULL,
--	[adddate] [datetime] NOT NULL,
--	[Manager] [varchar](1) COLLATE Cyrillic_General_CI_AS NOT NULL)

--	set @sql =
--		'insert into #lots select l.lot, la.sku, la.storerkey, 
--			case when la.lottable07 = '''' then ''<Пустой>'' else la.lottable07 end lottable07 
--		from '+@wh+'.lot l
--			join '+@wh+'.lotattribute la on l.lot = la.lot
--		where rtrim(lottable07) != ''STD'''
--	exec (@sql)
	
	
	select lli.lot, cast(null as varchar(10)) Manager,
		s.class, lli.sku, lli.storerkey, s.descr, qty, lli.loc, 
		 cast(null as int) isTransit, cast(null as int) isZakaz,lli.adddate 
	into #result
	from wh40.lotxlocxid lli
		join wh40.lotattribute la on lli.lot = la.lot
		join wh40.sku s on lli.sku=s.sku and lli.storerkey = s.storerkey
	where 1=2
	
	set @sql = 'insert into #result select lli.lot, 
		case when la.lottable07 = '''' then ''<Пустой>'' 
			when la.lottable07 = ''STD'' then '''' 
			else la.lottable07 
		end Manager,
		s.class,
		lli.sku,lli.storerkey, s.descr, qty, lli.loc, 
		case when lottable07 = ''STD'' then 0 else 1 end isTransit, 
		case when s.class = ''1'' then 1 else 0 end isZakaz, 
		lli.adddate 
	from '+@wh+'.lotxlocxid lli
		join '+@wh+'.lotattribute la on lli.lot = la.lot
		join '+@wh+'.sku s on lli.sku=s.sku and lli.storerkey = s.storerkey
	where lli.qty > 0 and ('
		+ case when isnull(@isTZ,0)=1 then ' lottable07 != ''STD'' ' 
				when isnull(@isTZ,0)=2 then ' s.class =''1'' ' 
				else ' lottable07 != ''STD'' or  s.class =''1'' ' 
			end + ') '
		+ case when isnull(@sku,'')='' then '' else ' and s.sku like '''+@sku+'''' end
		+ case when isnull(@skuName,'')='' then '' else ' and s.descr like '''+@skuName+'''' end
		+ case when isnull(@manager,'')='' then '' else ' and lottable07 like '''+@manager+'''' end
print @sql
	exec (@sql)
	
	
	
	
	
	
--	-- type = 0 - указывает что товар транзитный
--	set @sql =
--		'insert into #transitSKU
--		select lli.lot, lli.sku,lli.storerkey, s.descr, qty, lli.loc, 0 type, lli.adddate, l.lottable07 Manager
--		from '+@wh+'.lotxlocxid lli
--			join #lots l on l.lot = lli.lot
--			join '+@wh+'.sku s on lli.sku=s.sku and lli.storerkey = s.storerkey
--		where lli.qty>0'
--	exec (@sql)
--
--	-- type = 1 - обозначает что товар заказной 
--	set @sql =
--		'insert into #zakazSku select lli.lot,lli.sku,lli.storerkey,s.descr, qty, loc, 1 type, lli.adddate, '''' Manager  
--		from '+@wh+'.lotxlocxid lli
--			join '+@wh+'.sku s on lli.sku=s.sku and lli.storerkey = s.storerkey
--		where class =''1'' and lli.qty > 0'
--	exec (@sql)
	
----	select sku, storerkey into #sku from #transitSKU
----	select identity(int,1,1) id, sku, storerkey into #tmpsku from #zakazSKU
----	
----	delete from #tmpsku where id in (select id from #tmpsku t
----		join #sku s on s.sku= t.sku and s.storerkey=t.storerkey)
	
--select  class, count(serialkey) from wh40.sku group by class
	--insert into #sku select sku, storerkey from #zakazSKU
	
--	select * into #result from #transitSKU
--	insert #result select * from  #zakazSKU
	
	
		
	alter table #result add minutes int, dd int, hh int, mm int
	update #result set minutes = datediff(mi,adddate, getdate())
	update #result set dd = minutes/(60*24)--, mm = mm-mm/(60*24)
	--update #result set mm = minutes-dd*(60*24)
	update #result set hh = (minutes-dd*(60*24))/60
	update #result set mm = minutes-hh*60-dd*(60*24)
		
		select *, cast(dd as varchar(10)) + ' дней ' 
			+ case when hh<10 then '0' else '' end + cast(hh as varchar(10)) 
			+':'+case when mm<10 then '0' else ''  end + cast(mm as varchar(10)) 
			StoringTime
		from #result
		
--		drop table #zakazSKU
--		drop table #transitSKU
--		drop table #lots
		drop table #result

