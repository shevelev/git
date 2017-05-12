ALTER PROCEDURE [dbo].[proc_DA_Receipt]
--(
--	@wh varchar(10)
--)
as  
--############################################################### ПУО
print '1.1. чтение всех необработанных заголовков документов flag = 0'
	select * into #DA_ReceiptHead from DA_ReceiptHead where flag = 0
print '1.2. чтение всех деталей документов с flag = 0'
	select rh.id rhid, identity(int,1,1) receiptlinenumber, /*cast(null as varchar(5)) externlineno,*/ rd.* into #DA_ReceiptDetail from DA_ReceiptDetail rd join #DA_ReceiptHead rh on rd.externreceiptkey = rh.externreceiptkey and rd.flag = 0

print '2. выбор уникальных наиболее поздних документов среди одинаковых'
print '2.1. выставляем всем записям заголовка признак "ошибка"'
	update #DA_ReceiptHead set flag = 3, because = 'повторяющийся в пакете импорта документ'
	select drh.externreceiptkey, max (drh.id) id into #da_uni
		from #DA_ReceiptHead drh left join #DA_ReceiptHead drs on drh.externreceiptkey = drs.externreceiptkey
		group by drh.externreceiptkey
print '2.2. выставляем записям деталей признак "необработан"'
	update drh set drh.flag = 0, drh.because = ''
		from #DA_ReceiptHead drh join #da_uni du on drh.id = du.id
print '2.3. выставляем всем записям деталей признак "ошибка"'
	update #DA_ReceiptDetail set flag = 3, because = 'повторяющийся в пакете импорта документ' where flag = 0
print '2.4. выставляем записям деталей признак "необработан"'
	update drd set drd.flag = 0, drd.because = ''
		from #DA_ReceiptDetail drd join #DA_ReceiptHead drh on drd.rhid = drh.id where drh.flag = 0

print '3. изменение flag для документов временной таблицы, имеющихся в базе при условии @allowupdate = 0 или status >= 11'
print '3.0. проверка на разрешенность обновления документов'
	declare @allowUpdate int
	select @allowUpdate = allowUpdate from dbo.DA_MessageTypes where MessageKey = 'ASN'

print '3.1. обновление flag = 3 в заголовке повторяющегося доумента'
	update drh set drh.flag = 3, drh.because = 'обновление документов запрещено (повторяющийся документ)'
		from #DA_ReceiptHead drh join wh1.Receipt r on drh.externreceiptkey = r.externreceiptkey
		where (@allowupdate = 0) and drh.flag = 0

print '3.2. отбрасывание документов с пустым полем TYPE'
	update drh set drh.flag = 3, drh.because = 'незаполнено поле type'
		from #DA_ReceiptHead drh where drh.flag = 0 and (drh.[type] is null or rtrim(ltrim(drh.[type])) = '')

print '3.3. обновление flag = 3 в деталях документа'
	update drd set drd.flag = 3, drd.because = 'ошибка в заголовке документа'
		from #DA_ReceiptDetail drd join #DA_ReceiptHead drh on drd.rhid = drh.id
		where drh.flag = 3 and drd.flag = 0

print '4. выполняем проверку входных данных'
--print '4.1.1. проверяем наличие отсутвующих контрагентов или перевозчиков в справочнике'
--	update drh set drh.flag = 2, drh.because = 'отсутвует carriercode и/или storerkey в справочниках'
--		from #DA_ReceiptHead drh where (not drh.storerkey in (select storerkey from wh1.storer) or not drh.carrierkey in (select storerkey from wh1.storer) and drh.flag = 0 ) and drh.flag = 0
print '4.1.2. проверяем наличие неверного кода склада NAV'
--	update drh set drh.susr3 = 'ЦС+КОНС'
--		from #DA_ReceiptHead drh where not drh.susr3 in (select hostzone from wh1.hostzones) and drh.flag = 0
	update drd set drd.flag = 2, drd.because = 'неверный код склада NAV/1C'
		from #DA_ReceiptHead drh join #DA_ReceiptDetail drd on drh.externreceiptkey = drd.externreceiptkey
		where drh.flag = 2

print '4.2. проверяем наличие отсутвующих контрагентов в справочнике'
	update drd set drd.flag = 2, drd.because = 'отсутвует storerkey в справочнике storer'
		from #DA_ReceiptDetail drd where not drd.storerkey in (select storerkey from wh1.storer) and drd.flag = 0

print '4.3. проверяем наличие отсутвующих товаров в справочнике'
	update drd set drd.flag = 2, drd.because = 'отсутвует товар для владельца в справочнике sku'
		from #DA_ReceiptDetail drd where not drd.sku + drd.storerkey in (select sku + storerkey from wh1.sku) and drd.flag = 0


print '3.7.1. изменение флага на документах с ошибочными позициями'
	update drh set drh.flag = 2, because = 'в одной из строк документов есть отсутвующий товар'
		from #DA_ReceiptDetail drd join #DA_ReceiptHead drh on drh.id = drd.rhid
		where drd.flag > 1 and drh.flag = 0
print '3.7.2. перемещаем в некорректные всех деталей из некорректных заказов'
	update drd set drd.flag = 2, drd.because = 'в одной из строк документа есть отсутсвующий товар.'
		from #DA_ReceiptHead drh join #DA_ReceiptDetail drd on drh.id = drd.rhid
		where drh.flag = 2 and drd.flag = 0


print '4.4. отбрасывание деталей с нулевым количеством'
	update drd set drd.flag = 2, drd.because = 'нулевое количество товара в позиции'
		from #DA_ReceiptDetail drd where drd.flag = 0 and drd.qtyexpected = 0

--select * from #da_receipthead
--select * from #da_receiptdetail

print '5. добавление новых документов'
print '5.1. формирование внутреннего номера документа RECEIPTKEY'
	declare @receiptkey varchar(10)
	exec dbo.DA_GetNewKey 'wh1','receipt',@receiptkey output

print '5.2. добавление заголовка документа'
	insert into wh1.Receipt (receiptkey,     storerkey,     externreceiptkey,     [type],     carrierkey, carriername,     receiptdate,     susr3,     susr4, status)
		select				@receiptkey, drh.storerkey, drh.externreceiptkey, drh.[type], drh.carrierkey,  st.company, drh.receiptdate, drh.susr3, drh.susr4,    '0'
		from #DA_ReceiptHead drh --join wh1.hostzones sxt on drh.susr3 = sxt.hostzone
			left join wh1.storer st on st.storerkey = drh.carrierkey
			where drh.flag = 0

print '5.3. добавление деталей документа'
	insert into wh1.ReceiptDetail (receiptkey,                                         receiptlinenumber,     externreceiptkey,     externlineno,     storerkey,     sku,     qtyexpected,         packkey,            UOM,   toloc, status)
		select					 r.receiptkey, right('0000'+convert(varchar(5),drd.receiptlinenumber),5), drd.externreceiptkey, drd.externlineno, drd.storerkey, drd.sku, drd.qtyexpected, s.rfdefaultpack, s.rfdefaultuom,  'DOCK',    '0'
		from #DA_ReceiptDetail drd join #DA_ReceiptHead drh on drd.rhid = drh.id
			join wh1.Receipt r on r.externreceiptkey = drh.externreceiptkey
			join wh1.sku s on s.sku = drd.sku and s.storerkey = drd.storerkey
		where drd.flag = 0 and drh.flag = 0

print '6. обновление документов в обменных таблицах'
print '6.1. обновление flag в 2, при условии наличия в документе позиции с нулевым количеством'
	update drh set drh.flag = 2, drh.because = 'ошибка в деталях документа'
		from #DA_ReceiptHead drh join #DA_ReceiptDetail drd on drh.id = drd.rhid
		where drd.flag = 2
print '6.2. удаление заголовка документ в временной таблице flag = 1 flag = 0'
	delete from DA_ReceiptHead
		from DA_ReceiptHead rh join #DA_ReceiptHead drh on rh.id = drh.id
		where drh.flag = 0 or drh.flag = 1
print '6.3. удаление деталей документа в временной таблице flag = 1 flag = 0'
	delete from DA_ReceiptDetail
		from #DA_ReceiptDetail drd join DA_ReceiptDetail rd on rd.id = drd.id
		where drd.flag = 0 or drd.flag = 1
--	delete from DA_ReceiptDetail
--		from #DA_ReceiptHead drh join #DA_ReceiptDetail drd on drh.id = drd.rhid
--			join DA_ReceiptDetail rd on rd.id = drd.id
--		where ((drh.flag = 0 or drh.flag = 1) and (drd.flag = 0 or drd.flag = 1)) or (drh.flag = 2 and (drd.flag = 1 or drd.flag = 0))
print '6.4. обновление flag в заголовке в обменной таблице'
	update rh set rh.flag = drh.flag, rh.because = drh.because
		from DA_ReceiptHead rh join #DA_ReceiptHead drh on rh.id = drh.id
		where drh.flag = 2 or drh.flag = 3
print '6.5. обновление flag в деталях в обменной таблице'
	update rd set rd.flag = drd.flag, rd.because = drd.because
		from DA_ReceiptDetail rd join #DA_ReceiptDetail drd on rd.id = drd.id
		where drd.flag = 2 or drd.flag = 3

print '7. отправляем уведомления о возникновении ошибочных данных'
	if (select count (flag) from #DA_ReceiptDetail where flag > 1) != 0
		begin
			declare @body varchar(max)
			set @body = 'Date: ' + convert(varchar(10),getdate(),21) + char(10) + char(13)
			select @body = @body + 'ExternReceiptkey: ' + drh.externreceiptkey + '. Причина: ' + drh.because + char(10) + char(13) from #DA_ReceiptHead drh where drh.flag = 2 or drh.flag = 3
			exec app_DA_SendMail 'ASN IN.', @body
		end

drop table #da_uni
drop table #DA_receiptDetail
drop table #DA_receiptHead

