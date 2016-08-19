-- ПОДТВЕРЖДЕНИЕ ОТГРУЗКИ ЗАКАЗА

ALTER PROCEDURE [dbo].[proc_DA_OrderShipped](
	@wh varchar(10),
	@transmitlogkey varchar (10)
)AS

SET NOCOUNT ON

if @wh <> 'wh1'
begin
	raiserror('Недопустимая схема %s',16,1,@wh)
	return
end

declare	@orderkey varchar (10) -- номер заказа
declare @skip_0_qty varchar(10)

CREATE TABLE #result (	
	[storerkey] varchar(15),
	[externorderkey] varchar(32),
	[type] varchar(10),
	[susr1] varchar(30),
	[susr2] varchar(30),
	[susr3] varchar(30),
	[susr4] varchar(30),
	[consigneekey] varchar(15),
	[b_company] varchar(45),
	[carriercode] varchar(15),
	[sku] varchar(10),
	[shippedqty] decimal(22,5)
)

select @orderkey = tl.key1 from wh1.transmitlog tl 
where tl.transmitlogkey = @transmitlogkey

insert #result (storerkey, externorderkey, [type], susr1, susr2, susr3, susr4, consigneekey, b_company, carriercode, sku, shippedqty)
	select o.storerkey, o.externorderkey, o.[type], o.susr1, o.susr2, o.susr3, o.susr4, o.consigneekey, o.b_company, o.carriercode, d.sku, sum(p.qty) qty
	from wh1.orders o, wh1.orderdetail d, wh1.pickdetail p
	where o.orderkey=@orderkey and d.orderkey=o.orderkey and p.orderkey=o.orderkey and p.orderlinenumber=d.orderlinenumber
	group by o.storerkey, o.externorderkey, o.[type], o.susr1, o.susr2, o.susr3, o.susr4, o.consigneekey, o.b_company, o.carriercode, d.sku

set @skip_0_qty = 'N'
select @skip_0_qty = s.value from DA_SETTINGS s where s.parameter='custom.skip_zero_qty' and s.enabled=1

-- Вернуть результат Дата Адаптеру
select 'ORDERSHIPPED' as filetype, * from #result where @skip_0_qty != 'Y' or shippedqty > 0
drop table #result

