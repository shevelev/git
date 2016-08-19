--#################################################################################### ÏÎÄÒÂÅĞÆÄÅÍÈÅ ÊÎĞĞÅÊÒÈĞÎÂÊÈ

ALTER PROCEDURE [dbo].[proc_DA_InventoryOk] (
	@wh varchar(10),
	@transmitlogkey varchar (10))

AS

	select 'INVENTORY' filetype, ih.inventorykey, convert(varchar(10),ih.createdate,112) + ' ' + replace(convert(varchar(10),ih.createdate,108),':','') date, id.sklad, id.sku, id.storerkey, sum(id.factqty) factqty, sum(id.deltaqty) deltaqty
from wh1.transmitlog t join da_inventoryhead ih on t.key1 = ih.inventorykey
	join da_inventorydetail id on ih.inventorykey = id.inventorykey
where t.transmitlogkey = @transmitlogkey
group by ih.inventorykey, ih.createdate, id.sklad, id.sku, id.storerkey

