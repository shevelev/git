/****** Object:  StoredProcedure [dbo].[rep_ShippedList]    Script Date: 03/24/2011 15:14:50 ******/
ALTER PROCEDURE [dbo].[rep_ShippedList] (
	@wh varchar(10),
	@key varchar(12),
	@IsWave int -- 0 - заказ, 1-волна
)
AS
--select * from wh1
declare 
	@sql varchar(max)

--declare @wh varchar(10),
--		@key varchar(12),
--		@IsWave int -- 0 - заказ, 1-волна
--	select @wh='wh1', @key='0000017350', @iswave=0

--#region Создание временных таблиц
CREATE TABLE [dbo].[#Picks](
	[SERIALKEY] [int] NOT NULL,
	[WHSEID] [varchar](30) COLLATE Cyrillic_General_CI_AS NULL,
	[PICKDETAILKEY] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[CASEID] [varchar](20) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[PICKHEADERKEY] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[ORDERKEY] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[ORDERLINENUMBER] [varchar](5) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[LOT] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[STORERKEY] [varchar](15) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[SKU] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[ALTSKU] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[UOM] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[UOMQTY] [decimal](22, 5) NOT NULL,
	[QTY] [decimal](22, 5) NOT NULL,
	[QTYMOVED] [decimal](22, 5) NOT NULL,
	[STATUS] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[DROPID] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[LOC] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[ID] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[PACKKEY] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[UPDATESOURCE] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[CARTONGROUP] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[CARTONTYPE] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[TOLOC] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[DOREPLENISH] [varchar](1) COLLATE Cyrillic_General_CI_AS NULL,
	[REPLENISHZONE] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[DOCARTONIZE] [varchar](1) COLLATE Cyrillic_General_CI_AS NULL,
	[PICKMETHOD] [varchar](1) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[WAVEKEY] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[EFFECTIVEDATE] [datetime] NOT NULL,
	[FORTE_FLAG] [varchar](6) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[FROMLOC] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[TRACKINGID] [varchar](45) COLLATE Cyrillic_General_CI_AS NULL,
	[FREIGHTCHARGES] [float] NULL,
	[INTERMODALVEHICLE] [varchar](30) COLLATE Cyrillic_General_CI_AS NULL,
	[LOADID] [int] NULL,
	[STOP] [int] NULL,
	[DOOR] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
	[ROUTE] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
	[SORTATIONLOCATION] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
	[SORTATIONSTATION] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
	[BATCHCARTONID] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
	[ISCLOSED] [varchar](1) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[QCSTATUS] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[PDUDF1] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[PDUDF2] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[PDUDF3] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[PICKNOTES] [varchar](255) COLLATE Cyrillic_General_CI_AS NULL,
	[RECEIPTKEY] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[CROSSDOCKED] [varchar](1) COLLATE Cyrillic_General_CI_AS NULL,
	[SEQNO] [int] NULL,
	[LABELTYPE] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[COMPANYPREFIX] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[SERIALREFERENCE] [varchar](15) COLLATE Cyrillic_General_CI_AS NULL,
	[ADDDATE] [datetime] NOT NULL,
	[ADDWHO] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[EDITDATE] [datetime] NOT NULL,
	[EDITWHO] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[OPTIMIZECOP] [varchar](1) COLLATE Cyrillic_General_CI_AS NULL,
	[GROUPED] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[GIVEUSERKEY] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[TAKEUSERKEY] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[GIVEDATE] [datetime] NOT NULL,
	[CONFIRMUSERKEY] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[PICKERUSERKEY] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[CONFIRMDATE] [datetime] NOT NULL)

CREATE TABLE [dbo].[#resulttable](
	[orderkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[ExpTS] [varchar](20) COLLATE Cyrillic_General_CI_AS NULL,
	[dropid] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[loadid] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
	[door] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
	[caseCount] [int] NULL,
	[orderdate] [datetime] NOT NULL,
	[requestedshipdate] [datetime] NULL,
	[StorerName] [varchar](45) COLLATE Cyrillic_General_CI_AS NULL,
	[ClientName] [varchar](100) COLLATE Cyrillic_General_CI_AS NULL,
	[ClientCode] [varchar](15) COLLATE Cyrillic_General_CI_AS NULL,
	[ClientAddr] [varchar](238) COLLATE Cyrillic_General_CI_AS NULL,
	externorderkey varchar(18) null,
	droploc varchar(12),
	PUTAWAYZONE varchar(20) COLLATE Cyrillic_General_CI_AS NULL)

--CREATE TABLE [dbo].[#rt](
--	[orderkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[dropid] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[loadid] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
--	[door] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
--	[caseCount] [int] NULL,
--	[orderdate] [datetime] NOT NULL,
--	[requestedshipdate] [datetime] NULL,
--	[StorerName] [varchar](45) COLLATE Cyrillic_General_CI_AS NULL,
--	[ClientName] [varchar](100) COLLATE Cyrillic_General_CI_AS NULL,
--	[ClientCode] [varchar](15) COLLATE Cyrillic_General_CI_AS NULL,
--	[ClientAddr] [varchar](238) COLLATE Cyrillic_General_CI_AS NULL,
--	externorderkey varchar(18) null,
--	droploc varchar(12),
--	sku varchar(20) COLLATE Cyrillic_General_CI_AS NULL,
--	PUTAWAYZONE varchar(10) COLLATE Cyrillic_General_CI_AS NULL)

CREATE TABLE [dbo].[#absolute_rt](
	[orderkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[ExpTS] [varchar](20) COLLATE Cyrillic_General_CI_AS NULL,
	[dropid] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[loadid] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
	[door] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
	[caseCount] [int] NULL,
	[orderdate] [datetime] NOT NULL,
	[requestedshipdate] [datetime] NULL,
	[StorerName] [varchar](45) COLLATE Cyrillic_General_CI_AS NULL,
	[ClientName] [varchar](100) COLLATE Cyrillic_General_CI_AS NULL,
	[ClientCode] [varchar](15) COLLATE Cyrillic_General_CI_AS NULL,
	[ClientAddr] [varchar](238) COLLATE Cyrillic_General_CI_AS NULL,
	externorderkey varchar(18) null,
	droploc varchar(12),
	PUTAWAYZONE varchar(10) COLLATE Cyrillic_General_CI_AS NULL,
	DESCR varchar(60)COLLATE Cyrillic_General_CI_AS NULL)


--#endregion

	select orderkey into #ordersList from wh1.orders where 1=2
	if @iswave = 0
		insert #ordersList (orderkey) values(@key)
	else
		begin
			set @sql = 
			'insert #ordersList  select orderkey from '+@wh+'.wavedetail where wavekey = '+@key
			exec (@sql)
		end
/*	
	-- подготовить таблицу PackLoadSend
	select identity(int,1,1)id, orderkey into #tord from #ordersList
	declare @io int, @ok varchar(18)
	set @io=1
	while exists(select top 1 * from #tord where id=@io)
	begin
		select @ok=orderkey from #tord where id=@io
		exec dbo.DA_GetDropTSByOrder @wh, @ok, 1, 0
		set @io=@io+1
	end
*/

--------alter table #orders alter column serialkey varchar(10)
--------alter table #orders alter column serialkey int

select orderkey, externorderkey,orderdate, requestedshipdate, consigneekey, CarrierCode  into #orders from wh1.orders where 1=2
print 1
	set @sql = ' insert #orders select orderkey, externorderkey,orderdate, requestedshipdate, consigneekey, CarrierCode from '+@wh+'.Orders where orderkey in (select orderkey from #ordersList)'
	exec (@sql)
--select * from #orders
print 2
	set @sql = 'insert #Picks select *  from '+@wh+'.pickdetail where orderkey in (select orderkey from #ordersList)'
	exec (@sql)
print 3
	select orderkey, /*serialkey,*/ storerkey, dropid, count(distinct caseid)caseCount, [route], door
	into #pickCnt
	from #picks where status < 9 and case when isnull(dropid,'') = '' then caseid else dropid end != '' 
	group by orderkey,  storerkey, dropid, [route], loadid, door--, serialkey
--select * from #pickcnt	
	set @sql = 'insert into #resulttable
	select distinct pc.orderkey, exp.COMPANY ExpTS, pc.dropid, pc.[route] loadid, pc.door, caseCount,
		o.orderdate, o.requestedshipdate,
		st.company StorerName, cl.CompanyName ClientName, cl.storerkey ClientCode,
		cl.address1 +'' ''+ cl.address2 +'' ''+ cl.address3 +'' ''+ cl.address4 ClientAddr, o.externorderkey,
		d.droploc, l.PUTAWAYZONE --od.sku
	 from #pickcnt pc
		join #orders o on pc.orderkey=o.orderkey
--		join '+@wh+'.PackLoadSend pls on pls.serialkey = pc.serialkey
		left join '+@wh+'.storer st on st.storerkey = pc.storerkey
		left join '+@wh+'.storer cl on cl.storerkey = o.consigneekey
		left join '+@wh+'.storer exp on exp.storerkey = o.CarrierCode
		left join '+@wh+'.dropid d on d.dropid=pc.dropid
--		left join '+@wh+'.orderdetail od on od.orderkey = pc.orderkey
		left join '+@wh+'.loc l on l.loc = d.droploc '
	exec (@sql)	
--	select * from '+@wh+'.orders
		
--		set @sql = 'insert into #rt
--		select rest.orderkey, rest.dropid, rest.loadid, rest.door, rest.caseCount,
--		rest.orderdate, rest.requestedshipdate,
--		rest.StorerName, rest.ClientName, rest.ClientCode,
--		rest.ClientAddr, rest.externorderkey,
--		rest.droploc, rest.sku, l.PUTAWAYZONE
--	 from #resulttable rest
--		left join '+@wh+'.loc l on l.loc = rest.droploc /*and rest.ClientCode = s.STORERKEY*/'
--	exec (@sql)	

		set @sql = 'insert into #absolute_rt
		select rt.orderkey, rt.ExpTS, rt.dropid, rt.loadid, rt.door, rt.caseCount,
		rt.orderdate, rt.requestedshipdate,
		rt.StorerName, rt.ClientName, rt.ClientCode,
		rt.ClientAddr, rt.externorderkey,
		rt.droploc, rt.PUTAWAYZONE, put.DESCR
	 from #resulttable rt
		left join '+@wh+'.PUTAWAYZONE put on put.PUTAWAYZONE = rt.PUTAWAYZONE'
	
	
	exec (@sql)



	select case when @iswave=0 then orderkey else @key end orderkey, ExpTS, 
		dropid, loadid, door, /*(select sum(caseCount) from #absolute_rt)*/ caseCount,
		orderdate, requestedshipdate,
		StorerName, ClientName, ClientCode, droploc,
		ClientAddr, case when @iswave=0 then externorderkey  else '-' end externorderkey, @isWave isWave, PUTAWAYZONE, DESCR
	from #absolute_rt


--	[orderkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[dropid] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[loadid] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
--	[door] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
--	[caseCount] [int] NULL,
--	[orderdate] [datetime] NOT NULL,
--	[requestedshipdate] [datetime] NULL,
--	[StorerName] [varchar](45) COLLATE Cyrillic_General_CI_AS NULL,
--	[ClientName] [varchar](100) COLLATE Cyrillic_General_CI_AS NULL,
--	[ClientCode] [varchar](15) COLLATE Cyrillic_General_CI_AS NULL,
--	[ClientAddr] [varchar](238) COLLATE Cyrillic_General_CI_AS NULL,
--	externorderkey varchar(18) null)




--select * from wh1.wavedetail
	drop table #ordersList
	drop table #picks
	drop table #orders
	drop table #pickcnt
	drop table #resulttable
--	drop table #rt
	drop table #absolute_rt









