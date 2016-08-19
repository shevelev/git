






ALTER PROCEDURE [rep].[Order_Details_on_shipment] (
	@WH varchar(30),
	@order varchar(20)
)
AS

--declare @WH varchar(30),@order varchar(20)
--select @order = '0000006250', @WH='wh1'

	declare @sql varchar(max)

	--exec dbo.DA_GetDropTSByOrder @wh, @order, 1, 0
	
	select od.orderkey, od.externorderkey, od.orderlinenumber, od.sku, od.storerkey, 
		originalqty+adjustedqty OrderQTY, qtypicked, shippedqty, 
		s.descr skuName, oss.description statusName, od.editdate, od.lottable07
	into #ordDet
	 from wh1.orderdetail  od
		left join wh1.sku s on od.sku=s.sku and od.storerkey=s.storerkey
		left join wh1.orderstatussetup oss on oss.code = od.status
	where 1=2--od.orderkey = @order

	set @sql = 'insert	into #ordDet 
		select od.orderkey, od.externorderkey, od.orderlinenumber, od.sku, od.storerkey, 
		originalqty+adjustedqty OrderQTY, qtypicked, shippedqty, 
		s.descr skuName, oss.description statusName, od.editdate, od.lottable07
	
	 from '+@WH+'.orderdetail  od
		left join '+@WH+'.sku s on od.sku=s.sku and od.storerkey=s.storerkey
		left join '+@WH+'.orderstatussetup oss on oss.code = od.status
	where od.orderkey = '''+@order+''''
	exec(@sql)
	
	select orderkey, orderlinenumber, sum(qty)qty, max(editdate)editdate
	into #picks
	from wh1.pickdetail where 1=2 --orderkey = @order and status in (5,6)
	group by orderkey, orderlinenumber

	set @sql = 'insert into #picks select orderkey, orderlinenumber, sum(qty)qty, max(editdate)editdate
	from '+@WH+'.pickdetail where orderkey = '''+@order+''' and status in (6)
	group by orderkey, orderlinenumber'
	exec(@sql)

	select orderkey, orderlinenumber, sum(qty)qty, max(editdate)editdate
	into #picks2
	from wh1.pickdetail where 1=2 --orderkey = @order and status in (5,6)
	group by orderkey, orderlinenumber
	
	-- целую паллету не надо упаковывать.. но т.к. упаковывают все то комментируем этот код
----	set @sql = 'insert into #picks2 select orderkey, orderlinenumber, sum(qty)qty, max(editdate)editdate
----	from '+@WH+'.pickdetail where orderkey = '''+@order+''' and status in (5) 
----		and (dropid like ''P%'' or dropid like ''C%'')
----	group by orderkey, orderlinenumber'
----	exec(@sql)

--isnull(p2.editdate,p.editdate)editdate
	select od.orderkey, od.externorderkey, od.orderlinenumber, od.sku, od.storerkey, 
		od.OrderQTY, od.qtypicked, od.shippedqty, 
		case when isnull(p.qty,0)+isnull(od.qtypicked,0)+ isnull(od.shippedqty,0)+isnull(p2.qty,0)>0
			then 
			isnull(case when p.editdate>p2.editdate 
				then isnull(p.editdate,p2.editdate) 
				else isnull(p2.editdate,p.editdate) 
			end,od.editdate )
		else null end editdate,
--			p.editdate,p2.editdate, +isnull(od.shippedqty,0) 
		od.skuName, od.statusName,
		isnull(p.qty,0)+isnull(p2.qty,0) qtypacked, lottable07 --:
	from #ordDet od
		left join #picks p on od.orderlinenumber=p.orderlinenumber
		left join #picks2 p2 on od.orderlinenumber=p2.orderlinenumber
		
		
	drop table #picks
	drop table #picks2
	drop table #ordDet











