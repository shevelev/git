-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 13.04.2010 (НОВЭКС)
-- Описание: Статистика отгрузки по строчкам и объему
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV26_Plan_Stat_Order] ( 
	@wh varchar(30),								
	@date datetime
	
)
as

create table #result_table (
		Chislo int not null,
		Den varchar(2) not null,
		StrokN int null,
		CubeN decimal(22,7) null,
		StrokO int null,
		CubeO decimal(22,7) null
)

create table #tmp (
		Chislo int not null,
		Strok int null,
		CubeM decimal(22,7) null
)

declare @sql varchar(max),
		@bday varchar(10),
		@eday varchar(20),
		@iday varchar(20)

set @bday=convert(varchar(10),@date,112)
set @eday=convert(varchar(20),dateadd(s,-1,dateadd(month,1,cast((@bday)as datetime))),13)
set @iday=convert(varchar(20),dateadd(s,-1,dateadd(day,1,cast(@bday as datetime))),13)

print(@bday)
print(@eday)
print(@iday)

while @iday<>@eday
	begin
		insert into #result_table values(datepart(dd,cast(@iday as datetime)),datepart(dw,cast(@iday as datetime)),null,null,null,null)
		set @iday=convert(varchar(20),dateadd(day,1,cast(@iday as datetime)),13)
	end
insert into #result_table values(datepart(dd,cast(@iday as datetime)),datepart(dw,cast(@iday as datetime)),null,null,null,null)

update #result_table 
set	Den = 
	case Den
		when 1 then 'Вс'
		when 2 then 'Пн'
		when 3 then 'Вт'
		when 4 then 'Ср'
		when 5 then 'Чт'
		when 6 then 'Пт'
		when 7 then 'Сб'
	end
		
--select *
--from  #result_table

set @sql='
insert into #tmp
select datepart(dd,o.REQUESTEDSHIPDATE) chislo,
		count(o.REQUESTEDSHIPDATE) strok, 
		sum(sk.STDCUBE*od.ORIGINALQTY) cubeM
from '+@wh+'.orders o
	join '+@wh+'.orderdetail od on od.orderkey=o.orderkey
	join '+@wh+'.sku sk on sk.sku=od.sku and sk.storerkey=od.storerkey
	join '+@wh+'.storer st on st.storerkey=o.B_company
where (o.storerkey=''219'' or st.company like ''ООО "Новэкс" филиал%'') 
		and o.REQUESTEDSHIPDATE between '''+@bday+''' and '''+@eday+'''
group by datepart(dd,o.REQUESTEDSHIPDATE)
order by datepart(dd,o.REQUESTEDSHIPDATE)
'

print (@sql)
exec (@sql)

--select *
--from #tmp

update rt1 set rt1.StrokN = rt2.Strok,
				rt1.CubeN = rt2.CubeM
	from #tmp rt2 
		join #result_table rt1 on rt2.chislo = rt1.chislo

--select *
--from  #result_table

delete from #tmp

set @sql='
insert into #tmp
select datepart(dd,o.REQUESTEDSHIPDATE) chislo,
		count(o.REQUESTEDSHIPDATE) strok, 
		sum(sk.STDCUBE*od.ORIGINALQTY) cubeM
from '+@wh+'.orders o
	join '+@wh+'.orderdetail od on od.orderkey=o.orderkey
	join '+@wh+'.sku sk on sk.sku=od.sku and sk.storerkey=od.storerkey
	join '+@wh+'.storer st on st.storerkey=o.B_company
where (o.storerkey=''92''	and st.company NOT like ''ООО "Новэкс" филиал%'') 
		and o.REQUESTEDSHIPDATE between '''+@bday+''' and '''+@eday+'''
group by datepart(dd,o.REQUESTEDSHIPDATE)
order by datepart(dd,o.REQUESTEDSHIPDATE)
'

print (@sql)
exec (@sql)

--select *
--from #tmp

update rt1 set rt1.StrokO = rt2.Strok,
				rt1.CubeO = rt2.CubeM
	from #tmp rt2 
		join #result_table rt1 on rt2.chislo = rt1.chislo

select Chislo,
		Den,
		isnull(StrokN,0) StrokN,
		isnull(CubeN,0) CubeN,
		isnull(StrokO,0) StrokO,
		isnull(CubeO,0) CubeO
from  #result_table

drop table #result_table
drop table #tmp

