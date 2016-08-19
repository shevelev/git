ALTER PROCEDURE [dbo].[rep07t_AngarPickListDetail] (
	@wh varchar(30),
	@orderkey varchar(15)
)
as

--declare 
--	@wh varchar(30),
--	@orderkey varchar(15)
--select @wh='wh40', @orderkey='0000005838'


	declare @sql varchar (max)

CREATE TABLE [dbo].[#resultdetail](
	[sku] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[descr] [varchar](60) COLLATE Cyrillic_General_CI_AS NULL,
	[uom] [varchar] (10) COLLATE Cyrillic_General_CI_AS NULL,
	[description] [varchar] (250) COLLATE Cyrillic_General_CI_AS NULL,
	[openqty] [decimal](22, 5) NOT NULL,
	[angar] [varchar](60) COLLATE Cyrillic_General_CI_AS NULL,
	externlineno [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	BaseMeasure varchar(18) null,
	skususr6 varchar(30) null,
	door varchar(10) null)
	
	set @sql =
	'insert into #resultdetail
	select 
		whs.sku,
		whs.descr as descr,
		whod.uom as uom,
		whcl.description as desription,
		whod.openqty as openqty,
		rtrim(ltrim(substring(whpas.descr, charindex('':'', whpas.descr)+1, len(whpas.descr) - charindex('':'', whpas.descr)))) as angar,
		whod.externlineno, isnull(whs.susr4,whcl.description) BaseMeasure,
		whs.susr6, who.door
	from '+@wh+'.orders as who 
		left join '+@wh+'.orderdetail as whod on who.orderkey = whod.orderkey
		left join '+@wh+'.sku as whs on whs.sku = whod.sku and whs.storerkey = whod.storerkey
		left join '+@wh+'.putawaystrategy as whpas on whpas.putawaystrategykey = whs.putawaystrategykey
		left join '+@wh+'.codelkup as whcl on whcl.code = whod.uom
	where whod.openqty>0 
		and who.orderkey = '''+@orderkey+''''
	exec (@sql)

--select * from #resultdetail
--select * from wh40.orderdetail
	select sku, editdate = max(editdate) 
	into #alttmp
	from wh40.altsku 
	where sku in (select sku from #resultdetail)
	group by sku
--select * from #alttmp
	select a1.sku, a1.altsku, a1.editdate
	into #altsku 
	from wh40.altsku a1
		join #alttmp at	
			on a1.sku = at.sku and at.editdate = a1.editdate
--select * from #altsku	
	select distinct rd.*/*, altsku*/ from #resultdetail rd
		left join #altsku alt on alt.sku = rd.sku
	order by angar
	drop table #resultdetail
	drop table #altsku
	drop table #alttmp

