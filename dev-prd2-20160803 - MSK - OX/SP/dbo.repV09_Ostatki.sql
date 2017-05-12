-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 21.12.2009 (НОВЭКС)
-- Описание: Остатки товара
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV09_Ostatki] ( 
									
	@wh varchar(30),
	@storer varchar(20),
	@groupT varchar(30)

)

as

create table #result_table (
		serialkey int not null,
		Sku varchar(50) not null, -- Код товара
		Descr varchar(60) null, -- Описание товара
		Qty decimal(22,5) not null -- Кол-во товара
		
		
)

declare @sql varchar(max)
declare @grT varchar(max)

--set @grT=if isnull(@groupT, '')
if @groupT is not null
begin
	set @grT=' and td.descrip = '''+@groupT+''''
--	print @grT
end
if @groupT='BrakPriem'
	set @grT=' and lotx.loc not like ''Brak%'''
if @groupT is null
	set @grT=''

set @sql='
insert into #result_table
	select 	distinct lotx.serialkey,
			lotx.sku Sku,
			sk.descr Descr,
			(lotx.qty) Qty
	from '+@wh+'.LOTXLOCXID lotx
		left join '+@wh+'.SKU sk on lotx.storerkey = sk.storerkey
								and lotx.sku = sk.sku
		left join '+@wh+'.tariffdetail td on ( sk.busr3=td.descrip 
											or sk.busr2=td.descrip 
											or sk.busr1=td.descrip ) 
	where	lotx.qty>0 and lotx.storerkey='''+@storer+''''+@grT+'

	
	order by lotx.sku, sk.descr
'
	print (@sql)
	exec (@sql)

select rt.Sku,
		rt.Descr,
		sum(rt.Qty) Qty
from #result_table rt
where rt.Qty>0
group by rt.Sku, rt.Descr
order by rt.Sku, rt.Descr

drop table #result_table

