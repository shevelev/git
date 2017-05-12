-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 05.03.2010 (НОВЭКС)
-- Описание: Отчет потвержденная инвентаризация
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV18_Inv_LOST] ( 
									
	@wh varchar(30),
	@cartongroup varchar(max)
)

as

create table #tbl_cgroup (
		cartongroup varchar(10) not null -- Группа картонизации
)

create table #result_table (
		Storer varchar(15) not null,
		Company varchar(45) null,
		Sku varchar(50) not null,
		Descr varchar(60) null,
		Lot varchar(10) not null,
		Qty decimal(22,5) not null,
		ToLoc varchar(10) not null,
		FromLoc varchar(10) not null,
		Editwho	varchar(18) not null	
)

declare @sql varchar(max)

INSERT into #tbl_cgroup
select *
from [dbo].[MultiValue2Table](@cartongroup)

--select *
--from #tbl_cgroup


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
		lotx.loc ToLoc,
		'''' FromLoc,
		lotx.editwho Editwho		
from #tbl_cgroup tcg
left join '+@wh+'.sku sk on tcg.cartongroup=sk.cartongroup
left join '+@wh+'.LOTXLOCXID lotx on lotx.storerkey=sk.storerkey and lotx.sku=sk.sku
left join '+@wh+'.STORER st on lotx.storerkey=st.storerkey
where  lotx.loc=''LOST''
		and lotx.qty>0
'

print (@sql)
exec (@sql)

--select *
--from #result_table
--order by sku

set @sql='
update rt1 set rt1.FromLoc = i.FromLoc
	from '+@wh+'.itrn i 
		join #result_table rt1 on rt1.storer=i.storerkey 
									and rt1.sku=i.sku 
									and rt1.lot=i.lot 
									and rt1.toloc=i.toloc
									and rt1.editwho=i.editwho
'

print (@sql)
exec (@sql)

select *
from #result_table
order by sku


drop table #tbl_cgroup
drop table #result_table

