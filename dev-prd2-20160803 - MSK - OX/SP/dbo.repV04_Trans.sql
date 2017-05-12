-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 09.12.2009 (НОВЭКС)
-- Описание: Отчет транзит
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV04_Trans] ( 
									
	@wh varchar(30),
	@datebegin datetime,
	@dateend datetime,
	@storer varchar(20)
)

as
create table #result_table (
		Date datetime not null,
		DocKey varchar(20) not null,
		Vendor varchar(20) not null,
		Company varchar(45) null,
		Summa varchar(20) not null,
		Cube3 float null
)

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(10)

set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(10),@dateend+1,112)

/*Объединение таблицы транзит и storer для выдачи наименования поставщика*/
/*выбор данных входящих во временной промежуток и равные коду владельца*/
set @sql='
insert into #result_table
select 	convert(varchar(10),tasn.adddate,101) Date,
		tasn.TRANSASNKEY DocKey,
		tasn.vendorkey Vendor,
		storer.company Company,
		isnull(tasn.udf2,''0'') Summa,
		sum(tship.cube) Cube3
from '+@wh+'.TRANSASN tasn
	join '+@wh+'.STORER storer on tasn.vendorkey=storer.storerkey
	left join '+@wh+'.TRANSSHIP tship on tasn.TRANSASNKEY=tship.documentkey and tasn.vendorkey=tship.vendorkey
where (tasn.adddate between '''+@bdate+''' and '''+@edate+''') and tasn.customerkey='''+@storer+'''
group by tasn.adddate, tasn.TRANSASNKEY, tasn.vendorkey, storer.company,tasn.udf2
order by tasn.adddate
'

print (@sql)
exec (@sql)

/*Вывод таблицы */

select Date,
		DocKey,
		Vendor,
		Company,
		Summa,
		Cube3 
from #result_table

drop table #result_table

