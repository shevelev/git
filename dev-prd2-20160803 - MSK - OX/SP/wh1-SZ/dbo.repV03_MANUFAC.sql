-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 03.12.2009 (НОВЭКС)
-- Описание: Отчет товар с не проставленным полем  срок производства или годен до
--	Данная процедура осуществляет выборку товара с не проставленным полем  срок производства
--  при условии что данный тип товара учитывается с его срока производства.
--	соотвественно и по годен до...
-- =============================================

ALTER PROCEDURE [dbo].[repV03_MANUFAC] ( 
									
	@wh varchar(30),
	@storer varchar(15),
	@check int
)

as

create table #result_table (
		Storer varchar(15) not null,
		SkuCod varchar(50) not null,		
		SkuDescr varchar(60) null, 
		Loc varchar(10) not null,
		Kol decimal(22,5) not null,
		Lot varchar(10) not null
)

declare @sql varchar(max)
		
set @sql='
insert into #result_table
select  lotx.storerkey Storer,
		lotx.sku SkuCod,
		sk.descr SkuDescr,
		lotx.loc Loc,
		lotx.qty Kol,
		lotx.lot Lot
		
from '+@wh+'.LOTXLOCXID lotx
	join '+@wh+'.SKU sk on lotx.sku=sk.sku 
						and lotx.storerkey=sk.storerkey
	join '+@wh+'.LOTATTRIBUTE lotat on lotx.sku=lotat.sku 
									and lotx.storerkey=lotat.storerkey
									and lotx.lot=lotat.lot
where lotx.storerkey='''+@storer+'''
		'+
		case when @check=1 then 'and sk.lottablevalidationkey=''MANUFAC'''
			else 'and sk.lottablevalidationkey=''EXPIRED''' end
		+'
		'+case when @check=1 then 'and isnull(lotat.lottable04,'''')='''''
			else 'and isnull(lotat.lottable05,'''')=''''' end
		+'
		and lotx.qty<>0

order by lotx.sku
		 
'

print (@sql)
exec (@sql)

select  Storer,
		SkuCod,		
		SkuDescr, 
		Loc,
		Kol,
		Lot
from #result_table

drop table #result_table

