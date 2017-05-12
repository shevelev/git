ALTER PROCEDURE [rep].[Inventories_Receipt] (
	/*  27  Товарные запасы   */
		@WH varchar(30),
		@sku varchar(10)= null,
		@skuName varchar(250) = null,
		@storerName varchar(45) = null,
		@carrierName varchar(45) = null,
		@skuType varchar(10) = null,
		@skuGroup1 varchar(10) = null,
		@skuGroup2 varchar(30) = null,
		@sortOrder int = 1, 
		@sortDirection int = 0
)
as

/**** Data for testing  ***********/

--declare @sku varchar(10),
--		@skuName varchar(45),
--		@storerName varchar(45),
--		@carrierName varchar(45),
--		@skuType varchar(10),
--		@skuGroup1 varchar(10),
--		@skuGroup2 varchar(30),
--		@WH sysname
--declare @sortOrder int, @sortDirection int
--select @sortOrder = 1, @sortDirection=0
--	select @wh = 'wh40', @sku = '%'

/****  end Data For testing  ***********/

	set @wh = upper(@wh)
	set @sku= replace(upper(@sku),';','')  -- удалить ; из строк задаваемых пользователем для увеличения безопасности.
	set @skuName= replace(upper(@skuName),';','')
	set @storerName= replace(upper(@storerName),';','')
	set @carrierName= replace(upper(@carrierName),';','')
	set @skuType= replace(upper(@skuType),';','')
	set @skuGroup1= replace(upper(@skuGroup1),';','')
	set @skuGroup2= replace(upper(@skuGroup2),';','')



	declare	@sql varchar(8000)
	create table #sku (sku varchar(50), skuName varchar(250), storername varchar(45), CarrierName varchar(45),
			status varchar(10), lot varchar(10), skuType varchar(10), skuTypeName varchar(50),
			qty decimal(22,5), qtyAllocated decimal(22,5), qtypicked decimal(22,5), 
			skugroup varchar(10), skugroup2 varchar(30))

	set @sql = 'insert into #sku select s.sku, s.Descr skuName, st.Company storerName, st1.company CarrierName,
			lli.status, lli.lot, s.LOTTABLEVALIDATIONKEY skuType, lv.description skuTypeName , lli.qty, lli.qtyallocated, qtypicked  ,
			skugroup, skugroup2 '
--select * from wh40.lottablevalidation
	set @sql = @sql + ' from ' + @WH + '.lotxlocxid lli 
		left join ' + @WH + '.lotAttribute la on lli.lot=la.lot
		left join ' + @WH + '.receipt r on la.lottable06 = r.receiptkey
		left join ' + @WH + '.sku s on lli.sku=s.sku and lli.storerkey=s.storerkey
		left join ' + @WH + '.storer st on s.storerkey = st.storerkey
		left join ' + @WH + '.storer st1 on r.carrierkey = st1.storerkey
		left join ' + @WH + '.lottablevalidation lv on lv.lottablevalidationkey = s.LOTTABLEVALIDATIONKEY
	where 1=1 and lli.qty>0'
	set @sql = @sql + 
		case when isnull(@sku,'')='' then ' ' else ' and (lli.sku like '''+@sku+''') ' end +
		case when isnull(@skuName,'')=''  then ' ' else ' and (s.descr like '''+@skuName+''') ' end +
		case when isnull(@storerName,'')=''  then ' ' else ' and (st.company like '''+@storerName+''') ' end +
		case when isnull(@carrierName,'')=''  then ' ' else ' and (st1.company like '''+@carrierName+''') 'end +
		case when isnull(@skuGroup1,'')=''  then ' ' else ' and (skugroup like '''+@skuGroup1+''') 'end +
		case when isnull(@skuGroup2,'')=''  then ' ' else ' and (skuGroup2 like '''+@skuGroup2+''') 'end +
		case when isnull(@skutype,'')=''  then ' ' else ' and (s.lottablevalidationkey = '''+@skutype+''') 'end 
	exec (@sql)

	select sku, skuname, storername, carriername, skutype,skuTypeName, status ,
			skugroup, skugroup2, 
		sum(qty) qty, sum(qtyallocated) qtyalloc, sum(qtyPicked) qtyPick
	into #tmp
	from #sku
	group by sku, skuname, storername, carriername, skutype,skuTypeName, status ,
			skugroup, skugroup2

	select sku, skuname, storername, carriername, skutype, skuTypeName,status ,
			skugroup, skugroup2,
		case when status = 'OK' then qty else 0 end QTY, 
		case when status = 'OK' then qty-qtyalloc-qtypick else 0 end qtyAvailable, 
		qtyalloc ,
		case when status <> 'OK' then qty else 0 end qtyHold
		into #result
		from #tmp

select sku, skuname, storername, carriername, skutype, skuTypeName,
			skugroup, skugroup2,
sum(qty) qty, sum(qtyalloc) qtyalloc, sum(qtyAvailable) qtyAvailable, sum(qtyHold) qtyHold
	from #result
group by sku, skuname, storername, carriername, skutype, skuTypeName,
			skugroup, skugroup2
 order by sku



	--declare @sql varchar(8000)
--	set @sql = 'select *
--	from #result'
--	+ case when isnull(@sortOrder,0) > 0 then
--	' order by '  
--	+ case isnull(@sortOrder,0)
--		when 1 then 'sku' 
--		when 2 then 'skuName' 
--		when 3 then 'skuGroup, skuGroup2' 
--		when 4 then 'storerName' 
--		when 5 then 'CarrierName'
--		else 'sku' 
--	end + ' ' 
--	+ case isnull(@sortDirection,0)
--		when 0 then 'asc'
--		else 'desc'
--	end else '' end
--	exec (@sql)

	drop table #tmp
	drop table #result
	DROP TABLE #SKU

