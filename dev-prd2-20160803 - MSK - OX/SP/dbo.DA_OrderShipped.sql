ALTER PROCEDURE [dbo].[DA_OrderShipped](
	@wh varchar(10),
	@tKey varchar(10)
	
)AS
	declare @key1 varchar(10)
	select @key1 = key1 from wh1.transmitlog where transmitlogkey = @tkey
	
	-- получаем детали
	select * into #ordDet from wh1.orderdetail where orderkey = @key1
	
	-- получили отборы
	select * into #picks from wh1.pickdetail where  orderkey = @key1 and [status] = '9' and isnull(pdudf2,'0')='0'
	
	-- получили сумму по отборам
	select orderkey, sku, storerkey, sum(qty)qty into #pickSum from #picks group by orderkey, sku, storerkey
	
	-- возвращаем
	select o.externorderkey,  o. orderkey, o.type, o.consigneekey,
		o.actualshipdate, o.deliveryDate, o.priority, o.status, o.ordergroup,
		o.deliveryplace, o.editwho,
		ps.storerkey, ps.sku, ps.qty, ps.status, 
		ps.qty*s.stdcube PRODUCT_CUBE, ps.qty*s.stdgrosswgt PRODUCT_WEIGHT
	from wh1.orders o
		join #pickSum ps on o.orderkey = ps.orderkey
		join wh1.sku s on s.sku = ps.sku and s.storerkey = ps.storerkey
	where receiptkey = @key1
	
	--select * from wh40.sku

