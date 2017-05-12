-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 10.12.2009 (НОВЭКС)
-- Описание: Отчет транзит детализация
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV04_Trans_Detail] ( 
									
	@wh varchar(30),
	@dockey varchar(20),
	@vendor varchar(20)
)

as
create table #result_table2 (
		Date datetime not null,
		Vendor varchar(20) null,
		Vendor_Descr varchar(45) null,
		Customer varchar(20) not null,
		Customer_Descr varchar(45) null,
		Qty decimal(22,5) null,
		Weight float null,
		Cube3 float null
)

declare @sql varchar(max)


/*Объединение таблицы */		
set @sql='
insert into #result_table2
select  tship.adddate Date,
		tship.vendorkey Vendor,
		st1.company Vendor_Descr,
		tship.customerkey Customer,
		st2.company Customer_Descr,
		tship.qty Qty,
		tship.weight Weight,
		tship.cube Cube3
from '+@wh+'.TRANSSHIP tship
left join '+@wh+'.storer st1 on (tship.vendorkey=st1.storerkey)
left join '+@wh+'.storer st2 on (tship.customerkey=st2.storerkey)
where tship.vendorkey='''+@vendor+''' 
		and tship.documentkey='''+@dockey+'''
'

print (@sql)
exec (@sql)

/*Вывод таблицы */

select Date,
		Vendor,
		Vendor_Descr,
		Customer,
		Customer_Descr,
		Qty,
		Weight,
		Cube3
from #result_table2

drop table #result_table2

