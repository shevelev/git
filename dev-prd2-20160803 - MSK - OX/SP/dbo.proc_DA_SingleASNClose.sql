-- ПОДТВЕРЖДЕНИЕ ПУО
ALTER PROCEDURE [dbo].[proc_DA_SingleASNClose](
	--@source varchar(500) = null,
	@wh varchar(30),
	@transmitlogkey varchar (10))
as

-- Ошибки должны прерывать процедуру. Если возникли ошибки, п. 8 
-- не должен выполниться (не помечать ПУО как "выгружено в хост систему")
SET XACT_ABORT ON
SET NOCOUNT ON

declare @receiptkey varchar(10) 
declare @source varchar(500) = null
--set @receiptkey = '0000007126'

--declare @source varchar(20) set @source = 'proc_DA_SingleASNClose'
declare @send_error bit
declare @msg_errdetails varchar(max)

print '0. проверка повторного закрытия ПУО'
	select @receiptkey = tl.key1 from wh1.transmitlog tl where tl.transmitlogkey = @transmitlogkey
	if 0 < (select count(*) from wh1.receipt r where r.receiptkey=@receiptkey and r.susr5='9')
	begin
		--raiserror ('Повторное закрытие ПУО = %s',16,1, @receiptkey)
		set @send_error = 1
		set @source = 'proc_DA_SingleASNClose'
		set @msg_errdetails = 'Повторное закрытие ПУО '+ @receiptkey
		goto endproc
	end
	
		--print 'обновление упаковки в карточке товара'
		--update s set s.packkey = case when isnull(l.LOTTABLE01,'') = '' then 'STD' else l.LOTTABLE01 end,
		--		s.RFDEFAULTPACK = case when isnull(l.LOTTABLE01,'') = '' then 'STD' else l.LOTTABLE01 end
		--	from wh1.SKU s join wh1.receiptdetail pdr on pdr.sku = s.SKU and pdr.storerkey = s.storerkey
		--					join wh1.LOTattribute l on pdr.tolot = l.lot
		--	where pdr.RECEIPTKEY = @receiptkey

	select
		'CancelingShipment' filetype,
		storerkey,
		'' externorderkey
		from wh1.RECEIPT where RECEIPTKEY = @receiptkey and isnull(POKEY,'') != ''
		
	if @@ROWCOUNT = 0 
		begin
			set @send_error = 1
			set @msg_errdetails = 'Закрыто ПУО созданное внутренне № '+@receiptkey
		end

endproc:
if @send_error = 1
	begin
		print 'отправляем сообщение об ошибке по почте'
		print @msg_errdetails
		
		insert into DA_InboundErrorsLog (source,msg_errdetails) values (@source,@msg_errdetails)		
		exec app_DA_SendMail @source, @msg_errdetails
	end
