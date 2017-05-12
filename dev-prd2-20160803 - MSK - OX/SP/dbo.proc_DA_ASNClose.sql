-- ПОДТВЕРЖДЕНИЕ ПУО
ALTER PROCEDURE [dbo].[proc_DA_ASNClose](
	--@source varchar(500) = null,
	@wh varchar(30),
	@transmitlogkey varchar (10))
as

-- Ошибки должны прерывать процедуру. Если возникли ошибки, п. 8 
-- не должен выполниться (не помечать ПУО как "выгружено в хост систему")
SET XACT_ABORT ON
SET NOCOUNT ON

declare @send_error bit
declare @msg_errdetails varchar(max)
declare @source varchar(500) = null


--declare @transmitlogkey varchar (10) set @transmitlogkey = '0005245939'
declare @receiptkey varchar(10) 
--set @receiptkey = '0000006979'

print '0. проверка повторного закрытия ПУО'
	select @receiptkey = tl.key1 from wh1.transmitlog tl where tl.transmitlogkey = @transmitlogkey
	if 0 < (select count(*) from wh1.receipt r where r.receiptkey=@receiptkey and r.susr5='9')
	begin
		--raiserror ('Повторное закрытие ПУО = %s',16,1, @receiptkey)
		set @send_error = 1
		set @source = 'proc_DA_ASNClose'
		set @msg_errdetails = 'Повторное закрытие ПУО '+ @receiptkey
		goto endproc
	end	
		
print @receiptkey
if ((select COUNT (serialkey) from wh1.PO where OTHERREFERENCE = @receiptkey) <= 0)
	begin -- ПУО без ЗЗ
		print 'Одиночное ПУО'
		--получить номер для записи в лог
		exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
		
		--записать в лог событие об отгрузке заказа
		insert wh1.transmitlog (whseid, transmitlogkey, tablename, key1, ADDWHO) 
		values ('WH1', @transmitlogkey, 'SingleASNClose', @receiptkey, 'dataadapter')	
	end
else
	begin
		print 'Составное ПУО'
		--получить номер для записи в лог
		exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
		
		--записать в лог событие об отгрузке заказа
		insert wh1.transmitlog (whseid, transmitlogkey, tablename, key1, ADDWHO) 
		values ('WH1', @transmitlogkey, 'CompositeASNClose', @receiptkey, 'dataadapter')	
	end
	
endproc:
if @send_error = 1
	begin
		print 'отправляем сообщение об ошибке по почте'
		print @msg_errdetails
		insert into DA_InboundErrorsLog (source,msg_errdetails) values (@source,@msg_errdetails)		
		exec app_DA_SendMail @source, @msg_errdetails
	end
