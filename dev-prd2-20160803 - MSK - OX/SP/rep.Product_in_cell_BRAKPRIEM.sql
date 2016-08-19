-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 05.03.2010 (НОВЭКС)
-- Описание: Отчет товар в ячейке BRAKPRIEM
--	...
-- =============================================
ALTER PROCEDURE [rep].[Product_in_cell_BRAKPRIEM] ( 
									
	@wh varchar(30)
)

as

create table #result_table (
		Storer varchar(15) not null,
		Company varchar(45) null,
		Sku varchar(50) not null,
		Descr varchar(250) null,
		Lot varchar(10) not null,
		Qty decimal(22,5) not null,
		DatePriem datetime not null	
)

declare @sql varchar(max)


/*
*/
set @sql='
insert into #result_table
select  lotx.storerkey Storer,
		st.company Company,
		lotx.sku Sku,
		sk.descr Descr,
		lotx.lot Lot,
		lotx.qty Qty,
		lotx.adddate DatePriem		
from '+@wh+'.LOTXLOCXID lotx
left join '+@wh+'.sku sk on lotx.storerkey=sk.storerkey and lotx.sku=sk.sku
left join '+@wh+'.STORER st on lotx.storerkey=st.storerkey
where  lotx.loc=''BRAKPRIEM''
		and lotx.qty>0
'

print (@sql)
exec (@sql)


select *
from #result_table
order by DatePriem

drop table #result_table

