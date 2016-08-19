ALTER PROCEDURE [dbo].[rep21_OrderHistory] (
	@wh varchar(30),
	@order varchar(20)
)
AS

--declare @wh varchar(30),@order varchar(20)
--select @wh='wh40', @order = '0000000021'

	set @wh = upper(@wh)
	set @order= replace(upper(@order),';','')  -- удалить ; из строк задаваемых пользователем для увеличения безопасности.
	declare @sql varchar(max)

	declare @minPickDate datetime
	create table #mpd (date datetime)

	set @sql = 'insert into #mpd select min(adddate)  from '+@wh+'.pickdetail where orderkey='''+@order+''''
	exec (@sql)
	select @minPickDate = date from #mpd

	if @minpickdate is null  
	begin
		delete from #mpd
		set @sql = 'insert into #mpd select max(editdate)  from '+@wh+'.orderdetail where orderkey='''+@order+''''
		exec (@sql)
		select @minPickDate = date from #mpd
	end

	drop table #mpd

	select orderkey, orderlinenumber, externorderkey, externlineno,
		lot, storerkey, sku, originalqty+adjustedQTY OrderQTY, uom, packkey, adddate, addwho, editdate, editwho
	into #pos
	from wh1.orderdetail where 1=2

	set @sql = 'insert into #pos select orderkey, orderlinenumber, externorderkey, externlineno,
		lot, storerkey, sku, originalqty+adjustedQTY OrderQTY, uom, packkey, adddate, addwho, editdate, editwho' +
		' from '+@wh+'.orderdetail where orderkey='''+@order+''' order by 1 desc '
	exec (@sql)
	select orderlinenumber, sum(qty) pickedQTY
	into #picks 
	from wh1.pickdetail where 1=2 group by orderlinenumber

	set @sql = 'insert into #picks select orderlinenumber, sum(qty) pickedQTY
	 	from '+@wh+'.pickdetail where orderkey='''+@order+''' and status >= 5
		group by orderlinenumber'
	exec(@sql)


	set @sql = 'select orderkey, dt.orderlinenumber, externorderkey, externlineno,
		lot, dt.storerkey, dt.sku, sku.Descr skuName,
		case uom when ''EA'' then dt.Orderqty
				when ''CS'' then  dt.Orderqty/casecnt
				when ''PL'' then dt.Orderqty/pallet
		end OrderQTY,
		case uom when ''EA'' then p.pickedQTY
				when ''CS'' then  p.pickedQTY/casecnt
				when ''PL'' then p.pickedQTY/pallet
		end pickedQTY, 
		uom, dt.adddate, dt.addwho, dt.editdate, pu.usr_name + '' (''+ dt.editwho + '')'' editwho, 
		case when dt.adddate > '''+convert(varchar,@minpickdate,112)+''' then 1 else 0 end modifyFlag
	from #pos dt 
		left join #picks p on p.orderlinenumber = dt.orderlinenumber
		left join '+@wh+'.pack pk on pk.packkey = dt.packkey
		left join '+@wh+'.sku sku on dt.sku = sku.sku and dt.storerkey=sku.storerkey
			join  ssaadmin.pl_usr pu on dt.editwho = pu.usr_login
	order by dt.orderlinenumber'
	exec (@sql)

drop table #pos
drop table #picks

