ALTER PROCEDURE [dbo].[rep29_SkuByLots](
	@wh varchar(10),
	@sku VARCHAR(12),
	@skuName varchar(45) = null,
	@grp1 varchar(10) = null,
	@grp2 VARCHAR(10) = null,
	@storer varchar(12) = null,
	@storerName varchar(45) = null,
	@carrier  varchar(12) = null,
	@carrierName varchar(45) = null,
	@extInfo varchar(10) = null,
	@userQty int = null,
	@sortOrder int = 1, 
	@sortDirection int = 0
)
--with encryption
AS

--declare @wh varchar(10),
--	@sku VARCHAR(12),
--	@skuName varchar(45),
--	@grp1 varchar(10),
--	@grp2 VARCHAR(10),
--	@storer varchar(12),
--	@storerName varchar(45),
--	@carrier  varchar(12),
--	@carrierName varchar(45),
--	@extInfo varchar(10),
--	@userQty int,
--	@sortOrder int, @sortDirection int
--select @wh='wh40', @sku=null, @extInfo =null, @userQty=20, @carrierName='%свет%',
--	@sortOrder =1, @sortDirection =0
--
	--declare 

CREATE TABLE [#sku](
	[sku] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[skuName] [varchar](60) COLLATE Cyrillic_General_CI_AS NULL,
	[storerkey] [varchar](15) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[StorerName] [varchar](45) COLLATE Cyrillic_General_CI_AS NULL,
	[skuGroup] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[skugroup2] [varchar](30) COLLATE Cyrillic_General_CI_AS NULL,
	[skuType] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[REORDERQTY] [decimal](22, 5) NULL,
	[packkey] [varchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	STDORDERCOST varchar(20)  COLLATE Cyrillic_General_CI_AS NULL)


CREATE TABLE [#TmpSkuByLots](
	[sku] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[storerkey] [varchar](15) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[lot] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[carrierKey] [varchar](15) COLLATE Cyrillic_General_CI_AS NULL,
	[carrierName] [varchar](45) COLLATE Cyrillic_General_CI_AS NULL,
	[attr01] [varchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[attr04] [datetime] NULL,  -- A1
	[attr05] [datetime] NULL,
	[qty] [decimal](22, 5) NULL,
	[qtyAllocated] [decimal](22, 5) NULL,
	[qtyPicked] [decimal](22, 5) NULL,
	[qtyExpected] [decimal](22, 5) NULL,
	[qtyPickInProcess] [decimal](22, 5) NULL,
	[qtyHolded] [decimal](22, 5) NULL)

CREATE TABLE [#TMPresult](
	[sku] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[skuName] [varchar](60) COLLATE Cyrillic_General_CI_AS NULL,
	[storerkey] [varchar](15) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[StorerName] [varchar](45) COLLATE Cyrillic_General_CI_AS NULL,
	[carrierKey] [varchar](15) COLLATE Cyrillic_General_CI_AS NULL,
	[carrierName] [varchar](45) COLLATE Cyrillic_General_CI_AS NULL,
	[skuGroup] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[skugroup2] [varchar](30) COLLATE Cyrillic_General_CI_AS NULL,
	[skuTypeName] [varchar](60) COLLATE Cyrillic_General_CI_AS NULL,
	[skuType] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[ExtInfo] [varchar](31) COLLATE Cyrillic_General_CI_AS NULL,
	[REORDERQTY] [decimal](22, 5) NULL,
	[attr04] [datetime] NULL, --A1
	[attr05] [datetime] NULL,
	[lot] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[packkey] [varchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[qty] [decimal](38, 5) NULL,
	[qtyAllocated] [decimal](38, 5) NULL,
	[qtyPicked] [decimal](38, 5) NULL,
	[qtyExpected] [decimal](38, 5) NULL,
	[qtyPickInProcess] [decimal](38, 5) NULL,
	[qtyHolded] [decimal](38, 5) NULL,
	[qtyAvailable] [decimal](38, 5) NULL,
	STDORDERCOST varchar(20) null)


	declare @sql varchar(max)
set @sql =
	'insert	into #sku
	select sku, s.Descr skuName, s.storerkey, st.Company StorerName, 
				s.skuGroup, s.skugroup2, s.LOTTABLEVALIDATIONKEY skuType, s.REORDERQTY, packkey,STDORDERCOST
		 from '+@wh+'.sku s
			left join '+@wh+'.storer st on st.storerkey = s.storerkey
		where 1=1 ' +
			case when @sku is null then '' else ' and sku like '''+@sku+'''' end +
			case when @skuName is null then '' else ' and s.Descr like '''+@skuName+'''' end +
			case when @grp1 is null then '' else ' and s.skuGroup like '''+@grp1+'''' end +
			case when @grp2 is null then '' else ' and s.skugroup2 like '''+@grp2+'''' end +
			case when @storer is null then '' else ' and s.storerkey like '''+@storer+'''' end +
			case when @storerName is null then '' else ' and st.company like '''+@storerName+'''' end

exec (@sql)
print 1
-- select * from wh40.lotxlocxid where lot = '0000003564'
--		where (@sku is null or sku like @sku ) -- отбор по коду товара
--			and (@skuName is null or descr like @skuName) -- отбор по наименованию товара
--			and (@grp1 is null or skuGroup like @grp1) -- отбор по товарной группе 1
--			and (@grp2 is null or skuGroup2 like @grp2) -- отбор по товарной группе 2
--			and (@storer is null or s.storerkey = @storer) -- отбор по коду владельца
--			and (@storerName is null or st.company like @storerName) -- отбор по имени владельца
--select * from wh40.lotattribute
set @sql =
		'insert into #TmpSkuByLots
		select s.sku, s.storerkey, lli.lot, r.carrierKey carrierKey, st.Company carrierName,
			la.lottable01 attr01, la.lottable04 attr04 ,la.lottable05 attr05,  
			case when  lli.status = ''OK'' then lli.QTY else 0 end qty,
			case when lli.status = ''OK'' then lli.QTYALLOCATED else 0 end qtyAllocated,
			case when lli.status = ''OK'' then lli.QTYPICKED else 0 end qtyPicked,
			case when lli.status = ''OK'' then lli.QTYEXPECTED else 0 end qtyExpected,
			case when lli.status = ''OK'' then lli.QTYPICKINPROCESS else 0 end qtyPickInProcess,
			case when lli.status = ''HOLD'' then lli.QTY else 0 end qtyHolded
		from #sku s 
			left join '+@wh+'.lotxlocxid lli on lli.sku=s.sku and lli.storerkey=s.storerkey
			left join '+@wh+'.lotAttribute la on la.lot = lli.lot
			left join '+@wh+'.receipt r on la.lottable06 = r.receiptkey
			left join '+@wh+'.storer st on r.carrierKey = st.storerkey -- код поставщика
		where 1=1 and lli.qty>0 ' +
			case when @carrier is null then '' else ' and st.storerkey = ''' + @carrier + '''' end + -- фильтр по коду поставщика
			case when @carrierName is null then '' else ' and st.Company like ''' + @carrierName + '''' end + -- фильтр по имени поставщика
			' and not lli.lot is null'

exec (@sql)
print 2
		select sku, storerkey, lot, max(carrierKey) carrierKey, max(carrierName) carrierName,
			min(isnull(attr04,0)) attr04, --A1			
			min(isnull(attr05,0)) attr05,			
			min(isnull(attr01,0)) attr01,
			sum(isnull(QTY,0)) qty,
			sum(isnull(qtyAllocated,0)) qtyAllocated,
			sum(isnull(qtyPicked,0)) qtyPicked,
			sum(isnull(qtyExpected,0)) qtyExpected,
			sum(isnull(qtyPickInProcess,0)) qtyPickInProcess,
			sum(isnull(qtyHolded,0)) qtyHolded
		into #skuByLots
		from #TMPskuByLots 
		group by sku, storerkey, lot
--select dateadd(mm,0,'20080101')

--select * from #skuByLots
set @sql =
		'insert into #TMPresult
		select sl.sku, s.skuName, sl.storerkey, s.StorerName, sl.carrierKey, sl.carrierName,
				s.skuGroup, s.skugroup2, lv.Description skuTypeName, s.skuType,
				case s.skuType 
					when ''STD'' then ''''
					when ''01'' then ''Ф''
					when ''02'' then ''М'' + cast(cast (s.REORDERQTY as int) as varchar)
					when ''03'' then convert(varchar(20),dateadd(mm,isnull(cast(STDORDERCOST as int),0),attr05),112)
				else null end ExtInfo, 
				cast (s.REORDERQTY as int)REORDERQTY,  
				attr04,attr05,	lot, packkey, qty+qtyHolded-QTYPicked qty, qtyAllocated, qtyPicked, 
				qtyExpected, qtyPickInProcess, qtyHolded, 
				qty-qtyAllocated-QTYPicked qtyAvailable,
				STDORDERCOST
		from #skuByLots  sl
			left join #sku s on s.sku=sl.sku and s.storerkey=sl.storerkey
			left join '+@wh+'.lottableValidation lv on lv.LOTTABLEVALIDATIONKEY=s.skuType
		 order by sl.sku, lot'

exec (@sql)
--print @sql
print 3
-- select STDORDERCOST,* from wh40.sku where 
	--select @extInfo, * from #result

		select * into #result from #TMPresult
		where (@extInfo is null 
				OR (@extInfo=SKUTYPE
/*					AND ((skuType = '01') 
						OR (skuType = '02' AND (qty<=reorderqty OR qty<=isnull(@userQty,0) or @userQTY IS NULL))
						OR (skuType = '03' AND convert(varchar(10),dateadd(mm,isnull(cast(STDORDERCOST as int),0),attr04),112) < getdate())
						OR (skuType = '') OR (skuType = 'STD')
					)
*/				) 
			)
		order by sku
select * from #result
	--select * from #result
--		set @sql = 'select *
--		from #result'
--		+ case when isnull(@sortOrder,0) > 0 then
--		' order by '  
--		+ case isnull(@sortOrder,0)
--			when 1 then 'sku' 
--			when 2 then 'lot' 
--			when 3 then 'CarrierName'
--			when 4 then 'skuGroup, skuGroup2' 
--			when 5 then 'skuType' 
--			when 6 then 'storerName' 
--			else 'sku' 
--		end + ' ' 
--		+ case isnull(@sortDirection,0)
--			when 0 then 'asc'
--			else 'desc'
--		end else '' end
--		exec (@sql)

	drop table #tmpResult
	drop table #skuByLots
	drop table #TMPskuByLots
	drop table #result
	drop table #sku

