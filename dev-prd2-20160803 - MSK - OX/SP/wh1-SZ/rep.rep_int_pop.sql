ALTER PROCEDURE [rep].[rep_int_pop] (
	@sku varchar(10) = NULL,
	@orderkey varchar(10) = NULL,
	@route varchar(10) = NULL
)
AS
BEGIN

	select
		@sku = nullif(rtrim(@sku),''),
		@orderkey = nullif(rtrim(@orderkey),''),
		@route = nullif(rtrim(@route),'')
	
	create table #rezZz (
		orderkey varchar(20),
		[route] varchar(10),
		departuretime datetime,
		originalqty int,
		sku varchar(20),
		notes1 varchar(100),
		lot1 varchar(40),
		lot2 varchar(40),
		lot3 varchar(40),
		lot4 datetime,
		lot5 datetime,
		lot7 varchar(40),
		lot8 varchar(40),
		qty int,
		fromloc varchar(20),
		toloc varchar(20),
		descr varchar(50)
	)

	insert into #rezZz
	select
		od.ORDERKEY,
		lh.[ROUTE],
		lh.DEPARTURETIME,
		case when isnull(p.CASECNT,0) = 0 then od.ORIGINALQTY else od.ORIGINALQTY % convert(int,p.CASECNT) end as ORIGINALQTY,
		td.SKU,
		s.NOTES1,
		l.LOTTABLE01,
		l.LOTTABLE02,
		l.LOTTABLE03,
		l.LOTTABLE04,
		l.LOTTABLE05,
		l.LOTTABLE07,
		l.LOTTABLE08,
		td.QTY,
		td.FROMLOC,
		td.TOLOC,
		'Пополнение склада' descr
	from wh1.ORDERDETAIL od
		join wh1.SKU s on s.SKU = od.sku
		join wh1.ORDERS o
			join wh1.LOADORDERDETAIL lo
				--join wh1.STORER s on lo.CUSTOMER = s.STORERKEY
				join wh1.LOADSTOP ls
					join wh1.LOADHDR lh on ls.LOADID = lh.LOADID
				on lo.LOADSTOPID = ls.LOADSTOPID
			on o.ORDERKEY = lo.SHIPMENTORDERID
		on o.ORDERKEY = od.ORDERKEY and o.STATUS in ('02', '09')
		join wh1.TASKDETAIL td on od.SKU = td.SKU
		join wh1.LOTATTRIBUTE l
			left join wh1.PACK p on l.LOTTABLE01 = p.PACKKEY 
		on l.LOT = td.LOT
	where td.TASKTYPE = 'MV'
		and td.[STATUS] = '0'
		and ( @orderkey is NULL or od.ORDERKEY = @orderkey )
		and ( @sku is NULL or td.SKU = @sku )
		and ( @route is NULL or lh.[ROUTE] = @route )

	union all

	select
		od.ORDERKEY,
		lh.[ROUTE],
		lh.DEPARTURETIME,
		od.ORIGINALQTY,
		lxlx.SKU,
		s.NOTES1,
		l.LOTTABLE01,
		l.LOTTABLE02,
		l.LOTTABLE03,
		l.LOTTABLE04,
		l.LOTTABLE05,
		l.LOTTABLE07,
		l.LOTTABLE08,
		lxlx.QTY,
		lxlx.LOC as FROMLOC,
		'' as TOLOC,
		'Размещение с EA_IN' descr
	from wh1.ORDERDETAIL od
		join wh1.SKU s on s.SKU = od.SKU
		join wh1.ORDERS o
			join wh1.LOADORDERDETAIL lo
				--join wh1.STORER s on lo.CUSTOMER = s.STORERKEY
				join wh1.LOADSTOP ls
					join wh1.LOADHDR lh on ls.LOADID = lh.LOADID
				on lo.LOADSTOPID = ls.LOADSTOPID
			on o.ORDERKEY = lo.SHIPMENTORDERID
		on o.ORDERKEY = od.ORDERKEY and o.STATUS in ('02', '09')
		join wh1.LOTxLOCxID lxlx on od.SKU = lxlx.SKU
		join wh1.LOTATTRIBUTE l on l.LOT = lxlx.LOT
	where lxlx.LOC = 'EA_IN'
		and lxlx.QTY > 0
		and lxlx.ID = ''
		and ( @orderkey is NULL or od.ORDERKEY = @orderkey )
		and ( @sku is NULL or lxlx.SKU = @sku )
		and ( @route is NULL or lh.[ROUTE] = @route )

	select distinct * from #rezZz order by descr, notes1, originalqty desc

	drop table #rezZz

END


