ALTER PROCEDURE [dbo].[rep20_ListofOrders] (
	@wh varchar(30),
	@order varchar(10)=null,
	@externOrder varchar(18)=null,
	@storer varchar(50)=null,
	@client varchar(50)=null,
	@date1 smalldatetime=null,
	@date2 smalldatetime=null,
	@type varchar(10)=null,
	@manager varchar(10)=null,
	@status_begin varchar(10)=null,
	@status_end varchar(10)=null,
	@INN varchar(18)=null,
	@ohtype varchar(10)=null,
	@rfid varchar(10)=null,
	@susr4 varchar(30)=null
--	@sortOrder int = 1,
--	@sortDirection int = 0
)
AS


/******************  FOR internal Datasets ****************/
/* dsOrderStatus */
--select 0 so, code, description, showseq from wh1.orderstatussetup
--union select -1, null, '<Все>', 0
--order by 1, showseq
/****************** END FOR internal Datasets ****************/

/*--------------  For testing. Must be commented ----------------*/
--declare @order varchar(10),@externOrder varchar(18),
--		@storer varchar(50),
--		@client varchar(50),
--		@date1 smalldatetime,
--		@date2 smalldatetime,
--		@type varchar(10),
--		@manager varchar(10),
--		@status_begin varchar(10),
--		@status_end varchar(10),
--		@WH varchar(30),
--		@INN varchar(18),
--		@sortOrder int,
--		@sortDirection int,
--		@ohtype varchar(10),
--		@rfid varchar(10),@susr4 varchar(30)
--
--select @order = '0000007334', @externOrder = null,
--		@storer = null,
--		@client = null,
--		@date1 = null,
--		@date2 = null,
--		@type = null,
--		@manager = null,
--		@status_begin = null,
--		@status_end = null,
--		@WH ='WH40',
--		@ohtype = null,
--		@rfid = null

/*-----------------------------------------------------------*/

	set @wh = upper(@wh)
	set @order= dbo.strValueTuning(@order)  -- удалить ; из строк задаваемых пользователем для увеличения безопасности.
	set @externOrder= dbo.strValueTuning(@externOrder)  -- удалить ; из строк задаваемых пользователем для увеличения безопасности.
	set @storer= dbo.strValueTuning(@storer)
	set @client= dbo.strValueTuning(@client)
	set @type= dbo.strValueTuning(@type)
	set @manager= dbo.strValueTuning(@manager)
	set @status_begin= dbo.strValueTuning(@status_begin)
	set @status_end= dbo.strValueTuning(@status_end)
--	set @date1= replace(upper(@date1),';','')
--	set @date2= replace(upper(@date2),';','')
	set @INN= dbo.strValueTuning(@INN)
	set @susr4 = dbo.strValueTuning(@susr4)

--select * from WH1.orders

	if @order is null and	@storer is null and		@client  is null and 
		@manager  is  null and 	@type   is null and 
		@status_begin  is null and @status_end is null and @date1 is null and @date2 is null and @INN is null and @susr4 is null --:
	begin
		set @date2 = getdate()
		set @date1 = dateadd(dy, -10, @date2)
	end
	
--	if @date1 = @date2
--		set @date1 = dateadd(dy,-1,@date2)
	set @date2 = dateadd(dy,1,@date2)
	declare @sql varchar(max)

	declare @Vavg decimal(10,5)
	set @Vavg = 1.2*0.8*1.6
	-- создадим таблицу используя схему WH1, но без данных.
	select ord.ohtype, ck3.DESCRIPTION, ord.status, ord.orderkey, ord.externOrderkey, ord.storerkey, st.company StorerName, 
			consigneekey clientCode, st1.company ClientName,
			os.Description OrderStatus, ord.orderGroup, 
			ord.REQUESTEDSHIPDATE, ord.ACTUALSHIPDATE, ck1.Description TranspType, ck2.Description OrderType, 
			ck3.Description OrderEditType, ord.Priority, SORTATIONLOCATION, ord.susr1 manager,
			wd.wavekey Wave, ord.rfidflag, ord.adddate, st1.vat, ord.susr4 DocNumber --:
	into #orders
	from WH1.orders ord
		left join WH1.ORDERSTATUSSETUP os on os.code = ord.status -- статус заказа
		left join WH1.codelkup ck1 on ck1.code = ord.transportationmode and ck1.listname like 'TRANSPMODE' -- тип транспорта
		left join WH1.codelkup ck2 on ck2.code = ord.type and ck2.listname like 'ORDERTYPE' -- тип заказа
		left join WH1.codelkup ck3 on ck3.code = ord.ohtype and ck3.listname like 'ORDHNDTYPE' -- тип обработки заказа
		left join WH1.wavedetail wd on wd.orderkey=ord.orderkey
		left join WH1.storer st on st.storerkey=ord.storerkey -- для получения имени владельца
		left join WH1.storer st1 on st1.storerkey=ord.consigneekey -- для получения имени клиента
	where 1=2
	
--select * from WH1.orders

	set @sql = 'insert into #orders
	select ord.ohtype, ck3.DESCRIPTION, ord.status, ord.orderkey, ord.externOrderkey, ord.storerkey, st.company StorerName, 
			consigneekey clientCode, st1.company ClientName,
			case when ord.susr5=''6'' then ''Упакован'' else os.Description end OrderStatus,  ord.orderGroup,
			ord.REQUESTEDSHIPDATE, ord.ACTUALSHIPDATE, ck1.Description TranspType, ck2.Description OrderType, 
			ck3.Description OrderEditType, ord.Priority, SORTATIONLOCATION, ord.susr1 manager,
			wd.wavekey Wave, ord.rfidflag, ord.adddate, st1.vat, ord.susr4' --:
	set @sql = @sql + '
	from '+@WH+'.orders ord
		left join '+@WH+'.ORDERSTATUSSETUP os on os.code = ord.status '+ -- статус заказа
		'left join '+@WH+'.codelkup ck1 on ck1.code = ord.transportationmode and ck1.listname like ''TRANSPMODE'' ' + -- тип транспорта
		'left join '+@WH+'.codelkup ck2 on ck2.code = ord.type and ck2.listname like ''ORDERTYPE'' ' + -- тип заказа
		'left join '+@WH+'.codelkup ck3 on ck3.code = ord.ohtype and ck3.listname like ''ORDHNDTYPE'' ' + -- тип обработки заказа
		'left join '+@WH+'.wavedetail wd on wd.orderkey=ord.orderkey ' +
		'left join '+@WH+'.storer st on st.storerkey=ord.storerkey ' + -- для получения имени владельца
		'left join '+@WH+'.storer st1 on st1.storerkey=ord.consigneekey ' -- для получения имени клиента

	set @sql = @sql + '	where 1=1 ' +
		case when isnull(@externOrder,'')='' then '' else ' AND ord.externorderkey like '''+@externOrder+''' ' end +
		case when isnull(@order,'')='' then '' else ' AND ord.orderkey like '''+@order+''' ' end +
--		case when isnull(@storer,'')='' then '' else ' AND st.company like '''+@storer+''' ' end +
		case when isnull(@storer,'')='' then '' else ' AND ord.storerkey='''+@storer+''' ' end +
		case when isnull(@client,'')='' then '' else ' AND st1.company like '''+@client+''' ' end +
		case when isnull(@INN,'')='' then '' else ' AND st1.VAT like '''+@INN+''' ' end +
		case when isnull(@manager,'')=''  then '' else ' AND ord.susr1 like '''+@manager+''' ' end +
		case when @date1 is null  then '' else ' AND ord.REQUESTEDSHIPDATE >= '''+convert(varchar(10),@date1,112)+''' ' end +
		case when @date2 is null then '' else ' AND ord.REQUESTEDSHIPDATE < '''+convert(varchar(10),@date2,112)+''' ' end +
		case when isnull(@type,'')=''  then '' else ' AND ord.type = '''+@type+''' ' end +
		case when isnull(@status_begin,'')=''  then '' else ' AND ord.status >= '''+@status_begin+''' ' end +
		case when isnull(@status_end,'')=''  then '' else ' AND ord.status <= '''+@status_end+''' ' end + 
		case when isnull(@ohtype,'')=''  then '' else ' AND ord.ohtype like '''+@ohtype+''' ' end +
		case when isnull(@rfid,'')=''  then '' else ' AND ord.rfidflag like '''+@rfid+''' ' end + 		
		case when isnull(@susr4,'')=''  then '' else ' AND ord.susr4 like '''+@susr4+''' ' end 
	print @sql
	exec(@sql)
--select * from #orders

	-- получаем заказанные кол-ва
	-- формируем структуру таблицы 
	select orderkey, sum((od.originalqty+od.adjustedqty)*stdcube) OrdVol, 
		sum((od.originalqty+od.adjustedqty)*stdgrosswgt) ordWgt,
		ceiling(sum((od.originalqty+od.adjustedqty)*stdcube)/@Vavg) OrdPalletsVavg, 
		ceiling(sum((od.originalqty+od.adjustedqty)/case when isnull(pallet,0)=0 then 1 else pallet end)) OrdPallets
	into #ordDet
	from WH1.orderdetail od
		left join WH1.sku sku on od.sku=sku.sku and od.storerkey=sku.storerkey
		left join WH1.pack pk on pk.packkey = od.packkey
	where 1=2 group by od.orderkey

	-- формируем запрос для заполнения данными
	set @sql = 'insert into #ordDet select orderkey, sum((od.originalqty+od.adjustedqty)*stdcube) OrdVol, 
		sum((od.originalqty+od.adjustedqty)*stdgrosswgt) ordWgt,
		ceiling(sum((od.originalqty+od.adjustedqty)*stdcube)/'+cast(@Vavg as varchar)+') OrdPalletsVavg, 
		ceiling(sum((od.originalqty+od.adjustedqty)/case when isnull(pallet,0)=0 then 1 else pallet end)) OrdPallets '
	set @sql = @sql + ' from '+@WH+'.orderdetail od
		left join '+@WH+'.sku sku on od.sku=sku.sku and od.storerkey=sku.storerkey
		left join '+@WH+'.pack pk on pk.packkey = od.packkey
	where od.orderkey in (select orderkey from #orders)
	group by od.orderkey'
	exec (@sql)	

	-- получаем подобранные кол-ва
	-- формируем структуру таблицы
	select pd.orderkey, sum(pd.qty*stdcube) PickVol, sum(pd.qty*stdgrosswgt) PickWeight, 
		ceiling(sum(pd.qty*stdcube)/@Vavg) PickPalletsVavg, 
		ceiling(sum(pd.qty/case when isnull(pallet,0)=0 then 1 else pallet end)) PickPallets
	into #picks
	from WH1.pickdetail pd
		left join WH1.sku sku on pd.sku=sku.sku and pd.storerkey=sku.storerkey
		left join WH1.pack pk on pk.packkey = pd.packkey
	where 1=2 group by orderkey 
	-- заполняем ее данными
	set @sql = 'insert into #picks
	select pd.orderkey, sum(pd.qty*stdcube) PickVol, sum(pd.qty*stdgrosswgt) PickWeight, 
		ceiling(sum(pd.qty*stdcube)/'+cast(@Vavg as varchar)+') PickPalletsVavg, 
		ceiling(sum(pd.qty/case when isnull(pallet,0)=0 then 1 else pallet end)) PickPallets
	from '+@WH+'.pickdetail pd
		left join '+@WH+'.sku sku on pd.sku=sku.sku and pd.storerkey=sku.storerkey
		left join '+@WH+'.pack pk on pk.packkey = pd.packkey
	where pd.orderkey in (select orderkey from #orders) and status >= 5 
	group by orderkey '
	exec (@sql)

	select ord.ohtype, ord.DESCRIPTION, ord.orderkey, externorderkey, storerkey, storername, clientcode, clientname, orderstatus,
		requestedShipDate, ActualShipDate, transpType, Ordertype, OrderEditType, 
		Priority, SortationLocation, Manager, Wave, ordergroup,
		ordWGT, OrdVol, OrdPalletsVavg, OrdPallets,
		PickWeight, PickVol, PickPalletsVavg, PickPallets, rfidflag, ord.adddate, ord.vat, ord.DocNumber --:
	into #result
	from #orders ord
		left join #OrdDet o on o.orderkey = ord.orderkey
		left join #picks p on p.orderkey = ord.orderkey
	
	select distinct wavekey, wd.orderkey into #waves from WH1.wavedetail wd 
		join #result r on r.orderkey = wd.orderkey
--select * from #waves
	select distinct  wavekey, orderkey into #WVOrd from WH1.wavedetail 
	where wavekey in (select distinct wavekey from #waves)
	
	select wavekey, count(orderkey) orderCount into #wavesCount from #WVOrd group by wavekey
--select * from 	#wavesCount
	
	drop table #WVOrd
	
	--declare @sql varchar(8000)
	select distinct r.*, wd.*--, w.* 
	from #result r
		--left join #waves w on r.orderkey = w.orderkey
		left join #wavesCount wd on wd.wavekey = r.wave
	order by Priority,r.wave, r.orderkey
	
	
	
--	set @sql = 'select * from #result ' 
--	+ case when isnull(@sortOrder,1) > 0 then
--	' order by '  

-- update WH1.orders set priority=5 where priority=0
--	+ case isnull(@sortOrder,0)
--		when 1 then 'orderstatus' 
--		when 2 then 'storerName' 
--		when 3 then 'clientName'
--		when 4 then 'requestedShipDate' 
--		else 'status' 
--	end + ' ' 
--	+ case isnull(@sortDirection,0)
--		when 0 then 'asc'
--		else 'desc'
--	end end--else '' end
--	exec (@sql)

	drop table #result
	drop table #orders
	drop table #picks
	drop table #orddet
	drop table #waves
	drop table #wavesCount

