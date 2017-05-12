-- ПОДТВЕРЖДЕНИЕ ПУО
ALTER PROCEDURE [dbo].[proc_DA_ReceiptClose](
	@wh varchar(30),
	@transmitlogkey varchar (10))
as

-- Ошибки должны прерывать процедуру. Если возникли ошибки, п. 8 
-- не должен выполниться (не помечать ПУО как "выгружено в хост систему")
SET XACT_ABORT ON
SET NOCOUNT ON

declare @receiptkey varchar(10) 
--set @receiptkey = '0000006969'



declare  @receiptlinenumber varchar(5)
declare @polinenumber varchar(5)
declare @pokey varchar(10)
declare @bs varchar(3) set @bs = 'б\с'
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
	--qtyordered float NULL,
	--closedate varchar(10) NULL,
	--susr1 varchar(30) NULL,
	--susr2 varchar(30) NULL,
	--susr3 varchar(30) NULL,
	lottable04 datetime NULL,
	lottable05 datetime NULL,	
	LOTTABLE02 varchar(50) null
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
	--susr2 varchar(30) NULL,
	--susr3 varchar(30) NULL,
	susr4 varchar(30) NULL,
	susr5 varchar(30) NULL,	
	LOTTABLE02 varchar(50) null
)

create table #skuqty (
	sku varchar(50) NULL,
	storerkey varchar(15) NULL,	
	qty float NULL
)

select * into #podetailresult from #podetail


print '0. проверка повторного закрытия ПУО'
	select @receiptkey = tl.key1 from wh1.transmitlog tl where tl.transmitlogkey = @transmitlogkey


	if 0 < (select count(*) from wh1.receipt r where r.receiptkey=@receiptkey and r.susr5='1')
	begin
		raiserror ('Повторное закрытие ПУО = %s',16,1, @receiptkey)
		goto endproc
	end	

-- выборка приходов
insert into #receiptdetail 
select
SKU, storerkey,
0,
sum(QTYRECEIVED) qty,
sum(case when toloc not like 'brak%' then QTYRECEIVED else 0 end) qtyreceived, 
sum(case when toloc like 'brak%' then qtyreceived else 0 end) qtyreceivedbrak,lottable04, lottable05,
case when isnull(lottable02 ,'') = '' then @bs else lottable02 end lottable02
from wh1.RECEIPTDETAIL where qtyexpected = 0 and RECEIPTKEY = @receiptkey
group by SKU, STORERKEY, lottable04, lottable05, lottable02
order by sku 

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
'',
@bs
from wh1.PODETAIL pd join wh1.PO p on p.POKEY = pd.POKEY where p.OTHERREFERENCE = @receiptkey
group by pd.SKU, pd.STORERKEY, pd.pokey, pd.storerkey
order by pd.POKEY--, pd.POLINENUMBER

-- общее количество товара
insert into #skuqty (sku, storerkey, qty)
select sku, storerkey, SUM(rd.qty) qty from #receiptdetail rd group by rd.sku, rd.storerkey

--select * from #receiptdetail --where sku = '1007'
--select * from #podetail-- where sku = '1007'




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
								insert into #podetailresult (sku, storerkey, pokey, qtyordered, QTYRECEIVED, QTYREJECTED,LOTTABLE02)
									select rd.sku, rd.storerkey, pd.pokey, @poqtyordered, @poqtyordered, @rdqtyreceivedbrak,rd.LOTTABLE02 
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
								insert into #podetailresult (sku, storerkey, pokey, qtyordered, QTYRECEIVED, QTYREJECTED,LOTTABLE02)
									select rd.sku, rd.storerkey, pd.pokey, @poqtyordered, @poqtyordered, @poqtyordered, rd.LOTTABLE02
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
								insert into #podetailresult (sku, storerkey, pokey, qtyordered, QTYRECEIVED, QTYREJECTED,LOTTABLE02)
									select rd.sku, rd.storerkey, pd.pokey, 
											case when (@poqtyordered > @skuqty) and (@skuqty = @rdqtyreceived+@rdqtyreceivedbrak) then @poqtyordered else @rdqtyreceived+@rdqtyreceivedbrak end, 
											@rdqtyreceived+@rdqtyreceivedbrak, @rdqtyreceivedbrak,rd.LOTTABLE02
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
								insert into #podetailresult (sku, storerkey, pokey, qtyordered, QTYRECEIVED, QTYREJECTED,LOTTABLE02)
									select rd.sku, rd.storerkey, pd.pokey, 
											case when (@poqtyordered > @skuqty) and (@skuqty = @rdqtyreceived+@rdqtyreceivedbrak) then @poqtyordered else @rdqtyreceived+@rdqtyreceivedbrak end, 
										@rdqtyreceived+@rdqtyreceivedbrak, @rdqtyreceived, rd.LOTTABLE02
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
				insert into #podetailresult (sku, storerkey, qtyordered, QTYRECEIVED, QTYREJECTED,LOTTABLE02)
					select sku, storerkey, 0, qty, qtyreceivedbrak, LOTTABLE02
					from #receiptdetail
					where id= @rdid
				update #receiptdetail set
					qty = 0, qtyreceived = 0, qtyreceivedbrak = 0
					where id = @rdid
			end
	end

--есть полностью неудовлетворенные строки ЗЗ

insert into #podetailresult (pokey, sku, storerkey, qtyordered, QTYRECEIVED, QTYREJECTED, lottable02)
select pokey, sku, storerkey, qty, 0, 0, @bs from #podetail where qty != 0

--select * from #podetailresult --where sku = '1007'
--select * from #receiptdetail

 --вставка результатов в ЗЗ
while (exists(select * from #podetailresult))
	begin
		select distinct top(1) @pokey = pokey from #podetailresult
		
		select @polinenumber = MAX(POLINENUMBER) from wh1.PODETAIL where POKEY = @pokey

									insert into wh1.PODETAIL (
										pokey,
										POLINENUMBER,
										QTYORDERED,
										qtyadjusted,
										QTYRECEIVED,
										QTYREJECTED,
										SKU,
										SKUDESCRIPTION,
										STORERKEY,
										SUSR2,
										SUSR4,
										SUSR5,
										PACKKEY,
										UOM)
		select 
			@pokey,
			right('0000'+cast((pdr.ID+@polinenumber) as varchar(20)),5),
			0,
			pdr.qtyordered, --ожидаемое количство
			pdr.QTYRECEIVED, --принятое включая брак
			pdr.QTYREJECTED, --принятое брак
			pdr.sku,
			s.DESCR,
			pdr.storerkey,
			pdr.lottable02,
			rd.lottable04,
			rd.lottable05,
			s.PACKKEY,
			'EA'
			from #podetailresult pdr join wh1.sku s on pdr.sku = s.SKU and pdr.storerkey = s.storerkey
				left join #receiptdetail rd on rd.sku = pdr.sku and rd.storerkey = pdr.storerkey and pdr.LOTTABLE02 = rd.LOTTABLE02
			where pdr.pokey=@pokey
		
		delete from #podetailresult where @pokey=pokey
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
				pd.PACKKEY packkey,
				pd.SUSR2 attribute02,
				convert(varchar(20),pd.SUSR4,120) attribute04,
				convert(varchar(20),pd.susr5,120) attribute05
				from wh1.PO p join wh1.PODETAIL pd on p.POKEY = pd.pokey
					join wh1.RECEIPT r on r.RECEIPTKEY = p.OTHERREFERENCE
				where p.POKEY = @pokey and pd.QTYORDERED = 0
			
			delete from #pokey where POKEY = @pokey
		end
		
-- После успешной выдачи результата дата-адаптеру
print '9.1. обновление susr5 в переданном ПУО'
	update r set r.susr5 = '1' from wh1.receipt r where r.receiptkey = @receiptkey

print '9.2. обновление статуса ЗЗ'
	update wh1.po set [status] = '11' where otherreference = @receiptkey

	update pod set [status] = '11' 
		from wh1.po po, wh1.podetail pod 
		where po.otherreference = @receiptkey and po.pokey = pod.pokey

endproc:

--select * from #receiptdetail
--select * from #podetail-- where sku = '1007'
--select * from #podetailresult --where sku = '1007'

drop table #receiptdetail
drop table #podetail
drop table #podetailresult
drop table #skuqty
drop table #pokey
