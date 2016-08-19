ALTER PROCEDURE [dbo].[SP_POSTPHYSICAL_CST0030] 
@wh varchar(15)
AS

-- Процедура вызывается из DWarehouseManagement.PostPhysicalP1S1.ProcessStep при подтверждении инвентаризации в
-- рабочей станции (окно "Параметры инвентаризации"/"Physical parameters" меню "Принять результаты инв."/"Post physical").

-- В процедуре можно описать какие-либо действия, которые будут выполнены перед применением результатов инвентаризации.
-- На проекте "Северо-Запад" это - копирование данных из табл. инвентаризации в архивные таблицы.

-- Если никакие дополнительные действия не требуются, тело процедуры можно оставить пустым.

SET NOCOUNT ON

declare @currentdate datetime
declare @key int

set @currentdate = GETDATE() -- текущая дата

--получить номер для записи в лог
exec dbo.DA_GetNewKey 'wh1','INVENTORYKEY',@key output

--Необходимо, чтобы InventoryKey в табл. xxx_CST0030 и в TRANSMITLOG совпадал, т.к. при выгрузке данных идет связь таблиц по этому номеру. 
--AppServer при вставке события в TRANSMITLOG берет текущее значение счетчика из т. NCOUNTER.
--Поэтому здесь также берем текущее значение счетчика из NCOUNTER, а не то, которое вернула проц. DA_GetNewKey.
--Таким образом, для счетчика INVENTORYKEY в т. NCOUNTER хранится последнее занятое значение, а не первое свободное.
--select @key = right('0000000000' + cast(keycount as varchar),10) from wh1.NCOUNTER where KEYNAME ='INVENTORYKEY'
select @key = keycount from wh1.NCOUNTER where KEYNAME ='INVENTORYKEY'


-- текущие остатки
insert into wh1.lotxlocxid_CST0030 (
	[inventoryid_030],
	[adddate_030],
	[SERIALKEY],
	[WHSEID],
	[LOT],
	[LOC],
	[ID],
	[STORERKEY],
	[SKU],
	[QTY],
	[QTYALLOCATED],
	[QTYPICKED],
	[QTYEXPECTED],
	[QTYPICKINPROCESS],
	[PENDINGMOVEIN],
	[ARCHIVEQTY],
	[ARCHIVEDATE],
	[STATUS],
	[ADDDATE],
	[ADDWHO],
	[EDITDATE],
	[EDITWHO])
select 
	@key,
	@currentdate,
	[SERIALKEY],
	[WHSEID],
	[LOT],
	[LOC],
	[ID],
	[STORERKEY],
	[SKU],
	[QTY],
	[QTYALLOCATED],
	[QTYPICKED],
	[QTYEXPECTED],
	[QTYPICKINPROCESS],
	[PENDINGMOVEIN],
	[ARCHIVEQTY],
	[ARCHIVEDATE],
	[STATUS],
	[ADDDATE],
	[ADDWHO],
	[EDITDATE],
	[EDITWHO]
from wh1.lotxlocxid where QTY > 0


update p set 
	[STATUS] = '9'
from (
	select
		[STATUS],
		row_number() over (partition by TEAM, STORERKEY, SKU, LOC, LOT/*, ID*/ order by INVENTORYTAG desc, ADDDATE desc) as RN
	from wh1.PHYSICAL
	where [STATUS] = '0'
) p
where RN > 1



insert into wh1.PHYSICAL_CST0030(
	[PHYSICAL_030] ,
	[adddate_030] ,
	[SERIALKEY],
	[WHSEID] ,
	[TEAM],
	[STORERKEY],
	[SKU],
	[LOC],
	[LOT],
	[ID] ,
	[INVENTORYTAG],
	[QTY],
	[PACKKEY],
	[UOM],
	[STATUS],
	[ADDDATE],
	[ADDWHO],
	[EDITDATE],
	[EDITWHO])
select
	@key,
	@currentdate,
	[SERIALKEY],
	[WHSEID] ,
	[TEAM],
	[STORERKEY],
	[SKU],
	[LOC],
	[LOT],
	[ID] ,
	[INVENTORYTAG],
	[QTY],
	[PACKKEY],
	[UOM],
	[STATUS],
	[ADDDATE],
	[ADDWHO],
	[EDITDATE],
	[EDITWHO]
from WH1.PHYSICAL
where STATUS = 0




--select * from wh1.lotxlocxid_CST0030
--select * from wh1.PHYSICAL_CST0030

--delete from wh1.lotxlocxid_CST0030
--delete from wh1.PHYSICAL_CST0030

RETURN 0

