ALTER PROCEDURE [dbo].[check_doc]
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
--
--declare -- тип сверки 
--	@typeverification int
--				-- 1-Документы имеющие соответсвие в обоих системах и не имеющие расхождений 
--				-- 2-Документы имеющие соответсвие но с расхождениями (ассортимент, цены, количества, информация в шапках и т.д.)
--				-- 3-Документы S-Маркет, не имеющие соответствия в Infor WM
--				-- 4-Документы Infor WM, не имеющие соответствия в S-Маркет
--
--declare -- тип документа
--	@typedocument int
--				-- 0-Приемка
--				-- 1-Расход
--				-- 3-Пересчеты
--				-- 4-Перемещения
--
--declare -- код владельца
--	@storerkey varchar (20)
-- 
--declare -- код менеджера Smarket
--	@manager varchar (20) 
--
--declare --начальная дата периода сверки
--	@startdate datetime
--
--declare --конечная дата периода сверки
--	@enddate datetime	
--
--	set @startdate = N'2009-10-29'
--	set @enddate = N'2009-11-10'
--	set @typeverification = 4
--	set @typedocument = 0
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
	
	-- таблица результатов документов ИНФОР
	CREATE TABLE [#wmsum](
		[docnumber] [varchar](15) NULL,
		[smdocnumber] [varchar](15) NULL,
		[wm_sum] [numeric](38, 17) NULL
	)
	-- таблица результатов
	CREATE TABLE [#result](
		[wmdocnumber] [varchar](10) NULL,
		[sort] [int] NULL,
		[smdocnumber] [varchar](15) NULL,
		[docnumber] [varchar](15) NULL,
		[storerkey_name] [varchar] (100) NULL,
		[storerkey] [varchar](15) NULL,
		[storerkey2_name] [varchar] (100) NULL,
		[storerkey2] [varchar](15) NULL,
		[name_user] [varchar](80) NULL,
		[manager] [varchar](15) NULL,
		[name_dockind] [varchar](40) NULL,
		[dockind] [int] NULL,
		[name_doctype] [varchar](40) NULL,
		[doctype] [int] NULL,
		[name_operation] [varchar](40) NULL,
		[operation] [varchar](15) NULL,
		[name_post_status] [varchar] (100) null,
		[post_status] int null,
		[adddate] [datetime] NULL,
		[sm_sum] [numeric](38, 17) NULL,
		[wm_sum] [numeric](38, 17) NULL
	)

-- таблица номеров приходников и их подчиненных расходников
create table #conformdocs (
	receiptnumber int null,
	ordernumber int null
	)

create table #sm_docsr (
	docnumber varchar (15), --id_dochead
	wmdocnumber varchar (15), --ext_docindex 
	storerkey_name varchar(100),
	storerkey varchar (15), --shopindex
	storerkey2_name varchar(100),
	storerkey2 varchar(15), --client
	adddate datetime, --docdate
	dockind int,
	doctype int,
	sku varchar(15), -- articul
	unitprice numeric (20,10), --pricerub
	nds int,
	qty numeric (20,10), --quantity
	post_status int,
	manager varchar (15),
	operation varchar (15)
	)

select * into #sm_docso from #sm_docsr where 1=2

create table #wm_docs (
	docnumber varchar (15), --pokey
	smdocnumber varchar (15), --externpokey 
	storerkey varchar (15), --storerkey
	storerkey2 varchar(15), --sellersreference
	adddate datetime, --adddate
	sku varchar(15), -- sku
	unitprice numeric (20,10), --unitprice
	nds int, --unit_cost
	qty numeric (20,10), --qtyreceived
	qtybrack numeric (20,10) --qtyrejected
	)

create table #docsnumbers(
	id_dochead int
	)
	
declare -- дата начала обработки документов (запуск инфор)
	@start_infor_date datetime
	set @start_infor_date = '2009-10-01 00:00:00.000'

declare -- переменная идентификатор
	@id varchar(15)

declare -- переменная текста запроса
	@sql_docnum varchar (max)

-- постоянная часть запроса для выбора номеров документов по номерам инфор
	set @sql_docnum =
			'insert into #docsnumbers SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
				''select id_dochead from dochead where id_dochead = '

declare -- переменная текста запроса
	@sql varchar (max)

-- постоянная часть запроса номеров документов в базу смаркет 
	set @sql =
			'insert into #docsnumbers SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
				''select 
				dh.id_dochead
				from dochead dh 
				where dh.doc_date > ''''' + convert(varchar(23),@start_infor_date,121) + 
			''''' and dh.doc_date >= ''''' + convert(varchar(23),@startdate,121) + 
			''''' and dh.doc_date < ''''' + convert(varchar(23),@enddate,121) + '''''' +
			case when isnull(@storerkey,'') =  '' then '' else ' and dh.shopindex = ' + @storerkey + '' end +
			case when isnull(@manager,'') = '' then '' else ' and dh.manager = ' + @manager + '' end 

-- 
declare 
	@sql_seldoc varchar(max)
	set @sql_seldoc =
'select * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
										''select 
											cast(dh.id_dochead as varchar(15)) docnumber, 
											dh.ext_docindex wmdocnumber,
											cl.name_clients storerkey_name,
											cast(dh.shopindex as varchar (15)) storerkey,
											cl.name_clients storerkey2_name,
											cast(dh.client_index as varchar(15)) storerkey2,
											dh.doc_date adddate,
											dh.dockind,
											dh.doctype,
											cast(articul as varchar(15)) sku,
											round(ds.pricerub,10) unitprice,
											ts.tax1 nds,
											round(quantity,10) qty, 
											dh.post_status,
											dh.manager,
											dh.operation
										from dochead dh join docspec ds on dh.id_dochead = ds.id_dochead
											join taxspec ts on ds.taxhead = ts.taxhead and tax_kind = 0
											join clients cl on dh.client_index = cl.id_clients
										where dh.id_dochead = '

declare -- условие для выбора приходных документов
	@where_receipt varchar(500)
	set @where_receipt = ' and dh.post_status > 0 and (dh.doctype != 1470 and dh.doctype != 1472) and (dh.dockind = 0)'')'

declare -- условие для выбора расходных документов
	@where_order varchar(500)
	set @where_order = ' and dh.post_status > 0 and (dh.doctype != 1471 and dh.doctype != 1473) and (dh.dockind = 1)'')'

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
			-- ПРИХОД - ПОЛНОЕ СООТВЕТСТВИЕ ----------------------------------------------------------------------
			if @typedocument = 0
				begin
					print ' приходные документы @typedocument = 0'
					print ' выбор номеров приходных документов'
					set @sql = @sql + @where_receipt
					exec(@sql)

					print ' выбор документов инфор по номерам приходных документов смаркет'
					insert into #wm_docs
						select distinct
							po.pokey, 
							po.externpokey, 
							po.storerkey, 
							po.sellersreference, 
							po.adddate,
							pd.sku, 
							pd.unitprice, 
							pd.unit_cost,
							pd.qtyreceived,
							pd.qtyrejected
						from #docsnumbers cd join wh1.po po on 'SM'+cast(cd.id_dochead as varchar(15)) = po.externpokey
							join wh1.podetail pd on po.pokey = pd.pokey 

					print ' удаляем документы смаркет, отсутвующие в инфор'
					delete from dn
						from #docsnumbers dn full join #wm_docs wd on 'SM'+cast(dn.id_dochead as varchar(15)) = wd.smdocnumber 
						where wd.smdocnumber is null

					print ' поиск Расходных документов по приходным документам'
					while (exists (select top(1) * from #docsnumbers))
						begin
							print @id
							select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
							print '>>> обрабатываем документ '+@id
							print ' поиск Расходных документов через акты'
							set @sql = 
								'insert into #conformdocs select * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
								''select de.basedochead, dl.dochead  
									from dochead_export de join dochead_link dl on de.dochead = dl.basedochead
									where de.basedochead = ' + @id+''')'
							exec (@sql)
							if @@rowcount = 0
								begin
									print ' для приходного документа нет расходов через акты'
									print ' поиск Расходных документов без актов'
									set @sql = 
										'insert into #conformdocs select * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
										''select de.basedochead, de.dochead  
											from dochead_export de 
											where de.basedochead = ' + @id+''')'
									exec (@sql)
									if @@rowcount = 0
										begin
											print ' для приходного документа нет расходов'
											insert into #conformdocs (receiptnumber) values (@id)
										end
								end
							print '<<< удаляем обработанный документ '+@id
							delete from #docsnumbers where id_dochead = @id
						end

						print ' выбираем номера приходных документов для обработки'
						insert into #docsnumbers select distinct receiptnumber from #conformdocs
						while (exists(select top(1) * from #docsnumbers))
							begin
								select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
								print ' вставляем в #sm_docsr детали документа ' +@id
								set @sql = 
									'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
								exec (@sql)
								delete from #docsnumbers where id_dochead = cast (@id as int)
							end

						print ' выбираем расходные документы через акты для обработки'
						insert into #docsnumbers select distinct ordernumber from #conformdocs where isnull(ordernumber,0) != 0
							while (exists(select top(1) * from #docsnumbers))
								begin
									select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
									set @sql = 
										'insert into #sm_docso ' + @sql_seldoc + @id+''')'
									exec (@sql)
									delete from #docsnumbers where id_dochead = cast (@id as int)
								end

						print ' выбираем номера документов смаркет'
						insert into #docsnumbers select distinct receiptnumber from #conformdocs

						print ' проверка соответствия приходных документов смаркет - инфор'
						while ((select count(id_dochead) from #docsnumbers) > 0)
							begin
								select top(1) @id = id_dochead from #docsnumbers
								print 'проверка документа '+@id
								if (exists(
									select top(1) sdr.docnumber
										from #sm_docsr sdr join #conformdocs cd on sdr.docnumber = cd.receiptnumber
											left join #sm_docso sdo on sdo.docnumber = cd.ordernumber and sdo.sku = sdr.sku
											join #wm_docs wd on wd.smdocnumber = 'SM'+sdr.docnumber and wd.sku = sdr.sku
										where sdr.docnumber = @id and (sdr.storerkey != wd.storerkey or 'SM'+sdr.storerkey2 != wd.storerkey2 
												or sdr.nds != wd.nds or sdr.unitprice != wd.unitprice or ((wd.qty-wd.qtybrack)-(sdr.qty-isnull(sdo.qty,0))) != 0) ))
									begin
										print ' в документах есть расхождения, удаляем их из выборки '+@id
										delete from sdr from #sm_docsr sdr where sdr.docnumber = @id
										delete from sdo from #sm_docso sdo join #conformdocs cd on sdo.docnumber = cd.ordernumber where cd.receiptnumber = @id
										delete from wd from #wm_docs wd where wd.smdocnumber = 'SM'+@id
									end
								print ' удаляем обработанный документ '+@id
								delete from #docsnumbers where id_dochead = @id
							end
				end


			if @typedocument = 1
			-- РАСХОД - ПОЛНОЕ СООТВЕТСТВИЕ ----------------------------------------------------------------------
				begin 
					print ' расходные документы @typedocument = 0'
					print ' выбор номеров расходных документов'
					set @sql = @sql + @where_order
					exec(@sql)

					print ' выбор документов инфор по номерам расходных документов смаркет'
					insert into #wm_docs
						select distinct
							o.orderkey, 
							o.externorderkey, 
							o.storerkey, 
							o.b_company, 
							o.adddate,
							od.sku, 
							od.unitprice, 
							od.tax01,
							case when o.status >= '92' then od.shippedqty else od.openqty end,
							0
						from #docsnumbers cd join wh1.orders o on 'SM'+cast(cd.id_dochead as varchar(15)) = o.externorderkey
							join wh1.orderdetail od on o.orderkey = od.orderkey 

					print ' удаляем документы смаркет, отсутвующие в инфор'
					delete from dn
						from #docsnumbers dn full join #wm_docs wd on 'SM'+cast(dn.id_dochead as varchar(15)) = wd.smdocnumber 
						where wd.smdocnumber is null

					print ' выбираем номера расходных документов для обработки'
					insert into #docsnumbers select distinct receiptnumber from #conformdocs
					while (exists(select top(1) * from #docsnumbers))
						begin
							select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
							print ' вставляем в #sm_docsr детали документа ' +@id
							set @sql = 
								'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
							exec (@sql)
							delete from #docsnumbers where id_dochead = cast (@id as int)
						end

					print ' выбираем номера расходных документов для обработки'
					insert into #docsnumbers select distinct receiptnumber from #conformdocs
					print ' проверка соответствия расходных документов смаркет - инфор'
					while ((select count(id_dochead) from #docsnumbers) > 0)
						begin
							select top(1) @id = id_dochead from #docsnumbers
							print 'проверка документа '+@id
							if (exists(
									select top(1) sdr.docnumber
										from #sm_docsr sdr join #conformdocs cd on sdr.docnumber = cd.receiptnumber
											left join #sm_docso sdo on sdo.docnumber = cd.ordernumber and sdo.sku = sdr.sku
											join #wm_docs wd on wd.smdocnumber = 'SM'+sdr.docnumber and wd.sku = sdr.sku
										where sdr.docnumber = @id and (sdr.storerkey != wd.storerkey or 'SM'+sdr.storerkey2 != wd.storerkey2 
												or sdr.nds != wd.nds or sdr.unitprice != wd.unitprice or (wd.qty-(sdr.qty-isnull(sdo.qty,0))) != 0) ))
									begin
										print ' в документах есть расхождения, удаляем их из выборки '+@id
										delete from sdr from #sm_docsr sdr where sdr.docnumber = @id
										delete from sdo from #sm_docso sdo join #conformdocs cd on sdo.docnumber = cd.ordernumber where cd.receiptnumber = @id
										delete from wd from #wm_docs wd where wd.smdocnumber = 'SM'+@id
									end
								print ' удаляем обработанный документ '+@id
								delete from #docsnumbers where id_dochead = @id
							end
				end
		end


	/* > РАСХОЖДЕНИЯ */
	if @typeverification = 2
		begin
			print 'РАСХОЖДЕНИЯ ''@typeverification = 2'''
			-- ПРИХОД - РАСХОЖДЕНИЯ ----------------------------------------------------------------------
			if @typedocument = 0
				begin 
					print ' выбор номеров приходных документов'
					set @sql = @sql + @where_receipt
					exec(@sql)

					print ' выбор документов инфор по номерам приходных документов смаркет'
					insert into #wm_docs
						select distinct
							po.pokey, 
							po.externpokey, 
							po.storerkey, 
							po.sellersreference, 
							po.adddate,
							pd.sku, 
							pd.unitprice, 
							pd.unit_cost,
							pd.qtyreceived,
							pd.qtyrejected
						from #docsnumbers cd join wh1.po po on 'SM'+cast(cd.id_dochead as varchar(15)) = po.externpokey
							join wh1.podetail pd on po.pokey = pd.pokey 

					print ' удаляем документы смаркет, отсутвующие в инфор'
					delete from dn
						from #docsnumbers dn full join #wm_docs wd on 'SM'+cast(dn.id_dochead as varchar(15)) = wd.smdocnumber 
						where wd.smdocnumber is null

					print ' поиск Расходных документов по приходным документам'
					while (exists (select top(1) * from #docsnumbers))
						begin
							print @id
							select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
							print '>>> обрабатываем документ '+@id
							print ' поиск Расходных документов через акты'
							set @sql = 
								'insert into #conformdocs select * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
								''select de.basedochead, dl.dochead  
									from dochead_export de join dochead_link dl on de.dochead = dl.basedochead
									where de.basedochead = ' + @id+''')'
							exec (@sql)
							if @@rowcount = 0
								begin
									print ' для приходного документа нет расходов через акты'
									print ' поиск Расходных документов без актов'
									set @sql = 
										'insert into #conformdocs select * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
										''select de.basedochead, de.dochead  
											from dochead_export de 
											where de.basedochead = ' + @id+''')'
									exec (@sql)
									if @@rowcount = 0
										begin
											print ' для приходного документа нет расходов'
											insert into #conformdocs (receiptnumber) values (@id)
										end
								end
							print '<<< удаляем обработанный документ '+@id
							delete from #docsnumbers where id_dochead = @id
						end

						print ' выбираем номера приходных документов для обработки'
						insert into #docsnumbers select distinct receiptnumber from #conformdocs
						while (exists(select top(1) * from #docsnumbers))
							begin
								select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
								print ' вставляем в #sm_docsr детали документа ' +@id
								set @sql = 
									'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
								exec (@sql)
								delete from #docsnumbers where id_dochead = cast (@id as int)
							end

						print ' выбираем расходные документы через акты для обработки'
						insert into #docsnumbers select distinct ordernumber from #conformdocs where isnull(ordernumber,0) != 0
							while (exists(select top(1) * from #docsnumbers))
								begin
									select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
									set @sql = 
										'insert into #sm_docso ' + @sql_seldoc + @id+''')'
									exec (@sql)
									delete from #docsnumbers where id_dochead = cast (@id as int)
								end

						print ' выбираем номера документов смаркет'
						insert into #docsnumbers select distinct receiptnumber from #conformdocs

						print ' проверка соответствия приходных документов смаркет - инфор'
						while ((select count(id_dochead) from #docsnumbers) > 0)
							begin
								select top(1) @id = id_dochead from #docsnumbers
								print 'проверка документа '+@id
								if (not exists(
									select top(1) sdo.docnumber
										from #sm_docsr sdr join #conformdocs cd on sdr.docnumber = cd.receiptnumber
											left join #sm_docso sdo on sdo.docnumber = cd.ordernumber and sdo.sku = sdr.sku
											join #wm_docs wd on wd.smdocnumber = 'SM'+sdr.docnumber and wd.sku = sdr.sku
										where sdr.docnumber = @id and (sdr.storerkey != wd.storerkey or 'SM'+sdr.storerkey2 != wd.storerkey2 
												or sdr.nds != wd.nds or sdr.unitprice != wd.unitprice or ((wd.qty-wd.qtybrack)-(sdr.qty-isnull(sdo.qty,0))) != 0) ))
									begin
										print ' в документах есть расхождения, удаляем их из выборки '+@id
										delete from sdr from #sm_docsr sdr where sdr.docnumber = @id
										delete from sdo from #sm_docso sdo join #conformdocs cd on sdo.docnumber = cd.ordernumber where cd.receiptnumber = @id
										delete from wd from #wm_docs wd where wd.smdocnumber = 'SM'+@id
									end
								print ' удаляем обработанный документ '+@id
								delete from #docsnumbers where id_dochead = @id
							end
				end

			if @typedocument = 1
			-- РАСХОД - РАСХОЖДЕНИЯ ----------------------------------------------------------------------
				begin 
					print ' расходные документы @typedocument = 0'
					print ' выбор номеров расходных документов'
					set @sql = @sql + @where_order
					exec(@sql)

					print ' выбор документов инфор по номерам расходных документов смаркет'
					insert into #wm_docs
						select distinct
							o.orderkey, 
							o.externorderkey, 
							o.storerkey, 
							o.b_company, 
							o.adddate,
							od.sku, 
							od.unitprice, 
							od.tax01,
							case when o.status >= '92' then od.shippedqty else od.openqty end,
							0
						from #docsnumbers cd join wh1.orders o on 'SM'+cast(cd.id_dochead as varchar(15)) = o.externorderkey
							join wh1.orderdetail od on o.orderkey = od.orderkey 

					print ' удаляем документы смаркет, отсутвующие в инфор'
					delete from dn
						from #docsnumbers dn full join #wm_docs wd on 'SM'+cast(dn.id_dochead as varchar(15)) = wd.smdocnumber 
						where wd.smdocnumber is null

					insert into #conformdocs select id_dochead, null from #docsnumbers

					print ' выбираем номера расходных документов для обработки'
					while (exists(select top(1) * from #docsnumbers))
						begin
							select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
							print ' вставляем в #sm_docsr детали документа ' +@id
							set @sql = 
								'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
							exec (@sql)
							delete from #docsnumbers where id_dochead = cast (@id as int)
						end

					print ' выбираем номера расходных документов для обработки'
					insert into #docsnumbers select distinct receiptnumber from #conformdocs
					print ' проверка соответствия расходных документов смаркет - инфор'
					while ((select count(id_dochead) from #docsnumbers) > 0)
						begin
							select top(1) @id = id_dochead from #docsnumbers
							print 'проверка документа '+@id
							if (exists(
									select top(1) sdr.docnumber
										from #sm_docsr sdr join #conformdocs cd on sdr.docnumber = cd.receiptnumber
											left join #sm_docso sdo on sdo.docnumber = cd.ordernumber and sdo.sku = sdr.sku
											join #wm_docs wd on wd.smdocnumber = 'SM'+sdr.docnumber and wd.sku = sdr.sku
										where sdr.docnumber = @id and (sdr.storerkey = wd.storerkey and 'SM'+sdr.storerkey2 = wd.storerkey2 
												and sdr.nds = wd.nds and sdr.unitprice = wd.unitprice and (wd.qty-(sdr.qty-isnull(sdo.qty,0))) = 0) ))
									begin
										print ' в документах нет расхождений, удаляем их из выборки '+@id
										delete from sdr from #sm_docsr sdr where sdr.docnumber = @id
										delete from sdo from #sm_docso sdo join #conformdocs cd on sdo.docnumber = cd.ordernumber where cd.receiptnumber = @id
										delete from wd from #wm_docs wd where wd.smdocnumber = 'SM'+@id
									end
								print ' удаляем обработанный документ '+@id
								delete from #docsnumbers where id_dochead = @id
							end
				end
		end

	/* > SMarket */
	if @typeverification = 3
		begin
			print 'SMarket ''@typeverification = 3'''
			-- ПРИХОД - ТОЛЬКО СМАРКЕТ ----------------------------------------------------------------------
			if @typedocument = 0
				begin 
					print 'приходные документы ''@typedocument = 0'''
					print ' выбор номеров приходных документов'
					set @sql = @sql + @where_receipt
					exec(@sql)

					print ' удаляем документы смаркет, существующие в инфор'
					delete from dn
						from #docsnumbers dn join wh1.po p on 'SM'+cast(dn.id_dochead as varchar(15)) = p.externpokey 

					while (exists(select top(1) * from #docsnumbers))
						begin
							select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
							print ' вставляем в #sm_docsr детали документа ' +@id
							set @sql = 
								'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
							exec (@sql)
							delete from #docsnumbers where id_dochead = cast (@id as int)
						end

				end

			if @typedocument = 1
			-- РАСХОД - ТОЛЬКО СМАРКЕТ ----------------------------------------------------------------------
				begin 
					print 'расходные документы ''@typedocument = 1'''
					print ' выбор номеров расходных документов'
					set @sql = @sql + @where_order
					exec(@sql)

					print ' удаляем документы смаркет, существующие в инфор'
					delete from dn
						from #docsnumbers dn join wh1.orders o on 'SM'+cast(dn.id_dochead as varchar(15)) = o.externorderkey 

					while (exists(select top(1) * from #docsnumbers))
						begin
							select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
							print ' вставляем в #sm_docsr детали документа ' +@id
							set @sql = 
								'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
							exec (@sql)
							delete from #docsnumbers where id_dochead = cast (@id as int)
						end
				end
		end
	/* > infor WM */
	if @typeverification = 4
		begin
			print 'Infor WM ''@typeverification = 4'''
--			 ПРИХОД - ТОЛЬКО ИНФОР ----------------------------------------------------------------------
			if @typedocument = 0
				begin 
					print 'приходные документы ''@typedocument = 0'''
					print ' выбор документов инфор по входным условиям'
					insert into #wm_docs
						select 
							po.pokey, 
							po.externpokey, 
							po.storerkey, 
							po.sellersreference, 
							po.adddate,
							pd.sku, 
							pd.unitprice, 
							pd.unit_cost,
							pd.qtyreceived,
							pd.qtyrejected
						from wh1.po po join wh1.podetail pd on po.pokey = pd.pokey 
						where (po.storerkey = '92' or po.storerkey = '219') and
							po.adddate > @startdate and po.adddate < @enddate

					print ' выбираем номера документов инфор для обработки'
					insert into #conformdocs select distinct cast(substring(smdocnumber,3,100) as int),null from #wm_docs

					print ' удаляем документы существующие в смаркет'
					while (exists(select top(1) receiptnumber from #conformdocs)) 
						begin
							select top(1) @id = cast(receiptnumber as varchar(50)) from #conformdocs  
							print 'документ '+@id
							set @sql = 
								@sql_docnum + @id+''')'
							exec (@sql)

							if ((select count(id_dochead) from #docsnumbers ) > 0)
								begin
									print ' есть документ в смаркет, удаляем'
									delete from #docsnumbers
									delete from #wm_docs where smdocnumber = 'SM'+cast(@id as varchar(20))
								end
							delete from #conformdocs where receiptnumber = cast(@id as int)
						end

					print ' подготовка приходных документов инфор'
						insert into #wmsum
							select docnumber, smdocnumber, sum(qty*unitprice) wm_sum
							from #wm_docs group by docnumber, smdocnumber
										
					insert into #result (wmdocnumber,wm_sum)
						select docnumber,wm_sum from #wmsum
				end

			if @typedocument = 1
--			 РАСХОД - ТОЛЬКО ИНФОР ----------------------------------------------------------------------
				begin 
					print 'расходные документы ''@typedocument = 1'''
					print ' выбор документов инфор по входным условиям'
					insert into #wm_docs
						select 
							o.orderkey, 
							isnull(o.externorderkey,''), 
							o.storerkey, 
							o.b_company, 
							o.adddate,
							od.sku, 
							od.unitprice, 
							od.tax01,
							case when o.status >= '92' then od.shippedqty else od.openqty end,
							0
						from wh1.orders o join wh1.orderdetail od on o.orderkey = od.orderkey 
						where --substring(o.externorderkey,1,2) = 'SM' 
							--and 
							(o.storerkey = '92' or o.storerkey = '219')
							and o.type != '26'
							and o.adddate > @startdate and o.adddate < @enddate

					print ' выбираем номера документов инфор для обработки'
					insert into #conformdocs select distinct cast(substring(smdocnumber,3,100) as int),null from #wm_docs

					print ' удаляем документы существующие в смаркет'
					while (exists(select top(1) receiptnumber from #conformdocs)) 
						begin
							select top(1) @id = cast(receiptnumber as varchar(50)) from #conformdocs  
							print 'документ '+@id
							set @sql = 
								@sql_docnum + @id+''')'
							exec (@sql)

							if ((select count(id_dochead) from #docsnumbers ) > 0)
								begin
									print ' есть документ в смаркет, удаляем'
									delete from #docsnumbers
									delete from #wm_docs where smdocnumber = 'SM'+cast(@id as varchar(20))
								end
							delete from #conformdocs where receiptnumber = cast(@id as int)
						end

					print ' подготовка приходных документов инфор'
						insert into #wmsum
							select docnumber, smdocnumber, sum(qty*unitprice) wm_sum
							from #wm_docs group by docnumber, smdocnumber
										
					insert into #result (wmdocnumber,wm_sum)
						select docnumber,wm_sum from #wmsum
				end
		end

print ' приходные документы смаркет'
	insert into #result
		select '          ' wmdocnumber, 0 sort, sdr.docnumber smdocnumber,
			sdr.docnumber, sdr.storerkey_name, sdr.storerkey, sdr.storerkey2_name, sdr.storerkey2, su.name_user, sdr.manager, 
			sk.name_dockind, sdr.dockind, sd.name_doctype, sdr.doctype, op.name_operation, sdr.operation, ps.name_post_status, sdr.post_status, sdr.adddate, sum(qty*unitprice) sm_sum,
			0.0 wm_sum
		from #sm_docsr sdr join #sm_user su on sdr.manager=su.id_user
			join #sm_dk sk on sk.id_dockind = sdr.dockind
			join #sm_dt sd on sd.id_doctype = sdr.doctype
			join #sm_op op on op.id_operation = sdr.operation
			join #sm_ps ps on ps.id_post_status = sdr.post_status
		group by sdr.docnumber, sdr.storerkey_name, sdr.storerkey, sdr.storerkey2_name, sdr.storerkey2, su.name_user, sdr.manager, 
			sk.name_dockind, sdr.dockind, sd.name_doctype, sdr.doctype, op.name_operation, sdr.operation, ps.name_post_status, sdr.post_status, sdr.adddate

print ' расходные документы смаркет'
	insert into #result
		select 
			'          ' wmdocnumber, 1 sort, cd.receiptnumber smdocnumber,
			sdo.docnumber, sdo.storerkey_name, sdo.storerkey, sdo.storerkey2_name, sdo.storerkey2, su.name_user, sdo.manager, 
			sk.name_dockind, sdo.dockind, sd.name_doctype, sdo.doctype, op.name_operation, sdo.operation, ps.name_post_status, sdo.post_status, sdo.adddate, sum(qty*unitprice) sm_sum,
			0.0 wm_sum
		from #sm_docso sdo join #conformdocs cd on sdo.docnumber = cd.ordernumber
			join #sm_user su on sdo.manager=su.id_user
			join #sm_dk sk on sk.id_dockind = sdo.dockind
			join #sm_dt sd on sd.id_doctype = sdo.doctype
			join #sm_op op on op.id_operation = sdo.operation
			join #sm_ps ps on ps.id_post_status = sdo.post_status
		group by cd.receiptnumber, sdo.docnumber, sdo.storerkey_name, sdo.storerkey, sdo.storerkey2_name, sdo.storerkey2, su.name_user, sdo.manager, 
			sk.name_dockind, sdo.dockind, sd.name_doctype, sdo.doctype, op.name_operation, sdo.operation, ps.name_post_status, sdo.post_status, sdo.adddate

print ' подготовка приходных документов инфор'
	insert into #wmsum
		select docnumber, smdocnumber, sum(qty*unitprice) wm_sum
		from #wm_docs group by docnumber, smdocnumber

 print ' обновление данных из документов инфор'
	update r
		set r.wmdocnumber = wd.docnumber, r.wm_sum = wd.wm_sum
		from #wmsum wd join #result r on 'SM'+r.docnumber = wd.smdocnumber

--вывод результатов
select * from #result order by smdocnumber, sort, adddate

drop table #result
--drop table #tmp
drop table #docsnumbers
drop table #wmsum
drop table #conformdocs
drop table #sm_docso
drop table #sm_docsr
drop table #wm_docs
drop table #sm_user
drop table #sm_ps
drop table #sm_dt
drop table #sm_dk
drop table #sm_op
