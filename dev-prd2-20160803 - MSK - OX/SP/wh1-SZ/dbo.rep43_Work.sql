ALTER PROCEDURE [dbo].[rep43_Work](
	@wh varchar(10),  -- склад
	@dtFROM smalldatetime, -- дата начала
	@dtTO smalldatetime, -- дата окончания
--	@worker_n varchar (40), -- фио
	@who varchar (40) -- логин
)AS

CREATE TABLE [#restab](
	[addwho] [varchar] (18) COLLATE Cyrillic_General_CI_AS NULL,
	[usrname] [varchar](40) COLLATE Cyrillic_General_CI_AS NULL,
	[trantype] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[sourcetype] [varchar](30) COLLATE Cyrillic_General_CI_AS NULL,
	[adddate] smalldatetime,
	[quant] [int] NULL)

declare @sql varchar (max)

set @dtTO = dateadd(dy,1,@dtTO)

set @sql =
'insert into #restab
select i.addwho, u.usr_name, i.trantype, i.sourcetype, i.adddate, 0
from  ssaadmin.pl_usr u  join '+@wh+'.ITRN i on u.usr_login = i.addwho
	where 1=1 ' +
		case when @dtFROM is null  then '' else 'and i.editdate >= '''+convert(varchar(10),@dtFROM,112)+''' ' end +
		case when @dtTO is null  then '' else ' AND i.editdate < '''+convert(varchar(10),@dtTO,112)+''' ' end +
		case when @who is null then '' else ' and i.addwho like '''+@who+'''' end +
'order by i.addwho, i.trantype, i.sourcetype, i.adddate'

exec (@sql)

update #restab set 
	trantype = 
	case trantype
		when 'AJ' then 'Корректировка'
		when 'DP' then 'Приемка'  
		when 'MV' then 
			case sourcetype 
				when 'NSPRFPA02' then 'Размещение'
				when 'NSPRFRL01' then 'Перемещение'
				when 'nspRFTRP01' then 'Перемещение'
				when 'ntrTaskDetailUpdate' then 'Размещение'
				when 'PICKING' then 'Отбор'
				when '' then 'Перемещение'
				else '-Неизвестная операция'
			end
			else '-Неизвестная операция'
		end


-- dropid detail отгрузочная единица, комплектация.
--set @sql =
--'insert into #restab
--	select dd.addwho, pu.usr_name, ''Отгрузка'', '''', dd.editdate, 0
--	from wh40.DropidDetail dd join wh40.DropID di on di.dropid = dd.dropid
--	join ssaadmin.pl_usr pu on dd.addwho = pu.usr_login
--	where 1=1 '+
--		case when @dtFROM is null  then '' else 'and dd.adddate >= '''+convert(varchar(10),@dtFROM,112)+''' ' end +
--		case when @dtTO is null  then '' else ' AND dd.adddate < '''+convert(varchar(10),@dtTO,112)+''' ' end +
--		case when @who is null then '' else ' and dd.addwho like '''+@who+'''' end

set @sql =
'insert into #restab
	select di.addwho, pu.usr_name, ''Отгрузка'', '''', di.adddate, 0
	from '+@wh+'.DropidDetail di join ssaadmin.pl_usr pu on di.addwho = pu.usr_login
	where di.dropid like ''ts%'' and (di.childid like ''d%'' or di.childid like ''c%'') ' +
		case when @dtFROM is null  then '' else 'and di.adddate >= '''+convert(varchar(10),@dtFROM,112)+''' ' end +
		case when @dtTO is null  then '' else ' AND di.adddate < '''+convert(varchar(10),@dtTO,112)+''' ' end +
		case when @who is null then '' else ' and di.addwho like '''+@who+'''' end
exec (@sql) 

--set @sql =
--'insert into #restab
--	select distinct pd.editwho,pu.usr_name, ''Упаковка'', '''', di.adddate, 0
--	from wh40.DropID di join wh40.PickDetail pd on di.dropid = pd.pdudf1
--	join ssaadmin.pl_usr pu on pd.editwho = pu.usr_login
--	where 1=1 '+
--		case when @dtFROM is null  then '' else 'and di.adddate >= '''+convert(varchar(10),@dtFROM,112)+''' ' end +
--		case when @dtTO is null  then '' else ' AND di.adddate < '''+convert(varchar(10),@dtTO,112)+''' ' end +
--		case when @who is null then '' else ' and pd.editwho like '''+@who+'''' end

set @sql =
'insert into #restab
	select di.addwho, pu.usr_name, ''Упаковка'', '''', di.adddate, 0
	from '+@wh+'.DropIDdetail di join '+@wh+'.PickDetail pd on di.childid = pd.caseid
	join ssaadmin.pl_usr pu on di.addwho = pu.usr_login
	where 1=1 '+
		case when @dtFROM is null  then '' else 'and di.adddate >= '''+convert(varchar(10),@dtFROM,112)+''' ' end +
		case when @dtTO is null  then '' else ' AND di.adddate < '''+convert(varchar(10),@dtTO,112)+''' ' end +
		case when @who is null then '' else ' and di.addwho like '''+@who+'''' end


exec (@sql)

delete #restab where trantype = '-Неизвестная операция'


-- подсчет количества выполненых опреаций и их среднего выполнения
select 
	r.addwho,
	r.usrname,
	r.trantype,
	count(r.addwho) qty,
	ceiling(datediff(mi,min(r.adddate),max(r.adddate))/cast (count(r.addwho) as decimal (10,2))) midtime,
	0 maxtime,
	cast(0 as decimal (20,5)) ktu 
into #res
from #restab r
group by r.trantype, r.addwho, r.usrname
order by r.usrname

-- подсчет максимального перерыва между выполненными операциями
select identity (int, 1,1) id, * into #rest from #restab order by addwho, trantype, adddate

select r1.addwho, r1.usrname, r1.trantype, max(datediff(mi,r1.adddate,r2.adddate)) mt
into #maxt
from #rest r1 join #rest r2 on r1.addwho = r2.addwho and r1.trantype = r2.trantype and
r1.adddate <= r2.adddate and r1.id+1=r2.id
group by r1.addwho, r1.usrname, r1.trantype

-- пристыковка максимального времени простоя 
update #res set
 #res.maxtime = #maxt.mt
from
	#res join #maxt on #res.addwho = #maxt.addwho and #res.trantype = #maxt.trantype

set @sql='
update r set
r.ktu = r.qty * cast(ck.description as decimal(10,1))
from #res r join '+@wh+'.codelkup ck on r.trantype = cast(ck.notes as varchar (45))
where ck.listname = ''КТУ''
'
exec(@sql)

select * from #res

drop table #maxt
drop table #restab
drop table #rest
drop table #res
--select * from wh40.dropid di
--	where 1=1 and di.editdate >= '20080716'  AND di.editdate < '20080717'  and dropidtype = '4' -- отгрузка
--
--
--
--select dd.* from wh40.dropiddetail dd join wh40.dropid di on di.dropid = dd.dropid
--	where 1=1 and dd.adddate >= '20080716'  AND dd.adddate < '20080717'  and di.dropidtype = '4' -- загрузка

