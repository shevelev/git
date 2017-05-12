ALTER PROCEDURE [dbo].[rep24_Waves] (
  @wh varchar(10), 
  @N_wave varchar(10) =null, 
  @point varchar(10), 
  @ord_grp varchar(20),
  @business varchar(20)
)
--with encryption
as

--------------input data---------
--declare @wh varchar(10)
--declare @N_wave varchar(10)  -- номер волны
--declare @point varchar(10)  -- промежуточный пункт назначения
--declare @ord_grp varchar(20)
--set @wh = 'WH1'
----set @ord_grp = 'N%'
--set @N_wave = '0000000455'
-------------------------------
declare @sortOrder int, @sortDirection int
select @sortOrder = 1, @sortDirection=0
---------------------------------

declare @V varchar(20)

CREATE TABLE [dbo].[#status](
	[code] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[description] [varchar](250) COLLATE Cyrillic_General_CI_AS NULL)

CREATE TABLE [dbo].[#restabl](
	[wavekey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[ORDERKEY] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[General_volumn] [float] NULL,
	[General_weight] [float] NULL,
	[Palletoset] [int] NOT NULL)

CREATE TABLE [dbo].[#resulttable](
	[wavekey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[ordergroup] [varchar](250) COLLATE Cyrillic_General_CI_AS NULL,
	[sum_ordgr] [varchar](250) COLLATE Cyrillic_General_CI_AS NULL,
	[WayPoint] [varchar](30) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[status] [varchar](250) COLLATE Cyrillic_General_CI_AS NULL,
	[General_volumn] [float] NULL,
	[Quantity] varchar(20) null,
	[General_weight] [float] NULL,
	[Palletoset] [int] NULL)

CREATE TABLE [dbo].[#rt](
	[wavekey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[ordergroup] [varchar](250) COLLATE Cyrillic_General_CI_AS NULL,
	[sum_ordgr] [varchar](250) COLLATE Cyrillic_General_CI_AS NULL,
	[WayPoint] [varchar](30) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[status] [varchar](250) COLLATE Cyrillic_General_CI_AS NULL,
	[General_volumn] [float] NULL,
	[Quantity] varchar(20) null,
	[General_weight] [float] NULL,
	[Palletoset] [int] NULL)

CREATE TABLE [dbo].[#wave](
	[wavekey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[orderkey] [varchar](30) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[ordergroup] [varchar](250) COLLATE Cyrillic_General_CI_AS NULL)

--create  table #gvw(
--   Wavekey varchar(10),
--   Orderkey varchar(10),
--   General_Volumn numeric,
--   General_Weight numeric,
--   Palletoset int
--                    )

declare
	@sql varchar(max) 

set @V = 1.2*1.6*0.8 -- средний объем занимаемой паллетой

set @sql =
'insert into #status
  select code, description 
    from '+@wh+'.codelkup
    where listname = ''wavestatus'''
exec (@sql)

set @sql =
'insert into #restabl 
		select whwd.wavekey 
        , whpd.ORDERKEY 
        , sum(whpd.QTY * whs.STDCUBE) as General_volumn 
        , sum(whpd.QTY * whs.STDGROSSWGT) as General_weight 
        , 0 as Palletoset
     from '+@wh+'.WAVEDETAIL as whwd 
		inner join '+@wh+'.PICKDETAIL as whpd on whwd.ORDERKEY = whpd.ORDERKEY '
		+'and whpd.STORERKEY='''+@business+''' '
		+'inner join '+@wh+'.SKU as whs on whs.SKU = whpd.SKU 
     group by whwd.WAVEKEY , whpd.ORDERKEY'

exec (@sql)
--select distinct orderkey,pdudf1 from WH1.pickdetail where orderkey = '0000003233'

select distinct wd.wavekey, pd.dropid pdudf1 into #k from WH1.pickdetail  pd
	--join WH1.packloadsend pls on pls.serialkey=pd.serialkey
 join #restabl wd on wd.orderkey=pd.orderkey
where 1=2
set @sql = 'insert into #k select distinct wd.wavekey, pd.dropid pdudf1 from '+@wh+'.pickdetail  pd
	-- join '+@wh+'.packloadsend pls on pls.serialkey=pd.serialkey
 join #restabl wd on wd.orderkey=pd.orderkey'
exec (@sql)


select wavekey, count(pdudf1) cnt into #kSum from #k group by wavekey
--select distinct orderkey, pdudf1--count(distinct pdudf1) cnt
----into #ppp
-- from WH1.PICKDETAIL 
--where orderkey in (select orderkey from #restabl)--('0000003233')--
----group by orderkey 
--order by pdudf1
--select sum(cnt) from #ppp --group by orderkey
--select * from #ppp

--select * from WH1.pickdetail where orderkey = '0000001014'
--   select '+@wh+'.WAVEDETAIL.wavekey ' + -- номер волны
--        ', '+@wh+'.PICKDETAIL.ORDERKEY ' + -- номер заказа
--        ', sum('+@wh+'.PICKDETAIL.QTY * '+@wh+'.SKU.STDCUBE) as General_volumn  ' + -- общий объем по заказам
--        ', sum('+@wh+'.PICKDETAIL.QTY * '+@wh+'.SKU.STDGROSSWGT) as General_weight ' + -- общий вес брутто по заказам
  --      , 0 --ceiling(General_Volumn/@V) as Palletoset ' + -- Количество паллетомест по заказам
--' into gvw ' +
--     'from '+@wh+'.WAVEDETAIL inner join '+@wh+'.PICKDETAIL ' + 
--       'on '+@wh+'.WAVEDETAIL.ORDERKEY = '+@wh+'.PICKDETAIL.ORDERKEY ' +
--          'inner join '+@wh+'.SKU ' + 
--       'on '+@wh+'.SKU.SKU = '+@wh+'.PICKDETAIL.SKU ' +
--     'group by '+@wh+'.WAVEDETAIL.WAVEKEY ' +
--            ', '+@wh+'.PICKDETAIL.ORDERKEY'
--
--update rs set
--  Palletoset = k.cnt
-- 
--  from #restabl rs join #kSum k on k.wavekey=rs.wavekey

/*---------------------------------------*/

set @sql = ' select orderkey, ordergroup
into #temp
from '+@wh+'.ORDERS
where 1=1'+
case when isnull(@ord_grp,'')=''  then '' else ' and ordergroup like '''+@ord_grp+''' ' end
--select * from #temp

+' insert into #wave select w.wavekey, t.orderkey, t.ordergroup
from '+@wh+'.WAVEDETAIL w
join #temp t on t.orderkey = w.orderkey
where 1=1 '+
case when isnull(@N_wave,'')=''  then '' else ' and w.wavekey = '''+@N_wave+''' ' end

exec (@sql)

--select * from #wave

set @sql =  'insert into #resulttable ' +
'select wv.wavekey ' + -- номер волны
	 ', min(wv.ordergroup) ' +
	 ', count(distinct(wv.ordergroup))' +
     ', ''Промежуточный пункт назначения'' as WayPoint ' +
     ', (select top 1 description from #status where w.status = code) as status ' + -- статус
     ', sum(General_volumn) as General_volumn ' + -- общий объем
	 ', ceiling(sum(General_volumn) / '+@V+') as Quantity ' + --оценочное количество полетомест по обьему
     ', sum(General_weight) as General_weight ' + -- общий вес брутто
     ', 0 as Palletoset ' + -- Количество паллетомест
  'from '+@wh+'.wave w left join #restabl gvw ' +
    'on W.WAVEKEY = gvw.WAVEKEY ' + 
	'join #wave wv on wv.wavekey = w.wavekey 
	' +  
	'where 1=1 ' 
--case when @N_wave is null then '' else ' and w.WAVEKEY  LIKE ''' + @N_wave + ''' '  end
--' and w.wavekey like (select distinct(w.wavekey) from #wave w)'

--@N_wave+' is NULL or w.WAVEKEY  LIKE '+@N_wave+') ' +
--    'and ('+@point+' is NULL )' + /*or вставить сравнение Point*/
  +'group by wv.WAVEKEY, /*wv.ordergroup,*/ w.status' 
exec (@sql)
------  order by 
------
------w.WAVEKEY, WayPoint-- надо вставить столбец 'Промежуточный пункт назначения'
------         , w.status
	update rs set
	  Palletoset = k.cnt
	 
	  from #resulttable rs left join #kSum k on k.wavekey=rs.wavekey


	set @sql = 'insert into #rt select * 
	from #resulttable ' 
	+ case when isnull(@sortOrder,0) > 0 then
	' order by '  
	+ case isnull(@sortOrder,0)
		when 1 then 'wavekey' 
		when 2 then 'waypoint' 
		when 3 then 'status'
		else 'wavekey' 
	end + ' ' 
	+ case isnull(@sortDirection,0)
		when 0 then 'asc'
		else 'desc'
	end else '' end

	exec (@sql)
select * from #rt

drop table #status
drop table #rt
drop table #restabl
drop table #resulttable
--drop table #temp
drop table #wave
drop table #k
drop table #kSum

