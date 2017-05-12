ALTER PROCEDURE [dbo].[check]
	@startdate datetime, --начальная дата периода сверки
	@enddate datetime,	--конечная дата периода сверки
	@typeverification int, -- тип сверки 
				-- 1-Документы имеющие соответсвие в обоих системах и не имеющие расхождений 
				-- 2-Документы имеющие соответсвие но с расхождениями (ассортимент, цены, количества, информация в шапках и т.д.)
				-- 3-Документы S-Маркет, не имеющие соответствия в Infor WM
				-- 4-Документы Infor WM, не имеющие соответствия в S-Маркет
	@typedocument int, -- тип документа
				-- 0-Приемка
				-- 1-Расход
				-- 3-Пересчеты
				-- 4-Перемещения
				-- 5-Инвентаризация
	@storerkey varchar (20), -- код владельца
	@manager varchar (20) -- код менеджера Smarket

as

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
/*>>> отладочные параметры >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
--use PRD1
--declare
--	@startdate datetime, --начальная дата периода сверки
--	@enddate datetime,	--конечная дата периода сверки
--	@typeverification int, -- тип сверки 
--				-- 1-Документы имеющие соответсвие в обоих системах и не имеющие расхождений 
--				-- 2-Документы имеющие соответсвие но с расхождениями (ассортимент, цены, количества, информация в шапках и т.д.)
--				-- 3-Документы S-Маркет, не имеющие соответствия в Infor WM
--				-- 4-Документы Infor WM, не имеющие соответствия в S-Маркет
--	@typedocument int, -- тип документа
--				-- 0-Приемка
--				-- 1-Расход
--				-- 3-Пересчеты
--				-- 4-Перемещения
--	@storerkey varchar (20), -- код владельца
--	@manager varchar (20) -- код менеджера Smarket
--
--	set @startdate = N'2009-11-16'
--	set @enddate = N'2009-11-17'
--	set @typeverification = 1
--	set @typedocument = 3
--	set @storerkey ='' -- '', ''92, '219'
--	set @manager = '' -- ''

/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*<<< отладочные параметры <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

if (@startdate = @enddate) set @enddate = @startdate + 1 -- минимальный диапазон дат - 1 день.
print @startdate
print @enddate

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
/*>>> создание окружения >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

	-- таблицы с вспомогательными данными
	print 'таблица пользователей USER -> #sm_user'
	SELECT * into #sm_user FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select * from users')

	print 'таблица статусов документов post_status -> #sm_ps'
	SELECT * into #sm_ps FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select * from post_status') 

	print 'таблица типов документов doctype -> #sm_dt'
	SELECT * into #sm_dt FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select * from doctype') 

	print 'таблица видов документов dockind -> #sm_dk'
	SELECT * into #sm_dk FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select * from dockind') 

	print 'таблица операций operations -> #sm_dk'
	SELECT * into #sm_op FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select * from operations') 
	
	-- переменные
	declare 
		@sql nvarchar(4000), -- строка запроса
		@dockey varchar (15) -- номер обрабатываемого документа

	 -- порядковый номер цикла обработки документов
	declare
		@count int
	set @count = 0
		
	-- дата начала обработки документов (запуск инфор)
	declare @start_infor_date datetime
	set @start_infor_date = '2009-10-01 00:00:00.000'
	
	-- фильтр документов ПРИХОД
	declare @operation_0 varchar (150)
	set @operation_0 = ' and (dh.doctype != 1470 and dh.doctype != 1472) and (dh.dockind = 0 or dh.dockind = 9)'
	
	-- фильтр документов РАСХОД
	declare @operation_1 varchar (150)
	set @operation_1 = ' and (dh.doctype != 1471 and dh.doctype != 1473) and (dh.dockind = 1 or dh.dockind = 9)'

	-- фильтр документов ПЕРЕСЧЕТ
	declare @operation_3 varchar (150)	
	set @operation_3 = case when isnull(@storerkey,'') = '' then ' and (dh.doctype = 1470 or dh.doctype = 1472 or dh.doctype = 1471 or dh.doctype = 1473)' else case when @storerkey = 92 then ' and (dh.doctype = 1470 or dh.doctype = 1471) ' else ' and (dh.doctype = 1472 or dh.doctype = 1473)' end end + ' and (dh.dockind = 1 or dh.dockind = 0)'

	-- фильтр документов ПЕРЕМЕЩЕНИЕ
	declare @operation_4 varchar (150)	
	set @operation_4 = case when isnull(@storerkey,'') = '' then ' and (dh.doctype = 1148 or dh.doctype = 1431)' else case when @storerkey = 92 then ' and dh.doctype = 1148' else ' and dh.doctype = 1431' end end + ' and (dh.dockind = 2)'

	-- создание временной таблицы для заголовком документов выбранных из Смаркет
	SELECT * into #sm_dh FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3',
					'select dh.ext_docindex iwm_dockey, cast(dh.id_dochead as varchar(15)) sm_dockey, cast(dh.shopindex as varchar(15)) sm_storerkey, cast(dh.client_index as varchar(15)) sm_storerkey2, dh.doc_date sm_date, dh.client2_index sm_zone, dh.dockind sm_dockind,
							ds.articul sm_sku, round(ds.pricerub,10) sm_unitprice, 
							ts.tax1 sm_nds,	
							round(ds.quantity,10) sm_qty,						
							cl.name_clients, dh.operation sm_operation, dh.doctype sm_doctype, dh.post_status sm_post_status, dh.manager sm_manager
					from dochead dh join clients cl on dh.client_index = cl.id_clients
					join docspec ds on ds.id_dochead = dh.id_dochead
					join taxspec ts on ds.taxhead = ts.taxhead and tax_kind = 0
					where 1=2')

CREATE NONCLUSTERED INDEX sm_sm_dockey ON #sm_dh (sm_dockey)
CREATE NONCLUSTERED INDEX sm_iwm_dockey ON #sm_dh (iwm_dockey)
	-- создание временной таблицы для конкретного документа СМ
	select * into #sm_dh_one from #sm_dh

	-- создание временной таблицы для номеров документов
	select sm_dockey dockey into #dockey from #sm_dh where 1=2

	-- постоянная составляющая запроса в базу Смаркет (заголовок + детали)
	declare @const_sql nvarchar (2000)
	set @const_sql = 'insert into #sm_dh SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'','''+
					'select dh.ext_docindex iwm_dockey, dh.id_dochead sm_dockey, cast(dh.shopindex as varchar(15)) sm_storerkey, cast(dh.client_index as varchar(15)) sm_storerkey2, dh.doc_date sm_date, dh.client2_index sm_zone, dh.dockind sm_dockind,
							ds.articul sm_sku, round(ds.pricerub,10) sm_unitprice, 
							ts.tax1 sm_nds,
							round(ds.quantity,10) sm_qty,					
							cl.name_clients, dh.operation sm_operation, dh.doctype sm_doctype, dh.post_status sm_post_status, dh.manager sm_manager
						from dochead dh join docspec ds on ds.id_dochead = dh.id_dochead
						join clients cl on dh.client_index = cl.id_clients
						join taxspec ts on ds.taxhead = ts.taxhead and tax_kind = 0
						where dh.doc_date > ''''' + convert(varchar(23),@start_infor_date,121) + '''''' +
						' and dh.doc_date >= ''''' + convert(varchar(23),@startdate,121) + 
					''''' and dh.doc_date < ''''' + convert(varchar(23),@enddate,121) + '''''' +
						' and ds.quantity != 0 ' +
						' and dh.post_status > 0' + case when isnull(@storerkey,'') =  '' then '' else 
						' and dh.shopindex = ' + @storerkey + '' end + case when isnull(@manager,'') = '' then '' else 
						' and dh.manager = ' + @manager + '' end	

	-- создание временной таблицы для 
	select * into #sm_dockey FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3',
					'select ext_docindex iwm_dockey, cast(id_dochead as varchar(15)) sm_dockey
						from dochead where 1=2')

	-- задание постоянной составляющей запроса одного документа в базу Смаркет по заголовкам
	declare @one_const_sql nvarchar (2000)
	set @one_const_sql = 'insert into #sm_dockey SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'','''+
					'select dh.ext_docindex iwm_dockey, cast(dh.id_dochead as varchar(15)) sm_dockey
						from dochead dh where dh.doc_date > ''''' + convert(varchar(23),@start_infor_date,121) + ''''''

print 'создание временной таблицы докмуентов InforWM'
	create table #iwm_dh (
		iwm_dockey varchar (15),
		sm_dockey varchar(15),
		iwm_storerkey varchar(15),
		iwm_storerkey2 varchar(15),
		iwm_date datetime,
		iwm_zone varchar(10),
		iwm_sku varchar(15),
		iwm_unitprice numeric (20,10),
		iwm_nds numeric (20,10),
		iwm_qty numeric (20,10))

CREATE NONCLUSTERED INDEX iwm_iwm_dockey ON #sm_dh (iwm_dockey)
CREATE NONCLUSTERED INDEX iwm_sm_dockey ON #sm_dh (sm_dockey)
	-- создание временной таблицы для одного документа ИНФОР
	select * into #iwm_dh_one from #iwm_dh
	
/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*<<< создание окружения <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
/*>>> обработка >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

	/* > ПОЛНОЕ СООТВЕТСВИЕ */
	if @typeverification = 1
		begin
			print 'ПОЛНОЕ СООТВЕТСВИЕ ''@typeverification = 1'''
			-- ПРИХОД -----------------------------------------------------------------------
			if @typedocument = 0
				begin 
					print 'приходные документы ''dockind = 0'''
					print 'выбор документов Смаркет'
					set @sql = @const_sql + @operation_0 +''')'
					exec (@sql)
					print 'выбор документов Инфор'
					insert into #iwm_dh
					select cast(p.pokey as int) iwm_dockey, 
						substring(p.externpokey,3,15) sm_dockey, 
						p.storerkey iwm_storerkey, 
						substring(p.sellersreference,3,15) iwm_storerkey2, 
						p.adddate iwm_date, 
						'' zone,
						pd.sku iwm_sku,
						round(pd.unitprice,10) iwm_unitprice,
						pd.unit_cost iwm_nds,
						--case when p.status >= '11' then case when pd.qtyreceived = 0 then 0 else pd.unit_cost end else case when pd.qtyadjusted = 0 then 0 else pd.unit_cost end end iwm_nds, 
						case when p.status >= '11' then qtyreceived else qtyadjusted end iwm_qty 
						from wh1.po p join wh1.podetail pd on p.pokey = pd.pokey
						where substring(p.externpokey,1,2) = 'SM'
						and substring(p.externpokey,3,15) in (select distinct sm_dockey from #sm_dh)
						and (case when p.status >= '11' then qtyreceived else qtyadjusted end != 0)

					print 'выбор номеров документов для обработки'
					insert into #dockey select distinct sm_dockey  from #sm_dh

					while ((select count(dockey) from #dockey) > 0)
						begin
							-- выбор документа для обработки
							select top (1) @dockey = dockey from #dockey
							set @count = @count + 1
							print 'документ ('+cast(@count as varchar(15))+'): '+@dockey+'. Время:'+convert(varchar(50),getdate(),121)
							insert into #sm_dh_one select * from #sm_dh where sm_dockey = @dockey
							insert into #iwm_dh_one select * from #iwm_dh where sm_dockey = @dockey
							if ( exists
								(select top(1) idh.iwm_dockey --count(idh.sm_dockey)+count(sdh.sm_dockey)
									from #iwm_dh_one idh full join #sm_dh_one sdh on 
										idh.sm_dockey = sdh.sm_dockey and
										idh.iwm_sku = sdh.sm_sku and 
										idh.iwm_qty = sdh.sm_qty and 
										idh.iwm_nds = sdh.sm_nds and 
										idh.iwm_storerkey = sdh.sm_storerkey and
										idh.iwm_storerkey2 = sdh.sm_storerkey2
									where (idh.sm_dockey = @dockey or sdh.sm_dockey = @dockey)
										and (idh.sm_dockey is null or sdh.sm_dockey is null))
								)
								begin
									delete from #iwm_dh where sm_dockey = @dockey
									delete from #sm_dh where sm_dockey = @dockey
								end
							-- удаление обработанного документа
							delete from #dockey where dockey = @dockey
							delete from #sm_dh_one
							delete from #iwm_dh_one
						end
				end
				
			if @typedocument = 1
			-- РАСХОД -----------------------------------------------------------------------
				begin 
					print 'расходные документы ''dockind = 1'''
					print 'выбор документов Смаркет'
					set @sql = @const_sql + @operation_1 +''')'
					exec (@sql)

					print 'выбор документов Инфор'
					insert into #iwm_dh
					select cast(o.orderkey as int) iwm_dockey, 
						substring(o.externorderkey,3,15) sm_dockey, 
						o.storerkey iwm_storerkey, 
						substring(o.b_company,3,15) iwm_storerkey2, 
						o.adddate iwm_date, 
						'' zone,
						od.sku iwm_sku, 
						round(od.unitprice,10) iwm_unitprice, 
						od.tax01 iwm_nds,
--						case when o.status >= '92' then case when od.shippedqty = 0 then 0 else od.tax01 end else case when od.openqty = 0 then 0 else od.tax01 end end iwm_nds, 
						case when o.status >= '92' then od.shippedqty else od.openqty end iwm_qty 
						from wh1.orders o join wh1.orderdetail od on o.orderkey = od.orderkey
						where substring(o.externorderkey,1,2) = 'SM' and o.type != '26'
						and substring(o.externorderkey,3,15) in (select distinct sm_dockey from #sm_dh)
						and (case when o.status >= '92' then od.shippedqty else od.openqty end != 0)

					print 'выбор номеров документов для обработки'
					insert into #dockey select distinct sm_dockey  from #sm_dh

					while ((select count(dockey) from #dockey) > 0)
						begin
							-- выбор документа для обработки
							select top (1) @dockey = dockey from #dockey
							set @count = @count + 1
							print 'документ ('+cast(@count as varchar(15))+'): '+@dockey+'. Время:'+convert(varchar(50),getdate(),121)
							insert into #sm_dh_one select * from #sm_dh where sm_dockey = @dockey
							insert into #iwm_dh_one select * from #iwm_dh where sm_dockey = @dockey
							if (exists
								(select top(1) idh.iwm_dockey --
--										count(idh.sm_dockey)+count(sdh.sm_dockey)
									from #iwm_dh_one idh full join #sm_dh_one sdh on 
										idh.sm_dockey = sdh.sm_dockey and
										idh.iwm_sku = sdh.sm_sku and 
										idh.iwm_qty = sdh.sm_qty and 
										idh.iwm_nds = sdh.sm_nds and 
										idh.iwm_storerkey = sdh.sm_storerkey and
										idh.iwm_storerkey2 = sdh.sm_storerkey2
									where (idh.sm_dockey = @dockey or sdh.sm_dockey = @dockey)
										and (idh.sm_dockey is null or sdh.sm_dockey is null))
								)
								begin
									delete from #iwm_dh where sm_dockey = @dockey
									delete from #sm_dh where sm_dockey = @dockey
								end
							-- удаление обработанного документа
							delete from #dockey where dockey = @dockey
							delete from #sm_dh_one
							delete from #iwm_dh_one
						end
				end
					
			if @typedocument = 3
			-- ПЕРЕСЧЕТЫ --------------------------------------------------------------------
				begin 
					print 'пересчеты ''dockind = 0,1'''
					print 'выбор документов Смаркет'
					set @sql = @const_sql + @operation_3 +''')'
					exec (@sql) print @sql

					print 'изменение знака в количестве в зависимости от dockind'
					update #sm_dh set sm_qty = case when sm_dockind = '0' then sm_qty else sm_qty * (-1) end

					print 'выбор документов Инфор'
					insert into #iwm_dh
					select cast(ad.batchkey as int) iwm_dockey, null sm_dockey, ad.storerkey iwm_storerkey, null iwm_storerkey2, max(ad.editdate) iwm_date, ad.zone zone,
						ad.sku iwm_sku, 0 iwm_unitprice, 0 iwm_nds, sum(deltaqty) iwm_qty 
						from da_adjustment ad
						where cast(ad.batchkey as int) in (select distinct iwm_dockey from #sm_dh)
						group by ad.batchkey,ad.storerkey,ad.zone,ad.sku

					print 'обновление номеров документов Смаркета в Инфор'
					update id set id.sm_dockey = sd.sm_dockey
						from #iwm_dh id join #sm_dh sd on
							id.iwm_zone = sd.sm_zone and
							id.iwm_sku = sd.sm_sku and
							id.iwm_qty = sd.sm_qty and
							id.iwm_storerkey = sd.sm_storerkey and
							id.iwm_dockey = sd.iwm_dockey

					print 'выбираем даты для документов'
					select iwm_dockey, max(iwm_date) iwm_date into #tmp1 
						from #iwm_dh
						group by iwm_dockey
					print 'обновляем даты для документов'
					update id set id.iwm_date = t.iwm_date
						from #iwm_dh id join #tmp1 t on id.iwm_dockey = t.iwm_dockey
					drop table #tmp1

					print 'удаление NULL документов'
					delete #sm_dh where iwm_dockey is null
					delete #iwm_dh where sm_dockey is null

					print 'выбор номеров документов для обработки'
					insert into #dockey select distinct iwm_dockey  from #iwm_dh
					while ((select count(dockey) from #dockey) > 0)
						begin
							-- выбор документа для обработки
							select top (1) @dockey = dockey from #dockey
							set @count = @count + 1
							print 'документ ('+cast(@count as varchar(15))+'): '+@dockey+'. Время:'+convert(varchar(50),getdate(),121)
--							insert into #sm_dh_one select * from #sm_dh where sm_dockey = @dockey
--							insert into #iwm_dh_one select * from #iwm_dh where sm_dockey = @dockey
							if (exists
								(select top(1) idh.iwm_dockey
									from #iwm_dh idh full join #sm_dh sdh on 
										idh.sm_dockey = sdh.sm_dockey and
										idh.iwm_sku = sdh.sm_sku and 
										idh.iwm_storerkey = sdh.sm_storerkey and
										idh.iwm_qty = sdh.sm_qty and
										idh.iwm_zone = sdh.sm_zone and 
										idh.iwm_dockey = sdh.iwm_dockey
									where (idh.iwm_dockey = @dockey or sdh.iwm_dockey = @dockey)
										and (idh.sm_dockey is null or sdh.sm_dockey is null))
								)
								begin
									print 'удаляем документы '+ @dockey
									delete from #iwm_dh where iwm_dockey = @dockey
									delete from #sm_dh where iwm_dockey = @dockey
								end
							-- удаление обработанного документа
							delete from #dockey where dockey = @dockey
--							delete from #sm_dh_one
--							delete from #iwm_dh_one
						end
				end
				
			if @typedocument = 4
			-- ПЕРЕМЕЩЕНИЯ --------------------------------------------------------------------
				begin 
					print 'перемещения ''dockind = 2'''
					print 'выбор документов Смаркет'
					set @sql = @const_sql + @operation_4 +''')'
					exec (@sql)

					print 'выбор документов Инфор'
					insert into #iwm_dh
					select cast(i.itrnkey as int) iwm_dockey, null sm_dockey, i.storerkey iwm_storerkey, null iwm_storerkey2, i.adddate iwm_date, '' zone,
						i.sku iwm_sku, 0 iwm_unitprice, 0 iwm_nds, round(i.qty,10) iwm_qty 
						from wh1.itrn i 
						where cast(i.itrnkey as int) in (select distinct iwm_dockey from #sm_dh)

					print 'обновление номеров документов Смаркета в Инфор'
					update id set id.sm_dockey = sd.sm_dockey
						from #iwm_dh id join #sm_dh sd on
							id.iwm_dockey = sd.iwm_dockey

					print 'удаление NULL документов'
					delete #sm_dh where iwm_dockey is null
					delete #iwm_dh where sm_dockey is null
			
					print 'выбор номеров документов для обработки'
					insert into #dockey select distinct sm_dockey  from #sm_dh

					while ((select count(dockey) from #dockey) > 0)
						begin
							-- выбор документа для обработки
							select top (1) @dockey = dockey from #dockey
							set @count = @count + 1
							print 'документ ('+cast(@count as varchar(15))+'): '+@dockey+'. Время:'+convert(varchar(50),getdate(),121)
							insert into #sm_dh_one select * from #sm_dh where sm_dockey = @dockey
							insert into #iwm_dh_one select * from #iwm_dh where sm_dockey = @dockey
							if (
								(select count(idh.sm_dockey)+count(sdh.sm_dockey)
									from #iwm_dh_one idh full join #sm_dh_one sdh on 
										idh.sm_dockey = sdh.sm_dockey and
										idh.iwm_storerkey = sdh.sm_storerkey and 
										idh.iwm_qty = sdh.sm_qty
									where (idh.sm_dockey = @dockey or sdh.sm_dockey = @dockey)
										and (idh.sm_dockey is null or sdh.sm_dockey is null))
								!= 0)
								begin
									delete from #iwm_dh where sm_dockey = @dockey
									delete from #sm_dh where sm_dockey = @dockey
								end
							-- удаление обработанного документа
							delete from #dockey where dockey = @dockey
							delete from #sm_dh_one
							delete from #iwm_dh_one
						end										
				end
		end
	/* < ПОЛНОЕ СООТВЕТСТВИЕ */
		
	/* > РАСХОЖДЕНИЯ */
	if @typeverification = 2
		begin
			print 'РАСХОЖДЕНИЯ ''@typeverification = 2'''
			-- ПРИХОД -----------------------------------------------------------------------
			if @typedocument = 0
				begin 
					print 'приходные документы ''dockind = 0'''
					print 'выбор документов Смаркет'
					set @sql = @const_sql + @operation_0 +''')'
					exec (@sql)

					print 'выбор документов Инфор'
					insert into #iwm_dh
					select cast(p.pokey as int) iwm_dockey, 
						substring(p.externpokey,3,15) sm_dockey, p.storerkey iwm_storerkey, 
						substring(p.sellersreference,3,15) iwm_storerkey2, 
						p.adddate iwm_date, 
						'' zone,
						pd.sku iwm_sku, 
						round(pd.unitprice,10) iwm_unitprice, 
						pd.unit_cost iwm_nds,
--						case when p.status >= '11' then case when pd.qtyreceived = 0 then 0 else round(pd.unit_cost,10) end else case when pd.qtyadjusted = 0 then 0 else round(pd.unit_cost,10) end end iwm_nds, 
						case when p.status >= '11' then qtyreceived else qtyadjusted end iwm_qty 
						from wh1.po p join wh1.podetail pd on p.pokey = pd.pokey
						where substring(p.externpokey,1,2) = 'SM'
						and substring(p.externpokey,3,15) in (select distinct sm_dockey from #sm_dh)
						and (case when p.status >= '11' then qtyreceived else qtyadjusted end != 0)

					print 'выбор номеров документов для обработки'
					insert into #dockey select distinct sm_dockey  from #sm_dh

					while ((select count(dockey) from #dockey) > 0)
						begin
							-- выбор документа для обработки
							select top (1) @dockey = dockey from #dockey
							set @count = @count + 1
							print 'документ ('+cast(@count as varchar(15))+'): '+@dockey+'. Время:'+convert(varchar(50),getdate(),121)
							insert into #sm_dh_one select * from #sm_dh where sm_dockey = @dockey
							insert into #iwm_dh_one select * from #iwm_dh where sm_dockey = @dockey
							if ( not exists
								(select top (1) idh.iwm_dockey --count(idh.sm_dockey)+count(sdh.sm_dockey)
									from #iwm_dh_one idh full join #sm_dh_one sdh on 
										idh.sm_dockey = sdh.sm_dockey and
										idh.iwm_sku = sdh.sm_sku and 
										idh.iwm_qty = sdh.sm_qty and 
										idh.iwm_nds = sdh.sm_nds and 
										idh.iwm_storerkey = sdh.sm_storerkey and
										idh.iwm_storerkey2 = sdh.sm_storerkey2
									where 
										((idh.sm_dockey = @dockey or sdh.sm_dockey = @dockey) and 
										(sdh.sm_dockey is null or idh.sm_dockey is null)))
									)
								begin
									delete from #iwm_dh where sm_dockey = @dockey
									delete from #sm_dh where sm_dockey = @dockey
								end
							-- удаление не парных документов из смаркет
							delete from sdh
								from #sm_dh sdh full join #iwm_dh idh on sdh.sm_dockey = idh.sm_dockey
								where idh.sm_dockey is null and sdh.sm_dockey = @dockey
							-- удаление обработанного документа
							delete from #dockey where dockey = @dockey
							delete from #sm_dh_one
							delete from #iwm_dh_one
						end
				end
				
			if @typedocument = 1
			-- РАСХОД -----------------------------------------------------------------------
				begin 
					print 'расходные документы ''dockind = 1'''
					print 'выбор документов Смаркет'
					set @sql = @const_sql + @operation_1 +''')'
					exec (@sql)

					print 'выбор документов Инфор'
					insert into #iwm_dh
					select cast(o.orderkey as int) iwm_dockey, 
						substring(o.externorderkey,3,15) sm_dockey, 
						o.storerkey iwm_storerkey, 
						substring(o.b_company,3,15) iwm_storerkey2, 
						o.adddate iwm_date, 
						'' zone,
						od.sku iwm_sku, 
						round(od.unitprice,10) iwm_unitprice,
						od.tax01 iwm_nds,
--						case when o.status >= '92' then case when od.shippedqty = 0 then 0 else od.tax01 end else case when od.openqty = 0 then 0 else od.tax01 end end iwm_nds, 
						case when o.status >= '92' then od.shippedqty else od.openqty end iwm_qty 
						from wh1.orders o join wh1.orderdetail od on o.orderkey = od.orderkey
						where substring(o.externorderkey,1,2) = 'SM' and o.type != '26'
						and substring(o.externorderkey,3,15) in (select distinct sm_dockey from #sm_dh)
						and (case when o.status >= '92' then od.shippedqty else od.openqty end != 0)

					print 'выбор номеров документов для обработки'
					insert into #dockey select distinct sm_dockey  from #sm_dh

					-- удаление непарных документов из смаркет
					delete from sdh
						from #sm_dh sdh full join #iwm_dh idh on sdh.sm_dockey = idh.sm_dockey
						where idh.sm_dockey is null

					while ((select count(dockey) from #dockey) > 0)
						begin
							-- выбор документа для обработки
							select top (1) @dockey = dockey from #dockey
							set @count = @count + 1
							print 'документ ('+cast(@count as varchar(15))+'): '+@dockey+'. Время:'+convert(varchar(50),getdate(),121)
							if ( not exists
								(select top(1) idh.iwm_dockey --count(idh.sm_dockey)+count(sdh.sm_dockey)
									from #iwm_dh idh full join #sm_dh sdh on 
										idh.sm_dockey = sdh.sm_dockey and
										idh.iwm_sku = sdh.sm_sku and 
										idh.iwm_qty = sdh.sm_qty and 
										idh.iwm_nds = sdh.sm_nds and 
										idh.iwm_storerkey = sdh.sm_storerkey and
										idh.iwm_storerkey2 = sdh.sm_storerkey2
									where (idh.sm_dockey = @dockey or sdh.sm_dockey = @dockey)
										and (idh.sm_dockey is null or sdh.sm_dockey is null))
								)
								begin
									delete from #iwm_dh where sm_dockey = @dockey
									delete from #sm_dh where sm_dockey = @dockey
								end
							-- удаление обработанного документа
							delete from #dockey where dockey = @dockey
						end
				end
				
			if @typedocument = 3
			-- ПЕРЕСЧЕТЫ --------------------------------------------------------------------
				begin 
					print 'пересчеты ''dockind = 0,1'''
					print 'выбор документов Смаркет'
					set @sql = @const_sql + @operation_3 +''')'
					exec (@sql) print @sql

					print 'изменение знака в количестве в зависимости от dockind'
					update #sm_dh set sm_qty = case when sm_dockind = '0' then sm_qty else sm_qty * (-1) end
--select * from #sm_dh
					print 'выбор документов Инфор'
					insert into #iwm_dh
					select cast(ad.batchkey as int) iwm_dockey, null sm_dockey, ad.storerkey iwm_storerkey, null iwm_storerkey2, max(ad.editdate) iwm_date, ad.zone zone,
						ad.sku iwm_sku, 0 iwm_unitprice, 0 iwm_nds, sum(deltaqty) iwm_qty 
						from da_adjustment ad
						where cast(ad.batchkey as int) in (select distinct iwm_dockey from #sm_dh)
						group by ad.batchkey,ad.storerkey,ad.zone,ad.sku

					print 'обновление номеров документов Смаркета в Инфор'
					update id set id.sm_dockey = sd.sm_dockey
						from #iwm_dh id join #sm_dh sd on
							id.iwm_zone = sd.sm_zone and
							id.iwm_sku = sd.sm_sku and
							id.iwm_qty = sd.sm_qty and
							id.iwm_storerkey = sd.sm_storerkey and 
							id.iwm_dockey = sd.iwm_dockey
					print 'выбираем даты для документов'
					select iwm_dockey, max(iwm_date) iwm_date into #tmp 
						from #iwm_dh
						group by iwm_dockey
					print 'обновляем даты для документов'
					update id set id.iwm_date = t.iwm_date
						from #iwm_dh id join #tmp t on id.iwm_dockey = t.iwm_dockey
					drop table #tmp

					print 'удаление null документов'
					delete from #sm_dh where iwm_dockey is null
					delete from #iwm_dh where iwm_dockey is null

					print 'выбор номеров документов Infor для обработки'
					insert into #dockey select distinct iwm_dockey from #iwm_dh

					while ((select count(dockey) from #dockey) > 0)
						begin
							-- выбор документа для обработки
							select top (1) @dockey = dockey from #dockey
							set @count = @count + 1
							print 'документ ('+cast(@count as varchar(15))+'): '+@dockey+'. Время:'+convert(varchar(50),getdate(),121)
							if ( exists
								(select top(1) idh.iwm_dockey
									from #iwm_dh idh full join #sm_dh sdh on 
										idh.sm_dockey = sdh.sm_dockey and
										idh.iwm_sku = sdh.sm_sku and 
										idh.iwm_storerkey = sdh.sm_storerkey and
										idh.iwm_qty = sdh.sm_qty and
										idh.iwm_zone = sdh.sm_zone and
										idh.iwm_dockey = sdh.iwm_dockey
									where (idh.iwm_dockey = @dockey or sdh.iwm_dockey = @dockey)
										and (idh.sm_dockey is null or sdh.sm_dockey is null))
								)
								begin
									delete from #iwm_dh where iwm_dockey = @dockey
									delete from #sm_dh where iwm_dockey = @dockey
								end
							-- удаление обработанного документа
							delete from #dockey where dockey = @dockey
						end
				end
				
			if @typedocument = 4
			-- ПЕРЕМЕЩЕНИЯ --------------------------------------------------------------------
				begin 
					print 'перемещения ''dockind = 2'''
					print 'выбор документов Смаркет'
					set @sql = @const_sql + @operation_4 +''')'
					exec (@sql)

					print 'выбор документов Инфор'
					insert into #iwm_dh
					select cast(i.itrnkey as int) iwm_dockey, null sm_dockey, i.storerkey iwm_storerkey, null iwm_storerkey2, i.adddate iwm_date, '' zone,
						i.sku iwm_sku, 0 iwm_unitprice, 0 iwm_nds, round(i.qty,10) iwm_qty 
						from wh1.itrn i 
						where cast(i.itrnkey as int) in (select distinct iwm_dockey from #sm_dh)

					print 'обновление номеров документов Смаркета в Инфор'
					update id set id.sm_dockey = sd.sm_dockey
						from #iwm_dh id join #sm_dh sd on
							id.iwm_dockey = sd.iwm_dockey

					print 'удаление NULL документов'
					delete #sm_dh where iwm_dockey is null
					delete #iwm_dh where sm_dockey is null
			
					print 'выбор номеров документов для обработки'
					insert into #dockey select distinct sm_dockey  from #sm_dh

					while ((select count(dockey) from #dockey) > 0)
						begin
							-- выбор документа для обработки
							select top (1) @dockey = dockey from #dockey
							set @count = @count + 1
							print 'документ ('+cast(@count as varchar(15))+'): '+@dockey+'. Время:'+convert(varchar(50),getdate(),121)
							insert into #sm_dh_one select * from #sm_dh where sm_dockey = @dockey
							insert into #iwm_dh_one select * from #iwm_dh where sm_dockey = @dockey
							if (
								(select count(idh.sm_dockey)+count(sdh.sm_dockey)
									from #iwm_dh_one idh full join #sm_dh_one sdh on 
										idh.sm_dockey = sdh.sm_dockey and
										idh.iwm_storerkey = sdh.sm_storerkey and 
										idh.iwm_qty = sdh.sm_qty
									where (idh.sm_dockey = @dockey or sdh.sm_dockey = @dockey)
										and (idh.sm_dockey is null or sdh.sm_dockey is null))
								= 0)
								begin
									delete from #iwm_dh where sm_dockey = @dockey
									delete from #sm_dh where sm_dockey = @dockey
								end
							-- удаление обработанного документа
							delete from #dockey where dockey = @dockey
							delete from #sm_dh_one
							delete from #iwm_dh_one
						end				
				end
		end
	/* < РАСХОЖДЕНИЯ */	

	/* > SMarket */
	if @typeverification = 3
		begin
			print 'SMarket ''@typeverification = 3'''
			-- ПРИХОД -----------------------------------------------------------------------
			if @typedocument = 0
				begin 
					print 'приходные документы ''dockind = 0'''
					print 'выбор документов Смаркет'
					set @sql = @const_sql + @operation_0 +''')'
					exec (@sql)

					print 'выбор документов Инфор'
					insert into #iwm_dh
					select cast(p.pokey as int) iwm_dockey, substring(p.externpokey,3,15) sm_dockey, p.storerkey iwm_storerkey, substring(p.sellersreference,3,15) iwm_storerkey2, p.adddate iwm_date, '' zone,
						pd.sku iwm_sku, round(pd.unitprice,10) iwm_unitprice, round(pd.unit_cost,10) iwm_nds, case when pd.status >= '11' then qtyreceived else qtyadjusted end iwm_qty 
						from wh1.po p join wh1.podetail pd on p.pokey = pd.pokey
						where substring(p.externpokey,1,2) = 'SM'
						and substring(p.externpokey,3,15) in (select distinct sm_dockey from #sm_dh)
					
					-- удаление парных документов
					delete from sdh
						from #sm_dh sdh join #iwm_dh idh on sdh.sm_dockey = idh.sm_dockey

				end
				
			if @typedocument = 1
			-- РАСХОД -----------------------------------------------------------------------
				begin 
					print 'расходные документы ''dockind = 1'''
					print 'выбор документов Смаркет'
					set @sql = @const_sql + @operation_1 +''')'
					exec (@sql)

					print 'выбор документов Инфор'
					insert into #iwm_dh
					select cast(o.orderkey as int) iwm_dockey, substring(o.externorderkey,3,15) sm_dockey, o.storerkey iwm_storerkey, substring(o.b_company,3,15) iwm_storerkey2, o.adddate iwm_date, '' zone,
						od.sku iwm_sku, round(od.unitprice,10) iwm_unitprice, round(od.tax01,10) iwm_nds, case when od.status >= '16' then od.shippedqty else od.openqty end iwm_qty 
						from wh1.orders o join wh1.orderdetail od on o.orderkey = od.orderkey
						where substring(o.externorderkey,1,2) = 'SM' and o.type != '26'
						and substring(o.externorderkey,3,15) in (select distinct sm_dockey from #sm_dh)

					-- удаление парных документов
					delete from sdh
						from #sm_dh sdh join #iwm_dh idh on sdh.sm_dockey = idh.sm_dockey
				end
				
			if @typedocument = 3
			-- ПЕРЕСЧЕТЫ --------------------------------------------------------------------
				begin 
					print 'пересчеты ''dockind = 0,1'''
					print 'выбор документов Смаркет'
					set @sql = @const_sql + @operation_3 +''')'
					exec (@sql) print @sql

					print 'выбор документов Инфор'
					insert into #iwm_dh
					select cast(ad.batchkey as int) iwm_dockey, null sm_dockey, ad.storerkey iwm_storerkey, null iwm_storerkey2, max(ad.editdate) iwm_date, ad.zone zone,
						ad.sku iwm_sku, 0 iwm_unitprice, 0 iwm_nds, sum(deltaqty) iwm_qty 
						from da_adjustment ad
						where cast(ad.batchkey as int) in (select distinct iwm_dockey from #sm_dh)
						group by ad.batchkey,ad.storerkey,ad.zone,ad.sku

					-- удаление парных документов
					delete from sdh
						from #sm_dh sdh join #iwm_dh idh on sdh.iwm_dockey = idh.iwm_dockey
				end
				
			if @typedocument = 4
			-- ПЕРЕМЕЩЕНИЯ --------------------------------------------------------------------
				begin 
					print 'перемещения ''dockind = 2'''
					print 'выбор документов Смаркет'
					set @sql = @const_sql + @operation_4 +''')'
					exec (@sql)

					print 'выбор документов Инфор'
					insert into #iwm_dh
					select cast(i.itrnkey as int) iwm_dockey, null sm_dockey, i.storerkey iwm_storerkey, null iwm_storerkey2, i.adddate iwm_date, '' zone,
						i.sku iwm_sku, 0 iwm_unitprice, 0 iwm_nds, round(i.qty,10) iwm_qty 
						from wh1.itrn i 
						where cast(i.itrnkey as int) in (select distinct iwm_dockey from #sm_dh)

					-- удаление парных документов
					delete from sdh
						from #sm_dh sdh join #iwm_dh idh on sdh.sm_dockey = idh.sm_dockey
				end
		end
	/* < SMarket */	

	/* > InforWM */
	if @typeverification = 4
		begin
			print 'InforWM ''@typeverification = 4'''
			-- ПРИХОД -----------------------------------------------------------------------
			if @typedocument = 0
				begin 
					print 'приходные документы ''dockind = 0'''
					print 'выбор документов Инфор'
					insert into #iwm_dh
					select cast(p.pokey as int) iwm_dockey, substring(p.externpokey,3,15) sm_dockey, p.storerkey iwm_storerkey, substring(p.sellersreference,3,15) iwm_storerkey2, p.adddate iwm_date, '' zone,
						pd.sku iwm_sku, round(pd.unitprice,10) iwm_unitprice, round(pd.unit_cost,10) iwm_nds, case when pd.status >= '11' then qtyreceived else qtyadjusted end iwm_qty 
						from wh1.po p join wh1.podetail pd on p.pokey = pd.pokey
						where substring(p.externpokey,1,2) = 'SM'
						and p.adddate > @startdate and p.adddate < @enddate
					
					print 'выбор номеров документов для обработки'
					insert into #dockey select distinct sm_dockey from #iwm_dh

					while ((select count (dockey) from #dockey) > 0)
						begin
							-- выбор документа инфор
							select top (1) @dockey = dockey from #dockey
							set @count = @count + 1
							print 'документ ('+cast(@count as varchar(15))+'): '+@dockey+'. Время:'+convert(varchar(50),getdate(),121)
							set @sql = @one_const_sql + @operation_0 + ' and dh.id_dochead = ' + @dockey + ''')'
							exec (@sql)

							if ((select count (sm_dockey) from #sm_dockey) != 0)
								delete from #iwm_dh where sm_dockey = @dockey

							-- удаление обработанного номера документа
							delete from #dockey where dockey = @dockey

						end
				end
				
			if @typedocument = 1
			-- РАСХОД -----------------------------------------------------------------------
				begin 
					print 'расходные документы ''dockind = 1'''

					print 'выбор документов Инфор'
					insert into #iwm_dh
					select cast(o.orderkey as int) iwm_dockey, substring(o.externorderkey,3,15) sm_dockey, o.storerkey iwm_storerkey, substring(o.b_company,3,15) iwm_storerkey2, o.adddate iwm_date, '' zone,
						od.sku iwm_sku, round(od.unitprice,10) iwm_unitprice, round(od.tax01,10) iwm_nds, case when od.status >= '16' then od.shippedqty else od.openqty end iwm_qty 
						from wh1.orders o join wh1.orderdetail od on o.orderkey = od.orderkey
						where substring(o.externorderkey,1,2) = 'SM' and o.type != '26'
						and o.adddate > @startdate and o.adddate < @enddate
					
					print 'выбор номеров документов для обработки'
					insert into #dockey select distinct sm_dockey from #iwm_dh

					while ((select count (dockey) from #dockey) > 0)
						begin
							-- выбор документа инфор
							select top (1) @dockey = dockey from #dockey
							set @count = @count + 1
							print 'документ ('+cast(@count as varchar(15))+'): '+@dockey+'. Время:'+convert(varchar(50),getdate(),121)
							set @sql = @one_const_sql + @operation_1 + ' and dh.id_dochead = ' + @dockey + ''')'
							exec (@sql)

							if ((select count (sm_dockey) from #sm_dockey) != 0)
								delete from #iwm_dh where sm_dockey = @dockey

							-- удаление обработанного номера документа
							delete from #dockey where dockey = @dockey
						end
				end
				
			if @typedocument = 3
			-- ПЕРЕСЧЕТЫ --------------------------------------------------------------------
				begin 
					print 'пересчеты ''dockind = 0'''
					print 'выбор документов Инфор'
					insert into #iwm_dh
					select cast(ad.batchkey as int) iwm_dockey, '' sm_dockey, ad.storerkey iwm_storerkey, '' iwm_storerkey2, ad.editdate iwm_date, ad.zone zone,
						'' iwm_sku, 0 iwm_unitprice, 0 iwm_nds, ad.deltaqty iwm_qty 
						from da_adjustment ad 
						where  
							editdate > @start_infor_date
							and ad.editdate >= @startdate
							and ad.editdate <= @enddate
							and ad.storerkey like case when isnull(@storerkey,'') = '' then '%' else @storerkey end -- менеждер не передается по интеграции в инфор
			
					print 'выбор номеров документов для обработки'
					insert into #dockey select distinct iwm_dockey from #iwm_dh where isnull(iwm_dockey,'') != ''

					while ((select count (dockey) from #dockey) > 0)
						begin
							-- выбор номера документа инфор
							select top (1) @dockey = dockey from #dockey
							set @count = @count + 1
							print 'документ ('+cast(@count as varchar(15))+'): '+@dockey+'. Время:'+convert(varchar(50),getdate(),121)

							set @sql = @one_const_sql + @operation_3 + ' and dh.ext_docindex = ' + @dockey + ''')'
							exec (@sql)

							if ((select count (sm_dockey) from #sm_dockey) != 0)
								begin
									print 'удаление документа '+@dockey
									delete from #iwm_dh where sm_dockey = @dockey
								end

							-- удаление обработанного номера документа
							delete from #dockey where dockey = @dockey
						end
				end
				
			if @typedocument = 4
			-- ПЕРЕМЕЩЕНИЯ --------------------------------------------------------------------
				begin 
					print 'перемещения ''dockind = 0'''
					print 'выбор документов Инфор'
					insert into #iwm_dh
					select cast(i.itrnkey as int) iwm_dockey, '' sm_dockey, i.storerkey iwm_storerkey, '' iwm_storerkey2, i.adddate iwm_date, '' zone,
						'' iwm_sku, 0 iwm_unitprice, 0 iwm_nds, i.qty iwm_qty 
					from wh1.itrn i
						inner join wh1.loc l on l.loc = i.toloc
						inner join wh1.loc l2 on l2.loc = i.fromloc
					where 
						i.adddate > @start_infor_date
						and i.adddate >= @startdate
						and i.adddate <= @enddate
						and i.storerkey like case when isnull(@storerkey,'') = '' then '%' else @storerkey end -- менеждер не передается по интеграции в инфор
						and (i.toloc <> 'BRAKPRIEM') and (i.fromloc <> 'BRAKPRIEM')					-- взято из процедуры da_move
						and ( (l.putawayzone like 'BRAK%' and l2.putawayzone not like 'BRAK%')		-- взято из процедуры da_move
							 or (l2.putawayzone like 'BRAK%' and l.putawayzone not like 'BRAK%'))	-- взято из процедуры da_move
						and i.trantype = 'MV'	
					
					print 'выбор номеров документов для обработки'
					insert into #dockey select distinct iwm_dockey from #iwm_dh

					while ((select count (dockey) from #dockey) > 0)
						begin
							-- выбор документа инфор
							select top (1) @dockey = dockey from #dockey
							set @count = @count + 1
							print 'документ ('+cast(@count as varchar(15))+'): '+@dockey+'. Время:'+convert(varchar(50),getdate(),121)

							set @sql = @one_const_sql + @operation_4 + ' and dh.id_dochead = ' + @dockey + ''')'
							exec (@sql)

							if ((select count (sm_dockey) from #sm_dockey) != 0)
								delete from #iwm_dh where iwm_dockey = @dockey

							-- удаление обработанного номера документа
							delete from #dockey where dockey = @dockey
						end
				end
		end
	/* < InforWM */	

/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*<<< обработка <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
/*>>> вывод результатов >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

--select sm_dockey, count (sm_dockey) from #sm_dh group by sm_dockey
--select sm_dockey, count (iwm_dockey) from #iwm_dh group by sm_dockey
--
--select count (m.sm_dockey),count (s.iwm_dockey),s.sm_dockey
--  from #sm_dh s join #iwm_dh m on s.sm_dockey = m.sm_dockey
--group by s.sm_dockey order by s.sm_dockey
--
--select * from #sm_dh
--select * from #iwm_dh

	select distinct
						dh.iwm_dockey, 
						dh.sm_dockey, 
						dh.name_clients,
						dh.sm_storerkey2,
						dh.sm_date,
						dh.sm_operation, 
						dh.sm_dockind,
						dh.sm_doctype,
						dh.sm_post_status, 
						dh.sm_manager
	into #stmp
	from #sm_dh dh

	select distinct 
						dh.iwm_dockey, 
						dh.iwm_date,
						dh.sm_dockey

	into #itmp
	from #iwm_dh dh


				select distinct
						i.iwm_dockey dockey, 
						i.iwm_date adddate,
						dh.sm_dockey id_dochead, 
						dh.name_clients name_clients,
						dh.sm_storerkey2 client_index,
						dh.sm_date doc_date,
						so.name_operation+' (' + cast(dh.sm_operation as varchar(10)) + ')' operation, 
						sk.name_dockind+' (' + cast(dh.sm_dockind as varchar(10)) + ')' dokind,
						sd.name_doctype+' (' + cast(dh.sm_doctype as varchar(10)) + ')' doctype,
						sp.name_post_status+' (' + cast(dh.sm_post_status as varchar(10)) + ')' post_status, 
						su.name_user+' (' + cast(dh.sm_manager as varchar(10)) + ')' manager
					from #itmp i 
						full join #stmp dh on i.sm_dockey = dh.sm_dockey
						join #sm_user su on dh.sm_manager = su.id_user
						join #sm_ps sp on dh.sm_post_status = sp.id_post_status
						join #sm_dt sd on dh.sm_doctype = sd.id_doctype
						join #sm_dk sk on dh.sm_dockind = sk.id_dockind
						join #sm_op so on dh.sm_operation = so.id_operation
					order by dh.sm_dockey

--				select distinct
--						i.iwm_dockey dockey, 
--						i.iwm_date adddate,
--						dh.sm_dockey id_dochead, 
--						dh.name_clients name_clients,
--						dh.sm_storerkey2 client_index,
--						dh.sm_date doc_date,
--						so.name_operation+' (' + cast(dh.sm_operation as varchar(10)) + ')' operation, 
--						sk.name_dockind+' (' + cast(dh.sm_dockind as varchar(10)) + ')' dokind,
--						sd.name_doctype+' (' + cast(dh.sm_doctype as varchar(10)) + ')' doctype,
--						sp.name_post_status+' (' + cast(dh.sm_post_status as varchar(10)) + ')' post_status, 
--						su.name_user+' (' + cast(dh.sm_manager as varchar(10)) + ')' manager
--					from #iwm_dh i 
--						full join #sm_dh dh on i.sm_dockey = dh.sm_dockey
--						join #sm_user su on dh.sm_manager = su.id_user
--						join #sm_ps sp on dh.sm_post_status = sp.id_post_status
--						join #sm_dt sd on dh.sm_doctype = sd.id_doctype
--						join #sm_dk sk on dh.sm_dockind = sk.id_dockind
--						join #sm_op so on dh.sm_operation = so.id_operation
--					order by dh.sm_dockey


/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*<<< вывод результатов <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

drop table #itmp
drop table #stmp
drop table #sm_dh_one
drop table #iwm_dh_one
drop table #sm_dh
drop table #iwm_dh
drop table #sm_user
drop table #sm_ps
drop table #sm_dt
drop table #sm_dk
drop table #sm_op
drop table #dockey
drop table #sm_dockey
