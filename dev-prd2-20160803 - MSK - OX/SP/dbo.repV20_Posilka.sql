-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 29.03.2010 (НОВЭКС)
-- Описание: Отчет посылка
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV20_Posilka] ( 
									
	@wh varchar(30),
	@datebegin datetime,
	@dateend datetime
)

as
create table #result_table (
		DeliveryDate datetime not null,
		Vendor varchar(20) not null,
		VenCompany varchar(45) not null,
		Customer varchar(20) not null,
		CusCompany varchar(45) not null,
		Document varchar(20) not null,
		Containerid varchar(20) not null,
		Qty decimal(22,0)
)

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(10)

set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(10),@dateend+1,112)

/*Объединение таблицы транзит и storer для выдачи наименования поставщика*/
/*выбор данных входящих во временной промежуток и  код containerid не содержит D в начале*/
set @sql='
insert into #result_table
select  convert(varchar(10),trS.deliverydate,101) DeliveryDate,
		trS.vendorkey Vendor,
		st1.company VenCompany,
		trS.customerkey Customer,
		st2.company CusCompany,
		trS.documentkey Document,
		trS.containerid Containerid,
		trS.qty Qty
from '+@wh+'.TRANSSHIP trS
left join '+@wh+'.STORER st1 on trS.vendorkey=st1.storerkey
left join '+@wh+'.STORER st2 on trS.customerkey=st2.storerkey
where   (trS.deliverydate between '''+@bdate+''' and '''+@edate+''') 
		and trS.containerid not like ''D%''
order by trS.deliverydate
'

print (@sql)
exec (@sql)

/*Вывод таблицы */

select *
from #result_table

drop table #result_table

