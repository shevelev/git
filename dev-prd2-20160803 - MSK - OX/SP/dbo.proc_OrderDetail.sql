ALTER PROCEDURE [dbo].[proc_OrderDetail] (
@orderkey varchar(20) = '', -- номер документа
@createASN varchar (3) = null --создать ASN
)
as  
--############################################ СОСТАВ ЗАКАЗА НА ОТГРУЗКУ
declare @receiptkey varchar(20) -- номер документа возврата

if @createasn is null
	begin
		select o.orderkey, st.company + ' (' +st.storerkey+ ') ' carrier,od.orderlinenumber, s.sku, s.descr, od.originalqty, od.shippedqty, null receiptkey
		from wh1.orderdetail od join wh1.orders o on od.orderkey = o.orderkey
		join wh1.sku s on od.sku = s.sku and od.storerkey = s.storerkey
		left join wh1.storer st on o.carriercode = st.storerkey
		where o.orderkey = @orderkey
		order by od.orderlinenumber
	end
else
	begin
		exec dbo.proc_ASNCreate @Orderkey, @receiptkey output
		select o.orderkey, st.company + ' (' +st.storerkey+ ') ' carrier,od.orderlinenumber, s.sku, s.descr, od.originalqty, od.shippedqty, @receiptkey receiptkey
		from wh1.orderdetail od join wh1.orders o on od.orderkey = o.orderkey
		join wh1.sku s on od.sku = s.sku and od.storerkey = s.storerkey
		left join wh1.storer st on o.carriercode = st.storerkey
		where o.orderkey = @orderkey
		order by od.orderlinenumber
	end

