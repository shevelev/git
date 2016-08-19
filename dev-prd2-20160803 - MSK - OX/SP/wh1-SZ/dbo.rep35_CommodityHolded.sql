ALTER PROCEDURE [dbo].[rep35_CommodityHolded](
	/* 35 Проблемные товары (отчет о заблокированных товарах и товарах из проблемных ячеек) */
	@wh varchar(30),
	@sortOrder int = 1,
	@sortDirection int = 0
)
AS	

--	declare @wh varchar (30),	
--		@sortOrder int,
--		@sortDirection int
--	select @wh='wh40', @sortOrder = 1,	@sortDirection = 0

	set @wh = upper(@wh)
	declare @sql varchar(max)

	select lli.lot, lli.loc, lli.id, lli.storerkey, lli.sku, lli.status Hold, cast('' as varchar(10)) holdReason, 
		lli.qty
	into #tbl1
	from wh40.lotxlocxid lli
		join wh40.loc l on l.loc = lli.loc
	where 1=2

	set @sql = 'insert into #tbl1 
		select lli.lot, lli.loc, lli.id, lli.storerkey, lli.sku, lli.status Hold, '''', lli.qty
		from '+@wh+'.lotxlocxid lli
			join '+@wh+'.loc l on l.loc = lli.loc
		where l.logicallocation like ''PROBLEM'' and lli.qty > 0'
	exec (@sql)

	select lli.lot, lli.loc, lli.id, lli.storerkey, lli.sku, lli.status hold, ih.status holdReason, lli.qty,
		 ih.dateon, ih.whoon, datediff(mi, ih.dateon, getdate()) diffMinutes
	into #tbl2
	from WH40.INVENTORYHOLD ih
		join wh40.lotxlocxid lli on lli.loc = ih.loc or lli.id = ih.id or lli.lot=ih.lot
	where 1=2

	set @sql = 'insert into #tbl2
		select lli.lot, lli.loc, lli.id, lli.storerkey, lli.sku, lli.status hold, ih.status, lli.qty,
			ih.dateon, ih.whoon, datediff(mi, ih.dateon, getdate()) diffMinutes
		from '+@wh+'.INVENTORYHOLD ih
			join '+@wh+'.lotxlocxid lli on lli.loc = ih.loc or lli.id = ih.id or lli.lot=ih.lot
		where hold = ''HOLD'' and qty>0'
	exec (@sql)
	


--	select t.*, i.adddate, i.addwho, datediff(mi, i.adddate, getdate()) diffMinutes
--	into #result
--	from wh40.itrn i
--	join #tbl1 t on i.sku=t.sku and i.storerkey=t.storerkey and i.lot=t.lot and i.toloc=t.loc and i.toid=t.id

	select * into #result from #tbl2
	
	set @sql = 'insert into #result
		select t.*, i.adddate, i.addwho, datediff(mi, i.adddate, getdate()) diffMinutes
		from '+@wh+'.itrn i
			join #tbl1 t on i.sku=t.sku and i.storerkey=t.storerkey and i.lot=t.lot and i.toloc=t.loc and i.toid=t.id'
	exec(@sql)

	alter table #result add dd int, hh int, mm int


	update #result set dd= floor(diffminutes/(24*60))
	update #result set hh= floor((diffminutes-(dd*24*60))/60)
	update #result set mm=diffminutes-hh*60- dd*24*60

	set @sql = 'select r.*, sk.descr, usr.usr_name  userName, 
		case when dd=0 then '''' else cast (dd as varchar) + 
		case right(cast (dd as varchar),1)
			when 0 then '' дней '' 
			when 1 then '' день '' 
			when 2 then '' дня '' 
			when 3 then '' дня '' 
			when 4 then '' дня '' 
			when 5 then '' дней '' 
			when 6 then '' дней '' 
			when 7 then '' дней '' 
			when 8 then '' дней '' 
			when 9 then '' дней '' 
			else ''дн.''
		end end + 
		case when hh < 10 then ''0'' else '''' end+ cast(hh as varchar)	+'':''+
		case when mm < 10 then ''0'' else '''' end+cast(mm as varchar) HoldedTime
	from #result r
		left join ssaadmin.pl_usr usr on usr_login = whoon
			join '+@wh+'.sku sk on r.sku = sk.sku and r.storerkey = sk.storerkey
	order by ' +
	case isnull(@sortOrder,0)
		when 1 then 'loc' 
		when 2 then 'dd,hh,mm' 
		else 'loc' 
	end + ' ' 
	+ case isnull(@sortDirection,0)
		when 0 then 'asc'
		else 'desc'
	end 
	exec (@sql)



drop table #tbl1
drop table #tbl2
drop table #result

