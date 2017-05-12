/* список товаров (кабель) которые невозможно отгрузить цельным куском */
ALTER PROCEDURE [dbo].[rep97_NeedFullPart](
 	@wh  varchar (10),
	@orderkey varchar(10) = null,
	@manager varchar(30)
) as


--declare @wh  varchar (10), @orderkey varchar(10),	@manager varchar(30)
--select 	@wh ='wh40' ,@orderkey  = null,	@manager='NVA'




set nocount on
	create table #orderd (
		orderkey varchar(10) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		externorderkey varchar(32) COLLATE Cyrillic_General_CI_AS DEFAULT (''),	
		externlineno varchar(10) COLLATE Cyrillic_General_CI_AS DEFAULT (''),
		descr varchar(60) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		orderdate datetime NOT NULL DEFAULT ('2000-01-01 00:00:00.000'),
		editdate datetime NOT NULL DEFAULT ('2000-01-01 00:00:00.000'),
		susr1 varchar(30) COLLATE Cyrillic_General_CI_AS DEFAULT (''),
		sku varchar(50) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		storerkey varchar(15) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		openqty decimal(22, 5) NOT NULL DEFAULT (0),
		originalqty decimal(22, 5) NOT NULL DEFAULT (0),
		qtyallocated decimal(22, 5) NOT NULL DEFAULT (0))

set nocount on
	create table #lxlxid (
		sku varchar(50) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		storerkey varchar(15) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		loc varchar(10) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		plid varchar(18) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		qty decimal(22, 5) NOT NULL DEFAULT (0),
		qty_alloc decimal(22, 5) NOT NULL DEFAULT (0),
		lpnremainqty decimal(22, 5) NOT NULL DEFAULT (0),
		qty_alloc_lpn decimal(22, 5) NOT NULL DEFAULT (0))

	declare
		@sql varchar(max)

/* позиции в заказе ################################################################################ */
	set @sql = 
		'insert into #orderd 
		select o.orderkey, o.externorderkey, od.externlineno, s.descr, o.orderdate, o.editdate, o.susr1, od.sku, od.storerkey, od.openqty, od.originalqty, od.qtyallocated
		from 
			'+@wh+'.orders o 
			join '+@wh+'.orderdetail od on o.orderkey = od.orderkey
			join '+@wh+'.sku s on s.sku = od.sku and s.storerkey = od.storerkey
		where ' +
			case when @manager is null then '' else ' o.susr1 = ''' + @manager + ''' and ' end +
			case when @orderkey is null then '' else ' o.externorderkey = '''+@orderkey+''' and ' end +
			'o.status  < 95 and 
			 s.lottablevalidationkey = ''02''

		order by od.sku, od.storerkey, od.openqty desc'
	exec (@sql)
/* ################################################################################################## */
--select * from wh40.loc where loc = '07.03I21'
/* ячейки и паллеты с товаром из заказа ############################################################# */
	set @sql = 
	'insert into #lxlxid
	select distinct od.sku, od.storerkey, lli.loc, lli.id plid, lli.qty, (lli.qty - lli.qtyallocated) qty_alloc, s.lpnremainqty, (lli.qty - lli.qtyallocated - s.lpnremainqty) qty_alloc_lpn
	from #orderd od 
		join '+@wh+'.sku s on od.sku = s.sku and od.storerkey = s.storerkey
		join '+@wh+'.putawayzone paz on paz.putawayzone = s.putawayzone
		join '+@wh+'.lotxlocxid lli on od.sku = lli.sku and od.storerkey = lli.storerkey
	where s.lottablevalidationkey=''02''
		
		and lli.qty > 0
	order by od.sku, od.storerkey, qty_alloc_lpn desc'
--	(paz.putawayzone in(''C_OTBOR7'', ''C_OTMOTKA7'', ''C_XRANEN7'') or paz.putawayzone like ''CABEL%'')
	exec (@sql)
/* ################################################################################################## */

/* удаление полностью зарезервированных позиций из заказа ########################################### */
	delete #orderd where openqty = qtyallocated
/* ################################################################################################## */

/* удаление позиций заказа удовлетворяющих заданным условим (длина) ################################# */
declare @sku varchar(10), @storerkey varchar(15), @qty_alloc_lpn int, @qty_allocat int

	declare orderd cursor for select lli.sku, lli.storerkey, qty_alloc_lpn, qty_alloc from #lxlxid lli
	open orderd
		fetch next from orderd into
		@sku, @storerkey, @qty_alloc_lpn, @qty_allocat
	while @@FETCH_STATUS <> -1
		begin
			delete #orderd where #orderd.sku = @sku and #orderd.storerkey = @storerkey and 
				(#orderd.openqty <= @qty_alloc_lpn or #orderd.openqty = @qty_allocat)
			fetch next from orderd into
			@sku, @storerkey, @qty_alloc_lpn, @qty_allocat
		end
	close orderd
	deallocate orderd
/* ################################################################################################## */

	select * from #orderd
	drop table #lxlxid
	drop table #orderd

