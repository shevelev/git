-- ПОДТВЕРЖДЕНИЕ ПУО
ALTER PROCEDURE [dbo].[proc_DA_CompositeASNClose](
	--@source varchar(500) = null,
	@wh varchar(30),
	@transmitlogkey varchar (10))
as

-- Ошибки должны прерывать процедуру. Если возникли ошибки, п. 8 
-- не должен выполниться (не помечать ПУО как "выгружено в хост систему")
SET XACT_ABORT ON
SET NOCOUNT ON

declare @receiptkey varchar(10)--,@transmitlogkey varchar (10) 
--set @receiptkey = '0000025039'

declare @source varchar(100) --set --@source = 'proc_DA_CompositeASNClose'

declare @send_error bit
declare @msg_errdetails varchar(max)
declare  @receiptlinenumber varchar(5)
declare @polinenumber varchar(5)
declare @pokey varchar(10)
declare @bs varchar(3) select @bs = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'
declare @bsanalit varchar(3) select @bsanalit = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bsanalit'
declare @rqty float, @poqty float

CREATE TABLE [#receiptdetail](
	id int identity (1,1) not null,
	--polinenumber varchar(15) NULL,
	sku varchar(50) NULL,
	storerkey varchar(15) NULL,	
	skuqty float null,
	qty float null,
	qtyreceived float NULL,
	qtyreceivedbrak float NULL,
	susr2 varchar(30) NULL, -- серия
	lot varchar(20)
	--qtyordered float NULL,
	--closedate varchar(10) NULL,
	--susr1 varchar(30) NULL, -- всегда пустое
	--susr3 varchar(30) NULL, -- сумма по строке
	--susr4 varchar(30) NULL, -- доп поле
	--lottable04 datetime NULL,
	--lottable05 datetime NULL,	
	--LOTTABLE02 varchar(50) null, --серия
	--lottable03 varchar(50) null, --сертификат
	--lottable01 varchar(50) null, --ключ упаковки
	--lottable07 varchar(50) null, --брак
	--LOTTABLE08 varchar(50) null -- ФСН
	
)

CREATE TABLE [#podetail](
	id int identity (1,1) not null,
	--polinenumber varchar(15) NULL,
	pokey varchar(20) null,
	sku varchar(50) NULL,
	storerkey varchar(15) NULL,	
	qty float NULL,
	qtyordered float NULL, -- ожидаемое по ЗЗ
	QTYADJUSTED float NULL, -- ожидаемое по строке 
	QTYRECEIVED float NULL, -- принятое Н+Б
	QTYREJECTED float NULL, -- принятое Б
	--closedate varchar(10) NULL,
	--susr1 varchar(30) NULL,
	susr2 varchar(30) NULL, -- серия товара
	--susr3 varchar(30) NULL,
	--susr4 varchar(30) NULL,
	--susr5 varchar(30) NULL,	
	lot varchar(20)	
	--LOTTABLE02 varchar(50) null, --серия
	--lottable03 varchar(50) null, --сертификат
	--lottable01 varchar(50) null, --ключ упаковки
	--lottable07 varchar(50) null, --брак
	--LOTTABLE08 varchar(50) null -- ФСН
)

create table #skuqty (
	sku varchar(50) NULL,
	storerkey varchar(15) NULL,	
	qty float NULL
)


--create table #pokey (
--	pokey varchar(15) NULL
--)


select * into #podetailresult from #podetail


print '0. проверка повторного закрытия ПУО'
	select @receiptkey = tl.key1 from wh1.transmitlog tl where tl.transmitlogkey = @transmitlogkey
	if 0 < (select count(*) from wh1.receipt r where r.receiptkey=@receiptkey and r.susr5='9')
	begin
		--raiserror ('Повторное закрытие ПУО = %s',16,1, @receiptkey)
		set @send_error = 1
		set @msg_errdetails = 'Повторное закрытие ПУО '+ @receiptkey
		goto endproc
	end	

-- выборка приходов
insert into #receiptdetail 
select
SKU, 
storerkey,
0,
sum(QTYRECEIVED) qty,
sum(case when toloc not like 'brak%' then QTYRECEIVED else 0 end) qtyreceived, 
sum(case when toloc like 'brak%' then qtyreceived else 0 end) qtyreceivedbrak, 
LOTTABLE02,
TOLOT
--, lottable04, lottable05,
--case when isnull(lottable02 ,'') = '' then @bs else lottable02 end lottable02, LOTTABLE01, LOTTABLE07,lottable08
from wh1.RECEIPTDETAIL where RECEIPTKEY = @receiptkey and qtyexpected = 0 and QTYRECEIVED != 0
group by SKU, STORERKEY, TOLOT, LOTTABLE02--, lottable04, lottable05, lottable02
order by sku 

--select * from  #receiptdetail 

		--print 'обновление упаковки в карточке товара'
		--update s set s.packkey = case when isnull(l.LOTTABLE01,'') = '' then l.LOTTABLE01 else 'STD' end,
		--		s.RFDEFAULTPACK = case when isnull(l.LOTTABLE01,'') = '' then l.LOTTABLE01 else 'STD' end
		--	from wh1.SKU s join #receiptdetail pdr on pdr.sku = s.SKU and pdr.storerkey = s.storerkey
		--					join wh1.LOTattribute l on pdr.lot = l.lot

--select  '#receiptdetai', * from #receiptdetail 

--выборка ожиданий
insert into #podetail
select 
pd.pokey, 
pd.SKU, 
pd.STORERKEY,
sum(pd.QTYORDERED) qty, 
sum(pd.QTYORDERED) QTYORDERED, 
0 QTYADJUSTED, 
0 QTYRECEIVED, 
0 QTYREJECTED,
'',
''--,
--@bs
from wh1.PODETAIL pd join wh1.PO p on p.POKEY = pd.POKEY where p.OTHERREFERENCE = @receiptkey
group by pd.SKU, pd.STORERKEY, pd.pokey, pd.storerkey
order by pd.POKEY--, pd.POLINENUMBER


--select * from wh1.PO p where p.OTHERREFERENCE = '0000006979'

--select * from #podetail

-- общее количество товара
insert into #skuqty (sku, storerkey, qty)
select sku, storerkey, SUM(rd.qty) qty from #receiptdetail rd group by rd.sku, rd.storerkey

--select * from #receiptdetail where sku = '38183'
--select * from #podetail where sku = '38183'

declare @sku varchar (20), @storerkey varchar (20), @rdid int, @poid int
declare @poqtyordered float 
declare @rdqtyreceived float, @rdqtyreceivedbrak float
declare @skuqty float

--если есть строки с ненулевым количеством то обрабатываем
while exists(select * from #receiptdetail where qty != 0) 
	begin print 'есть строки с ненулевым принятым количеством'
		--выбор первой строки из принятого количства
		select top(1) @rdid = id, @sku = sku, @storerkey = storerkey, @rdqtyreceived = qtyreceived, @rdqtyreceivedbrak = qtyreceivedbrak 
			from #receiptdetail where qty != 0
		print 'storerkey '+@storerkey+', sku '+@sku+', qtyreceived '+cast(@rdqtyreceived as varchar(20))+', qtyreceivedbrack ' + cast( @rdqtyreceivedbrak as varchar(20))
		--если есть строки с ненулевым ожидаемым количеством то обрабатываем
		if exists(select * from #podetail where sku = @sku and storerkey = @storerkey and qty != 0)
			begin print 'есть строки с ненулевым ожидаемым количеством'
				--выбор первой строки по товару в зз
				select top(1) @poid = ID, @poqtyordered = qty from #podetail where sku = @sku and storerkey = @storerkey and qty != 0
				print 'storerkey '+@storerkey+', sku '+@sku+', qtyordered '+cast(@poqtyordered as varchar(20))
				--сведение количеств
				if @poqtyordered <= @rdqtyreceived 
					begin print 'ожидаемое меньше принятого'
						if @poqtyordered >= @rdqtyreceivedbrak 
							begin print 'колво брака не больше ожидаемого'
								insert into #podetailresult (sku, storerkey, pokey, qtyordered, QTYRECEIVED, QTYREJECTED, lot)--,LOTTABLE02, lottable01, lottable07,lottable08)
									select rd.sku, rd.storerkey, pd.pokey, @poqtyordered, @poqtyordered, @rdqtyreceivedbrak, rd.lot--,rd.LOTTABLE02, rd.lottable01, rd.lottable07, rd.lottable08
										from #receiptdetail rd, #podetail pd
										where rd.id = @rdid	and pd.id = @poid
								update #receiptdetail set
									qtyreceivedbrak = 0,
									qtyreceived = qtyreceived - @poqtyordered,
									qty = qty - @rdqtyreceivedbrak - @poqtyordered
									where id = @rdid
								update #podetail set
									qty = 0--, qtyordered = 0
									where id = @poid
								update #skuqty set qty = qty - @poqtyordered where sku = @sku and storerkey = @storerkey
								--select * from #skuqty where sku=@sku and @storerkey = @storerkey
							end
						else  
							begin print 'колво брака больше ожидаемого количества'
								insert into #podetailresult (sku, storerkey, pokey, qtyordered, QTYRECEIVED, QTYREJECTED, lot)--,LOTTABLE02, lottable01, lottable07, lottable08)
									select rd.sku, rd.storerkey, pd.pokey, @poqtyordered, @poqtyordered, @poqtyordered, rd.LOT--TABLE02, rd.lottable01, rd.lottable07, rd.lottable08
										from #receiptdetail rd, #podetail pd
										where rd.id = @rdid	and pd.id = @poid
								update #receiptdetail set
									qtyreceivedbrak = qtyreceivedbrak - @poqtyordered,
									qtyreceived = qtyreceived - @poqtyordered,
									qty = qty - @rdqtyreceivedbrak - @poqtyordered
									where id = @rdid
								update #podetail set
									qty = 0--, qtyordered = 0
									where id = @poid									
								update #skuqty set qty = qty - @poqtyordered 
									where sku = @sku and storerkey = @storerkey
								update #skuqty set qty=qty-@poqtyordered where sku=@sku and @storerkey = @storerkey																							
								--select * from #skuqty where sku=@sku and @storerkey = @storerkey
							end
					end
				else  
					begin print 'ожидаемое количество больше принятого'
						select @skuqty = qty from #skuqty where sku = @sku and @storerkey = @storerkey
						if @poqtyordered >= @rdqtyreceivedbrak 
							begin print 'колво брака не больше ожидаемого'
								insert into #podetailresult (sku, storerkey, pokey, qtyordered, QTYRECEIVED, QTYREJECTED,lot)
									select rd.sku, rd.storerkey, pd.pokey, 
											case when (@poqtyordered > @skuqty) and (@skuqty = @rdqtyreceived+@rdqtyreceivedbrak) then @poqtyordered else @rdqtyreceived+@rdqtyreceivedbrak end, 
											@rdqtyreceived+@rdqtyreceivedbrak, @rdqtyreceivedbrak,rd.lot
										from #receiptdetail rd, #podetail pd
										where rd.id = @rdid	and pd.id = @poid
								update #receiptdetail set
									qtyreceivedbrak = 0,
									qtyreceived = 0,
									qty = 0
									where id = @rdid
								update #podetail set
									qty = qty - case when (@poqtyordered > @skuqty) and (@skuqty = @rdqtyreceived+@rdqtyreceivedbrak) then @poqtyordered else @rdqtyreceived+@rdqtyreceivedbrak end
									where id = @poid	
								update #skuqty set qty=qty-@rdqtyreceived-@rdqtyreceivedbrak where sku=@sku and @storerkey = @storerkey								
								--select * from #skuqty where sku=@sku and @storerkey = @storerkey
							end
						else 
							begin print 'колво брака больше ожидаемого количества'
								insert into #podetailresult (sku, storerkey, pokey, qtyordered, QTYRECEIVED, QTYREJECTED,lot)--LOTTABLE02, lottable01, lottable07, lottable08)
									select rd.sku, rd.storerkey, pd.pokey, 
											case when (@poqtyordered > @skuqty) and (@skuqty = @rdqtyreceived+@rdqtyreceivedbrak) then @poqtyordered else @rdqtyreceived+@rdqtyreceivedbrak end, 
										@rdqtyreceived+@rdqtyreceivedbrak, @rdqtyreceived, rd.lot--rd.LOTTABLE02, rd.lottable01, rd.lottable07, rd.lottable08
										from #receiptdetail rd, #podetail pd
										where rd.id = @rdid	and pd.id = @poid
								update #receiptdetail set
									qtyreceivedbrak = qtyreceivedbrak - @rdqtyreceived,
									qtyreceived = qtyreceived - @rdqtyreceived,
									qty = qty - @rdqtyreceived
									where id = @rdid
								update #podetail set
									qty = qty - case when (@poqtyordered > @skuqty) and (@skuqty = @rdqtyreceived+@rdqtyreceivedbrak) then @poqtyordered else @rdqtyreceived+@rdqtyreceivedbrak end
									where id = @poid	
								update #skuqty set qty=qty-@rdqtyreceived-@rdqtyreceivedbrak where sku=@sku and @storerkey = @storerkey																							
								--select * from #skuqty where sku=@sku and @storerkey = @storerkey
							end
					end
				--уменьшение ожижаемого количества в ЗЗ на принятое
				--вставка строки с количеством в результирующую таблицу ЗЗ
				--обновление количества в принятом количестве 
			end
		else -- излишки товара
			begin print 'излишки товара'
				insert into #podetailresult (sku, storerkey, qtyordered, QTYRECEIVED, QTYREJECTED,lot)--LOTTABLE02, lottable01, lottable07, lottable08)
					select sku, storerkey, 0, qty, qtyreceivedbrak, lot--LOTTABLE02, lottable01, lottable07, lottable08
					from #receiptdetail
					where id= @rdid
				update #receiptdetail set
					qty = 0, qtyreceived = 0, qtyreceivedbrak = 0
					where id = @rdid
			end
	end

print 'есть полностью неудовлетворенные строки ЗЗ'

insert into #podetailresult (pokey, sku, storerkey, qtyordered, QTYRECEIVED, QTYREJECTED, lot)-- lottable02)
select pokey, sku, storerkey, qty, 0, 0, lot/*@bs*/ from #podetail where qty != 0

--select '#podetail', * from #podetail
--select '#podetailresul', * from #podetailresult where sku = '38183'
--select * from #receiptdetail

 --вставка результатов в ЗЗ
while (exists(select * from #podetailresult))
	begin
		select distinct top(1) @pokey = pokey from #podetailresult
		
		select @polinenumber = MAX(POLINENUMBER) from wh1.PODETAIL where POKEY = @pokey
									insert into wh1.PODETAIL (
										pokey,
										POLINENUMBER,
										QTYORDERED,-- ожидаемое по ЗЗ
										qtyadjusted, -- ожидаемое по строке
										QTYRECEIVED, -- принятое Н+Б
										QTYREJECTED, -- принятое Б
										SKU,
										SKUDESCRIPTION,
										STORERKEY,
										SUSR2,
										--SUSR4,
										SUSR5,
										PACKKEY,
										UOM)
		select 
			@pokey pokey,
			right('0000'+cast((pdr.ID+@polinenumber) as varchar(20)),5) polinenumber,
			0,
			pdr.qtyordered, --ожидаемое количство
			pdr.QTYRECEIVED, --принятое включая брак
			pdr.QTYREJECTED, --принятое брак
			pdr.sku,
			left(s.DESCR,60), -- в wh1.PoDetail - skudescription 60 символов, если будет больше, будет ошибка и файл в аналит не уйдет.
			pdr.storerkey,
			--l.LOTTABLE02, --case when isnull(l.LOTTABLE02,@bs) = @bs OR isnull(l.LOTTABLE02,@bs) = @bsanalit,
			case when isnull(l.LOTTABLE02,'') = '' then @bsanalit else l.LOTTABLE02 end,
			l.LOT,
			isnull(l.LOTTABLE01,'STD'),
			--pdr.lottable02,
			--rd.lottable04,
			--rd.lottable05,
			--pdr.lottable01, --PACKKEY,
			'EA'
			from #podetailresult pdr join wh1.sku s on pdr.sku = s.SKU and pdr.storerkey = s.storerkey
				left join #receiptdetail rd on rd.sku = pdr.sku and rd.storerkey = pdr.storerkey and pdr.lot =  rd.lot --pdr.LOTTABLE02 = rd.LOTTABLE02
				left join wh1.LOTattribute l on pdr.lot = l.lot
			where pdr.pokey = @pokey
			--and pdr.sku = '38183'
		
		delete from #podetailresult where @pokey = pokey 
	end

print 'выбираем номера ЗЗ для пуо'
	--insert into #pokey select pokey from wh1.PO where OTHERREFERENCE = @receiptkey order by POKEY
	select pokey into #pokey from wh1.PO where OTHERREFERENCE = @receiptkey order by POKEY

print 'обрабатываем поочередно все ЗЗ'
	while 0 < (select count (pokey) from #pokey)
		begin
			select top(1) @pokey = pokey from #pokey
			
			select 
				'RECEIPTCONFIRM' filetype,
				p.STORERKEY storerkey,
				p.OTHERREFERENCE receiptkey,
				p.EXTERNPOKEY externpokey,
				p.POKEY pokey,
				p.POTYPE potype,
				p.SUSR2 susr2,
				p.SUSR3 susr3,
				p.NOTES notes,
				p.SELLERNAME sellername,
				p.VESSEL vessel,
				r.RECEIPTDATE receiptdate,
				r.CLOSEDDATE closedate,
				pd.SKU sku,
				--pd.QTYORDERED qty,
				pd.QTYADJUSTED - pd.QTYRECEIVED qtyrejected,
				pd.QTYADJUSTED qtyexpected,--оюиаемое
				pd.QTYRECEIVED qtyreceived,--принятое
				pd.QTYREJECTED qtyreceivedbrak,--брак
		--		0 qtyrejected,
				l.LOTTABLE01 packkey,
				case when l.LOTTABLE02 = @bs then @bsanalit else l.LOTTABLE02 end attribute02, --замена кода безсерийного товара инфор на код аналита
				convert(varchar(20),l.LOTTABLE04,120) attribute04,
				convert(varchar(20),l.LOTTABLE05,120) attribute05,
				p.BUYERADDRESS4 numberdoc
			from wh1.PO p join wh1.PODETAIL pd on p.POKEY = pd.pokey
				join wh1.RECEIPT r on r.RECEIPTKEY = p.OTHERREFERENCE
				left join wh1.LOTATTRIBUTE l on l.LOT = pd.susr5
			where p.POKEY = @pokey and pd.QTYORDERED = 0
			
			delete from #pokey where POKEY = @pokey
		end
		
-- После успешной выдачи результата дата-адаптеру
print '9.1. обновление susr5 в переданном ПУО'
	update r set r.susr5 = '9' from wh1.receipt r where r.receiptkey = @receiptkey

print '9.2. обновление статуса ЗЗ'
	update wh1.po set [status] = '11' where otherreference = @receiptkey

	update pod set [status] = '11' 
		from wh1.po po, wh1.podetail pod 
		where po.otherreference = @receiptkey and po.pokey = pod.pokey

endproc:
if @send_error = 1
	begin
		print 'отправляем сообщение об ошибке по почте'
		print @msg_errdetails
		set @source = 'proc_DA_CompositeASNClose'
		insert into DA_InboundErrorsLog (source,msg_errdetails) values (@source,@msg_errdetails)		
		exec app_DA_SendMail @source, @msg_errdetails
	end


	
--select * from #receiptdetail
--select * from #podetail where sku = '38183'
--select * from #podetailresult where sku = '38183'

--drop table #receiptdetail
--drop table #podetail
--drop table #podetailresult
--drop table #skuqty
--drop table #pokey



