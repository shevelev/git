-- ПОДТВЕРЖДЕНИЕ ОКОНЧАНИЯ КОНТРОЛЯ ЗАКАЗА

ALTER PROCEDURE [wh2].[proc_DA_PickControlCaseCompleted](
	@wh varchar(10),
	@transmitlogkey varchar (10)
)AS


declare @log int -- писать лог в DA_LOG
set @log = 1 -- писать лог в DA_LOG


declare	@orderkey varchar (10) -- номер заказа
declare	@caseid varchar (10) -- номер кейса

--declare	@transmitlogkey varchar (10)
--set @transmitlogkey = '0016605187'

declare @bs varchar(3) select @bs = short from wh2.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'
declare @bsanalit varchar(3) select @bsanalit = short from wh2.CODELKUP where LISTNAME='sysvar' and CODE = 'bsanalit'

create table #case (
	caseid varchar (20),
	pickdetailkey varchar(20),
	locpd varchar (20) null,
	loci varchar (20) null,
	loc varchar (20) null,
	statuspd varchar (20) null,
	zone varchar(50) null,
	control varchar(50) null,
	status varchar(50) null,
	run_allocation int null,
	run_cc int null
)

CREATE TABLE #result (	
	[orderkey] varchar(32),
	[storerkey] varchar(15),--
	[externorderkey] varchar(32),--
	consigneekey varchar(20),
	[type] varchar(10),--
	[susr1] varchar(50),--
	[susr2] varchar(30),--
	[susr3] varchar(30),--
	--[susr4] varchar(30),--
	[c_contact1] varchar(30),--
	[REQUESTEDSHIPDATE] varchar(20),
	[sku] varchar(50),--
	[packkey] varchar(50),--
	[LOTTABLE02] varchar(50),--
	[LOTTABLE04] varchar(50) null,--datetime null,--
	[LOTTABLE05] varchar(50) null,--datetime null,--
	[LOTTABLE06] varchar(50),
	[openqty] decimal(22,5), --
	packedqty decimal(22,5),
	boxnum real
	)

declare @source varchar(50) 
declare @send_error bit
declare @msg_errdetails varchar(max)
declare @n bigint



select  @orderkey = tl.key1 
from	wh2.transmitlog tl 
where	tl.transmitlogkey = @transmitlogkey


select	key4
into	#tr
from	wh2.transmitlog
where	TABLENAME in ('pickcontrolcasecompleted','customerorderlinepacked','customerorderpacked')
	and KEY1 = @orderkey
	and KEY4 = '1'
	
if exists (select 1 from #tr)
BEGIN
	if @log=1
		insert into DA_Log(direction,isError,objectID,message)
		values('Out',0,@transmitlogkey,'1. Заказ уже обработан.')
	set @orderkey = ''
END

if @orderkey <> ''
BEGIN
	
	--if (select count(*) from wh2.orders where ORDERKEY = @orderkey and susr2 >= '6') != 0
	--begin
	--	print 'повторная упаковка заказа'
	--	set @send_error = 1
	--	set @msg_errdetails = 'Повторная упаковка Заказа на отгрузку '+ @orderkey
	--	goto endproc
	--end

	print 'выборка отборов по заказу'
	insert into #case
	select	caseid, PICKDETAILKEY, LOC,  null, null,status, null, null, null, null, null
	from	wh2.PICKDETAIL 
	where	ORDERKEY = @orderkey and QTY>0

	-- если есть запись в ITRN то заполняем ячейку ИЗ
	update	c 
	set	loci = i.fromloc
	from	#case c 
		left join wh2.ITRN i 
		    on i.SOURCEKEY = c.pickdetailkey
	where	TRANTYPE = 'MV'

	-- обновляем ячейку ОТКУДА
	update	c 
	set	c.loc = case when c.loci IS null then c.locpd else c.loci end
	from	#case c

	-- определяем зоны для ячеек
	update	c
	set	c.zone = pz.PUTAWAYZONE, 
		c.control = pz.CARTONIZEAREA
	from	#case c 
		join wh2.LOC l 
		    on c.loc = l.LOC
		join wh2.PUTAWAYZONE pz 
		    on pz.PUTAWAYZONE = l.PUTAWAYZONE

	-- статус проконтроллированности кейса.
	update	c
	set	c.status = isnull(p.status,0), 
		c.run_allocation = p.RUN_ALLOCATION, 
		c.run_cc = p.RUN_CC
	from	#case c 
		left join wh2.pickcontrol p 
		    on c.caseid = p.caseid

	print 'проверка заказа'
	if (select COUNT(*) from #case where control = 'K' and (status != '1' or run_allocation = 1 or run_cc = 1)) != 0
	begin
		print 'заказ НЕ проконтролирован'
		if @log=1
			insert into DA_Log(direction,isError,objectID,message)
			values('Out',0,@transmitlogkey,'2. заказ НЕ проконтролирован.')
	
		--raiserror('Заказ НЕ проконтролирован',16,1,@orderkey)
		--return
		set @send_error = 1
		set @msg_errdetails = 'Заказ НЕ проконтролирован '+ @orderkey
		goto endproc		
	end
	else
	begin
		print 'заказ проконтролирован'
		if @log=1
			insert into DA_Log(direction,isError,objectID,message)
			values('Out',0,@transmitlogkey,'3. заказ проконтролирован.')

		-- все ли дропы отобраны и упакованы
		if (select COUNT(*) from #case where control != 'K' and statuspd < '6') != 0
		begin
			print 'заказ НЕ упакован'
			if @log=1
				insert into DA_Log(direction,isError,objectID,message)
				values('Out',0,@transmitlogkey,'4. заказ НЕ упакован.')

			--raiserror('Заказ проконтролирован но не упакован',16,1,@orderkey)
			--return
			set @send_error = 1
			set @msg_errdetails = 'Заказ проконтролирован но не упакован'+ @orderkey
			goto endproc
		end
		else
		begin
		
			print 'заказ упакован'
 		/* Изменил бокснум Шевелев 12.03.2015 */
 			if @log=1
				insert into DA_Log(direction,isError,objectID,message)
				values('Out',0,@transmitlogkey,'5. заказ упакован.')

 			
        		declare @boxnum float
				declare @boxnumP float
				select distinct caseid, control into #casedist from #case
				select @boxnum = SUM (isnull(boxnum,0))
					from wh2.pickcontrol_label pc join #casedist c on pc.caseid = c.caseid 
					where c.control = 'K'
					
	
			
				select @boxnumP = isnull(sum(pd.qty /cast(isnull(p.CASECNT,1) as float)),0) from 
						#casedist c join wh2.pickdetail pd on c.caseid = pd.caseid
						join wh2.lotattribute la on pd.lot = la.lot
						left join wh2.PACK p on p.PACKKEY = la.lottable01
						where c.control != 'K'
				set @boxnum=isnull(@boxnum,0)+isnull(@boxnumP,0)	
				
		/* Изменил бокснум Шевелев 12.03.2015 */
        		
        		
        		
			insert into #result 
			select 
				o.ORDERKEY,
				o.storerkey,
				o.externorderkey,
				o.consigneekey,
				o.[type],
				o.susr1,
				o.susr2,
				o.susr3,
				o.C_CONTACT1,
				o.REQUESTEDSHIPDATE,
				od.sku,
				od.packkey,
				case when od.LOTTABLE02 = '' then 'бс' else      od.LOTTABLE02      end AS LOTTABLE02,
				--od.LOTTABLE02, 
				convert(varchar(12),ISNULL(od.lottable04,'19000101'),112) as LOTTABLE04, --od.LOTTABLE04, 
				convert(varchar(12),ISNULL(od.lottable05,'19000101'),112) as LOTTABLE05, --od.LOTTABLE05, 
				od.NOTES, 
				od.openqty as [openqty],
				case when od.QTYPICKED = 0 then od.SHIPPEDQTY else od.QTYPICKED end as [packedqty],
				@boxnum as boxnum
			from	wh2.orders o 
				join wh2.orderdetail od 
				    on o.orderkey = od.orderkey
			where	o.orderkey = @orderkey
        		
select * from #result
        		
			update	pd 
			set	pd.pdudf1 = '6'
			from	wh2.pickdetail pd 
			where	pd.ORDERKEY = @orderkey
        		
			update	wh2.orders 
				set STATUS = case when STATUS < '78'  then '78' else STATUS end 
			where	ORDERKEY = @orderkey 
			--	and SUSR2 != '9'
				
				
			update	wh2.TRANSMITLOG
			set	KEY4 = '1'
			where	TRANSMITLOGKEY = @transmitlogkey
        				
			insert into wh2.ORDERSTATUSHISTORY (whseid, orderkey, orderlinenumber, ordertype,status, adddate, addwho, comments)
			select 'wh2', @orderkey, '', 'SO', '78', GETDATE(), 'DataAdapter', 'Ручной статус контроля'
        		
			print 'выгружаем результат в DAX'
        	
        	select * from #result
        	
        	-- Шапка для обновления статуса, на скомплектовано
				update daxTable
						set	daxTable.status = '26',
							daxTable.boxnum = r.boxnum
							--daxTable.daxstatus = '26'
					from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[INFORINTEGRATIONTABLE_SHIPMENT] daxTable
					join #result r on 
						daxTable.docid	= r.externorderkey	-- Внешний номер
				
				if @@ROWCOUNT <> 0
				begin
				-- Детали для обновления статуса+кол-во скомплектованного в деталях.		
					update dax
							set dax.pickedqtyinfor = r.packedqty,
								dax.status = '26'
						from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[INFORINTEGRATIONLINE_SHIPMENT] dax
						join #result r on 
							dax.docid	= r.externorderkey and	-- Внешний номер
							dax.itemid	= r.sku and				-- Товар
							--dax.inventserialid = r.LOTTABLE02 and	-- Серия
							dax.inventserialid = case when r.LOTTABLE02 = '' then 'бс' else r.LOTTABLE02 end and	-- Серия
							dax.INVENTEXPIREDATE = convert(varchar(12),ISNULL(r.lottable05,'19000101'),112) and
							dax.inventlocationid = r.susr1 --and	-- Склад
							--dax.ORDEREDQTYDAX = r.openqty		-- заказанное кол-во
							
					where r.orderkey = @orderkey	
				end
        	
			
			------select	@n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
			------from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[INFORINTEGRATIONTABLE_SHIPMENT]
			
			------insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[INFORINTEGRATIONTABLE_SHIPMENT]
			------(dataareaid,INFORDAXSYSTEM,docid,doctype, CUSTVENDAC,inventlocationid,status,daxstatus,WMSPickingRouteId , boxnum,recid)
			--------(dataareaid,docid,doctype,invoiceid,salesidbase,wmspickingrouteid,demandshipdate,
			--------consigneeaccount_ru,inventlocationid,status,boxcount,recid)
	    		
			------select	distinct 'SZ','1', externorderkey,[type], 
			------	consigneekey,susr1 as inventlocationid, '26' as status, '5' as daxstatus,susr2,boxnum,@n + 1 as recid
			------from	#result
        		
			------if @@ROWCOUNT <> 0
			------begin
			------select	identity(int,1,1) as id,
			------		'SZ' as dataareaid,externorderkey,c_contact1,sku,[packedqty],[openqty],susr1 as inventlocationid,lottable06,
			------		lottable02,lottable05,lottable04,susr2,
			------		 '26' as status
			------	into	#e
			------	from	#result
        			
			------	select	@n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
			------	from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[INFORINTEGRATIONLINE_SHIPMENT]
        		
        		
			------	insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[INFORINTEGRATIONLINE_SHIPMENT]
			------	(dataareaid,docid,itemid,[ORDEREDQTYDAX],[PICKEDQTYINFOR],inventlocationid,
			------	inventserialid,inventexpiredate,status, daxstatus,WMSPickingRouteId,recid)
                		
			------	select	dataareaid,externorderkey,sku,[openqty],[packedqty],inventlocationid,
			------		lottable02,lottable05, status,'5' as daxstatus, susr2,@n + e.id as recid
			------	from	#e e
			
        				
			------end		
        		
			print 'выгружаем результат датадаптеру'
			if @log=1
				insert into DA_Log(direction,isError,objectID,message)
				values('Out',0,@transmitlogkey,'6. выгружаем результат датадаптеру.')

			select 'ORDERPACKED' filetype, * from #result
		end		
	end

	endproc:
        				
					--drop table #result
					--drop table #tmp
					--select 'ORDERPACKED' filetype, * from #result
        				
	--drop table #case
	--drop table #result
	--drop table #casedist

	if @send_error = 1
	begin
		if @log=1
				insert into DA_Log(direction,isError,objectID,message)
				values('Out',0,@transmitlogkey,'7. Ошибка.')

		print 'отправляем сообщение о повторной упаковке/контроле заказа'
		print @msg_errdetails
		--set @source = 'proc_DA_PickControlCaseCompleted'
		--insert into DA_InboundErrorsLog (source,msg_errdetails) values (@source,@msg_errdetails)		
		--exec app_DA_SendMail @source, @msg_errdetails
        	
		print 'выгружаем результат с Ошибкой в DAX'
 
 --select * from  [SPB-SQL1210DBE\MSSQLDBE]].[DAX2009_1].[dbo].SZ_ImpOutputOrdersPicking      	

		select	@n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
		from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputOrdersPicking	
        	
		insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputOrdersPicking
		(dataareaid,docid,doctype,invoiceid,salesidbase,wmspickingrouteid,demandshipdate,
		consigneeaccount_ru,inventlocationid,status,recid,error)
        	
		select	distinct 'SZ',externorderkey,[type],susr3 as invoiceid,c_contact1 as salesidbase,susr2 as wmspickingrouteid,REQUESTEDSHIPDATE,
			consigneekey,susr1 as inventlocationid, '15' as status,@n + 1 as recid,@msg_errdetails as error
		from	#result
        	
		if @@ROWCOUNT <> 0
		begin
				select	identity(int,1,1) as id,
				'SZ' as dataareaid,externorderkey,c_contact1,sku,[packedqty],[openqty],susr1 as inventlocationid,lottable06,
				lottable02,lottable05,lottable04,
				 '15' as status
			into	#ee
			from	#result
        		
			select	@n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
			from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputOrderlinespic
        	
        	
			insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputOrderlinespic
			(dataareaid,docid,salesidbase,itemid,salesqty,orderedqty,inventlocationid,inventbatchid,
			inventserialid,inventexpiredate,inventserialproddate,
			status,recid,error)
            		
			select	dataareaid,externorderkey,c_contact1,sku,[packedqty],[openqty],inventlocationid,lottable06,
				lottable02,lottable05,lottable04,
				status, @n + id as recid,@msg_errdetails as error
			from	#ee
			
        			
		end
	end
	
	
	
END




IF OBJECT_ID('tempdb..#e') IS NOT NULL DROP TABLE #e
IF OBJECT_ID('tempdb..#ee') IS NOT NULL DROP TABLE #ee
IF OBJECT_ID('tempdb..#case') IS NOT NULL DROP TABLE #case
IF OBJECT_ID('tempdb..#result') IS NOT NULL DROP TABLE #result
IF OBJECT_ID('tempdb..#casedist') IS NOT NULL DROP TABLE #casedist

----status pickdetail
----	0 - зарезервирован
----	1 - запущен
----	5 - отобран
----	6 - упакован
----	8 - загружен
----	9 - отгружен

----
----
----

