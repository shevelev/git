-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 05.03.2010 (НОВЭКС)
-- Описание: Отчет потвержденная инвентаризация
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV17_Inv_Itrn] ( 
									
	@wh varchar(30),
	@storer varchar(20),
	@datebegin datetime,
	@dateend datetime
)

as

create table #result_table (
		Lot varchar(10) not null,
		Loc varchar(10) not null,
		Sku varchar(50) not null,
		Descr varchar(60) null,
		Qty decimal(22,5) not null,
		Date datetime not null,
		Who varchar(18) not null
)

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(10)

set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(10),@dateend+1,112)

/*
*/
set @sql='
insert into #result_table
select  i.lot Lot,
		i.toloc Loc,
		i.sku Sku,
		sk.descr Descr,
		i.qty Qty,
		i.editdate Date,
		i.editwho Who
from '+@wh+'.ITRN i 
left join '+@wh+'.sku sk on i.storerkey=sk.storerkey and i.sku=sk.sku
where i.storerkey='''+@storer+'''
		and (i.editdate between '''+@bdate+''' and '''+@edate+''')
		and i.trantype=''AJ''
		and i.sourcetype=''ntrAdjustmentDetailAdd''
'

print (@sql)
exec (@sql)

select *
from #result_table
order by sku

drop table #result_table

