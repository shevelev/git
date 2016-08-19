--################################################################################################
--         процедура создает консолидированный заказ и  (@type = 'new')
--                   добавляет детали					(@type = 'detail')
--################################################################################################
ALTER PROCEDURE [dbo].[app_DA_OrderCons] 
	@orderkey varchar(10), 
	@type varchar (20)
AS

declare @listexternorderkey varchar(max)
set @listexternorderkey = ''

print '>>> app_DA_OrderCons >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
print '@orderkey: '+@orderkey+'. @type: '+@type+'.'
if @type = 'new' 
	begin
		print 'DAOC.1. Добавление нового консолидированного заказа'
		print 'DAOC.1.1. добавление заголовка документа. Orderkey: ' + @orderkey
		insert into wh1.orders (orderkey, storerkey,  externorderkey, [type], consigneekey, carriercode,                                                                            intermodalvehicle, requestedshipdate,         deliveryplace,  deliveryadr, susr3, susr4, c_company, transportationmode, carriername, c_vat, c_address1, c_address2, c_address3, c_address4,   door, b_company)
			select			   @orderkey, storerkey, 'consolidation', [type], consigneekey, carriercode, case when carriercode is null or ltrim(rtrim(carriercode)) = '' then '' else carriercode end, requestedshipdate, left(deliveryaddr,30), deliveryaddr, susr3, susr4, c_company,                '0', carriername, c_vat, c_address1, c_address2, c_address3, c_address4, 'DOCK', b_company
			from ##DA_OrderHead where flag = 0
		print 'DAOC.1.2. добавление деталей документа'

		select 
				dod.ohid ohid,
				dod.externorderkey externorderkey, 
				min (dod.externlineno) externlineno,
				min(dod.orderlinenumber) orderlinenumber,
				dod.storerkey storerkey, 
				dod.sku sku,
				sum (dod.openqty) originalqty,
				sum (dod.openqty) openqty,
				dod.allocatestrategykey allocatestrategykey, 
				dod.preallocatestrategykey preallocatestrategykey, 
				dod.allocatestrategytype allocatestrategytype, 
				dod.cartongroup cartongroup, 
				dod.packkey packkey, 
				dod.shelflife shelflife,
				dod.flag
			into #group_skuif
			from ##DA_OrderDetail dod
			group by 
				dod.ohid, 
				dod.externorderkey, 
				dod.storerkey, 
				dod.sku, 
				dod.allocatestrategykey,
				dod.preallocatestrategykey,
				dod.allocatestrategytype,
				dod.cartongroup,
				dod.packkey,
				dod.shelflife,
				dod.flag


		insert into wh1.orderdetail (orderkey, orderlinenumber,                             externorderkey,     externlineno,     storerkey,     sku, originalqty,     openqty,  uom,     allocatestrategykey,     preallocatestrategykey,     allocatestrategytype,     cartongroup,     packkey, shelflife,    skurotation)
			 select @orderkey, right('0000'+convert(varchar(5),dod.orderlinenumber),5), dod.externorderkey, dod.externlineno, dod.storerkey, dod.sku, dod.openqty, dod.openqty, 'EA', dod.allocatestrategykey, dod.preallocatestrategykey, dod.allocatestrategytype, dod.cartongroup, dod.packkey, dod.shelflife, s.rotateby
			from ##DA_OrderHead doh join #group_skuif dod on doh.id = dod.ohid join wh1.sku s on dod.sku = s.sku and dod.storerkey = s.storerkey
			where doh.flag = 0 and dod.flag = 0 

		drop table #group_skuif
	end

if @type = 'detail' 
	begin
		print 'DAOC.1. Добавление деталей в консолидированный заказ. Orderkey: ' + @orderkey

		select ohid, sku, storerkey, sum (openqty) openqty, flag
			into #group_sku
			from ##DA_OrderDetail
			group by ohid, sku, storerkey, flag

		update od set od.originalqty = od.originalqty + dod.openqty, od.openqty = od.openqty + dod.openqty
			from wh1.orderdetail od join #group_sku dod on od.sku = dod.sku and od.storerkey = dod.storerkey
				join  ##DA_OrderHead doh on doh.id = dod.ohid
			where doh.flag = 0 and dod.flag = 0 and od.orderkey = @orderkey

		drop table #group_sku

		update dod set flag = 1
			from wh1.orderdetail od join ##DA_OrderDetail dod on od.sku = dod.sku and od.storerkey = dod.storerkey
				join  ##DA_OrderHead doh  on doh.id = dod.ohid
			where doh.flag = 0 and dod.flag = 0 and od.orderkey = @orderkey

		select 
				dod.ohid ohid,
				dod.externorderkey externorderkey, 
				min (dod.externlineno) externlineno,
				min(dod.orderlinenumber) orderlinenumber,
				dod.storerkey storerkey, 
				dod.sku sku,
				sum (dod.openqty) originalqty,
				sum (dod.openqty) openqty,
				dod.allocatestrategykey allocatestrategykey, 
				dod.preallocatestrategykey preallocatestrategykey, 
				dod.allocatestrategytype allocatestrategytype, 
				dod.cartongroup cartongroup, 
				dod.packkey packkey, 
				dod.shelflife shelflife,
				dod.flag
			into #group_skui
			from ##DA_OrderDetail dod
			group by 
				dod.ohid, 
				dod.externorderkey, 
				dod.storerkey, 
				dod.sku, 
				dod.allocatestrategykey,
				dod.preallocatestrategykey,
				dod.allocatestrategytype,
				dod.cartongroup,
				dod.packkey,
				dod.shelflife,
				dod.flag

		insert into wh1.orderdetail (orderkey,																																  orderlinenumber,     externorderkey,     externlineno,     storerkey,     sku, originalqty,     openqty,  uom,     allocatestrategykey,     preallocatestrategykey,     allocatestrategytype,     cartongroup,     packkey,     shelflife, skurotation)
			  select @orderkey,right('0000'+convert(varchar(5),(select convert(int,max (orderlinenumber)) from wh1.orderdetail where orderkey = @orderkey)+convert(int,dod.orderlinenumber)),5), dod.externorderkey, dod.externlineno, dod.storerkey, dod.sku, dod.openqty, dod.openqty, 'EA', dod.allocatestrategykey, dod.preallocatestrategykey, dod.allocatestrategytype, dod.cartongroup, dod.packkey, dod.shelflife, s.rotateby
			from ##DA_OrderHead doh join #group_skui dod on doh.id = dod.ohid join wh1.sku s on dod.sku = s.sku and dod.storerkey = s.storerkey
			where doh.flag = 0 and dod.flag = 0 

		drop table #group_skui

	end

	print 'DAOC.2.1. добавление шапки заказа в таблицу временного хранения'
	insert into wh1.orders_c (orderkey, storerkey, externorderkey, [type], susr3, susr4, consigneekey, carriercode, requestedshipdate, deliveryaddr, c_company, carriername, c_vat, c_address1, c_address2, c_address3, c_address4, b_company)
					select @orderkey, storerkey, externorderkey, [type], susr3, susr4, consigneekey, carriercode, requestedshipdate, deliveryaddr, c_company, carriername, c_vat, c_address1, c_address2, c_address3, c_address4, b_company
					from ##DA_OrderHead where flag < 2

	print 'DAOC.2.2. добавление деталей заказа в таблицу временного хранения'
	insert into wh1.orderdetail_c (orderkey, externorderkey, externlineno, storerkey, sku, openqty, allocatestrategykey, preallocatestrategykey, allocatestrategytype, cartongroup, packkey, shelflife)
			select @orderkey, dod.externorderkey, dod.externlineno, dod.storerkey, dod.sku, dod.openqty, dod.allocatestrategykey, dod.preallocatestrategykey, dod.allocatestrategytype, dod.cartongroup, dod.packkey, dod.shelflife 
			from ##DA_OrderHead doh join ##DA_OrderDetail dod on doh.id = dod.ohid
			where doh.flag < 2 and dod.flag < 2  

	print 'DAOC.3.1. сохранение списка входящих в consolidation заказ '+ case when @orderkey is null then 'null' else @orderkey end +' заказов'
	exec app_DA_OrderConsNumbers @orderkey

	
print '<<< app_DA_OrderCons <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'

