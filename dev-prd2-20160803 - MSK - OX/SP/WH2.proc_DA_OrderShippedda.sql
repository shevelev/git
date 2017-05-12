-- ПОДТВЕРЖДЕНИЕ ОТГРУЗКИ ЗАКАЗА

ALTER PROCEDURE [wh2].[proc_DA_OrderShippedda](
	@wh varchar(10),
	@transmitlogkey varchar (10)
)AS

SET NOCOUNT ON
--
--if @wh <> 'wh2'
--begin
--	raiserror('Недопустимая схема %s',16,1,@wh)
--	return
--end
--
declare	@orderkey varchar (10) -- номер заказа
--declare @skip_0_qty varchar(10)
--declare	@transmitlogkey varchar (10)
--set @transmitlogkey = '0005364737'

declare @bs varchar(3) select @bs = short from wh2.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'
declare @bsanalit varchar(3) select @bsanalit = short from wh2.CODELKUP where LISTNAME='sysvar' and CODE = 'bsanalit'
declare @send_error bit
declare @msg_errdetails varchar(max)
declare @source varchar(500) = null,
	@n bigint

CREATE TABLE #result (	
	[orderkey] varchar(32),
	[storerkey] varchar(15),--
	[externorderkey] varchar(32),--
	[type] varchar(10),--
	[susr1] varchar(30),--
	[susr2] varchar(30),--
	[susr3] varchar(30),--
	[C_CONTACT1] varchar(30),
	[consigneekey] varchar(15),
	[REQUESTEDSHIPDATE] varchar(20),
	[sku] varchar(50),--
	[packkey] varchar(50),--
	[openqty] decimal(22,5), --
	[shippedqty] decimal(22,5), --
	[LOTTABLE02] varchar(50),--
	[LOTTABLE04] varchar(50) null,--datetime null,--
	[LOTTABLE05] varchar(50) null,--datetime null,--
	[LOTTABLE06] varchar(50)	
)


print '0. проверка повторного закрытия заказа'

select @orderkey = tl.key1 from wh2.transmitlog tl where tl.transmitlogkey = @transmitlogkey

--if 0 < (select count(*) from wh2.orders r where r.orderkey=@orderkey and r.susr2='9')
--begin
--	--raiserror ('Повторное закрытие Заказа = %s',16,1, @orderkey)
--	set @send_error = 1
--	set @msg_errdetails = 'Повторное закрытие Заказа '+ @orderkey
--	goto endproc
--end	


if exists(select * from wh2.ORDERS where [TYPE] = '26' and ORDERKEY = @orderkey)
goto endproc --отмененный заказ

--выбираем строки неотправленных отборов 
select	serialkey,orderkey,sku,status,pdudf2,pickdetailkey,orderlinenumber,qty,dropid 
into	#tmp
from	wh2.pickdetail 
where	orderkey = @orderkey 
	and status >= '8'--in ('1','5','6','8','9')


-- проверям, все ли отборы отгружены
if (exists(select top(1) serialkey from #tmp where status < '9'))
begin
	-- не все загруженные отборы отгружены - завершаем обработку
	print ' не все отборы отгружены'
end
else
begin
	print 'формируем результат датаадаптеру'
	
	insert into #result 
	select 
		o.ORDERKEY,
		o.storerkey,
		o.externorderkey,
		o.[type],
		o.susr1,
		o.susr2,
		o.susr3,
		o.C_CONTACT1,
		o.CONSIGNEEKEY,
		o.REQUESTEDSHIPDATE,
		od.sku,
		od.packkey,
		--od.openqty as [openqty],
		od.originalqty as [openqty],  -- заменил на originalqty
		case when od.QTYPICKED = 0 then od.SHIPPEDQTY else od.QTYPICKED end as [shipqty],
		--od.LOTTABLE02, 
		case when od.LOTTABLE02 = '' then 'бс' else      od.LOTTABLE02      end AS LOTTABLE02, --od.LOTTABLE02, 
		convert(varchar(12),ISNULL(od.lottable04,'19000101'),112) as LOTTABLE04, --od.LOTTABLE04, 
		convert(varchar(12),ISNULL(od.lottable05,'19000101'),112) as LOTTABLE05, --od.LOTTABLE05, 
		od.NOTES ----LOTTABLE06 Шевелев С.С. 19.11.2015 Партия A od.LOTTABLE06
	from	wh2.orders o 
		join wh2.orderdetail od 
		    on o.orderkey = od.orderkey
	where	o.orderkey = @orderkey
	
	print 'выгружаем результат в DAX'	
	
	---- Проверка статуса документа в обменных таблицах.
	if ((select distinct d.status from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[INFORINTEGRATIONTABLE_SHIPMENT] d
		join  #result r on d.docid	= r.externorderkey) = '10')
			-->------ Генерируем комплектацию+отгрузку
			begin
				-- Шапка
				update daxTable
						set	daxTable.status = '28'
					from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[INFORINTEGRATIONTABLE_SHIPMENT] daxTable
					join #result r on 
						daxTable.docid	= r.externorderkey	-- Внешний номер
				
				if @@ROWCOUNT <> 0
				begin
				-- Детали			
					update dax
							set dax.shippedqtyinfor = r.shippedqty,
								dax.pickedqtyinfor  = r.shippedqty,
								dax.status = '28'
						from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[INFORINTEGRATIONLINE_SHIPMENT] dax
						join #result r on 
							dax.docid	= r.externorderkey and	-- Внешний номер
							dax.itemid	= r.sku and				-- Товар
							dax.inventserialid = r.LOTTABLE02 and	-- Серия
							dax.INVENTEXPIREDATE = convert(varchar(12),ISNULL(r.lottable05,'19000101'),112) and
							dax.inventlocationid = r.susr1 --and	-- Склад
							--dax.ORDEREDQTYDAX = r.openqty		-- заказанное кол-во
							
					where r.orderkey = @orderkey	
				end
			end
			-->------
	else if ((select distinct d.status from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[INFORINTEGRATIONTABLE_SHIPMENT] d
		join  #result r on d.docid	= r.externorderkey) = '26')
			-->------ Генерируем отгрузку
			begin
				-- Шапка
				update daxTable
						set	daxTable.status = '28'
					from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[INFORINTEGRATIONTABLE_SHIPMENT] daxTable
					join #result r on 
						daxTable.docid	= r.externorderkey	-- Внешний номер
				
				if @@ROWCOUNT <> 0
				begin
				-- Детали			
					update dax
							set dax.shippedqtyinfor = r.shippedqty,
								dax.status = '28'
						from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[INFORINTEGRATIONLINE_SHIPMENT] dax
						join #result r on 
							dax.docid	= r.externorderkey and	-- Внешний номер
							dax.itemid	= r.sku and				-- Товар
							dax.inventserialid = r.LOTTABLE02 and	-- Серия
							dax.INVENTEXPIREDATE = convert(varchar(12),ISNULL(r.lottable05,'19000101'),112) and
							dax.inventlocationid = r.susr1 --and	-- Склад
							--dax.ORDEREDQTYDAX = r.openqty		-- заказанное кол-во
							
					where r.orderkey = @orderkey	
				end
			end
			-->------
			

end


select  'ORDERSHIPPED' filetype, * from	#result

print 'возвращаем результат датаадаптеру'

declare @www int
select @www = COUNT(*) from #result
print @www


print 'формируем сообщение об отгрузке машины'
declare @loadid varchar(20)

select	@loadid = isnull(ls.LOADID,'')
from	wh2.LOADORDERDETAIL lod 
	join wh2.ORDERS o 
	    on lod.SHIPMENTORDERID = o.ORDERKEY 
	join wh2.LOADSTOP ls 
	    on ls.LOADSTOPID = lod.LOADSTOPID
where o.ORDERKEY = @orderkey
	
print 'загрузка ' +@loadid

if @loadid != ''
begin
    print 'заказ находится в загрузке'
    if (select	COUNT(o.serialkey) 
        from	wh2.ORDERS o 
		join wh2.loadorderdetail lod 
		    on lod.SHIPMENTORDERID = o.ORDERKEY 
		join wh2.LOADSTOP ls 
		    on ls.LOADSTOPID = lod.LOADSTOPID 
        where	isnull(o.susr2,'0') != '9' and ls.LOADID = @loadid
	) = 0
    begin
	    --получить номер для записи в лог
	    exec dbo.DA_GetNewKey 'wh2','eventlogkey',@transmitlogkey output
    	
	    --записать в лог событие об отгрузке заказа
	    insert wh2.transmitlog (whseid, transmitlogkey, tablename, key1,ADDWHO) 
	    values ('wh2', @transmitlogkey, 'tsshipped', @loadid, 'dataadapter')
    end
end


--drop table #result1

endproc:

if @send_error = 1
begin
	print 'отправляем сообщение об ошибке'
	print @msg_errdetails
	--set @source = 'proc_DA_PickControlCaseCompleted'
	--insert into DA_InboundErrorsLog (source,msg_errdetails) values (@source,@msg_errdetails)		
	--exec app_DA_SendMail @source, @msg_errdetails
	
	print 'выгружаем результат с Ошибкой в DAX'
	

	select	@n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
	from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputOrdersShip	
	
	insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputOrdersShip
	(dataareaid,docid,doctype,invoiceid,salesidbase,wmspickingrouteid,demandshipdate,
	consigneeaccount_ru,inventlocationid,status,recid,error)
	
	select	distinct 'SZ',externorderkey,[type],susr3 as invoiceid,c_contact1 as salesidbase,susr2 as wmspickingrouteid,REQUESTEDSHIPDATE,
		consigneekey,susr1 as inventlocationid, '15' as status,@n + 1 as recid,@msg_errdetails
	from	#result
	
	if @@ROWCOUNT <> 0
	begin
			select	identity(int,1,1) as id,
			'SZ' as dataareaid,externorderkey,c_contact1,sku,[openqty],shippedqty,susr1 as inventlocationid,lottable06,
			lottable02,lottable05,lottable04,
			 '5' as status
		into	#ee
		from	#result
	
		select	@n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
		from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputOrderlineShip
	
	
		insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputOrderlineShip
		(dataareaid,docid,salesidbase,itemid,salesqty,lineqty,orderedqty,inventlocationid,inventbatchid,
		inventserialid,inventexpiredate,inventserialproddate,
		status,recid,error)
    		
		select	dataareaid,externorderkey,c_contact1,sku,shippedqty,shippedqty,[openqty],inventlocationid,lottable06,
			lottable02,lottable05,lottable04,
			status, @n + id as recid,@msg_errdetails
		from	#ee
			
	end
end


IF OBJECT_ID('tempdb..#e') IS NOT NULL DROP TABLE #e
IF OBJECT_ID('tempdb..#ee') IS NOT NULL DROP TABLE #ee
IF OBJECT_ID('tempdb..#tmp') IS NOT NULL DROP TABLE #tmp
IF OBJECT_ID('tempdb..#result') IS NOT NULL DROP TABLE #result
	
--status pickdetail
--	0 - зарезервирован
--	1 - запущен
--	5 - отобран
--	6 - упакован
--	8 - загружен
--	9 - отгружен

--
--
--

