ALTER PROCEDURE [dbo].[rep33_OrdersCompletedToShip](
	@wh varchar(10),
	@date1 smalldatetime = null,
	@date2 smalldatetime = null,
	@orderkey varchar(12) = null,
	@extOrderKey varchar(32) = null,
	@clientName varchar(45) = null,
	@carrierName varchar(45) = null,
	@ordergroup varchar(10),
	@wavekey varchar(10) = null,
	@door VARCHAR(10) = null
)
as
--declare @wh varchar(10),@date1 smalldatetime,
--		@date2 smalldatetime,
--		@orderkey varchar(12),
--		@extOrderKey varchar(32),
--		@clientName varchar(45),
--		@carrierName varchar(45),
--		@wavekey varchar(10),
--		@ordergroup varchar(10),
--		@door VARCHAR(10)
--select @wh='wh40', @orderkey='0000002920', @date1='20080101'--, @door='DOCK81'

declare
	@sql varchar(max)

--#region таблицы
CREATE TABLE [dbo].[#orders](
	[orderkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[requestedShipDate] [datetime] NULL,
	[door] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[ClientName] [varchar](100) COLLATE Cyrillic_General_CI_AS NULL,
	[statusName] [varchar](30) COLLATE Cyrillic_General_CI_AS NULL,
	[carrierName] [varchar](100) COLLATE Cyrillic_General_CI_AS NULL,
	[status] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[OrderInfrontDoor] [numeric](2, 2) NOT NULL,
	[minutesToShipOrder] [int] NOT NULL,
	[wavekey] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[OrderGroup] [varchar](20) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[wavestatus] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[WaveInfrontDoor] [numeric](1, 1) NOT NULL,
	[minutesToShipWave] [int] NOT NULL)

CREATE TABLE [dbo].[#picks](
	[pickdetailkey] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[orderkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[dropid] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[sku] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[storerkey] [varchar](15) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[status] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[loc] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[toloc] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[door] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
	[adddate] [datetime] NOT NULL,
	[editdate] [datetime] NOT NULL)

CREATE TABLE [dbo].[#OrderLoadStops](
	[shipmentorderid] [varchar](20) COLLATE Cyrillic_General_CI_AS NULL,
	[loadstopid] [int] NOT NULL)

CREATE TABLE [dbo].[#ordersDoor](
	[orderkey] [varchar](20) COLLATE Cyrillic_General_CI_AS NULL,
	[unitid] [varchar](20) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[status] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL)

CREATE TABLE [dbo].[#waveOrders](
	[SERIALKEY] [int] NOT NULL,
	[WHSEID] [varchar](30) COLLATE Cyrillic_General_CI_AS NULL,
	[WAVEDETAILKEY] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[WAVEKEY] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[ORDERKEY] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[PROCESSFLAG] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[ADDDATE] [datetime] NOT NULL,
	[ADDWHO] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[EDITDATE] [datetime] NOT NULL,
	[EDITWHO] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL)

CREATE TABLE [dbo].[#Wavepicks](
	[pickdetailkey] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[orderkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[wavekey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[sku] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[storerkey] [varchar](15) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[status] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[loc] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[toloc] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[door] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
	[adddate] [datetime] NOT NULL,
	[editdate] [datetime] NOT NULL)

CREATE TABLE [dbo].[#WaveLoadStops](
	[wavekey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[loadstopid] [int] NOT NULL)

CREATE TABLE [dbo].[#WaveDoor](
	[wavekey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[unitid] [varchar](20) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[status] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL)

--#endregion

--declare @date1 smalldatetime,
--		@date2 smalldatetime,
--		@orderkey varchar(12),
--		@extOrderKey varchar(32),
--		@clientName varchar(45),
--		@carrierName varchar(45),
--		@wavekey varchar(10),
--		@door VARCHAR(10)
--select @date1='20080101'--, @door='DOCK81'

--Отбор по дате отгрузки, по номеру заказа, 
-- по покупателю, перевозчику, идентификатору волны, воротам
	if not @date2 is null
		set @date2 = dateadd(dy, 1, convert(varchar(10), @date2,112))
	
	
	set @sql =	
	'insert into #orders
select o.orderkey, o.requestedShipDate, o.door, cl.companyName ClientName, 
		oss.description statusName, car.companyName carrierName,
		o.status, 0.00 OrderInfrontDoor, 0 minutesToShipOrder, w.wavekey, OrderGroup,
		w.status wavestatus, 0.0 WaveInfrontDoor, 0 minutesToShipWave

	from '+@wh+'.orders o
		left join '+@wh+'.storer cl on o.consigneeKey = cl.storerkey
		left join '+@wh+'.storer car on o.carriercode = car.storerkey
		left join '+@wh+'.wavedetail wd on wd.orderkey=o.orderkey
		left join '+@wh+'.wave w on wd.wavekey = w.wavekey
		left join '+@wh+'.orderstatussetup oss on o.status=oss.code
	where 1=1 and o.status < 92 ' +
		case when @date1 is null then '' else ' and requestedShipDate >= ''' + convert(varchar (10), @date1,112) + '''' end +
		case when @date2 is null then '' else ' and requestedShipDate < ''' + convert(varchar (10), @date2,112) + '''' end +
		case when isnull(@orderkey,'')=''  then '' else ' and o.orderkey = ' + @orderkey end +
		case when isnull(@extOrderKey,'')='' then '' else ' and o.externorderkey = ' + @extorderkey end +
		case when isnull(@clientName,'')='' then '' else ' and cl.companyName like ''' + @clientName + '' end +
		case when isnull(@carrierName,'')='' then '' else ' and car.companyName like ''' + @carrierName + '' end +
		case when isnull(@wavekey,'')='' then '' else ' and w.wavekey = ' + @wavekey end +
		case when isnull(@door,'')='' then '' else ' and door = ' + @door end
	exec (@sql)		
		
	set @sql = 
	'insert into #picks 
	select pickdetailkey, orderkey, dropid, sku, storerkey, status, loc, toloc, door, adddate, editdate
	from '+@wh+'.pickdetail where orderkey in (select orderkey from #orders)'
	exec (@sql)	

	select orderkey, min(adddate) OrderstartPicking, max(editdate)OrderLastOperation,
		sum(case when status = 9 then 1 else 0 end) OrdShipped, --pickdetailkey, status 
		sum(case when status = 8 then 1 else 0 end) OrdLoaded,
		sum(case when status = 6 then 1 else 0 end) OrdPacked,
		sum(case when status = 5 then 1 else 0 end) OrdPicked,
		sum(case when status = 3 then 1 else 0 end) OrdPiking,
		sum(case when status = 1 then 1 else 0 end) OrdPrinted,
		sum(case when status = 0 then 1 else 0 end) OrdStandart,
		count(pickdetailkey) picksCount
	into #pickCounts
	from #picks
	group by orderkey
	
	--select * into #doors from wh40.loc where putawayzone like 'OUT'
	
	-- вычисляем % выполнения операции перемещения заказа к воротам
	set @sql = 
	'insert into #OrderLoadStops select distinct shipmentorderid, loadstopid  
	from '+@wh+'.loadorderdetail where shipmentorderID in (select orderkey from #orders)'
	exec (@sql)	

	set @sql=
	'insert into #ordersDoor
	select shipmentorderid orderkey, unitid, status 
	from '+@wh+'.loadunitdetail lud
	join #OrderLoadStops ols on ols.loadstopid = lud.loadstopid'
	exec (@sql)


	select orderkey, 
		cast(sum(case when status = 0 then 1 else 0 end) as decimal(5,2)) LoadNotStarted, --pickdetailkey, status 
		cast(sum(case when status = 1 then 1 else 0 end) as decimal(5,2)) Loading,
		cast(sum(case when status = 2 then 1 else 0 end) as decimal(5,2)) loadCarged,
		cast(sum(case when status = 9 then 1 else 0 end) as decimal(5,2)) LoadShipped,
		cast(count(1) as decimal(5,2)) LoadsCount,
		cast(0.00 as decimal(5,2)) ordLoadWait, cast(0.00 as decimal(5,2)) ordloading, 
		cast(0.00 as decimal(5,2))ordLoaded, cast(0.00 as decimal(5,2)) ordLoadShipped
	into #ordersDoorCalc
	from #ordersDoor
	group by orderkey
	
	update #ordersDoorCalc set 
		ordLoadWait= 100.0*cast(LoadNotStarted as decimal(5,2))/cast(LoadsCount as decimal(5,2)),
		ordloading= 100.0*cast(Loading as decimal(5,2))/cast(LoadsCount as decimal(5,2)),
		ordLoaded = 100.0*cast(loadCarged as decimal(5,2))/cast(LoadsCount as decimal(5,2)),
		ordLoadShipped= 100.0*cast(LoadShipped as decimal(5,2))/cast(LoadsCount as decimal(5,2))
		
		
	set @sql =
	'insert into #waveOrders select * from '+@wh+'.wavedetail where orderkey in (select orderkey from #orders)'
	exec (@sql)	

	set @sql =
	'insert into #Wavepicks select pickdetailkey, pd.orderkey, wo.wavekey, pd.sku, pd.storerkey, pd.status, 
		pd.loc, pd.toloc, pd.door, pd.adddate, pd.editdate 
	
	from '+@wh+'.pickdetail pd
		join #waveOrders wo on pd.orderkey = wo.orderkey'
	exec (@sql)

	--where orderkey in (select orderkey from #orders)
	
	select wavekey,  min(adddate) WavestartPicking, max(editdate)WaveLastOperation,
		sum(case when status = 9 then 1 else 0 end) WaveShipped, --pickdetailkey, status 
		sum(case when status = 8 then 1 else 0 end) WaveLoaded,
		sum(case when status = 6 then 1 else 0 end) WavePacked,
		sum(case when status = 5 then 1 else 0 end) WavePicked,
		sum(case when status = 3 then 1 else 0 end) WavePiking,
		sum(case when status = 1 then 1 else 0 end) WavePrinted,
		sum(case when status = 0 then 1 else 0 end) WaveStandart,
		count(pickdetailkey) picksCount
	into #WavepickCounts
	from #Wavepicks
	group by wavekey


	-- вычисляем % выполнения операции перемещения ВОЛНЫ к воротам
	set @sql = 
	'insert into #WaveLoadStops select distinct wavekey, loadstopid  
	from '+@wh+'.loadorderdetail lod
		join #Waveorders wo on shipmentorderID = orderkey'
	exec (@sql)

	set @sql =
	'insert into #WaveDoor select ols.wavekey, unitid, status 
	from '+@wh+'.loadunitdetail lud
		join #WaveLoadStops ols on ols.loadstopid = lud.loadstopid'
	exec (@sql)

	select wavekey, 
		cast(sum(case when status = 0 then 1 else 0 end) as decimal(5,2)) LoadNotStarted, --pickdetailkey, status 
		cast(sum(case when status = 1 then 1 else 0 end) as decimal(5,2)) Loading,
		cast(sum(case when status = 2 then 1 else 0 end) as decimal(5,2)) loadCarged,
		cast(sum(case when status = 9 then 1 else 0 end) as decimal(5,2)) LoadShipped,
		cast(count(1) as decimal(5,2)) LoadsCount,
		cast(0.00 as decimal(5,2)) WaveLoadWait, cast(0.00 as decimal(5,2)) Waveloading, 
		cast(0.00 as decimal(5,2))WaveLoaded, cast(0.00 as decimal(5,2)) WaveLoadShipped
	into #WaveDoorCalc
	from #WaveDoor
	group by wavekey
	
	update #WaveDoorCalc set 
		WaveLoadWait= 100.0*cast(LoadNotStarted as decimal(5,2))/cast(LoadsCount as decimal(5,2)),
		Waveloading= 100.0*cast(Loading as decimal(5,2))/cast(LoadsCount as decimal(5,2)),
		WaveLoaded = 100.0*cast(loadCarged as decimal(5,2))/cast(LoadsCount as decimal(5,2)),
		WaveLoadShipped= 100.0*cast(LoadShipped as decimal(5,2))/cast(LoadsCount as decimal(5,2))


	select o.*,
		OrderstartPicking, OrderLastOperation,OrdShipped, pc.OrdLoaded,OrdPacked,
		OrdPicked,OrdPiking,OrdPrinted,OrdStandart,
		odc.ordLoaded+odc.ordLoadShipped ordMovecomplete, odc.LoadsCount OrderMovesCount,
		dateadd(mi,((100*(datediff(mi,OrderstartPicking,OrderLastOperation)/
			case when (odc.ordLoaded+odc.ordLoadShipped)=0 then 1 else (odc.ordLoaded+odc.ordLoadShipped) end)) -
			datediff(mi,OrderstartPicking,OrderLastOperation)),OrderstartPicking)
		ordertimeTocomplete,
		WavestartPicking,WaveLastOperation,WaveShipped,wpc.WaveLoaded,WavePacked,
		WavePicked,WavePiking,WavePrinted,WaveStandart,
		wdc.WaveLoaded+wdc.WaveLoadShipped waveMovecomplete, wdc.LoadsCount waveMovesCount,
		dateadd(mi,((100*(datediff(mi,WavestartPicking,WaveLastOperation)/
		case when (wdc.WaveLoaded+wdc.WaveLoadShipped) = 0 then 1 else (wdc.WaveLoaded+wdc.WaveLoadShipped)end)) -
			datediff(mi,WavestartPicking,WaveLastOperation)),WavestartPicking)
		WavetimeTocomplete
	into #Summary
	from #orders o
		left join #ordersDoorCalc odc on o.orderkey = odc.orderkey
		left join #WaveDoorCalc wdc on o.wavekey = wdc.Wavekey
		left join #PickCounts pc on o.orderkey = pc.orderkey
		left join #WavePickCounts wpc on o.wavekey = wpc.wavekey
	
	select	orderkey, requestedShipDate, door, ClientName, CarrierName, orderGroup,
		statusName OrderStatusName, ordMoveComplete, orderTimeToComplete,
		wavekey, ck.description wavestatus, WaveMoveComplete, WaveTimeToComplete
	from #summary
	left join wh40.codelkup ck on ck.code = wavestatus and listname = 'WAVESTATUS'

	
		
--	select * from 
	
	drop table #orders
	drop table #picks
	drop table #pickCounts
	drop table #Waveorders
	drop table #Wavepicks
	drop table #WavepickCounts
	drop table #summary
	--drop table #doors
	drop table #ordersDoorCalc
	drop table #OrderLoadStops
	drop table #ordersDoor
	drop table #WaveLoadStops
	drop table #WaveDoor
	drop table #WaveDoorCalc
/*drop table 
drop table 
	*/

