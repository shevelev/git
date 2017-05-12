/**********************************************************************************************/

-- ОТМЕНА ОТГРУЗКИ ЗАКАЗА

ALTER PROCEDURE [WH2].[proc_DA_OrderShipped](
	@wh varchar(10),
	@transmitlogkey varchar (10)
)AS

------------declare	@orderkey varchar (10) -- номер заказа

------------select @orderkey = tl.key1 from WH2.transmitlog tl 
------------where tl.transmitlogkey = @transmitlogkey


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
from	WH2.orders o, WH2.transmitlog tl 
where	tl.transmitlogkey = @transmitlogkey 
	and o.orderkey = tl.key1

-- если не все отборы заказа упакованы, или сообщение уже отправлено в хост-систему, ДА не выгружает файл

-- pickdetail.status = ''6'' упакованная строка отбора
-- pickdetail.status = ''9'' отгруженная строка отбора

-- pickdetail.pdudf2 = ''6'' позиция отбора отправлена в HOST систему после упаковки
-- pickdetail.pdudf2 = ''9'' позиция отбора отправлена в HOST систему после отгрузки

select @linecnt  = count(*) from WH2.pickdetail where orderkey = @orderkey
select @linecnt2 = count(*) from WH2.pickdetail where orderkey = @orderkey and 
					[status]='9' and (isnull(pdudf2,'')='' or pdudf2='6')

if @linecnt = @linecnt2
begin
	--получить номер для записи в лог
	exec dbo.DA_GetNewKey 'WH2','eventlogkey',@transmitlogkey output
	
	--записать в лог событие об отгрузке заказа
	insert WH2.transmitlog (whseid, transmitlogkey, tablename, key1,ADDWHO) 
	values ('WH2', @transmitlogkey, 'ordershippedda', @orderkey, 'dataadapter')

	-- Сообщение готово к отправке в хост-систему
	update WH2.pickdetail set pdudf2 = isnull(pdudf2,'')+ '9' where orderkey = @orderkey
end


select 'RETURNSHIPMENTORDER' filetype, STORERKEY, ORDERKEY,EXTERNORDERKEY from WH2.ORDERS where ORDERKEY = @orderkey --and type = '26'

--drop table #result
--drop table #tmp
--drop table #result1


----status pickdetail
----	0 - зарезервирован
----	1 - запущен
----	5 - отобран
----	6 - упакован
----	8 - загружен
----	9 - отгружен

----
----
----

