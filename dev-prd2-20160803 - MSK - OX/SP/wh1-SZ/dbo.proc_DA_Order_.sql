ALTER PROCEDURE [dbo].[proc_DA_Order]
as  
--############################################################### ЗАКАЗ НА ОТГРУЗКУ
print '1.1. чтение всех необработанных заголовков документов flag = 0'
	select * into ##DA_OrderHead from DA_OrderHead where flag = 0
print '1.2. чтение всех деталей документов с flag = 0'
	select oh.id ohid, identity(int,1,1) orderlinenumber, od.* into ##DA_OrderDetail from DA_OrderDetail od join ##DA_OrderHead oh on od.externorderkey = oh.externorderkey and od.flag = 0

print '2. выбор уникальных наиболее поздних документов среди одинаковых'
print '2.1. выставляем всем записям заголовка признак "ошибка"'
	update ##DA_OrderHead set flag = 3, because = 'повторяющийся в пакете импорта документ'
	select doh.externorderkey, max (doh.id) id into #da_uni
		from ##DA_OrderHead doh left join ##DA_OrderHead dos on doh.externorderkey = dos.externorderkey
		group by doh.externorderkey
print '2.2. выставляем записям заголовков признак "необработан"'
	update doh set doh.flag = 0, doh.because = ''
		from ##DA_OrderHead doh join #da_uni du on doh.id = du.id
print '2.3. выставляем всем записям деталей признак "ошибка"'
	update ##DA_OrderDetail set flag = 3, because = 'повторяющийся документ' where flag = 0
print '2.4. выставляем записям деталей признак "необработан"'
	update dod set dod.flag = 0, dod.because = ''
		from ##DA_OrderDetail dod join ##DA_OrderHead doh on dod.ohid = doh.id where doh.flag = 0

print '3. выполняем проверку входных данных'
--print '	-- изменение значения null на empty в поле ordergroupэ'
--	update ##DA_OrderHead set ordergroup = ''
--		where ordergroup is null
print '3.1. проверка на разрешенность обновления документов'
	declare @allowUpdate int
	select @allowUpdate = allowUpdate from dbo.DA_MessageTypes where MessageKey = 'SO'
print '3.1.0. внешний номер заказа не может быть равен consolidation'
	update ##DA_OrderHead set flag = 3, because = 'внешний номер заказа не может быть равен consolidation'
		where externorderkey = 'consolidation'
print '3.1.1. изменение flag на документах, существующих в базе при allowupdate = 0'
	update doh set doh.flag = 3, doh.because = 'изменение существующих документов запрещено (повторяющийся документ)'
		from ##DA_OrderHead doh join wh1.Orders o on doh.externorderkey = o.externorderkey
	where doh.flag = 0 and @allowUpdate = 0

--????????????????????????????????????????????????????????????
--print '3.1.2. проверка существования консолидированного заказа, если заказ уже был ранее в консолидации'
--	delete from oc 
--		from wh1.orders_c oc join ##DA_OrderHead doh on oc.externorderkey = doh.externorderkey
--		where doh.flag = 0 and not oc.orderkey in (select orderkey from wh1.orders where externorderkey = 'consolidation')
--	delete from odc
--		from wh1.orderdetail_c odc join ##DA_OrderHead doh on odc.externorderkey = doh.externorderkey
--		where doh.flag = 0 and not odc.orderkey in (select orderkey from wh1.orders where externorderkey = 'consolidation')
--????????????????????????????????????????????????????????????
			
print '3.1.2. изменение flag на документах, существующих в consolidation заказах'
	update doh set doh.flag = 3, doh.because = 'изменение существующих документов в консолидированном заказе - запрещено (повторяющийся документ)'
		from ##DA_OrderHead doh join wh1.Orders_c o on doh.externorderkey = o.externorderkey
	where doh.flag = 0 and @allowUpdate = 0

	update dod set dod.flag = 3, dod.because = 'ошибка в заголовке документа'
		from ##DA_OrderHead doh join ##DA_OrderDetail dod on doh.id = dod.ohid
	where doh.flag = 3 and dod.flag = 0

print '3.2. исключение деталей с отрицательным или 0 количеством'
	update ##DA_OrderDetail set flag = 2, because = 'отрицательное количество в строке заказа' where openqty <= 0

print '3.3. проверяем наличие отсутвующих контрагентов в справочнике'
	update doh set doh.flag = 2, doh.because = 'отсутсвует контрагент в справочнике storer'
		from ##DA_OrderHead doh where not doh.storerkey in (select storerkey from wh1.storer) and doh.flag = 0

print '3.4.1. проверяем наличие отсутвующих торговых точек в справочнике'
	update doh set doh.flag = 2, doh.because = 'отсутвует торговая точка в справочнике storer'
		from ##DA_OrderHead doh where not doh.consigneekey in (select storerkey from wh1.storer) and doh.flag = 0

print '3.4.2. проверяем наличие грузополучателя null (торговая точка)'
	update doh set doh.flag = 2, doh.because = 'незаполнена торговая точка consigneekey'
		from ##DA_OrderHead doh where (doh.consigneekey is null or rtrim(ltrim(doh.consigneekey)) = '') and doh.flag = 0
print '3.4.3. проверяем наличие покупателя null (плательщик)'
	update doh set doh.b_company = case when doh.b_company is null or rtrim(ltrim(doh.b_company)) = '' then '' else doh.b_company end
		from ##DA_OrderHead doh

print '3.4.1. проверяем наличие отсутвующих покупателей в справочнике'
	update doh set doh.flag = 2, doh.because = 'отсутвует покупатель в справочнике consigneekey'
		from ##DA_OrderHead doh where not doh.b_company in (select storerkey from wh1.storer) and doh.flag = 0 and doh.b_company != ''

print '3.5. проверяем наличие отсутвующих экспедиторов в справочнике'
	update doh set doh.flag = 2, doh.because = 'отсутвует экспедитор в справочнике storer'
		from ##DA_OrderHead doh where not doh.carriercode in (select storerkey from wh1.storer) and doh.flag = 0

print '3.6. перемещаем в некорректные всех деталей из некорректных заказов'
	update dod set dod.flag = 2, dod.because = 'ошибка в заголовке документа'
		from ##DA_OrderHead doh join ##DA_OrderDetail dod on doh.id = dod.ohid
		where doh.flag = 2 and dod.flag = 0

print '3.7. проверяем наличие отсутвующих товаров в справочнике'
	update dod set dod.flag = 2, dod.because = 'отсутвует товар в справочнике sku'
		from ##DA_OrderDetail dod where not dod.sku + dod.storerkey in (select sku + storerkey from wh1.sku) and dod.flag = 0


--print '3.7.1. изменение флага на документах с ошибочными позициями'
--	update doh set doh.flag = 2, because = 'в одной из строк документов есть отсутвующий товар'
--		from ##DA_OrderDetail dod join ##DA_OrderHead doh on doh.id = dod.ohid
--		where dod.flag > 1 and doh.flag = 0
--print '3.7.2. перемещаем в некорректные всех деталей из некорректных заказов'
--	update dod set dod.flag = 2, dod.because = 'в одной из строк документа есть отсутсвующий товар.'
--		from ##DA_OrderHead doh join ##DA_OrderDetail dod on doh.id = dod.ohid
--		where doh.flag = 2 and dod.flag = 0


print '3.8. вставка наименования покупателя в заголовок заказа'
	update doh set c_company = st.company
		from ##DA_OrderHead doh join wh1.Storer st on doh.consigneekey = st.storerkey

print '3.9. вставка наименования перевозчика в заголовок заказа'
	update doh set doh.carriername = st.company
		from ##DA_OrderHead doh join wh1.Storer st on doh.carriercode = st.storerkey	

print '3.10. вставка ИНН покупателя в заголовок заказа'
	update doh set doh.c_vat = st.vat
		from ##DA_OrderHead doh join wh1.Storer st on doh.consigneekey = st.storerkey	

print '3.11. вставка адресов в заголовок заказа'
	update doh set doh.c_address1 = st.address1, doh.c_address2 = st.address2, doh.c_address3 = st.address3, doh.c_address4 = st.address4
		from ##DA_OrderHead doh join wh1.Storer st on doh.consigneekey = st.storerkey

print '3.12. проверка есть ли в заказе хоть одна строка'
	if (select count (dod.id) from ##DA_Orderdetail dod join ##DA_OrderHead doh on doh.id = dod.ohid where dod.flag = 0) = 0
		begin
			print '3.12.1. в заказе нет ни одной верной строки'
			update doh set doh.flag = 2, doh.because = 'в заказе нет ни одной корректной строки'
				from ##DA_OrderHead doh 
			where doh.flag = 0
			goto nextstep
		end


print '3.9. формирование новой группы картонизации, стратегии для строки заказа'
update dod set dod.allocatestrategykey = ast.allocatestrategykey, dod.preallocatestrategykey = stg.preallocatestrategykey, dod.allocatestrategytype = ast.allocatestrategytype, 
dod.cartongroup = s.cartongroup + case when stxs.pallet is null or rtrim(ltrim(stxs.pallet)) = '' then '' else rtrim(ltrim(stxs.pallet)) end, dod.packkey = s.packkey, dod.shelflife = stxs.shelflife
--select s.strategykey + ltrim(rtrim(stxs.packtype)) strategy, s.cartongroup + case when stxs.pallet is null or rtrim(ltrim(stxs.pallet)) = '' then '' else stxs.pallet end cartongroup
	from ##DA_OrderHead doh join ##DA_OrderDetail dod on doh.id = dod.ohid -- связка шапки с деталями
		join wh1.sku s on dod.sku = s.sku and dod.storerkey = s.storerkey -- связка с таблицей sku для получения для товара cartongroup, и стратегии размещения
		join wh1.storer st on st.storerkey = case when doh.b_company is null or ltrim(rtrim(doh.b_company)) = '' then doh.consigneekey else doh.b_company end -- susr1 для покупателя (тип клиента)
		join wh1.storerxsku stxs on stxs.susr1 = st.susr1 and stxs.busr4 = s.busr4 -- минимальный запас по сроку годности, типа картонизации, 
		join wh1.strategy stg on stg.strategykey = (s.strategykey + case when ltrim(rtrim(stxs.packtype)) = '' or stxs.packtype is null then '' else stxs.packtype end) -- выбор полей для новой стратегии
		join wh1.allocatestrategy ast on ast.allocatestrategykey = stg.allocatestrategykey
	where dod.flag = 0 and doh.flag = 0

update dod set dod.flag = 2, dod.because = 'нет необходимой группы картонизации и/или стратегии'
	from ##DA_OrderDetail dod where dod.allocatestrategykey is null or rtrim(ltrim(dod.allocatestrategykey)) = ''

print '4.0. проверка наличия добавленных заказов'
	if (select count(externorderkey) from ##DA_OrderHead where flag = 0) = 0 
		begin
			print '4.1. Добавленных заказов нет'
		end
	else
		begin
			print '4.2. Есть добавленный заказ. Обрабатываем.'
			exec app_DA_OrderIn
		end

nextstep:
print '5. удаление документов'
print '5.1. изменение flag = 2 в шапках ошибочных документов'
	update doh set doh.flag = 2, doh.because = case when doh.because is null or doh.because = '' then 'ошибка в деталях документа' else doh.because end
		from ##DA_OrderHead doh join ##DA_OrderDetail dod on doh.id = dod.ohid
		where dod.flag = 2 or dod.flag = 3
print '5.2.1. удаление заголовков'
	delete from DA_OrderHead
		from DA_OrderHead oh join ##DA_OrderHead doh on oh.id = doh.id 
		where doh.flag = 0 or doh.flag = 1
print '5.2.2. удаление деталей'
	delete from DA_OrderDetail
		from DA_OrderDetail od join ##DA_OrderDetail dod on od.id = dod.id
			where dod.flag = 0 or dod.flag = 1

print '5.3.1 изменение Flag на заголовки в обменной таблице'
	update o set o.flag = doh.flag, o.because = doh.because
		from ##DA_OrderHead doh join DA_OrderHead o on o.externorderkey = doh.externorderkey
		where o.flag = 0 -- для сохранения предыдущего кода ошибки
print '5.3.2. изменение Flag и все рассчитанные значения на детали в обенной таблице'
	update od set od.flag = dod.flag, od.because = dod.because,
		od.allocatestrategykey = dod.allocatestrategykey,
		od.preallocatestrategykey = dod.preallocatestrategykey,
		od.allocatestrategytype = dod.allocatestrategytype, 
		od.cartongroup = dod.cartongroup,
		od.packkey = dod.packkey
		from ##DA_OrderDetail dod join DA_OrderDetail od on od.id = dod.id

print '6. отправляем уведомления о возникновении ошибочных данных'
	if (select count (flag) from ##DA_OrderHead where flag > 1) > 0
		begin
			declare @body varchar(max)
			set @body = 'Date: ' + convert(varchar(10),getdate(),21) + char(10) + char(13)
			select @body = @body + 'ExternOrderkey: ' + drh.externorderkey + '. Причина: ' + drh.because + char(10) + char(13) from ##DA_OrderHead drh where drh.flag > 1
			exec app_DA_SendMail 'ORDER.', @body
		end

drop table #da_uni
drop table ##DA_OrderDetail
drop table ##DA_OrderHead

