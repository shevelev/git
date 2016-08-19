-- =============================================
-- Автор:		Смехнов Антон
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 27.10.2009 (НОВЭКС)
-- Описание: Пересчет параметров пополнения для товаров по которым были изменения

-- =============================================
ALTER PROCEDURE [WH1].[novex_RecalcPickLoc_for_modifed_SKU] 
AS

declare @pLOC	varchar(10)

print '1111111111111111111111111111111111111111111111111111111111111111111111111111'
print 'Отбираем товары, по которым на складе произошли изменения'
print 'Товары группы X исключаем из рассмотрения'
select distinct sku.storerkey, sku.sku
into #SKUbalance
from sku left join old_sku on (sku.storerkey=old_sku.storerkey and sku.sku=old_sku.sku )
where 
(	(old_sku.sku is null)
	OR
	(sku.stdcube<>old_sku.stdcube or sku.stdgrosswgt<>old_sku.stdgrosswgt or isnull(sku.abc,'C')<>old_sku.abc )
)
AND 
sku.abc<>'X'

--select * from #SKUbalance
print '2222222222222222222222222222222222222222222222222222222222222222222222222222'
print 'Отбираем ячейки по которым требуется провести пересчет параметров пополнения по причине изменения товаров'
print 'Ячейки с товарами группы X исключаем из рассмотрения'
select distinct sxl.loc, loc.cubiccapacity, cast(0 as float) skucount
into #selectedLocs
from SKUxLOC sxl join #SKUbalance SB on (sxl.storerkey=SB.storerkey and sxl.sku=SB.sku)
				 join loc on (loc.loc=sxl.loc)
				 join SKU on (sxl.storerkey=SKU.storerkey and sxl.sku=SKU.sku)
where (sxl.allowreplenishfromcasepick=1 or sxl.allowreplenishfrombulk=1)
group by sxl.loc, loc.cubiccapacity
having max(isnull(sku.abc,'C'))<>'X'
--select * from #selectedLocs

print '...Рассчитываем и обновляем пороги пополнения для всех выбранных ячеек'
DECLARE LOCATIONSLIST CURSOR STATIC FOR 
SELECT LOC FROM #selectedLocs

OPEN LOCATIONSLIST
FETCH NEXT FROM LOCATIONSLIST INTO @pLOC

WHILE @@FETCH_STATUS = 0
BEGIN
	exec WH1.novex_RecalcLoc @pLOC
	FETCH NEXT FROM LOCATIONSLIST INTO @pLOC
END

CLOSE LOCATIONSLIST
DEALLOCATE LOCATIONSLIST


print '4444444444444444444444444444444444444444444444444444444444444444444444444444'
print 'Запоминаем товары'
truncate table wh1.old_sku

insert into old_sku
select storerkey, sku, stdcube, stdgrosswgt, isnull(abc,'C')
from sku

