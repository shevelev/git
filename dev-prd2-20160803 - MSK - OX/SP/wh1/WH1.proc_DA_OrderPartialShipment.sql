

ALTER PROCEDURE [WH1].[proc_DA_OrderPartialShipment](
	@wh varchar(10),
	@transmitlogkey varchar (10)	
)AS

SET NOCOUNT ON
SET XACT_ABORT ON

if @wh <> 'wh1'
begin
	raiserror('Недопустимая схема %s',16,1,@wh)
	return
end

declare	@orderkey varchar (10) -- номер заказа
declare	@key2 varchar (10)     -- номер строки заказа
declare @linecnt  int
declare @linecnt2 int

create TABLE #result 
(	
	[storerkey] varchar(15),
	[externorderkey] varchar(32),
	[type] varchar(10),
	[susr1] varchar(30),
	[susr2] varchar(30),
	[susr3] varchar(30),
	[consigneekey] varchar(10),
	[b_company] varchar(10),
	[carriercode] varchar(10),
	[sku] varchar(10),
	[shippedqty] varchar(30)
)

select	@orderkey = o.orderkey, @key2 = tl.key2 
from	wh1.orders o, wh1.transmitlog tl 
where	tl.transmitlogkey = @transmitlogkey 
	and o.orderkey = tl.key1

-- если не все отборы заказа упакованы, или сообщение уже отправлено в хост-систему, ДА не выгружает файл

-- pickdetail.status = ''6'' упакованная строка отбора
-- pickdetail.status = ''9'' отгруженная строка отбора

-- pickdetail.pdudf2 = ''6'' позиция отбора отправлена в HOST систему после упаковки
-- pickdetail.pdudf2 = ''9'' позиция отбора отправлена в HOST систему после отгрузки

select @linecnt  = count(*) from wh1.pickdetail where orderkey = @orderkey
select @linecnt2 = count(*) from wh1.pickdetail where orderkey = @orderkey and 
					[status]='9' and (isnull(pdudf2,'')='' or pdudf2='6')

if @linecnt = @linecnt2
begin
	--получить номер для записи в лог
	exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
	
	--записать в лог событие об отгрузке заказа
	insert wh1.transmitlog (whseid, transmitlogkey, tablename, key1,ADDWHO) 
	values ('WH1', @transmitlogkey, 'ordershippedda', @orderkey, 'dataadapter')

	-- Сообщение готово к отправке в хост-систему
	update wh1.pickdetail set pdudf2 = isnull(pdudf2,'')+ '9' where orderkey = @orderkey
end

--вернуть пустой рекордсет
select 'PARTIALSHIPMENT' as filetype, * from #result



