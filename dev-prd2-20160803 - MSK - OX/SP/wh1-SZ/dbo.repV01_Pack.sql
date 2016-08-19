-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 03.12.2009 (НОВЭКС)
-- Описание: Отчет товара с фасовкой
--	Данная процедура осуществляет выборку товара по виду фасовки для конкретного клиента.
--	...
-- =============================================

ALTER PROCEDURE [dbo].[repV01_Pack] ( 
									
	@wh varchar(30),
	@storer varchar(15)
)

as

create table #result_table (
		SkuCod varchar(50) not null,
		Storer varchar(15) not null,
		SkuDescr varchar(60) null, 
		Loc varchar(10) not null,
		Lot varchar(10) not null,
		Pack varchar(50) not null,
		Kol decimal(22,5) not null
)

declare @sql varchar(max)
		
set @sql='

insert into #result_table
select 		lotx.sku SkuCod,
			lotx.storerkey Storer,
			sk.descr SkuDescr,
			lotx.loc Loc,
			lotx.lot Lot,
			lotat.lottable01 Pack,
			lotx.qty Kol

from '+@wh+'.LOTXLOCXID lotx 
			join '+@wh+'.SKU sk on lotx.sku=sk.sku 
								and lotx.storerkey=sk.storerkey
			join '+@wh+'.LOTATTRIBUTE lotat on lotx.sku=lotat.sku 
											and lotx.storerkey=lotat.storerkey 
											and lotx.lot=lotat.lot
											
											
where lotx.storerkey='''+@storer+''' and lotx.qty <>0 
	  
order by lotx.sku
		 
'

print (@sql)
exec (@sql)

select SkuCod,
		Storer,
		SkuDescr, 
		Loc,
		Lot,
		Pack,
		Kol
from #result_table

drop table #result_table

