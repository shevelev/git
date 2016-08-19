ALTER PROCEDURE [dbo].[check_detail] (
	@dockey varchar (15),
	@typedocument int, -- тип документа
				-- 0-Приемка
				-- 1-Расход
				-- 3-Пересчеты
				-- 4-Перемещения
				-- 5-Инвентаризация
	@system int
				-- 0-Infor WM
				-- 1-S-Maket
)
as

create table #result (
	linenumber int,
	articul int,
	descr varchar (80),
	sm_qty numeric (20,5),
	sm_unitprice numeric (20,5),
	sm_unitprice_1 numeric (20,5),
	sm_nds numeric (20,5),
	sm_summ numeric (20,5),
	sm_summ_1 numeric(20,5),
	wm_qty numeric(20,5),
	wm_unitprice numeric(20,5),
	wm_nds numeric(20,5),
	wm_summ numeric (20,5),
	wm_client varchar (25),
	sm_client varchar (25),
	wm_clientname varchar (80),
	sm_clientname varchar (80),
	wm_susr5 varchar(50),
	sm_storerkey varchar(15), --shopindex
	wm_storerkey varchar(15) null
)

select * into #result_r from #result where 1=2

--declare
--	@dockey varchar (15),
--	@typedocument int, -- тип документа
----				 0-Приемка
----				 1-Расход
----				 3-Пересчеты
----				 4-Перемещения
----				 5-Инвентаризация
--	@system int
----				 0-Infor WM
----				 1-S-Maket
--
--set @dockey = '4464409'
--set @typedocument = 0
--set @system = 1


declare 
	@sql nvarchar(4000),
	@start_infor_date datetime,
	@dockey_sm varchar (15),
	@dockey_iwm varchar (15)

-- дата начала обработки документов (запуск инфор)
set @start_infor_date = '2009-10-01 00:00:00.000'

	if @typedocument = 0
		begin
			print 'приходный документ'
-- определение системы документа
			if @system = 0
				begin
					print 'документ Infor WM'
					select @dockey_sm = substring(externpokey,3,20) from wh1.po where cast(pokey as int) = @dockey
					set @dockey_iwm = 'SM'+@dockey_sm
				end
			if @system = 1
				begin
					print 'документ S-Market'
					set @dockey_sm = @dockey
					set @dockey_iwm = 'SM'+@dockey
				end
			print 'pokey = '+ @dockey_iwm+', id_dochead = ' + @dockey_sm
			set @sql =
			'insert into #result
			SELECT r_linenumber,r_articul,r_descr,sm_qty,sm_unitprice,sm_unitprice_1,sm_nds,sm_summs,sm_summs_1,0,0,0,0,'''',client_index,'''',name_clients,'''',sm_storerkey,''''
				FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
					''select 
					ds.pos_number r_linenumber, 
					ds.articul r_articul,
					cs.name r_descr, 
					ds.quantity sm_qty, 
					ds.pricerub sm_unitprice, 
					ds.pricerub_1 sm_unitprice_1, 
					ts.tax1 sm_nds,
					ds.quantity*ds.pricerub sm_summs, 
					ds.quantity*ds.pricerub_1 sm_summs_1,
					dh.client_index,
					cl.name_clients,
					dh.shopindex sm_storerkey
					from dochead dh join docspec ds on dh.id_dochead = ds.id_dochead 
					join taxspec ts on ds.taxhead = ts.taxhead and tax_kind = 0
					join cardscla cs on cs.articul = ds.articul 
					join clients cl on dh.client_index = cl.id_clients
					where dh.id_dochead = ' + @dockey_sm+''')'
			print 'детали документа смаркет'
print @sql
			exec (@sql)
			print 'детали документа инфор'
			insert into #result_r
				(linenumber,
				articul,
				descr,
				sm_qty,
				sm_unitprice,
				sm_unitprice_1,
				sm_nds,
				sm_summ,
				sm_summ_1,
				wm_qty,
				wm_unitprice,
				wm_nds,
				wm_summ,
				wm_client,
				sm_client,
				wm_clientname,
				sm_clientname,
				wm_susr5,
				sm_storerkey,
				wm_storerkey)
			select
				'',pd.sku,s.descr,0,0,0,0,0,0,
				case when p.status >= '11' then pd.qtyreceived else pd.qtyadjusted end wm_qty,
				pd.unitprice wm_unitprice,
				pd.unit_cost wm_nds,
				case when p.status >= '11' then pd.unitprice*pd.qtyreceived else pd.unitprice*pd.qtyadjusted end wm_summ,
				p.sellersreference wm_client,'' sm_client,st.company wm_clientname,'' sm_clientname,'' wm_susr5, '' sm_storerkey, pd.storerkey wm_storerkey
			from wh1.podetail pd join wh1.sku s on pd.sku = s.sku 
				join wh1.po p on p.pokey = pd.pokey
				join wh1.storer st on p.sellersreference = st.storerkey
				where pd.externpokey = @dockey_iwm
			print 'вывод объеденных результатов'
			select distinct 
				r.linenumber,
				case when isnull(r.articul,'') = '' then r_r.articul else r.articul end articul,
				case when isnull(r.descr,'') = '' then r_r.descr else r.descr end descr,
				r.sm_qty,
				r.sm_unitprice sm_unitprice,
				r.sm_unitprice_1 sm_unitprice_1,
				r.sm_nds sm_nds,
				r.sm_summ sm_summ,
				r.sm_summ_1 sm_summ_1,
				r_r.wm_qty wm_qty,
				r_r.wm_unitprice wm_unitprice,
				r_r.wm_nds wm_nds,
--				round(r_r.wm_summ,2) wm_summ,
				r_r.wm_qty*r_r.wm_unitprice wm_summ,
				substring(r_r.wm_client,3,15) wm_client,
				r.sm_client,
				r_r.wm_clientname,
				r.sm_clientname,
				r_r.wm_susr5,
				r.sm_storerkey,
				r_r.wm_storerkey
			from #result r full join #result_r r_r on r.articul = r_r.articul
--			where (isnull(r.articul,'') != '' and r_r.wm_qty != 0) 
--				or (isnull(r_r.articul,'') != '' and r.sm_qty != 0)
			where r_r.wm_qty != 0 or r.sm_qty != 0
			order by r.linenumber

--select * from #result
--select * from #result_r

			drop table #result
			drop table #result_r
		end
	if @typedocument = 1
		begin
			print 'расходный документ'
-- определение системы документа
			if @system = 0
				begin
					print 'документ Infor WM'
					select @dockey_sm = substring(externorderkey,3,20) from wh1.orderdetail where cast(orderkey as int) = @dockey
					set @dockey_iwm = 'SM'+@dockey_sm
				end
			if @system = 1
				begin
					print 'документ S-Market'
					set @dockey_sm = @dockey
					set @dockey_iwm = 'SM'+@dockey
				end
			print 'orderkey = '+ @dockey_iwm+', id_dochead = ' + @dockey_sm
			set @sql =
			'insert into #result
			SELECT r_linenumber,r_articul,r_descr,sm_qty,sm_unitprice,sm_unitprice_1,sm_nds,sm_summs,sm_summs_1,0,0,0,0,'''',client_index,'''',name_clients,'''',sm_storerkey,''''
				FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
					''select 
					ds.pos_number r_linenumber, 
					ds.articul r_articul,
					cs.name r_descr, 
					ds.quantity sm_qty, 
					ds.pricerub sm_unitprice, 
					ds.pricerub_1 sm_unitprice_1, 
					ts.tax1 sm_nds,
					ds.quantity*ds.pricerub sm_summs, 
					ds.quantity*ds.pricerub_1 sm_summs_1,
					dh.client_index,
					cl.name_clients,
					dh.shopindex sm_storerkey
					from dochead dh join docspec ds on dh.id_dochead = ds.id_dochead 
					join taxspec ts on ds.taxhead = ts.taxhead and tax_kind = 0
					join cardscla cs on cs.articul = ds.articul 
					join clients cl on dh.client_index = cl.id_clients
					where dh.id_dochead = ' + @dockey_sm+''')'
			print 'выборка деталей документа смаркет'
			exec (@sql)
			print 'детали документа инфор'
			insert into #result_r
				(linenumber,
				articul,
				descr,
				sm_qty,
				sm_unitprice,
				sm_unitprice_1,
				sm_nds,
				sm_summ,
				sm_summ_1,
				wm_qty,
				wm_unitprice,
				wm_nds,
				wm_summ,
				wm_client,
				sm_client,
				wm_clientname,
				sm_clientname,
				wm_susr5,
				sm_storerkey,
				wm_storerkey)
			select
				'',od.sku,s.descr,0,0,0,0,0,0,case when o.status >= '92' then od.shippedqty else od.openqty end,
				od.unitprice,
				od.tax01, 
				case when o.status >= '92' then od.unitprice*od.shippedqty else od.unitprice*od.openqty end,
				o.b_company, '', st.company, '', o.susr5, '' sm_storerkey, o.storerkey wm_storerkey
			from wh1.orderdetail od join wh1.sku s on od.sku = s.sku and od.storerkey = s.storerkey
				join wh1.orders o on o.orderkey = od.orderkey
				join wh1.storer st on o.b_company = st.storerkey
				where od.externorderkey = @dockey_iwm
			print 'вывод результатов'
			select  distinct
				r.linenumber,
				case when isnull(r.articul,'') = '' then r_r.articul else r.articul end articul,
				case when isnull(r.descr,'') = '' then r_r.descr else r.descr end descr,
				r.sm_qty,
				r.sm_unitprice sm_unitprice,
				r.sm_unitprice_1 sm_unitprice_1,
				r.sm_nds sm_nds,
				r.sm_summ sm_summ,
				r.sm_summ_1 sm_summ_1,
				r_r.wm_qty wm_qty,
				r_r.wm_unitprice wm_unitprice,
				r_r.wm_nds wm_nds,
--				round(r_r.wm_summ,2) wm_summ,
				r_r.wm_qty*r_r.wm_unitprice wm_summ,
				substring(r_r.wm_client,3,15) wm_client,
				r.sm_client,
				r_r.wm_clientname,
				r.sm_clientname,
				r_r.wm_susr5,
				r.sm_storerkey,
				r_r.wm_storerkey
			from #result r full join #result_r r_r on r.articul = r_r.articul
--			where (isnull(r.articul,'') != '' and r_r.wm_qty != 0) 
--				or (isnull(r_r.articul,'') != '' and r.sm_qty != 0)
			where r_r.wm_qty != 0 or r.sm_qty != 0

			order by r.linenumber

			drop table #result
			drop table #result_r
		end	
	if @typedocument = 3
		begin
			print 'пересчеты'
			create table #idp (ext_docindex int)
			if @system = 0
				begin
					print 'документ Infor WM'
					set @dockey_sm = cast(cast(@dockey as int) as varchar(10))
					set @dockey_iwm = @dockey

					print 'batchkey = '+ @dockey_iwm+', ext_docindex = ' + @dockey_sm
					set @sql =
					'insert into #result
					SELECT r_linenumber,r_articul,r_descr,sm_qty,sm_unitprice,sm_unitprice_1,sm_nds,sm_summs,sm_summs_1,0,0,0,0,'''','''','''','''','''',sm_storerkey,''''
						FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
							''select 
							ds.pos_number r_linenumber, 
							ds.articul r_articul,
							cs.name r_descr, 
							case when dh.dockind = ''''0'''' then ds.quantity else ds.quantity * (-1) end sm_qty, 
							0 sm_unitprice, 
							0 sm_unitprice_1, 
							0 sm_nds, 
							0 sm_summs, 
							0 sm_summs_1,
							dh.shopindex sm_storerkey
							from dochead dh join docspec ds on dh.id_dochead = ds.id_dochead 
							join cardscla cs on cs.articul = ds.articul 
							where 
								((dh.doctype = 1470 or dh.doctype = 1472 or dh.doctype = 1471 or dh.doctype = 1473)  and (dh.dockind = 1 or dh.dockind = 0))
								and dh.ext_docindex = ''''' +@dockey_sm+''''''')'
					exec (@sql)
print @sql
					select sum(deltaqty) qty,sku,storerkey into #result_iwm from da_adjustment where cast(batchkey as int) = cast (@dockey_iwm as int) group by sku,storerkey
--select * from #result_iwm
					update r set r.wm_qty = ri.qty, r.wm_unitprice = 0, r.wm_nds = 0, r.wm_summ = 0, r.wm_storerkey = ri.storerkey
						from #result_iwm ri join #result r on r.articul = cast(ri.sku as int)
					drop table #result_iwm
				end
			if @system = 1
				begin
					print 'документ S-Market'
					set @sql = 'insert into #idp SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
					''select ext_docindex from dochead where id_dochead = '''''+@dockey+''''''')'
--print @sql select * from #idp
					exec (@sql)
					select @dockey_sm = cast(cast(ext_docindex as int)as varchar(10)) from #idp
					set @dockey_iwm = @dockey_sm

					print 'batchkey = '+ @dockey_iwm+', ext_docindex = ' + @dockey_sm
					set @sql =
					'insert into #result
					SELECT r_linenumber,r_articul,r_descr,sm_qty,sm_unitprice,sm_unitprice_1,sm_nds,sm_summs,sm_summs_1,0,0,0,0,'''','''','''','''','''',sm_storerkey,''''
						FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
							''select 
							ds.pos_number r_linenumber, 
							ds.articul r_articul,
							cs.name r_descr, 
							case when dh.dockind = ''''0'''' then ds.quantity else ds.quantity * (-1) end sm_qty, 
							0 sm_unitprice, 
							0 sm_unitprice_1, 
							0 sm_nds, 
							0 sm_summs, 
							0 sm_summs_1,
							dh.shopindex sm_storerkey
							from dochead dh join docspec ds on dh.id_dochead = ds.id_dochead 
							join cardscla cs on cs.articul = ds.articul 
							where dh.id_dochead = ''''' +@dockey+''''''')'
print @sql
					exec (@sql)

					select sum(deltaqty) qty,sku,storerkey into #result_iwm1 from da_adjustment where cast(batchkey as int) = cast(@dockey_iwm as int) group by sku,storerkey

					update r set r.wm_qty = ri.qty, r.wm_unitprice = 0, r.wm_nds = 0, r.wm_summ = 0, r.wm_storerkey = ri.storerkey
						from #result_iwm1 ri join #result r on r.articul = cast(ri.sku as int)
					drop table #result_iwm1
				end

			drop table #idp 

			select * from #result
			drop table #result
			drop table #result_r


		end	
	if @typedocument = 4
		begin
			print 'перемещения'
			create table #idr (ext_docindex int)
			if @system = 0
				begin
					print 'документ Infor WM'
					set @dockey_sm = cast(cast(@dockey as int) as varchar(10))
					set @dockey_iwm = @dockey
				end
			if @system = 1
				begin
					print 'документ S-Market'
					set @sql = 'insert into #idr SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
					''select ext_docindex from dochead where id_dochead = '''''+@dockey+''''''')'
--print @sql select * from #idr
					exec (@sql)
					select @dockey_sm = cast(cast(ext_docindex as int)as varchar(10)) from #idr
					set @dockey_iwm = @dockey_sm
				end
			drop table #idr 
			print 'itrnkey = '+ @dockey_iwm+', ext_docindex = ' + @dockey_sm
			set @sql =
			'insert into #result
			SELECT r_linenumber,r_articul,r_descr,sm_qty,sm_unitprice,sm_unitprice_1,sm_nds,sm_summs,sm_summs_1,0,0,0,0,'''','''','''','''','''',sm_storerkey,''''
				FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
					''select 
					ds.pos_number r_linenumber, 
					ds.articul r_articul,
					cs.name r_descr, 
					ds.quantity sm_qty, 
					0 sm_unitprice, 
					ds.pricerub_1 sm_unitprice_1, 
					0 sm_nds, 
					0 sm_summs, 
					ds.quantity*ds.pricerub_1 sm_summs_1,
					dh.shopindex sm_storerkey
					from dochead dh join docspec ds on dh.id_dochead = ds.id_dochead 
					join cardscla cs on cs.articul = ds.articul 
					where dh.ext_docindex = ''''' +@dockey_sm+''''''')'
			print 'выборка деталей документа Смаркет'
			exec (@sql)

			print 'детали документа инфор'
			insert into #result_r
				(linenumber,
				articul,
				descr,
				sm_qty,
				sm_unitprice,
				sm_unitprice_1,
				sm_nds,
				sm_summ,
				sm_summ_1,
				wm_qty,
				wm_unitprice,
				wm_nds,
				wm_summ,
				wm_client,
				sm_client,
				wm_clientname,
				sm_clientname,
				wm_susr5,
				sm_storerkey,
				wm_storerkey)
			select
				'',i.sku,s.descr,0,0,0,0,0,0,i.qty,0,0,0,'','','','','','',i.storerkey
			from wh1.itrn i join wh1.sku s on i.sku = s.sku and i.storerkey = s.storerkey
				where i.itrnkey = @dockey_iwm

			print 'вывод результатов'
			select  distinct
				r.linenumber,
				case when isnull(r.articul,'') = '' then r_r.articul else r.articul end articul,
				case when isnull(r.descr,'') = '' then r_r.descr else r.descr end descr,
				r.sm_qty,
				round(r.sm_unitprice,10) sm_unitprice,
				round(r.sm_unitprice_1,10) sm_unitprice_1,
				round(r.sm_nds,10) sm_nds,
				round(r.sm_summ,10) sm_summ,
				round(r.sm_summ_1,10) sm_summ_1,
				r_r.wm_qty,
				round(r_r.wm_unitprice,10) wm_unitprice,
				round(r_r.wm_nds,10) wm_nds,
				round(r_r.wm_summ,10) wm_summ,
				'' wm_client,
				'' sm_client,
				'' wm_clientname,
				'' sm_clientname,
				'' sm_susr5,
				r.sm_storerkey,
				r_r.wm_storerkey
			from #result r full join #result_r r_r on r.articul = r_r.articul
			drop table #result
			drop table #result_r
		end

