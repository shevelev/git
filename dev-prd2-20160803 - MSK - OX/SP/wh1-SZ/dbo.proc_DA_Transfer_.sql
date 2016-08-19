ALTER PROCEDURE [dbo].[proc_DA_Transfer](
	@wh varchar(10),
	@transmitlogkey varchar (10)
	
)AS

declare  @sql varchar(max)
--,@transmitlogkey varchar(10),
--@wh varchar(10)
--set @wh = 'wh1'
--set @transmitlogkey = '0000000073'

CREATE TABLE #Result(
	[filetype] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[storerkey] [varchar](15) COLLATE Cyrillic_General_CI_AS NULL,
	[adjustmentkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[adjustmentlinenumber] [varchar](5) COLLATE Cyrillic_General_CI_AS NULL,
	[sku] [varchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[reasoncode] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[description] [varchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[qty] [int] NULL,
	[editdate] [varchar] (10) COLLATE Cyrillic_General_CI_AS NULL,
	[editwho] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
	[lottable08] [varchar](50) COLLATE Cyrillic_General_CI_AS NULL
)

print '	-- корректировка FROM'

set @sql = 
'insert into #Result
select 
	''TRANSFER''  filetype,
	td.fromstorerkey,
	td.transferkey,
	td.transferlinenumber,
	td.fromsku,
	''TRANSFER'' reasoncode,
	''ТРАНСФЕР'' description,
	-td.fromqty,
	convert(varchar(10),td.editdate,112) editdate,
	td.editwho,
	lt.lottable08
	from '+@wh+'.transmitlog tl
join '+@wh+'.transferdetail td on tl.key1 = td.transferkey
join '+@wh+'.lotattribute lt on lt.lot = td.fromlot
where tl.tablename = ''transferfinalized'' and tl.transmitlogkey = '''+@transmitlogkey+''''

exec (@sql)

print '	-- корректировка TO'
set @sql = 
'insert into #Result
select 
	''TRANSFER''  filetype,
	td.tostorerkey,
	td.transferkey,
	td.transferlinenumber,
	td.tosku,
	''TRANSFER'' reasoncode,
	''ТРАНСФЕР'' description,
	td.toqty,
	convert(varchar(10),td.editdate,112) editdate,
	td.editwho,
	td.lottable08
	from wh1.transmitlog tl
join wh1.transferdetail td on tl.key1 = td.transferkey
where tl.tablename = ''transferfinalized'' and tl.transmitlogkey = '''+@transmitlogkey+''''

exec (@sql)

select * from #Result

drop table #Result

