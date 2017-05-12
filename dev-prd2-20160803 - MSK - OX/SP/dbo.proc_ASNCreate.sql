ALTER PROCEDURE [dbo].[proc_ASNCreate] (
@orderkey varchar(20) = '', -- номер документа
@receiptkey varchar(20) output
)
as  
--############################################ СОЗДАНИЕ ЗАКАЗА НА ПРИЕМКУ НА ОСНОВАНИИ ЗАКАЗА НА ОТГРУЗКУ

select 
o.storerkey,
o.externorderkey externreceiptkey,
o.[type],
o.carriercode carrierkey,
st.company,
getdate () receiptdate,
o.susr3,
o.susr4
into #DA_ReceiptHead
from wh1.orders o join wh1.storer st on o.carriercode = st.storerkey
where o.orderkey = @orderkey

select
od.orderlinenumber receiptlinenumber, 
od.externorderkey externreceiptkey, 
od.orderlinenumber externlineno,
od.storerkey, 
od.sku, 
--od.openqty qtyexpected, 
s.rfdefaultpack, 
s.rfdefaultuom
into #DA_ReceiptDetail
from wh1.orderdetail od join wh1.sku s on s.sku = od.sku and s.storerkey = od.storerkey
where od.orderkey = @orderkey

print '5. добавление новых документов'
print '5.1. формирование внутреннего номера документа RECEIPTKEY'
--	declare @receiptkey varchar(10)
	exec dbo.DA_GetNewKey 'wh1','receipt',@receiptkey output

print '5.2. добавление заголовка документа'
	insert into wh1.Receipt (receiptkey,     storerkey,                  rma, externreceiptkey, [type],     carrierkey, carriername,     receiptdate,     susr3,     susr4, status,     pokey)
		select				@receiptkey, drh.storerkey, drh.externreceiptkey,         'return',   '11', drh.carrierkey,  st.company, drh.receiptdate, drh.susr3, drh.susr4,    '0', @orderkey
		from #DA_ReceiptHead drh
			left join wh1.storer st on st.storerkey = drh.carrierkey

print '5.3. добавление деталей документа'
	insert into wh1.ReceiptDetail (receiptkey,                                         receiptlinenumber, externreceiptkey,     externlineno, qtyexpected,     storerkey,     sku,         packkey,            UOM,   toloc, status)
		select					  @receiptkey, right('0000'+convert(varchar(5),drd.receiptlinenumber),5),         'return', drd.externlineno,           0, drd.storerkey, drd.sku, s.rfdefaultpack, s.rfdefaultuom,  'DOCK',    '0'
		from #DA_ReceiptDetail drd join wh1.sku s on s.sku = drd.sku and s.storerkey = drd.storerkey
return

