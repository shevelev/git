-- =============================================
-- јвтор:		—олдаткин ¬ладимир
-- ѕроект:		Ќќ¬Ё —, г.Ѕарнаул
-- ƒата создани€: 07.12.2009 (Ќќ¬Ё —)
-- ќписание: ќтчет по свободным €чейкам
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV02_Loc] ( 
									
	@wh varchar(30),
	@Vzone varchar(10)
)

as
create table #result_table (
		Putzone varchar(10) not null,
		PutDescr varchar(60) not null,
		Loc varchar(10) not null,
		Qty decimal(22,5) not null
)

declare @sql varchar(max)

/*ќбъединение таблицы €чейка с таблицой остатки и таблицой описани€ зон
с указанием кол-во товара в €чейке

выбор по отбору и хранению*/		
set @sql='

insert into #result_table
select  locB.putawayzone Putzone,
		put.Descr PutDescr,
		locB.loc Loc,
		sum(isnull(lotx.qty,0)) Qty
from '+@wh+'.LOC locB
	/*выбор всех имеющихс€ €чеек с проставлением кол-ва товара в них, по остатку*/
	left join '+@wh+'.LOTXLOCXID lotx on locB.loc=lotx.loc
	/*выбор €чеек по улицам*/
	left join '+@wh+'.PUTAWAYZONE Put on locB.PUTAWAYZONE=Put.PUTAWAYZONE
	/*выбор €чеек хранени€ и отбора*/
where '+
			case when @Vzone='ALL'  then 'LocB.locationtype in (''CASE'',''PICK'')'
				 when @Vzone='PICK'  then 'LocB.locationtype in (''PICK'')' 
				 when @Vzone='CASE'  then 'LocB.locationtype in (''CASE'')'					
			end +
			'
		and (LocB.loc not like ''%.0.0'' or LocB.loc like ''_S__.0.0'')
		and LocB.locationflag=''NONE''

group by locB.loc,
		 locB.putawayzone,
		 put.Descr
order by locB.loc
'

print (@sql)
exec (@sql)

/*¬ывод таблицы с нулевым кол-вом товара*/
select Putzone,
	   PutDescr,
	   Loc
from #result_table rt
where rt.Qty=0


drop table #result_table

