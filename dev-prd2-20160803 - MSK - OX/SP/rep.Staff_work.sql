ALTER PROCEDURE [rep].[Staff_work] 
( @wh varchar (10),
@dtFROM datetime, 
@dtTO datetime, 
@who varchar (20)
)
as

CREATE TABLE [#rt] (
	[addwho] [varchar] (18) COLLATE Cyrillic_General_CI_AS NULL, --код работника
	[usrname] [varchar](40) COLLATE Cyrillic_General_CI_AS NULL, --работник
	[qtyreceipt] [int] NULL, --отгрузка
	[qtyupdate] [int] NULL, --корректировка
	[qtyorder] [int] NULL, --приемка
	[qtylocated] [int] NULL, --размещение
	[qtymov] [int] NULL, --перемещение
	[qtyselect] [int] NULL, --отбор
	[qtypick] [int] NULL --комплектация
)

CREATE TABLE [#tp] (
	[addwho] [varchar] (18) COLLATE Cyrillic_General_CI_AS NULL, --код работника
	[qtypick] [int] NULL --комплектация
)

CREATE TABLE [#restab](
	[addwho] [varchar] (18) COLLATE Cyrillic_General_CI_AS NULL,
	[usrname] [varchar](40) COLLATE Cyrillic_General_CI_AS NULL,
	[trantype] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[sourcetype] [varchar](30) COLLATE Cyrillic_General_CI_AS NULL,
	[quant] [int] NULL)

--менеджер, отгрузка, корректировка, приемка, размещение, перемещение, отбор, комплектация.

declare @sql varchar (max)

insert into #rt (addwho, usrname) select usr_login, usr_name from ssaadmin.pl_usr

set @dtTO = dateadd(dy,1,@dtTO)

set @sql = 
'insert into #restab
select i.addwho, min (u.usr_name) usrname, i.trantype, i.sourcetype, count(serialkey) quant
from ssaadmin.pl_usr u join '+@wh+'.ITRN i on u.usr_login = i.addwho
where 1=1 '+
		case when @dtFROM is null  then '' else 'and i.editdate >= '''+convert(varchar(10),@dtFROM,112)+''' ' end +
		case when @dtTO is null  then '' else ' AND i.editdate < '''+convert(varchar(10),@dtTO,112)+''' ' end +
		case when @who is null then '' else 'and i.addwho = '''+@who+'''' end +
' and i.sourcetype != ''SHORTPICK'' 
group by i.addwho, i.trantype, i.sourcetype
order by i.addwho, i.trantype, i.sourcetype'

exec (@sql)

update #restab set 
	trantype = 
	case trantype
--		when 'WD' then 'Отгрузка'
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

--set @sql = 
--	'insert into #tp
--	select pd.editwho, count(distinct pd.pdudf1) qtypick 
--	from '+@wh+'.PickDetail pd join '+@wh+'.DropID di on di.dropid = pd.pdudf1
--	where pd.status = ''9'' ' +
--	case when @dtFROM is null  then '' else 'and pd.editdate >= '''+convert(varchar(10),@dtFROM,112)+''' ' end +
--	case when @dtTO is null  then '' else ' AND pd.editdate < '''+convert(varchar(10),@dtTO,112)+''' ' end +
--' group by pd.editwho'

set @sql = 
	'insert into #tp
	select di.addwho, count(di.serialkey) qtypick 
	from '+@wh+'.dropidDetail di 
	where di.dropid like ''ts%'' and (di.childid like ''d%'' or di.childid like ''c%'')' +
	case when @dtFROM is null  then '' else 'and di.adddate >= '''+convert(varchar(10),@dtFROM,112)+''' ' end +
	case when @dtTO is null  then '' else ' AND di.adddate < '''+convert(varchar(10),@dtTO,112)+''' ' end +
' group by di.addwho'

exec (@sql)

update rt2 set rt2.qtyreceipt = tp.qtypick --отгрузка
	from #rt rt2 join #tp tp  on tp.addwho = rt2.addwho 

truncate table #tp 

update rt2 set rt2.qtyupdate = rt1.quant
	from #restab rt1 join #rt rt2 on rt1.addwho = rt2.addwho 
	where rt1.trantype = 'Корректировка'

update rt2 set rt2.qtyorder = rt1.quant
	from #restab rt1 join #rt rt2 on rt1.addwho = rt2.addwho 
	where rt1.trantype = 'Приемка'

update rt2 set rt2.qtylocated = rt1.quant
	from #restab rt1 join #rt rt2 on rt1.addwho = rt2.addwho 
	where rt1.trantype = 'Размещение'-- and (rt1.sourcetype = 'NSPRFPA02' or rt1.sourcetype = 'ntrTaskDetailUpdate')

update rt2 set rt2.qtymov = rt1.quant
	from #restab rt1 join #rt rt2 on rt1.addwho = rt2.addwho 
	where rt1.trantype = 'Перемещение' -- and (rt1.sourcetype = 'NSPRFRL01' or rt1.sourcetype = 'nspRFTRP01' or rt1.sourcetype = '')

update rt2 set rt2.qtyselect = rt1.quant
	from #restab rt1 join #rt rt2 on rt1.addwho = rt2.addwho 
	where rt1.trantype = 'Отбор' -- and rt1.sourcetype = 'PICKING'

--set @sql = 
--	'insert into #tp
--	select di.addwho, count(pd.pickdetailkey) qtypick 
--	from '+@wh+'.DropID di join '+@wh+'.PickDetail pd on di.dropid = pd.pdudf1
--	where 1=1 ' +
--	case when @dtFROM is null  then '' else 'and di.adddate >= '''+convert(varchar(10),@dtFROM,112)+''' ' end +
--	case when @dtTO is null  then '' else ' AND di.adddate < '''+convert(varchar(10),@dtTO,112)+''' ' end +
--' group by di.addwho'

--select editwho, count () from wh40.dropiddetail di

set @sql = 
'insert into #tp
select di.addwho, count(di.serialkey)  
from '+@wh+'.pickdetail pd join '+@wh+'.dropiddetail di on pd.caseid = di.childid
where 1=1 ' +
case when @dtFROM is null  then '' else 'and di.adddate >= '''+convert(varchar(10),@dtFROM,112)+''' ' end +
case when @dtTO is null  then '' else ' AND di.adddate < '''+convert(varchar(10),@dtTO,112)+''' ' end +
'group by di.addwho'

exec (@sql)

update rt2 set rt2.qtypick = tp.qtypick --комплектация
	from #tp tp join #rt rt2 on tp.addwho = rt2.addwho 

-- удаление пользователей без операций
delete from #rt where qtyreceipt is NULL and
	qtyupdate is NULL and
	qtyorder is NULL and
	qtylocated is NULL and
	qtymov is NULL and
	qtyselect is NULL and
	qtypick is NULL

select * from #rt order by usrname

drop table #rt
drop table #restab
drop table #tp

