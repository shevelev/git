-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 29.03.2010 (НОВЭКС)
-- Описание: Отчет посылка
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV21_Spisok_ZO] ( 
									
	@wh varchar(30),
	@date datetime
	
)

as
create table #result_table (
		OrderKey varchar(10) not null,
		ExternOrderKey varchar(32) not null,
		ConsigneeKey varchar(15) not null,
		Company varchar(45) not null
)

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(10)

set @bdate=convert(varchar(10),@date,112)
set @edate=convert(varchar(10),@date+1,112)

/**/
/**/
set @sql='
insert into #result_table
select  ord.orderkey OrderKey,
		isnull(ord.susr4,'''') ExternOrderKey,
		ord.consigneekey ConsigneeKey,
		st.company Company
from '+@wh+'.ORDERS ord
left join '+@wh+'.STORER st on ord.consigneekey=st.storerkey
where   ord.storerkey=''92'' 
		and st.company not like ''%Новэкс%''
		and (ord.requestedshipdate between '''+@bdate+''' and '''+@edate+''')
order by st.company
'

print (@sql)
exec (@sql)

/*Вывод таблицы */

select *
from #result_table

drop table #result_table

