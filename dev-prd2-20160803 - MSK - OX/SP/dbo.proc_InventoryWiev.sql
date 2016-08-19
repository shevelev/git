ALTER PROCEDURE [dbo].[proc_InventoryWiev] (
		@wh varchar(10),
		@invkey varchar (10)
)

AS
declare @sql varchar(max)
--##################################################################################### ÏĞÎÑÌÎÒĞ ÊÎĞĞÅÊÒÈĞÎÂÊÈ
-- âûâîä ğåçóëüòàòîâ
set @sql =
'select distinct hz.hostzone, ih.createdate, s.company, id.inventorykey, id.skugroup, id.sku, id.storerkey, sum (id.factqty) factqty, sum(id.deltaqty) deltaqty, id.sklad, id.descr
from da_inventorydetail id join '+@wh+'.storer s on s.storerkey = id.storerkey
join '+@wh+'.hostzones hz on id.sklad = hz.hostzone
join da_inventoryhead ih on ih.inventorykey = id.inventorykey
where ih.inventorykey = '''+@invkey+''' and ih.whseid = '''+@wh+'''
group by hz.hostzone, ih.createdate, s.company, id.inventorykey, id.skugroup, id.sku, id.storerkey, id.sklad, id.descr'
exec (@sql)

