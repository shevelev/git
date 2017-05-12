ALTER PROCEDURE [dbo].[ReReleaseDoc] 
	@typedoc varchar (15), -- тип документа
	-- ASN выгрузка приемки ПУО
	-- SOP выгрузка упаковки/контроля заказа на отгрузку
	-- SOS выгрузка отгрузки заказа на отгрузку
	-- LD выгрузка загрузки
	@numberdoc varchar (15) -- номер документа
AS

--declare @typedoc varchar (15)
--declare @numberdoc varchar (15)
--set @typedoc = 'SOP'
--set @numberdoc = '0000004377'


set nocount on

declare @msg varchar (max) set @msg = ''
declare @transmitlogkey varchar (20) set @transmitlogkey = null
declare @transmitflag9 varchar (50)	set @transmitflag9 = NULL
declare @transmiterror varchar (2000)	set @transmiterror = null


/*********************************************************************************************/
/* ПУО ***************************************************************************************/
/*********************************************************************************************/
if @typedoc = 'ASN'
	begin
		print 'Документ ПУО'
		if (select COUNT (serialkey) from wh1.RECEIPT where RECEIPTKEY = @numberdoc) != 1
			begin
				print 'ПУО с номером ' + @numberdoc + ' не существует.'
				set @msg = 'ПУО с номером ' + @numberdoc + ' не существует.'
				goto EndProc
			end		
		--if (select COUNT (serialkey) from wh1.receipt where RECEIPTKEY = @numberdoc and STATUS = '11') != 1
		--	begin
		--		print 'ПУО ' + @numberdoc + '. Документ не закрыт.'
		--		set @msg = 'ПУО ' + @numberdoc + '. Документ не закрыт.'
		--		goto EndProc
		--	end
			select top(1) @transmitlogkey = TRANSMITLOGKEY from wh1.TRANSMITLOG where key1 = @numberdoc and TABLENAME = 'CompositeASNClose'
		if isnull(@transmitlogkey,'') = ''
			begin
				print 'Документ ПУО ' + @numberdoc + ' закрыт. Событие в wh1.TRANSMITLOG отсутствует. Создаем событие.'
				exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
				
				insert into wh1.TRANSMITLOG (whseid, transmitlogkey,			tablename,		key1, key2, key3, key4, key5, transmitflag, transmitflag2, transmitflag3, transmitflag4, transmitflag5, transmitflag6, transmitflag7, transmitflag8, transmitflag9, transmitbatch, eventstatus, eventfailurecount, eventcategory, message, adddate, addwho,	 editdate, editwho, error)
										select 'WH1', @transmitlogkey,'CompositeASNClose',@numberdoc,	'',		'','',		'',			'0',		null,			null,			null,			null,		null,			null,			null,		null,				'',			0,					0,			'E',	'',	GETDATE(),		'RR',	GETDATE(), 'RR',	''
			end
		else 
			begin
				print 'Перезапускаем событие в wh1.TRANSMITLOG.'
				update wh1.receipt set susr5='' where RECEIPTKEY = @numberdoc
				delete from pod 
					from wh1.PODETAIL pod join WH1.PO p on pod.POKEY = p.POKEY
					where pod.QTYORDERED = 0 and p.OTHERREFERENCE = @numberdoc	
				update wh1.TRANSMITLOG set transmitflag9 = null, EVENTFAILURECOUNT = EVENTFAILURECOUNT + 1 where TRANSMITLOGKEY = @transmitlogkey	
			end
		while (select transmitflag9 from wh1.TRANSMITLOG where tRANSMITLOGKEY = @transmitlogkey) is null
			begin
				print 'Ожидаем обработки события ДатаАдаптером'
				waitfor delay '00:00:01'
			end
		select @transmitflag9 = transmitflag9, @transmiterror = error from wh1.TRANSMITLOG where TRANSMITLOGKEY = @transmitlogkey
		if @transmitflag9 = 'OK'
			begin
				print 'Подтверждение приемки ПУО '+@numberdoc+' успешно выгружено.'
				set @msg = 'Подтверждение приемки ПУО '+@numberdoc+' успешно выгружено.'
			end
		else
			begin
				print 'Ошибка. wh1.TRANSMITLOG.transmitflag9 = ' + @transmitflag9 + ' Подтверждение приемки ПУО не выгружено.'
				print @transmiterror
				set @msg = 'Ошибка. wh1.TRANSMITLOG.transmitflag9 = ' + @transmitflag9 + ' Подтверждение приемки ПУО не выгружено.'			
			end
	end


/*********************************************************************************************/
/* ЗАКАЗ НА ОТГРУЗКУ УПАКОВКА ****************************************************************/
/*********************************************************************************************/
if @typedoc = 'SOP'
	begin
		print 'Документ ЗАКАЗ НА ОТГРУЗКУ УПАКОВКА'
		if (select COUNT (serialkey) from wh1.ORDERS where orderkey = @numberdoc) != 1
			begin
				print 'ЗАКАЗ НА ОТГРУЗКУ с номером ' + @numberdoc + ' не существует.'
				set @msg = 'ЗАКАЗ НА ОТГРУЗКУ с номером ' + @numberdoc + ' не существует.'
				goto EndProc
			end	
		create table #case (
			orderkey varchar(20),
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
			run_cc int null,
			contrdatetime datetime null,
			sku varchar(20) null
		)
			print 'ЗАКАЗ '+@numberdoc+' проконтролирован'
			select top(1) @transmitlogkey = TRANSMITLOGKEY from wh1.TRANSMITLOG where KEY1 = @numberdoc and (TABLENAME = 'customerorderlinepacked' or TABLENAME = 'customerorderpacked' or TABLENAME = 'pickcontrolcasecompleted')
			if isnull(@transmitlogkey,'') = ''
				begin 
					print 'ЗАКАЗ ' + @numberdoc + ' Прверен/упакован. Событие в wh1.TRANSMITLOG отсутствует. Создаем событие.'
					exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
						
					insert into wh1.TRANSMITLOG (whseid, transmitlogkey,			tablename,		key1, key2, key3, key4, key5, transmitflag, transmitflag2, transmitflag3, transmitflag4, transmitflag5, transmitflag6, transmitflag7, transmitflag8, transmitflag9, transmitbatch, eventstatus, eventfailurecount, eventcategory, message, adddate, addwho,	 editdate, editwho, error)
						select 'WH1', @transmitlogkey,'customerorderpacked',@numberdoc,	'',		'','',		'',			'0',		null,			null,			null,			null,		null,			null,			null,		null,				'',			0,					0,			'E',	'',	GETDATE(),		'RR',	GETDATE(), 'RR',	''
				end
			else
				begin
					print 'перезапуск события ' + @transmitlogkey + '.' 
					update wh1.ORDERS set susr2 = '' where ORDERKEY = @numberdoc
					update wh1.TRANSMITLOG set transmitflag9 = null where TRANSMITLOGKEY = @transmitlogkey	
				end
			while (select transmitflag9 from wh1.TRANSMITLOG where tRANSMITLOGKEY = @transmitlogkey) is null
				begin
					print 'Ожидаем обработки события ДатаАдаптером'
					waitfor delay '00:00:01'
				end
			select @transmitflag9 = transmitflag9, @transmiterror = error from wh1.TRANSMITLOG where TRANSMITLOGKEY = @transmitlogkey
			if @transmitflag9 = 'OK'
				begin
					print 'Подтверждение упаковки/контроля ЗАКАЗА '+@numberdoc+' успешно выгружено.'
					set @msg = 'Подтверждение упаковки/контроля ЗАКАЗА '+@numberdoc+' успешно выгружено.'
				end
			else
				begin
					print 'Ошибка. wh1.TRANSMITLOG.transmitflag9 = ' + @transmitflag9 + ' Подтверждение упаковки/контроля ЗАКАЗА '+@numberdoc+' не выгружено.'
					print @transmiterror
					set @msg = 'Ошибка. wh1.TRANSMITLOG.transmitflag9 = ' + @transmitflag9 + ' Подтверждение упаковки/контроля ЗАКАЗА '+@numberdoc+' не выгружено.'			
				end
		drop table #case
	end

/*********************************************************************************************/
/* ЗАКАЗ НА ОТГРУЗКУ ОТГРУЗКА ****************************************************************/
/*********************************************************************************************/
if @typedoc = 'SOS'
	begin
		print 'Документ ЗАКАЗ НА ОТГРУЗКУ'
		if (select COUNT (serialkey) from wh1.ORDERS where orderkey = @numberdoc) != 1
			begin
				print 'ЗАКАЗ НА ОТГРУЗКУ с номером ' + @numberdoc + ' не существует.'
				set @msg = 'ЗАКАЗ НА ОТГРУЗКУ с номером ' + @numberdoc + ' не существует.'
				goto EndProc
			end	
		create table #case1 (
			orderkey varchar(20),
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
			run_cc int null,
			contrdatetime datetime null,
			sku varchar(20) null
		)
				print 'ЗАКАЗ '+@numberdoc+' проконтролирован'
				select 'ЗАКАЗ '+@numberdoc+' Отгружен'
				select top(1) @transmitlogkey = TRANSMITLOGKEY from wh1.TRANSMITLOG where KEY1 = @numberdoc and (TABLENAME = 'CompositeASNClose')
				if isnull(@transmitlogkey,'') = ''
					begin 
						print 'ЗАКАЗ ' + @numberdoc + ' Отгружен. Событие в wh1.TRANSMITLOG отсутствует. Создаем событие.'
						exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
	
						insert into wh1.TRANSMITLOG (whseid, transmitlogkey,			tablename,		key1, key2, key3, key4, key5, transmitflag, transmitflag2, transmitflag3, transmitflag4, transmitflag5, transmitflag6, transmitflag7, transmitflag8, transmitflag9, transmitbatch, eventstatus, eventfailurecount, eventcategory, message, adddate, addwho,	 editdate, editwho, error)
							select 'WH1', @transmitlogkey,'CompositeASNClose',@numberdoc,	'',		'','',		'',			'0',		null,			null,			null,			null,		null,			null,			null,		null,				'',			0,					0,			'E',	'',	GETDATE(),		'RR',	GETDATE(), 'RR',	''
					end
				else
					begin
						print 'перезапуск события.'
						update wh1.ORDERS set susr2 = '' where ORDERKEY = @numberdoc
						update wh1.TRANSMITLOG set transmitflag9 = null where TRANSMITLOGKEY = @transmitlogkey	
					end
				while (select transmitflag9 from wh1.TRANSMITLOG where tRANSMITLOGKEY = @transmitlogkey) is null
					begin
						print 'Ожидаем обработки события ДатаАдаптером'
						waitfor delay '00:00:01'
					end
				select @transmitflag9 = transmitflag9, @transmiterror = error from wh1.TRANSMITLOG where TRANSMITLOGKEY = @transmitlogkey
				if @transmitflag9 = 'OK'
					begin
						print 'Подтверждение ОТГРУЗКИ ЗАКАЗА '+@numberdoc+' успешно выгружено.'
						set @msg = 'Подтверждение ОТГРУЗКИ ЗАКАЗА '+@numberdoc+' успешно выгружено.'
					end
				else
					begin
						print 'Ошибка. wh1.TRANSMITLOG.transmitflag9 = ' + @transmitflag9 + ' Подтверждение ОТГРУЗКИ ЗАКАЗА '+@numberdoc+' не выгружено.'
						print @transmiterror
						set @msg = 'Ошибка. wh1.TRANSMITLOG.transmitflag9 = ' + @transmitflag9 + ' Подтверждение ОТГРУЗКИ ЗАКАЗА '+@numberdoc+' не выгружено.'			
					end
		drop table #case1
	end

/*********************************************************************************************/
/* ЗАГРУЗКА **********************************************************************************/
/*********************************************************************************************/
if @typedoc = 'LD'
	begin
		print 'Документ ЗАГРУЗКА'
		if (select COUNT (serialkey) from wh1.LOADHDR where LOADID = @numberdoc) != 1
			begin
				print 'ЗАГРУЗКА с номером ' + @numberdoc + ' не существует.'
				set @msg = 'ЗАГРУЗКА с номером ' + @numberdoc + ' не существует.'
				goto EndProc				
			end
		select top(1) @transmitlogkey = transmitlogkey from wh1.TRANSMITLOG where KEY1 = @numberdoc and TABLENAME = 'tsshipped'	
		if isnull(@transmitlogkey,'') = ''
			begin
				print 'ЗАГРУЗКА ' + @numberdoc + ' закрыта. Событие в wh1.TRANSMITLOG отсутствует. Создаем событие.'
				exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
				
				insert into wh1.TRANSMITLOG (whseid, transmitlogkey,			tablename,		key1, key2, key3, key4, key5, transmitflag, transmitflag2, transmitflag3, transmitflag4, transmitflag5, transmitflag6, transmitflag7, transmitflag8, transmitflag9, transmitbatch, eventstatus, eventfailurecount, eventcategory, message, adddate, addwho,	 editdate, editwho, error)
										select 'WH1', @transmitlogkey,'tsshipped',@numberdoc,	'',		'','',		'',			'0',		null,			null,			null,			null,		null,			null,			null,		null,				'',			0,					0,			'E',	'',	GETDATE(),		'RR',	GETDATE(), 'RR',	''
			end
		else
			begin
				print 'Перезапускаем событие в wh1.TRANSMITLOG.'
				update wh1.receipt set susr5='' where RECEIPTKEY = @numberdoc
				delete from pod 
					from wh1.PODETAIL pod join WH1.PO p on pod.POKEY = p.POKEY
					where pod.QTYORDERED = 0 and p.OTHERREFERENCE = @numberdoc	
				update wh1.TRANSMITLOG set transmitflag9 = null, EVENTFAILURECOUNT = EVENTFAILURECOUNT + 1 where TRANSMITLOGKEY = @transmitlogkey					
			end
		while (select transmitflag9 from wh1.TRANSMITLOG where TRANSMITLOGKEY = @transmitlogkey	) is null
			begin
				--pause
				print 'Ожидаем обработки события ДатаАдаптером'
				waitfor delay '00:00:01'
			end
		select @transmitflag9 = transmitflag9, @transmiterror = error from wh1.TRANSMITLOG where TRANSMITLOGKEY = @transmitlogkey
		if @transmitflag9 = 'OK'
			begin
				print 'Подтверждение отгрузки ЗАГРУЗКИ '+@numberdoc+' успешно выгружено.'
				set @msg = 'Подтверждение отгрузки ЗАГРУЗКИ '+@numberdoc+' успешно выгружено.'
			end
		else
			begin
				print 'Ошибка. wh1.TRANSMITLOG.transmitflag9 = ' + @transmitflag9 + ' Подтверждение отгрузки ЗАГРУЗКИ не выгружено.'
				print @transmiterror
				set @msg = 'Ошибка. wh1.TRANSMITLOG.transmitflag9 = ' + @transmitflag9 + ' Подтверждение отгрузки ЗАГРУЗКИ не выгружено.'			
			end
	end
	

EndProc:
	select MSG = @msg, ERROR = @transmiterror
	

