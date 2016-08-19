ALTER PROCEDURE [dbo].[rep09b_CaseIDReturnList] (
	@wh varchar(10),
	@orderkey varchar(18),
	@sku varchar(20)
)AS

	declare @sql varchar(max)
/*----------------------------------------*/
--declare @wh varchar(10),
--	@orderkey varchar(18),
--	@sku varchar(20)
--set @wh = 'wh40'
--set @orderkey = '0000001306'
----set @sku = '011709840'
/*----------------------------------------*/

--	set @sql = 'select td.sku, s.Descr skuName, td.qty, td.fromLoc toLoc, td.caseid 
--	from '+@wh+'.taskdetail td
--		join '+@wh+'.sku s on s.sku=td.sku and s.storerkey=td.storerkey
--		join '+@wh+'.pickdetail pd on pd.caseid = td.caseid
--	where 1=1 
--		and td.tasktype = ''PK'' and pd.orderkey = '''+@orderkey+''''
		--+ case when isnull(@caseid,'')='' then '' else ' and td.caseid= '''+@caseid+''' ' end
		
--	exec (@sql)
--select * from wh40.taskdetail
--create table #t(
--	sku varchar(20) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	skuName varchar(50) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	qty decimal(22,5),
--	toLoc varchar(20) COLLATE Cyrillic_General_CI_AS NOT NULL, 
--	caseid varchar(20) COLLATE Cyrillic_General_CI_AS NOT NULL, 
--	orderkey varchar(20) COLLATE Cyrillic_General_CI_AS NOT NULL)
--create table #result(
--	sku varchar(20) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	skuName varchar(50) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	qty decimal(22,5),
--	toLoc varchar(20) COLLATE Cyrillic_General_CI_AS NOT NULL, 
--	caseid varchar(20) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	orderkey varchar(20) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	ORDERDATE datetime,
--	C_COMPANY varchar(40) COLLATE Cyrillic_General_CI_AS NOT NULL)
--
--	
--set @sql = 'insert into #t
--	select td.sku, s.Descr skuName, td.qty, td.fromLoc toLoc, td.caseid, pd.orderkey
--	from '+@wh+'.taskdetail td
--		join '+@wh+'.sku s on s.sku=td.sku and s.storerkey=td.storerkey
--		join '+@wh+'.pickdetail pd on pd.caseid = td.caseid
--	where 1=1 
--		and td.tasktype = ''PK'' and '+ case when isnull(@orderkey,'')='' then '1=1 and' else ' pd.orderkey = '''+@orderkey+''' and ' end +
--		case when isnull(@sku,'')='' then '1=1' else ' td.sku = '''+@sku+''' ' end
--exec (@sql)
--
--set @sql = 'insert into #result
--	select t.sku, t.skuName, t.qty, t.toLoc, t.caseid, t.orderkey, o.ORDERDATE, o.C_COMPANY
--	from #t t
--		join '+@wh+'.orders o on o.orderkey = t.orderkey'
--exec (@sql)
--
--select * from #result
--
--drop table #t,#result
--// KSV
set @orderkey = '%' + @orderkey
-- KSV END 
set @sql = '
	select distinct td.sku, s.Descr skuName, td.qty, td.fromLoc toLoc, td.caseid, pd.orderkey
	into #t
	from '+@wh+'.taskdetail td
		join '+@wh+'.sku s on s.sku=td.sku and s.storerkey=td.storerkey
		join '+@wh+'.pickdetail pd on pd.caseid = td.caseid
	where 1=1 
		and td.tasktype = ''PK'' and '+ case when isnull(@orderkey,'')='' then '1=1 and' else ' pd.orderkey like '''+@orderkey+''' and ' end +
		case when isnull(@sku,'')='' then '1=1' else ' td.sku like ''' + '%' + ''' + '''+@sku+''' ' end +
	'
	select t.sku, t.skuName, t.qty, t.toLoc, t.caseid, t.orderkey, o.ORDERDATE, o.C_COMPANY
	into #result
	from #t t
		join '+@wh+'.orders o on o.orderkey = t.orderkey

	select * from #result'
print @sql
exec (@sql)

