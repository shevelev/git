ALTER PROCEDURE [dbo].[rep09_CaseIDReturnList] (
	@wh varchar(10),
	@caseid varchar(18)
)AS

	declare @sql varchar(max)
   -- KSV
	 set @caseid = '%' + @caseid
   -- KSV END

	set @sql = 'select td.sku, s.Descr skuName, qty, fromLoc toLoc 
	from '+@wh+'.taskdetail td
		join '+@wh+'.sku s on s.sku=td.sku and s.storerkey=td.storerkey
	where 1=1 
		and tasktype = ''PK''
		and caseid like '''+@caseid+''' '
	exec (@sql)

