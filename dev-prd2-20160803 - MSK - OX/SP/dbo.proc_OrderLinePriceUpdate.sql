--################################################################################################
-- Обновление цены строки заказа
--################################################################################################
ALTER PROCEDURE [dbo].[proc_OrderLinePriceUpdate]
	@OrderKey		varchar(10),
	@OrderLineNumber varchar(5),
	@UnitPrice		float,
	@TAX01			float

AS

declare
	@oldUnitPrice		float,
	@oldTAX01			float

print '>>> Обновление цены товара по строке заказа >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
print 'Заказ №: '+ISNULL(@Orderkey,'null') + ' строка № '+ISNULL(@Orderkey,'null')

select od.orderkey, od.orderlinenumber, od.storerkey, od.sku, s.descr, od.unitprice, od.tax01
into #updatedLine
from wh1.orderdetail od
join wh1.sku s on (od.storerkey=s.storerkey and od.sku=s.sku)
where od.orderkey=@OrderKey and od.OrderLineNumber=@OrderLineNumber

if (select count(orderkey) from #updatedLine)=1
begin
	select @oldUnitPrice=isnull(unitprice,0),	@oldTAX01=isnull(tax01,0) from #updatedLine

	update wh1.orderdetail
	set unitprice=abs(isnull(@UnitPrice,@oldUnitPrice)),
		tax01=abs(isnull(@TAX01,@oldTAX01))
	where orderkey=@OrderKey and OrderLineNumber=@OrderLineNumber

	insert into #updatedLine
	select @OrderKey, @OrderLineNumber, '---', '---', '---', abs(isnull(@UnitPrice,@oldUnitPrice)), abs(isnull(@TAX01,@oldTAX01))
end

select * from #updatedLine

