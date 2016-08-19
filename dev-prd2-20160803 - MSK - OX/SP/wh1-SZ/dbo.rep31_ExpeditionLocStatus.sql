ALTER PROCEDURE [dbo].[rep31_ExpeditionLocStatus] (
@wh varchar(10), 
@orderkey varchar(12) = null,
@exorderkey varchar(12) = null,
@flag varchar(12))


AS

/*--------Тест---------*/
--declare @wh varchar(10), 
--@orderkey varchar(12),
--@exorderkey varchar(12),
--@flag varchar(12)
--set @wh = 'wh40'
--set @orderkey = null
--set @exorderkey = null
--set @flag = 0
/*---------------------*/

CREATE TABLE [dbo].[#temp0](
	[loc] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[flag] varchar(32) COLLATE Cyrillic_General_CI_AS DEFAULT ('')
)

CREATE TABLE [dbo].[#tmp1](
	[loc] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[orderkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[externorderkey] varchar(32) COLLATE Cyrillic_General_CI_AS DEFAULT (''),	
	[adddate] [datetime] NOT NULL DEFAULT ('2000-01-01 00:00:00.000'),
	[qtypick] decimal(22, 5) NOT NULL DEFAULT (0),
	[allqty] decimal(22, 5) NOT NULL DEFAULT (0),
	[qtyneedpick] decimal(22, 5) NOT NULL DEFAULT (0),
	[midtime] decimal(22, 5) NOT NULL DEFAULT (0),
	[plandt] [datetime] NOT NULL DEFAULT ('2000-01-01 00:00:00.000'),
	[status] varchar(32) COLLATE Cyrillic_General_CI_AS DEFAULT ('')
)

CREATE TABLE [dbo].[#tmp2](
	[orderkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[allqty] decimal(22, 5) NOT NULL DEFAULT (0)
)

CREATE TABLE [dbo].[#loc](
	[loc] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
)

CREATE TABLE [dbo].[#temp](
	[orderkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[toloc] [varchar](20) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[door] [varchar](20) COLLATE Cyrillic_General_CI_AS NOT NULL
)

declare @sql varchar(max)

set @sql = 
'insert into #loc
select loc from '+@wh+'.loc where putawayzone like ''PODOBRANO%''
insert into #temp
select distinct o.orderkey orderkey, pd.toloc, o.door
		from '+@wh+'.pickdetail pd
		left join '+@wh+'.orders o on o.orderkey = pd.orderkey
		where ((pd.status >=5 and pd.status < 9 ) or pd.status is null ) and  pd.toloc not in (select loc from #loc)'
print @sql
exec (@sql)
--select * from #temp where door = 'U.05G'
set @sql =
'insert into #temp0
select distinct l.loc, case when exists(select * from #temp where orderkey = o.orderkey) then 1 else 0 end flag
from '+@wh+'.loc l
left join '+@wh+'.orders o on o.door = l.loc 
where putawayzone like ''KOMPLEKT%'''
print @sql
exec (@sql)
select loc, flag into #t from #temp0 where flag = 1
delete from #temp0 where flag = 0 and loc in (select loc from #t)
--select * from #temp0 where loc = 'U.05G' order by loc

set @sql = 
'insert into #tmp1
select  l.loc loc, o.orderkey orderkey, o.externorderkey externorderkey, min(pd.adddate) adddate, count (pd.pickdetailkey) qtypick, 0 allqty,
	0 qtyneedpick, floor(datediff(mi,min(pd.adddate),max(pd.editdate))/count (pd.pickdetailkey)) midtime, ''2000-01-01 00:00:00.000'' plandate, 
	oss.description status
from '+@wh+'.orders o join '+@wh+'.orderdetail od on o.orderkey = od.orderkey
	join '+@wh+'.pickdetail pd on od.orderkey = pd.orderkey and od.orderlinenumber = pd.orderlinenumber
join '+@wh+'.loc l on o.door = l.loc and l.putawayzone like ''KOMPLEKT%''
join '+@wh+'.orderstatussetup oss on o.status = oss.code
where o.status < 95 and pd.status >= 5 and pd.status < 8 and pd.toloc not in (select loc from #loc) ' +
case when @orderkey is null then '' else ' and o.orderkey = ''' + @orderkey + '''' end +
case when @exorderkey is null then '' else ' and o.externorderkey = ''' + @exorderkey + '''' end +
' group by l.loc, o.orderkey, o.EXTERNORDERKEY, oss.description,pd.toloc,o.door
order by l.loc'
print @sql
exec (@sql)
--select * from #tmp1 where loc = 'U.05J03'

set @sql = 
'insert into #tmp2
select o.orderkey orderkey, count (pd.pickdetailkey) allqty
from '+@wh+'.orders o join '+@wh+'.orderdetail od on o.orderkey = od.orderkey
	join '+@wh+'.pickdetail pd on od.orderkey = pd.orderkey and od.orderlinenumber = pd.orderlinenumber
join '+@wh+'.loc l on o.door = l.loc and l.putawayzone like ''KOMPLEKT%''
where o.status < 95
group by l.loc, o.orderkey
order by l.loc'
exec (@sql)
--select * from #tmp2

update t1
set t1.allqty = t2.allqty
from #tmp1 t1 join #tmp2 t2 on t1.orderkey = t2.orderkey

update #tmp1
set qtyneedpick = allqty - qtypick

update #tmp1
set plandt = dateadd(mi,qtyneedpick * midtime,getdate())
--select * from #tmp1


select * from #temp0 t0
left join #tmp1 t1 on t1.loc = t0.loc
where flag = @flag or @flag is null

drop table #tmp1
drop table #temp
drop table #loc
drop table #temp0
drop table #tmp2
drop table #t

----declare @wh varchar(10), @orderkey varchar(12)
----select @wh='WH40' , @orderkey = null
--
--CREATE TABLE [dbo].[#loc](
--	[loc] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL)
--
--CREATE TABLE [dbo].[#tmp](
--	[loc] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[toloc] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
--	[orderkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL)
--
--CREATE TABLE [dbo].[#orders](
--	[orderkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[status] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	StatusDescr varchar(50) COLLATE Cyrillic_General_CI_AS null)
--
--CREATE TABLE [dbo].[#Picks](
--	[orderkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[Shipped] [int] NULL,
--	[Loaded] [int] NULL,
--	[Packed] [int] NULL,
--	[Picked] [int] NULL,
--	[Piking] [int] NULL,
--	[Printed] [int] NULL,
--	[Standart] [int] NULL,
--	[picksCount] [int] NULL)
--
--
--declare
--	@sql varchar(max)
--	set @sql =
--		'insert into #loc select loc from '+@wh+'.loc where putawayzone like ''KOMPLEKT8'''
--	exec (@sql)
--	set @sql =
--		--'insert into #tmp select distinct loc, toloc, orderkey from '+@wh+'.pickdetail where status < 9 and 
--		'insert into #tmp select distinct door, door, orderkey from '+@wh+'.orders where status < 61 AND
--				(door in (select loc from #loc))'-- OR
--				--toloc in (select loc from #loc))'
--	exec (@sql)
--
----select * from #tmp	
--		select distinct loc,orderkey into #buzytmp from #tmp
----		insert #buzytmp (loc,orderkey) select distinct toloc, orderkey from #tmp
--		select distinct loc, orderkey into #buzy from #buzytmp
--
--		select l.loc,case 
--				when isnull(b.loc,'')='' then 'Свободная'
--				else  orderkey
--			end orderkey, 
--			case when isnull(b.loc,'')='' then 0
--				else  1
--			end flag
--		into #Ustat from #loc l
--		left join #buzy b on b.loc = l.loc
--	set @sql =
--		'insert into #orders select orderkey, status, oss.Description from '+@wh+'.orders 
--		left join '+@wh+'.orderstatussetup oss on oss.code = status
--		where orderkey in  (select distinct orderkey from #ustat)'
--	exec (@sql)
----select * from wh40.orderstatussetup
--	set @sql =
--		'insert into #Picks select orderkey, 
--			sum(case when status = 9 then 1 else 0 end) Shipped,
--			sum(case when status = 8 then 1 else 0 end) Loaded,
--			sum(case when status = 6 then 1 else 0 end) Packed,
--			sum(case when status = 5 then 1 else 0 end) Picked,
--			sum(case when status = 3 then 1 else 0 end) Piking,
--			sum(case when status = 1 then 1 else 0 end) Printed,
--			sum(case when status = 0 then 1 else 0 end) Standart,
--			count(pickdetailkey) picksCount
--		from '+@wh+'.pickdetail where orderkey in (select orderkey from #orders)
--		group by orderkey'
--	exec (@sql)
--
--	delete from #picks where shipped = pickscount
--
--	select u.*, o.StatusDescr, 100*picked/case when picksCount=0 then 1 else picksCount end packed 
--	from #ustat u
--		left join #picks p on u.orderkey=p.orderkey
--		left join #orders o on o.orderkey = u.orderkey
--			
--
--	drop table #picks
--	drop table #orders
--	drop table #ustat
--	drop table #buzy
--	drop table #buzytmp		
--	drop table #tmp
--	drop table #loc
--
----select * from 
------and loc <> toloc
----select distinct loc 
----delete from #loc where loc in (select loc from #buzy)
----
----
----select l.loc, 
----	door, --status, loadid
----	case isnull(status,-1) when 0 then 'Ожидается перемещение товара для загрузки ' + loadid
----		when 1 then 'Начато перемещение товара для загрузки ' + loadid
----		when 2 then 'Закончено перемещение товара для загрузки ' + loadid
----		when -1 then 'Свободные ворота'
----	end StatusDescr, isnull(status,-1)status
----from #loc l
----	left join wh40.loadhdr lh on l.loc = lh.door and status<9
----
----
----select * from wh40.loc where loc like 'U%'
----ROLLBACK

