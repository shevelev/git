-- =============================================
-- Автор:		Смехнов Антон
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 18.11.2009 (НОВЭКС)
-- Описание: очистка настроек пополнения для указаной ячейки и товара БЕЗ ПЕРЕСЧЕТА УРОВНЕЙ ПОПОЛНЕНИЯ ДЛЯ ДРЯГИХ ТОВАРОВ ЯЧЕЙКИ !!!

-- =============================================
ALTER PROCEDURE [WH1].[novex_ClearSKUPickLoc] 
		@loc as varchar(10),
		@storerkey as varchar(15),
		@sku as varchar(60)
AS

print '3333333333333333333333333333333333333333333333333333333333333333333333333333'
print 'Очищаем настройки пополнения, для указанной ячейки и товара'

if (isnull(@loc,'')<>'' and isnull(@storerkey,'')<>'' and isnull(@sku,'')<>'')
begin

	update wh1.skuxloc
	set qtylocationlimit=0,
		qtylocationminimum=0,
		ALLOWREPLENISHFROMCASEPICK=0,
		ALLOWREPLENISHFROMBULK=0,
		replenishmentseverity=0,
		REPLENISHMENTPRIORITY='9'
	where
	(isnull(@loc,'')<>'' and isnull(@storerkey,'')<>'' and isnull(@sku,'')<>'')
	AND
	(	qtylocationlimit>0
		or qtylocationminimum>0
		or ALLOWREPLENISHFROMCASEPICK=1
		or ALLOWREPLENISHFROMBULK=1)
	AND
	(loc=@loc)
	AND
	( storerkey=@storerkey and sku=@sku )

end

