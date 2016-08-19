--################################################################################################
--         процедура обрабатывает импортируемый заказ на отгрузку по установленной логике
--################################################################################################
ALTER PROCEDURE [dbo].[app_DA_OrderIn] 
AS
declare @orderkey varchar (10), -- заказ
		@storerkey varchar (15), -- код владельца
		@carriercode varchar (15), -- код перевозчика/экспедитора
		@consigneekey varchar (15), -- код торговой точки
		@typework int, -- тип обработки
		@wavekey varchar (10), -- номер волны
		@wavedetailkey varchar (10), -- номер строки волны
		@wavedescr varchar (15), -- описание волны
		@qtyorderwave int, -- количество заказов в автоматически создаваемой волне
--		@dispatchcasepickmethod varchar (10), -- метод распределения задач отбор ящика
		@Load varchar (10), -- необходимость формирования загрузок
		@loadid varchar (10), -- номер загрузки
		@loadstopid int, -- идентификатор стопа (остановки маршрута) в загрузке
		@loadorderdetailid int, -- идентификатор строки с заказом в загрузке
		@stop int, -- номер стопа в загрузке
		@carriername varchar (45), -- ниаменование перевозчика
		@requestedshipdate varchar(10), -- планируемая дата отгрузки
		@b_company varchar (15) -- код покупателя
--		@Return varchar (30) -- точка возврата

--set @dispatchcasepickmethod = '1'
print '>>> app_DA_OrderIn >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
print 'DAOI.1.x. определение входных данных для распределения заказов'
	select	@storerkey = case when storerkey is null or ltrim(rtrim(storerkey)) = '' then '' else ltrim(rtrim(storerkey)) end, 
			@carriercode = case when carriercode is null or ltrim(rtrim(carriercode)) = '' then '' else ltrim(rtrim(carriercode)) end, 
			@consigneekey = case when consigneekey is null or ltrim(rtrim(consigneekey)) = '' then '' else ltrim(rtrim(consigneekey)) end,
			@requestedshipdate = case when requestedshipdate is null then '' else convert(varchar(10),requestedshipdate,21) end,
			@b_company = case when b_company is null or ltrim(rtrim(b_company)) = '' then consigneekey else ltrim(rtrim(b_company)) end
		from ##DA_OrderHead where flag = 0

print 'DAOI.2.x. определение типа обработки заказа'
	select @typework = bt.wavetype from wh1.businesstypes bt
		where bt.storerkey = @storerkey
print 'Orderkey: ' + case when convert(varchar(10),@orderkey) is null then '' else convert(varchar(10),@orderkey) end + '. CarrierCode: ' + case when @carriercode is null then '' else @carriercode end + '. Consigneekey: ' + case when @consigneekey is null then '' else @consigneekey end + '. Storerkey:' + case when @storerkey is null then '' else @storerkey end + '. typework:' + case when convert(varchar(10),@typework) is null then '' else convert(varchar(10),@typework) end + '.'

	if @typework = 1
		begin
			print 'DAOI. тип обработки 1'
			if (select ltrim(rtrim(upper(susr1))) from wh1.storer where storerkey = @b_company) = 'ОБЫЧНЫЙ'
				begin
					print 'DAOI.5.1.3. обычный клиент. b_company: ' + @b_company
					if @carriercode = ''
						begin
							print 'DAOI.5.1.4. Перевозчик незаполнен.'
							print 'DAOI.5.1.5.1. формирование внутреннего номера документа ORDERKEY'
							exec dbo.DA_GetNewKey 'wh1','order',@orderkey output
							print 'DAOI.5.1.5.2. добавление заголовка документа'
							insert into wh1.orders (orderkey,  storerkey, externorderkey, [type],  consigneekey,  carriercode, intermodalvehicle, requestedshipdate,         deliveryplace,  deliveryadr, susr3, susr4, c_company,  b_company, transportationmode, carriername, c_vat, c_address1, c_address2, c_address3, c_address4,   door)
								select			   @orderkey, @storerkey, externorderkey, [type], @consigneekey, @carriercode,      @carriercode, requestedshipdate, left(deliveryaddr,30), deliveryaddr, susr3, susr4, c_company, @b_company,                '0', carriername, c_vat, c_address1, c_address2, c_address3, c_address4, 'DOCK'
								from ##DA_OrderHead where flag = 0
							print 'DAOI.5.1.5.3. добавление деталей документа'
							insert into wh1.orderdetail (orderkey, orderlinenumber,                             externorderkey,     externlineno,     storerkey,     sku, originalqty,     openqty,  uom,     allocatestrategykey,     preallocatestrategykey,     allocatestrategytype,     cartongroup,     packkey,     shelflife)
								 select @orderkey, right('0000'+convert(varchar(5),dod.orderlinenumber),5), dod.externorderkey, dod.externlineno, dod.storerkey, dod.sku, dod.openqty, dod.openqty, 'EA', dod.allocatestrategykey, dod.preallocatestrategykey, dod.allocatestrategytype, dod.cartongroup, dod.packkey, dod.shelflife
								from ##DA_OrderHead doh join ##DA_OrderDetail dod on doh.id = dod.ohid
								where doh.flag = 0 and dod.flag = 0 
						end	
					else
						begin -- поиск консолидированного заказа
							print 'DAOI.5.1.4. перевозчик заполнен. Carriercode: ' + @Carriercode + '. Дата отгрузки: '+@requestedshipdate + '. B_Company ' + @b_company+'. Consigneekey '+@consigneekey

							select @orderkey = o.orderkey
								from wh1.orders o join wh1.storer s on o.b_company = s.storerkey
								where o.externorderkey = 'consolidation' 
									and o.status < '11' 
									and o.carriercode = @carriercode 
									and convert(varchar(10),o.requestedshipdate,21) = @requestedshipdate
									and ltrim(rtrim(upper(s.susr1))) = 'ОБЫЧНЫЙ'

							if @orderkey is null or rtrim(ltrim(@orderkey)) = ''
								begin
									print 'DAOI.5.1.5. консолидированного заказа с датой отгрузки '+@requestedshipdate+' нет. создаем новый.'
									print 'DAOI.5.1.5.1. формирование внутреннего номера документа ORDERKEY'
									exec dbo.DA_GetNewKey 'wh1','order',@orderkey output
									
									print 'DAOI.5.1.5.2. app_DA_OrderCons ' + @Orderkey + ', new'
									exec app_DA_OrderCons @Orderkey, 'new'

									set @Load = 'yes'
									set @wavedescr = 'consolidation'
									exec app_DA_Waves null, @wavedescr, @orderkey, @carriercode, 'new' 
									--goto NewWave
								end
							else
								begin
									print 'DAOI.5.1.5. консолидированный заказ есть. добавляем в него строки. или объеденяем если товар+владелец уже есть'
--									print 'DAOI.5.1.5.2. app_DA_OrderCons ' + @Orderkey + ', detail'
									exec app_DA_OrderCons @Orderkey, 'detail'
								end
						end
				end
			else
				begin
					print 'DAOI.5.1.3. необычный клиент. b_Company: ' + @b_company+'. Consigneekey: '+@consigneekey
					-- поиск конслидированного заказа
					select @orderkey = o.orderkey
						from wh1.orders o
						where o.externorderkey = 'consolidation' 
							and o.status < '11' 
							and o.b_company = @b_company 
							and convert(varchar(10),requestedshipdate,21) = @requestedshipdate
							and o.consigneekey = @consigneekey
							and	o.carriercode = @carriercode

					if @orderkey is null or rtrim(ltrim(@orderkey)) = ''
						begin
							print 'DAOI.5.1.5. консолидированного заказа с планируемой датой отгрузки '+@requestedshipdate+' нет. создаем новый.'
							print 'DAOI.5.1.5.1. формирование внутреннего номера документа ORDERKEY'
							exec dbo.DA_GetNewKey 'wh1','order',@orderkey output

							print 'DAOI.5.1.5.2. app_DA_OrderCons ' + @Orderkey + ', new'
							exec app_DA_OrderCons @Orderkey, 'new'

							set @Load = 'yes'
							set @wavedescr = 'consolidation'
							exec app_DA_Waves null, @wavedescr, @orderkey, @carriercode, 'new'
--							goto NewWave
						end
					else
						begin
							print 'DAOI.5.1.5. консолидированный заказ есть. добавляем в него строки. или объеденяем если товар+владелец уже есть'

							print 'DAOI.5.1.5.2. app_DA_OrderCons ' + @Orderkey + ', detail'
							exec app_DA_OrderCons @Orderkey, 'detail'
						end
				end
		end	
	else
		begin
			print 'DAOI. тип обработки 2'
			print 'DAOI.4. добавление документов'
			print 'DAOI.4.1. формирование внутреннего номера документа ORDERKEY'
			exec dbo.DA_GetNewKey 'wh1','order',@orderkey output

			print 'DAOI.4.2. добавление заголовка документа'
			insert into wh1.orders (orderkey,  storerkey, externorderkey, [type],  consigneekey,  carriercode, intermodalvehicle, requestedshipdate,         deliveryplace,  deliveryadr, susr3, susr4, c_company,  b_company, transportationmode, carriername, c_vat, c_address1, c_address2, c_address3, c_address4,   door)
				select			   @orderkey, @storerkey, externorderkey, [type], @consigneekey, @carriercode,      @carriercode, requestedshipdate, left(deliveryaddr,30), deliveryaddr, susr3, susr4, c_company, @b_company,                '0', carriername, c_vat, c_address1, c_address2, c_address3, c_address4, 'DOCK'
				from ##DA_OrderHead where flag = 0

			print 'DAOI.4.3. добавление деталей документа'
			insert into wh1.orderdetail (orderkey, orderlinenumber,                             externorderkey,     externlineno,     storerkey,     sku, originalqty,     openqty,  uom,     allocatestrategykey,     preallocatestrategykey,     allocatestrategytype,     cartongroup,     packkey,       shelflife)
									select o.orderkey, right('0000'+convert(varchar(5),dod.orderlinenumber),5), dod.externorderkey, dod.externlineno, dod.storerkey, dod.sku, dod.openqty, dod.openqty, 'EA', dod.allocatestrategykey, dod.preallocatestrategykey, dod.allocatestrategytype, dod.cartongroup, dod.packkey, dod.shelflife
				from ##DA_OrderHead doh join ##DA_OrderDetail dod on doh.id = dod.ohid
								join wh1.orders o on o.externorderkey = doh.externorderkey
				where doh.flag = 0 and dod.flag = 0

			print 'DAOI.4.4. определение наименования перевозчика'
			select @carriername = carriername
				from ##DA_OrderHead where flag = 0

			print 'DAOI.5.2. тип обработки 2'
			if (select ltrim(rtrim(upper(susr1))) from wh1.storer where storerkey = @b_company) = 'ОБЫЧНЫЙ'
				begin
					print 'DAOI.5.2.3. обычный клиент. b_company: ' + @b_company
					if @carriercode = ''
						begin
							print 'DAOI.5.2.4. перевозчик незадан.'
							-- поиск волны
							select distinct @wavekey = w.wavekey
								from wh1.wave w join wh1.wavedetail wd on w.wavekey = wd.wavekey
									join wh1.orders o on o.orderkey = wd.orderkey
								where w.descr = '' and w.status = '0'
--									and o.consigneekey = @consigneekey -- объединение по контрагентам
									and o.storerkey = @storerkey and convert(varchar(10),o.requestedshipdate,21) = @requestedshipdate
								group by w.wavekey
								having max (o.status) <= '11' -- проверка наличия запущенных заказов
							if @wavekey is null or ltrim(rtrim(@wavekey)) = '' set @wavekey = ''
							-- максимальное количество заказов в волне
							select @qtyorderwave = convert(int,description) from wh1.codelkup where listname = 'sysvar' and code = 'qtyorderw'
							if @wavekey = ''
								begin
									print 'DAOI.5.2.5. волны c пустым DESCR и заказапи с планируемой датой отгрузки '+@requestedshipdate+' нет'
									set @wavedescr = ''
									exec app_DA_Waves null, @wavedescr, @orderkey, '', 'new'--:
--									goto NewWave
								end
							else
								begin
									print 'DAOI.5.2.5. волна c пустым DESCR и планируемой датой отгрузки '+@requestedshipdate+' есть. Wavekey: ' + @Wavekey
--									set @Return = 'CheckQtyOrderWave'
--									goto NewWaveDetailKey
--								CheckQtyOrderWave:
									exec app_DA_Waves @wavekey, null, @orderkey, @carriercode,'detail'

									if (select count (wd.serialkey) from wh1.wavedetail wd where wd.wavekey = @Wavekey) = @qtyorderwave
										begin
											print 'DAOI.5.2.6. в волне максимальное количество заказов. Descr = ' + @Wavekey
											update wh1.wave set descr = @Wavekey where wavekey = @wavekey
										end
								end
						end
					else
						begin
							print 'DAOI.5.2.4. перевозчик задан. CarrierKey: ' + @carriercode
							-- поиск волны
							select distinct @wavekey = w.wavekey 
								from wh1.wave w join wh1.wavedetail wd on w.wavekey = wd.wavekey
									join wh1.orders o on o.orderkey = wd.orderkey 
								where w.descr = @carriercode and w.status = '0'
--									and o.consigneekey = @consigneekey -- объединение по контрагенту
									and o.storerkey = @storerkey and convert(varchar(10),o.requestedshipdate,21) = @requestedshipdate
								group by w.wavekey
								having max (o.status) <= '11' -- проверка наличия запущенных заказов
							if @wavekey is null or ltrim(rtrim(@wavekey)) = '' set @wavekey = ''
							if @wavekey = ''
								begin 
									print 'DAOI.5.2.5. незапущенной волны для перевозчика нет'
									set @wavedescr = @carriercode
									set @Load = 'yes'
									exec app_DA_Waves null, @wavedescr, @orderkey, @carriercode,'new'

--									goto NewWave
								end
							else
								begin 
									print 'DAOI.5.2.5. незапущенная волна для перевозчика есть. Wavekey: ' + @Wavekey
									set @Load = 'yes'
									exec app_DA_Waves @wavekey, null, @orderkey, @carriercode, 'detail'
--									goto NewWaveDetailKey
								end
						end
				end
			else 
				begin
					print 'DAOI.5.2.3. необычный клиент. b_Company: ' + @b_Company
					
--					if @carriercode != ''
--						begin
--							print 'DAOI.5.2.3.1. перевозчик задан. Carriercode: ' + @Carriercode
--
--						end
--					else
--						begin
--							print 'DAOI.5.2.3.1. перевозчик не задан.'
--							-- поиск незапущенной волны
--							select @wavekey = w.wavekey 
--								from wh1.wave w join wh1.wavedetail wd on w.wavekey = wd.wavekey
--									join wh1.orders o on o.orderkey = wd.orderkey
----								where w.descr = @consigneekey and w.status = '0'
--								where w.descr = '' and w.status = '0'
--									and o.consigneekey = @consigneekey
--									and o.storerkey = @storerkey 
--									and convert(varchar(10),o.requestedshipdate,21) = @requestedshipdate
--									and o.carriercode = @carriercode --:
--								group by w.wavekey
--								having max (o.status) <= '11' -- проверка наличия запущенных заказов
--							if @wavekey is null or ltrim(rtrim(@wavekey)) = '' set @wavekey = ''
--							if @wavekey = ''
--								begin
--									print 'DAOI.5.2.4. незапущенной волны с планируемой датой отгрузки '+@requestedshipdate+' для клиента нет'
--									if @carriercode != '' set @load = 'yes'
--									set @wavedescr = @consigneekey
--									exec app_DA_Waves null, @wavedescr, @orderkey, @carriercode, 'new'
----									goto NewWave
--								end
--							else
--								begin 
--									print 'DAOI.5.2.4. незапущенная волна для с планируемой датой отгрузки '+@requestedshipdate+' клиента есть. Wavekey: ' + @WaveKey
--									if @carriercode != '' set @load = 'yes'
--									exec app_DA_Waves @wavekey, null, @orderkey, @carriercode, 'detail'
----									goto NewWaveDetailKey
--								end
--						end

					-- поиск незапущенной волны
					select @wavekey = w.wavekey 
						from wh1.wave w join wh1.wavedetail wd on w.wavekey = wd.wavekey
							join wh1.orders o on o.orderkey = wd.orderkey
--						where w.descr = @consigneekey and w.status = '0'
						where w.descr = @consigneekey and w.status = '0'
							and o.b_company = @b_company
							and o.storerkey = @storerkey and convert(varchar(10),o.requestedshipdate,21) = @requestedshipdate
							and o.carriercode = @carriercode --:
						group by w.wavekey
						having max (o.status) <= '11' -- проверка наличия запущенных заказов
					if @wavekey is null or ltrim(rtrim(@wavekey)) = '' set @wavekey = ''
					if @wavekey = ''
						begin
							print 'DAOI.5.2.4. незапущенной волны с планируемой датой отгрузки '+@requestedshipdate+' для клиента '+@consigneekey+' и перевозчика '+@carriercode+' нет'
							if @carriercode != '' set @load = 'yes'
							set @wavedescr = @consigneekey
							exec app_DA_Waves null, @wavedescr, @orderkey, @carriercode, 'new'
--							goto NewWave
						end
					else
						begin 
							print 'DAOI.5.2.4. незапущенная волна для с планируемой датой отгрузки '+@requestedshipdate+' для клиента '+@consigneekey+' и перевозчика '+@carriercode+'есть. Wavekey: ' + @WaveKey
							if @carriercode != '' set @load = 'yes'
							exec app_DA_Waves @wavekey, null, @orderkey, @carriercode, 'detail'
--							goto NewWaveDetailKey
						end
				end
		end

NextStep:
print '6. проверка необходимости формирования загрузок'
	if @Load = 'yes'
		begin
			print '6.0. проверяем существует ли загрузка для storerkey: '+@storerkey+' с предполагаемой датой отгрузки '+@requestedshipdate+'. Carriercode: '+@carriercode+'.'
			select top 1 @loadid = lh.loadid, @loadstopid = ls.loadstopid from wh1.loadhdr lh join wh1.loadstop ls on lh.loadid = ls.loadid
				join wh1.loadorderdetail lod on lod.loadstopid = ls.loadstopid
				join wh1.orders o on o.orderkey = lod.shipmentorderid
					where (lh.door is null or ltrim(rtrim(lh.door)) = '') and lh.carrierid = @carriercode and 
						--lh.[route] = @carriercode 
						lh.externalid = @carriercode and o.storerkey = @storerkey and convert(varchar(10),o.requestedshipdate,21) = @requestedshipdate
			if @loadid is null or ltrim(rtrim(@loadid)) = ''
				begin
					print '6.1. загрузки с door = '' или null для carrier: ' + @carriercode + ' с планируемой датой отгрузки '+@requestedshipdate+' нет. создаем загрузку.'
					exec dbo.DA_GetNewKey 'wh1','CARTONID',@loadid output	
					print 'Номер загрузки loadid: ' + @loadid
					print '6.1.1. добавляем шапку загрузки'
					insert wh1.loadhdr (whseid,  loadid,   externalid, [route],    carrierid, status, door,             trailerid)
						select           'WH1', @loadid, @carriercode, @loadid, @carriercode,    '0',   '', left(@carriername, 10)
					print '6.1.2. добавляем СТОП в загрузку'
					exec dbo.DA_GetNewKey 'wh1','LOADSTOPID',@loadstopid output	
					print 'Идентификатор остановки в загрузке loadstopid: ' + convert(varchar(10),@loadstopid)
					set @stop = 1 -- всегда одна остановка в загрузке
					insert wh1.loadstop (whseid,  loadid,  loadstopid,  stop, status)
						select            'WH1', @loadid, @loadstopid, @stop,    '0'

				end
--			else
--				begin
--					print '6.1. загрузка со status = 0 для carrier: ' + @carriercode + ' есть. Loadid: ' + @Loadid
--					-- определение необходимых переменных
--					select top 1 @loadid = lh.loadid, @loadstopid = ls.loadstopid from wh1.loadhdr lh join wh1.loadstop ls on lh.loadid = ls.loadid
--						where (lh.door is null or ltrim(rtrim(lh.door)) = '') and lh.carrierid = @carriercode and lh.[route] = @carriercode and ls.stop = 1
--				end
			print '6.2. добавляем заказ на отгрузку в загрузку'
			exec dbo.DA_GetNewKey 'wh1','LOADORDERDETAILID',@loadorderdetailid output	
			insert wh1.loadorderdetail (whseid, loadstopid, loadorderdetailid, storer, shipmentorderid, customer)
				select 'WH1', @loadstopid, @loadorderdetailid, @storerkey, @orderkey, @consigneekey

			print '6.3. Обновляем поле b_zip в заказе для заполнения загрузки'
			update wh1.orders set b_zip = @loadid where orderkey = @orderkey

		end
/*
wh1.loadhdr -- таблица шапок загрузок
	loadid -- pk идентификатор загрузки wh1.ncounter.cartonid

wh1.loadorderdetail -- таблица заказов в загрузках
	loadorderdetailid -- pk идентификатор строки с номером заказа в загрузке wh1.ncounter.loadorderdetailid
	shipmentorder -- номер заказа на отгрузку
	loadstopid -- идентификатор остановки для заказа wh1.loadstop

wh1.loadunitdetail -- таблица погрузочных единиц заказов
	loadunitdetailid -- pk 

wh1.loadstop -- таблица остановок
	stop -- номер остановки
	loadstopid -- pk идентификатор остановки wh1.ncounter.loadstopid
	loadid -- идентификатор загрузки wh1.loadhdr

wh1.loadplanning -- ???
	loadplanningkey -- pk идентификатор ??? wh1.ncounter.loadplanning
*/
	else
		print '6.1. загрузки ненужны'

print '<<< app_DA_OrderIn <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'

