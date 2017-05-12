ALTER PROCEDURE [dbo].[check_doc]
	@startdate datetime, --��������� ���� ������� ������
	@enddate datetime,	--�������� ���� ������� ������
	@typeverification int, -- ��� ������ 
--				 1-��������� ������� ����������� � ����� �������� � �� ������� ����������� 
--				 2-��������� ������� ����������� �� � ������������� (�����������, ����, ����������, ���������� � ������ � �.�.)
--				 3-��������� S-������, �� ������� ������������ � Infor WM
--				 4-��������� Infor WM, �� ������� ������������ � S-������
	@typedocument int, -- ��� ���������
--				 0-�������
--				 1-������
--				 3-���������
--				 4-�����������
--				 5-��������������
	@storerkey varchar (20), -- ��� ���������
	@manager varchar (20) -- ��� ��������� Smarket

as
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
/*>>> ���������� ��������� >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
--use PRD1
--
--declare -- ��� ������ 
--	@typeverification int
--				-- 1-��������� ������� ����������� � ����� �������� � �� ������� ����������� 
--				-- 2-��������� ������� ����������� �� � ������������� (�����������, ����, ����������, ���������� � ������ � �.�.)
--				-- 3-��������� S-������, �� ������� ������������ � Infor WM
--				-- 4-��������� Infor WM, �� ������� ������������ � S-������
--
--declare -- ��� ���������
--	@typedocument int
--				-- 0-�������
--				-- 1-������
--				-- 3-���������
--				-- 4-�����������
--
--declare -- ��� ���������
--	@storerkey varchar (20)
-- 
--declare -- ��� ��������� Smarket
--	@manager varchar (20) 
--
--declare --��������� ���� ������� ������
--	@startdate datetime
--
--declare --�������� ���� ������� ������
--	@enddate datetime	
--
--	set @startdate = N'2010-01-11'
--	set @enddate = N'2010-01-11'
--	set @typeverification = 2
--	set @typedocument = 0
--	set @storerkey ='' -- '', ''92, '219'
--	set @manager = '' -- ''
/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*<<< ���������� ��������� <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
if (@startdate = @enddate) set @enddate = @startdate + 1 -- ����������� �������� ��� - 1 ����.
print @startdate
print @enddate
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
/*>>> �������� ��������� >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

	-- ������� � ���������������� �������
	print '������� ������������� USER -> #sm_user'
	SELECT * into #sm_user FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select * from users')

	print '������� �������� ���������� post_status -> #sm_ps'
	SELECT * into #sm_ps FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select * from post_status') 

	print '������� ����� ���������� doctype -> #sm_dt'
	SELECT * into #sm_dt FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select * from doctype') 

	print '������� ����� ���������� dockind -> #sm_dk'
	SELECT * into #sm_dk FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select * from dockind') 

	print '������� �������� operations -> #sm_dk'
	SELECT * into #sm_op FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select * from operations') 
	
	-- ������� ����������� ���������� �����
	CREATE TABLE [#wmsum](
		[docnumber] [varchar](15) NULL,
		[smdocnumber] [varchar](15) NULL,
		[wm_sum] [numeric](38, 17) NULL,
		[wmadddate] datetime null
	)

	-- ������� ����������� ���������� �������
create table #smsumm (
	receiptnumber int null,
	storerkey [varchar] (100) NULL,
	storerkey2 [varchar] (100) NULL,
	sku varchar(15),
	nds int,
	qty numeric (20,10)
)
	-- ������� �����������
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
		[wm_sum] [numeric](38, 17) NULL,
		[wmadddate] datetime null
	)

-- ������� ������� ����������� � �� ����������� �����������
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
	operation varchar (15),
	zone varchar (50) --dh.client2_index 
	--deltaqty numeric (20,10) --����� ����������� � ���������
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
	qtybrack numeric (20,10), --qtyrejected
	zone varchar (50) -- zone
	)

create table #docsnumbers(
	id_dochead int null,
	ext_docindex varchar(50) null
	)

declare -- ���� ������ ��������� ���������� (������ �����)
	@start_infor_date datetime
	set @start_infor_date = '2009-10-01 00:00:00.000'

declare -- ���������� �������������
	@id varchar(15)

declare -- ���������� ������ �������
	@sql_docnum varchar (max)

-- ���������� ����� ������� ��� ������ ������� ���������� �� ������� �����
	set @sql_docnum =
			'insert into #docsnumbers SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
				''select id_dochead, ext_docindex from dochead where id_dochead = '

declare -- ���������� ������ �������
	@sql varchar (max)

-- ���������� ����� ������� ������� ���������� � ���� ������� 
	set @sql =
			'insert into #docsnumbers SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
				''select 
				dh.id_dochead, dh.ext_docindex
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
											ds.pricerub unitprice,
											ts.tax1 nds,
											quantity qty, 
											dh.post_status,
											dh.manager,
											dh.operation,
											dh.client2_index zone
										from dochead dh join docspec ds on dh.id_dochead = ds.id_dochead
											join taxspec ts on ds.taxhead = ts.taxhead and tax_kind = 0
											join clients cl on dh.client_index = cl.id_clients
										where dh.id_dochead = '

declare -- ������� ��� ������ ��������� ����������
	@where_receipt varchar(500)
	set @where_receipt = ' and dh.post_status > 0 and (dh.doctype != 1470 and dh.doctype != 1472) and (dh.dockind = 0)'')'

declare -- ������� ��� ������ ��������� ����������
	@where_order varchar(500)
	set @where_order = ' and dh.post_status > 0 and (dh.doctype != 1471 and dh.doctype != 1473) and (dh.dockind = 1)'')'

declare -- ������� ��� ������ ����������
	@where_recount varchar(500)
	set @where_recount = case when isnull(@storerkey,'') = '' then ' and (dh.doctype = 1470 or dh.doctype = 1472 or dh.doctype = 1471 or dh.doctype = 1473)' else case when @storerkey = 92 then ' and (dh.doctype = 1470 or dh.doctype = 1471) ' else ' and (dh.doctype = 1472 or dh.doctype = 1473)' end end + ' and (dh.dockind = 1 or dh.dockind = 0)'

declare -- ������� ��� ������ �����������
	@where_mov varchar (500)
	set @where_mov = case when isnull(@storerkey,'') = '' then ' and (dh.doctype = 1148 or dh.doctype = 1431)' else case when @storerkey = 92 then ' and dh.doctype = 1148' else ' and dh.doctype = 1431' end end + ' and (dh.dockind = 2)'
/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*<<< �������� ��������� <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
/*>>> ��������� >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

/* >>> ������ ����������� >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
	if @typeverification = 1
		begin
			print '������ ����������� ''@typeverification = 1'''
			-- ������ - ������ ������������ ----------------------------------------------------------------------
			if @typedocument = 0
				begin
					print ' ��������� ��������� @typedocument = 0'
					print ' ����� ������� ��������� ����������'
					set @sql = @sql + @where_receipt
					exec(@sql)

					print ' ����� ���������� ����� �� ������� ��������� ���������� �������'
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
							pd.qtyrejected,
							'' zone
						from #docsnumbers cd join wh1.po po on 'SM'+cast(cd.id_dochead as varchar(15)) = po.externpokey
							join wh1.podetail pd on po.pokey = pd.pokey 

					print ' ������� ��������� �������, ����������� � �����'
					delete from dn
						from #docsnumbers dn full join #wm_docs wd on 'SM'+cast(dn.id_dochead as varchar(15)) = wd.smdocnumber 
						where wd.smdocnumber is null

					print ' ����� ��������� ���������� �� ��������� ����������'
					while (exists (select top(1) * from #docsnumbers))
						begin
							print @id
							select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
							print '>>> ������������ �������� '+@id
							print ' ����� ��������� ���������� ����� ����'
							set @sql = 
								'insert into #conformdocs select * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
								''select de.basedochead, dl.dochead  
									from dochead_export de join dochead_link dl on de.dochead = dl.basedochead
									where de.basedochead = ' + @id+''')'
							exec (@sql)
							if @@rowcount = 0
								begin
									print ' ��� ���������� ��������� ��� �������� ����� ����'
									print ' ����� ��������� ���������� ��� �����'
									set @sql = 
										'insert into #conformdocs select * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
										''select de.basedochead, de.dochead  
											from dochead_export de 
											where de.basedochead = ' + @id+''')'
									exec (@sql)
									if @@rowcount = 0
										begin
											print ' ��� ���������� ��������� ��� ��������'
											insert into #conformdocs (receiptnumber) values (@id)
										end
								end
							print '<<< ������� ������������ �������� '+@id
							delete from #docsnumbers where id_dochead = @id
						end

						print ' �������� ������ ��������� ���������� ��� ���������'
						insert into #docsnumbers (id_dochead) select distinct receiptnumber from #conformdocs
						while (exists(select top(1) * from #docsnumbers))
							begin
								select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
								print ' ��������� � #sm_docsr ������ ��������� ' +@id
								set @sql = 
									'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
								exec (@sql)
								delete from #docsnumbers where id_dochead = cast (@id as int)
							end

						print ' �������� ��������� ��������� ����� ���� ��� ���������'
						insert into #docsnumbers (id_dochead) select distinct ordernumber from #conformdocs where isnull(ordernumber,0) != 0
							while (exists(select top(1) * from #docsnumbers))
								begin
									select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
									set @sql = 
										'insert into #sm_docso ' + @sql_seldoc + @id+''')'
									exec (@sql)
									delete from #docsnumbers where id_dochead = cast (@id as int)
								end

						print ' �������� ������ ���������� �������'
						insert into #docsnumbers (id_dochead) select distinct receiptnumber from #conformdocs

						print ' �������� ������� (�������+����) �� �� ������� ��������� ����������'
						while (exists(select top(1) * from #docsnumbers))
							begin
								select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
								insert into #smsumm
								select cd.receiptnumber, sdo.storerkey, sdo.storerkey, sdo.sku, sdo.nds, sum (qty) qty--, sdo.storerkey2,sdo.nds,sdo.dockind,sdo.doctype
									from #conformdocs cd join #sm_docso sdo on cd.ordernumber = sdo.docnumber
									where cd.receiptnumber = @id
									group by cd.receiptnumber, sdo.storerkey,sdo.sku,sdo.nds--,sdo.storerkey,sdo.dockind,sdo.doctype
								delete from #docsnumbers where id_dochead = cast (@id as int)
						end

						print ' �������� ������ ���������� �������'
						insert into #docsnumbers (id_dochead) select distinct receiptnumber from #conformdocs

						print ' �������� ������������ ��������� ���������� ������� - �����'
						while ((select count(id_dochead) from #docsnumbers) > 0)
							begin
								select top(1) @id = id_dochead from #docsnumbers
								print '�������� ��������� '+@id
								if (exists(
									select top(1) sdr.*
										from #sm_docsr sdr 
										full join #wm_docs wd 
											on 'SM'+sdr.docnumber = wd.smdocnumber and
											sdr.sku = wd.sku and 
											sdr.storerkey = wd.storerkey and 
											'SM'+sdr.storerkey2 = wd.storerkey2 and 
											sdr.nds = wd.nds and 
											sdr.unitprice = wd.unitprice
										full join #smsumm ss on ss.receiptnumber = sdr.docnumber
											and ss.sku = isnull(sdr.sku,wd.sku)
											and ss.storerkey = isnull (sdr.storerkey,wd.storerkey)
											and ss.nds = isnull (sdr.nds,wd.nds)
										 where sdr.docnumber = @id and ((isnull(wd.qty,0)-isnull(wd.qtybrack,0))-(isnull(sdr.qty,0)-isnull(ss.qty,0))) != 0))
									begin
										print ' � ���������� ���� �����������, ������� �� �� ������� '+@id
										delete from sdr from #sm_docsr sdr where sdr.docnumber = @id
--										delete from sdo from #sm_docso sdo join #conformdocs cd on sdo.docnumber = cd.ordernumber where cd.receiptnumber = @id
										delete from wd from #wm_docs wd where wd.smdocnumber = 'SM'+@id
										delete from #conformdocs where receiptnumber = @id
									end
								print ' ������� ������������ �������� '+@id
								delete from #docsnumbers where id_dochead = @id
							end
				end


			if @typedocument = 1
			-- ������ - ������ ������������ ----------------------------------------------------------------------
				begin 
					print ' ��������� ��������� @typedocument = 0'
					print ' ����� ������� ��������� ����������'
					set @sql = @sql + @where_order
					exec(@sql)

					print ' ����� ���������� ����� �� ������� ��������� ���������� �������'
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
							0,
							'' zone
						from #docsnumbers cd join wh1.orders o on 'SM'+cast(cd.id_dochead as varchar(15)) = o.externorderkey
							join wh1.orderdetail od on o.orderkey = od.orderkey 

					print ' ������� ��������� �������, ����������� � �����'
					delete from dn
						from #docsnumbers dn full join #wm_docs wd on 'SM'+cast(dn.id_dochead as varchar(15)) = wd.smdocnumber 
						where wd.smdocnumber is null

					print ' �������� ������ ��������� ���������� ��� ���������'
					insert into #docsnumbers (id_dochead) select distinct receiptnumber from #conformdocs
					while (exists(select top(1) * from #docsnumbers))
						begin
							select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
							print ' ��������� � #sm_docsr ������ ��������� ' +@id
							set @sql = 
								'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
							exec (@sql)
							delete from #docsnumbers where id_dochead = cast (@id as int)
						end

					print ' �������� ������ ��������� ���������� ��� ���������'
					insert into #docsnumbers (id_dochead) select distinct receiptnumber from #conformdocs
					print ' �������� ������������ ��������� ���������� ������� - �����'
					while ((select count(id_dochead) from #docsnumbers) > 0)
						begin
							select top(1) @id = id_dochead from #docsnumbers
							print '�������� ��������� '+@id
							if (exists(
									select top(1) sdr.docnumber
										from #sm_docsr sdr join #conformdocs cd on sdr.docnumber = cd.receiptnumber
											left join #sm_docso sdo on sdo.docnumber = cd.ordernumber and sdo.sku = sdr.sku
											join #wm_docs wd on wd.smdocnumber = 'SM'+sdr.docnumber and wd.sku = sdr.sku
										where sdr.docnumber = @id and (sdr.storerkey != wd.storerkey or 'SM'+sdr.storerkey2 != wd.storerkey2 
												or sdr.nds != wd.nds or sdr.unitprice != wd.unitprice or (wd.qty-(sdr.qty-isnull(sdo.qty,0))) != 0) ))
									begin
										print ' � ���������� ���� �����������, ������� �� �� ������� '+@id
										delete from sdr from #sm_docsr sdr where sdr.docnumber = @id
--										delete from sdo from #sm_docso sdo join #conformdocs cd on sdo.docnumber = cd.ordernumber where cd.receiptnumber = @id
										delete from wd from #wm_docs wd where wd.smdocnumber = 'SM'+@id
										delete from #conformdocs where receiptnumber = @id
									end
								print ' ������� ������������ �������� '+@id
								delete from #docsnumbers where id_dochead = @id
							end
				end
			if @typedocument = 3
			-- ��������� - ������ ������������ -----------------------------------------------------------------
				begin
					print '��������� ''dockind = 0,1'''
					print '����� ���������� �������'
					set @sql = @sql + @where_recount +''')' 
					exec (@sql)

					print ' �������� ���������� ��� ������� ������� ���������� '
					delete from dn 
						from #docsnumbers dn left join da_adjustment da on dn.ext_docindex = cast(da.batchkey as int)
						where da.batchkey is null

					insert into #conformdocs select * from #docsnumbers

					print ' ����� ���������� �����'
					insert into #wm_docs 
						select 
							da.batchkey docnumber,
							null smdocnumber,
							storerkey storerkey,
							'' storerkey2,
							null adddate,
							da.sku sku,
							0 unitprice,
							0 nds,
							sum(deltaqty) qty,
							0 qtybrack,
							da.zone zone
						from da_adjustment da join #conformdocs cd on cast(da.batchkey as int) = cd.ordernumber
						group by da.batchkey, storerkey, da.sku, da.zone

					print ' ������� ���� ���������� �����'
					update wd set adddate = (select max(editdate) 
						from da_adjustment da where da.batchkey = wd.docnumber)
						from #wm_docs wd

					print ' �������� ������ ���������� ��� ���������'
					while (exists(select top(1) * from #docsnumbers))
						begin
							select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
							print ' ��������� � #sm_docsr ������ ��������� ' + @id
							set @sql = 
								'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
							exec (@sql)
							delete from #docsnumbers where id_dochead = cast (@id as int)
						end

					print ' ��������� ����� � ���������� � ���������� �� ���� ���������'
					update #sm_docsr set qty = case when dockind = '0' then qty else qty * (-1) end

					print ' ����������� ��������� ������� �� ������� �����'
					insert into #sm_docso (wmdocnumber, sku, zone, storerkey, qty)
					select wmdocnumber, sku, zone, storerkey, sum(qty) qty 
						from #sm_docsr
						group by wmdocnumber, sku, zone, storerkey
					
					print ' �������� ������ ���������� ������� ����� ��� ���������'
					insert into #docsnumbers select distinct null, ordernumber from #conformdocs 
					
					print ' ��������� ������� ���������� ����� � �������'
					while (exists(select top(1) * from #docsnumbers)) 
						begin
							select top(1) @id = ext_docindex from #docsnumbers
							
							if ((select count (*)
									from #sm_docso sdo join #wm_docs wd 
										on cast(sdo.wmdocnumber as int) = cast(wd.docnumber as int)
										and sdo.storerkey = wd.storerkey
										and sdo.sku = wd.sku
										and sdo.zone = wd.zone
										and sdo.qty = wd.qty
									where sdo.wmdocnumber = @id) != 
								(select count (*)
									from #sm_docso sdo full join #wm_docs wd 
										on cast(sdo.wmdocnumber as int) = cast(wd.docnumber as int)
										and sdo.storerkey = wd.storerkey
										and sdo.sku = wd.sku
										and sdo.zone = wd.zone
										and sdo.qty = wd.qty
									where sdo.wmdocnumber = @id)
							)
								begin
									print '� ���������� ���� ���������� ������� ��'
									delete from #sm_docso where wmdocnumber = @id 
									delete from #sm_docsr where wmdocnumber = @id
									delete from #wm_docs where cast(docnumber as int) = cast(@id as int)
								end
							print ' ������� ������������ �������� '+@id			
							delete from #docsnumbers where ext_docindex = @id
							
						end					
						
			print '���������� ������ ��� ������ � �����'
			print ' �������� ������ ������� ����� ��� ���������'
			insert into #docsnumbers select distinct null, ordernumber from #conformdocs 
			while (exists(select top(1) * from #docsnumbers))
				begin
					select top(1) @id = ext_docindex from #docsnumbers

					insert into #result
						select distinct
							wd.docnumber, 1 sort, sdr.docnumber smdocnumber,
							sdr.docnumber, sdr.storerkey_name, sdr.storerkey, sdr.storerkey2_name, sdr.storerkey2, su.name_user, sdr.manager, 
							sk.name_dockind, sdr.dockind, sd.name_doctype, sdr.doctype, op.name_operation, sdr.operation, ps.name_post_status, sdr.post_status, sdr.adddate, 0 sm_sum,
							0.0 wm_sum, wd.adddate wmadddate
						from #sm_docsr sdr
							join #wm_docs wd on cast(wd.docnumber as int) = cast(sdr.wmdocnumber as int)
							join #sm_user su on su.id_user = sdr.manager
							join #sm_dk sk on sk.id_dockind = sdr.dockind
							join #sm_dt sd on sd.id_doctype = sdr.doctype
							join #sm_op op on op.id_operation = sdr.operation
							join #sm_ps ps on ps.id_post_status = sdr.post_status
						where sdr.wmdocnumber = @id

					delete from #docsnumbers where ext_docindex = @id
				end
			
			goto endproc
 				end
			if @typedocument = 4
			-- ����������� - ������ ������������ -------------------------------------------------------------------
				begin 
					print '����������� ''dockind = 2'''
					print '����� ���������� �������'
					set @sql = @sql + @where_mov +''')'
					exec (@sql)

					print '����� ���������� �����'
					insert into #wm_docs
					select cast(i.itrnkey as int) docnumber, null smdocnumber, i.storerkey storerkey, null storerkey2, i.adddate date, '' zone,
						i.sku sku, round(0,2) unitprice, round(0,2) nds, round(i.qty,2) qty, round(0,2) qtybrack
						from wh1.itrn i 
						where cast(i.itrnkey as int) in (select distinct ext_docindex from #docsnumbers)

					print ' ������� ��������� �������, ����������� � �����'
					delete from dn
						from #docsnumbers dn full join #wm_docs wd on cast(dn.ext_docindex as varchar(15)) = wd.docnumber 
						where dn.ext_docindex is null

					insert into #conformdocs select * from #docsnumbers

					print '����� ������� ���������� ��� ���������'
					while (exists(select top(1) id_dochead from #docsnumbers))
						begin
							select top (1) @id = id_dochead from #docsnumbers
							print ' ��������� � #sm_docsr ������ ��������� ' +@id
							set @sql = 
								'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
							exec (@sql)
							delete from #docsnumbers where id_dochead = @id
						end

					print '����� ������� ���������� ��� ���������'
					insert into #docsnumbers select distinct * from #conformdocs
					while (exists(select top(1) ext_docindex from #docsnumbers))
						begin
							select top(1) @id = ext_docindex from #docsnumbers

							print ' �������� ����������� ����������'
							if (exists(
								select * 
									from #wm_docs wd full join #sm_docsr sdr on wd.docnumber = sdr.wmdocnumber and wd.sku = sdr.sku
									where wd.docnumber = @id and (wd.storerkey != sdr.storerkey
									or (round(wd.qty,2)-sdr.qty) != 0)))
								begin 
									print ' � ���������� ���� �����������, ������� '
									delete from #wm_docs where docnumber = @id
									delete from #sm_docsr where wmdocnumber = @id
								end
							delete from #docsnumbers where ext_docindex = @id
						end
					print ' �������� � ����������� ������ ���������'
					update wd set wd.smdocnumber = 'SM'+sdr.docnumber
						from #wm_docs wd join #sm_docsr sdr on wd.docnumber = sdr.wmdocnumber
				end
		end


/* >>> ����������� >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
	if @typeverification = 2
		begin
			print '����������� ''@typeverification = 2'''
			-- ������ - ����������� ----------------------------------------------------------------------
			if @typedocument = 0
				begin 
					print ' ����� ������� ��������� ����������'
					set @sql = @sql + @where_receipt
					exec(@sql)

					print ' ����� ���������� ����� �� ������� ��������� ���������� �������'
					insert into #wm_docs
						select distinct
							po.pokey, 
							po.externpokey, 
							po.storerkey, 
							po.sellersreference, 
							po.adddate,
							pd.sku, 
							pd.unitprice unitprice, 
							pd.unit_cost unit_cost,
							pd.qtyreceived qtyreceived,
							pd.qtyrejected qtyrejected,
							'' zone
						from #docsnumbers cd join wh1.po po on 'SM'+cast(cd.id_dochead as varchar(15)) = po.externpokey
							join wh1.podetail pd on po.pokey = pd.pokey 

					print ' ������� ��������� �������, ����������� � �����'
					delete from dn
						from #docsnumbers dn full join #wm_docs wd on 'SM'+cast(dn.id_dochead as varchar(15)) = wd.smdocnumber 
						where wd.smdocnumber is null

					print ' ����� ��������� ���������� �� ��������� ����������'
					while (exists (select top(1) * from #docsnumbers))
						begin
							print @id
							select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
							print '>>> ������������ �������� '+@id
							print ' ����� ��������� ���������� ����� ����'
							set @sql = 
								'insert into #conformdocs select * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
								''select de.basedochead, dl.dochead  
									from dochead_export de join dochead_link dl on de.dochead = dl.basedochead
									where de.basedochead = ' + @id+''')'
							exec (@sql)
							if @@rowcount = 0
								begin
									print ' ��� ���������� ��������� ��� �������� ����� ����'
									print ' ����� ��������� ���������� ��� �����'
									set @sql = 
										'insert into #conformdocs select * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
										''select de.basedochead, de.dochead  
											from dochead_export de 
											where de.basedochead = ' + @id+''')'
									exec (@sql)
									if @@rowcount = 0
										begin
											print ' ��� ���������� ��������� ��� ��������'
											insert into #conformdocs (receiptnumber) values (@id)
										end
								end
							print '<<< ������� ������������ �������� '+@id
							delete from #docsnumbers where id_dochead = @id
						end

						print ' �������� ������ ��������� ���������� ��� ���������'
						insert into #docsnumbers select distinct receiptnumber, ordernumber from #conformdocs
						while (exists(select top(1) * from #docsnumbers))
							begin
								select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
								print ' ��������� � #sm_docsr ������ ��������� ' +@id
								set @sql = 
									'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
								exec (@sql)
--if @id = 4445244 select * from #sm_docsr where docnumber = '4445244'
								delete from #docsnumbers where id_dochead = cast (@id as int)
							end

						print ' �������� ��������� ��������� ����� ���� ��� ���������'
						insert into #docsnumbers (id_dochead) select distinct ordernumber from #conformdocs where isnull(ordernumber,0) != 0
							while (exists(select top(1) * from #docsnumbers))
								begin
									select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
									set @sql = 
										'insert into #sm_docso ' + @sql_seldoc + @id+''')'
									exec (@sql)
--if @id = 4445244 select * from #sm_docso where docnumber = '4445244'
									delete from #docsnumbers where id_dochead = cast (@id as int)
								end

						print ' �������� ������ ���������� �������'
						insert into #docsnumbers (id_dochead) select distinct receiptnumber from #conformdocs
--select * from #smsumm where receiptnumber = '4445244'
						print ' �������� ������� (�������+����) �� �� ������� ��������� ����������'
						while (exists(select top(1) * from #docsnumbers))
							begin
								select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
								insert into #smsumm
								select cd.receiptnumber, sdo.storerkey, sdo.storerkey, sdo.sku, sdo.nds, sum (qty) qty--, sdo.storerkey2,sdo.nds,sdo.dockind,sdo.doctype
									from #conformdocs cd join #sm_docso sdo on cd.ordernumber = sdo.docnumber
									where cd.receiptnumber = @id
									group by cd.receiptnumber, sdo.storerkey,sdo.sku,sdo.nds--,sdo.storerkey,sdo.dockind,sdo.doctype
--if @id = 4445244 select * from #sm_docsr where docnumber = '4445244'
								delete from #docsnumbers where id_dochead = cast (@id as int)
						end

						print ' �������� ������ ���������� �������'
						insert into #docsnumbers (id_dochead) select distinct receiptnumber from #conformdocs

--select  
--((round(isnull(wd.qty,0),2)-round(isnull(wd.qtybrack,0),2))-(isnull(sdr.qty,0)-isnull(ss.qty,0))),
--sdr.*
--										from #sm_docsr sdr 
--										full join #wm_docs wd 
--											on 'SM'+sdr.docnumber = wd.smdocnumber and
--										
--											sdr.sku = wd.sku and 
--											sdr.storerkey = wd.storerkey and 
--											'SM'+sdr.storerkey2 = wd.storerkey2 and 
--											sdr.nds = round(wd.nds,2) and 
--											sdr.unitprice = round(wd.unitprice,2)
--										full join #smsumm ss on ss.receiptnumber = sdr.docnumber
--											and ss.sku = isnull(sdr.sku,wd.sku)
--											and ss.storerkey = isnull (sdr.storerkey,wd.storerkey)
--											and ss.nds = isnull (sdr.nds,wd.nds)
--										 where sdr.docnumber = '4445244' 
--and ((round(isnull(wd.qty,0),2)-round(isnull(wd.qtybrack,0),2))-(isnull(sdr.qty,0)-isnull(ss.qty,0))) != 0



						print ' �������� ������������ ��������� ���������� ������� - �����'
						while ((select count(id_dochead) from #docsnumbers) > 0)
							begin
								select top(1) @id = id_dochead from #docsnumbers
								print '�������� ��������� '+@id

								if (not exists(
									select top(1) sdr.*
										from #sm_docsr sdr 
										full join #wm_docs wd 
											on 'SM'+sdr.docnumber = wd.smdocnumber and
											sdr.sku = wd.sku and 
											sdr.storerkey = wd.storerkey and 
											'SM'+sdr.storerkey2 = wd.storerkey2 and 
											sdr.nds = wd.nds and 
											sdr.unitprice = wd.unitprice
										full join #smsumm ss on ss.receiptnumber = sdr.docnumber
											and ss.sku = isnull(sdr.sku,wd.sku)
											and ss.storerkey = isnull (sdr.storerkey,wd.storerkey)
											and ss.nds = isnull (sdr.nds,wd.nds)
										 where sdr.docnumber = @id and (isnull(wd.qty,0)-isnull(wd.qtybrack,0))-(isnull(sdr.qty,0)-isnull(ss.qty,0)) != 0))
									begin
										print ' � ���������� ��� �����������, ������� �� �� ������� '+@id
										delete from sdr from #sm_docsr sdr where sdr.docnumber = @id
--										delete from sdo from #sm_docso sdo join #conformdocs cd on sdo.docnumber = cd.ordernumber where cd.receiptnumber = @id
										delete from wd from #wm_docs wd where wd.smdocnumber = 'SM'+@id
										delete from #conformdocs where receiptnumber = @id
									end
								print ' ������� ������������ �������� '+@id
								delete from #docsnumbers where id_dochead = @id
							end
				end

			if @typedocument = 1
			-- ������ - ����������� ----------------------------------------------------------------------
				begin 
					print ' ��������� ��������� @typedocument = 0'
					print ' ����� ������� ��������� ����������'
					set @sql = @sql + @where_order
					exec(@sql)

					print ' ����� ���������� ����� �� ������� ��������� ���������� �������'
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
							0,
							'' zone
						from #docsnumbers cd join wh1.orders o on 'SM'+cast(cd.id_dochead as varchar(15)) = o.externorderkey
							join wh1.orderdetail od on o.orderkey = od.orderkey 

					print ' ������� ��������� �������, ����������� � �����'
					delete from dn
						from #docsnumbers dn full join #wm_docs wd on 'SM'+cast(dn.id_dochead as varchar(15)) = wd.smdocnumber 
						where wd.smdocnumber is null

					insert into #conformdocs select id_dochead, null from #docsnumbers

					print ' �������� ������ ��������� ���������� ��� ���������'
					while (exists(select top(1) * from #docsnumbers))
						begin
							select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
							print ' ��������� � #sm_docsr ������ ��������� ' +@id
							set @sql = 
								'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
							exec (@sql)
							delete from #docsnumbers where id_dochead = cast (@id as int)
						end

					print ' �������� ������ ��������� ���������� ��� ���������'
					insert into #docsnumbers (id_dochead) select distinct receiptnumber from #conformdocs
					print ' �������� ������������ ��������� ���������� ������� - �����'
					while ((select count(id_dochead) from #docsnumbers) > 0)
						begin
							select top(1) @id = id_dochead from #docsnumbers
							print '�������� ��������� '+@id
							if (exists(
									select top(1) sdr.docnumber
										from #sm_docsr sdr join #conformdocs cd on sdr.docnumber = cd.receiptnumber
											left join #sm_docso sdo on sdo.docnumber = cd.ordernumber and sdo.sku = sdr.sku
											join #wm_docs wd on wd.smdocnumber = 'SM'+sdr.docnumber and wd.sku = sdr.sku
										where sdr.docnumber = @id and (sdr.storerkey = wd.storerkey and 'SM'+sdr.storerkey2 = wd.storerkey2 
												and sdr.nds = wd.nds and sdr.unitprice = wd.unitprice and (wd.qty-(sdr.qty-isnull(sdo.qty,0))) = 0) ))
									begin
										print ' � ���������� ��� �����������, ������� �� �� ������� '+@id
										delete from sdr from #sm_docsr sdr where sdr.docnumber = @id
--										delete from sdo from #sm_docso sdo join #conformdocs cd on sdo.docnumber = cd.ordernumber where cd.receiptnumber = @id
										delete from wd from #wm_docs wd where wd.smdocnumber = 'SM'+@id
										delete from #conformdocs where receiptnumber = @id
									end
								print ' ������� ������������ �������� '+@id
								delete from #docsnumbers where id_dochead = @id
							end
				end
			if @typedocument = 3
			-- ��������� - � ������������� -----------------------------------------------------------------
				begin 
					print '��������� ''dockind = 0,1'''
					print '����� ���������� �������'
					set @sql = @sql + @where_recount +''')' 
					exec (@sql)

					print ' �������� ���������� ��� ������� ������� ���������� '
					delete from dn 
						from #docsnumbers dn left join da_adjustment da on dn.ext_docindex = cast(da.batchkey as int)
						where da.batchkey is null

					insert into #conformdocs select * from #docsnumbers

					print ' ����� ���������� �����'
					insert into #wm_docs 
						select 
							da.batchkey docnumber,
							null smdocnumber,
							storerkey storerkey,
							'' storerkey2,
							null adddate,
							da.sku sku,
							0 unitprice,
							0 nds,
							sum(deltaqty) qty,
							0 qtybrack,
							da.zone zone
						from da_adjustment da join #conformdocs cd on cast(da.batchkey as int) = cd.ordernumber
						group by da.batchkey, storerkey, da.sku, da.zone

					print ' ������� ���� ���������� �����'
					update wd set adddate = (select max(editdate) 
						from da_adjustment da where da.batchkey = wd.docnumber)
						from #wm_docs wd

					print ' �������� ������ ���������� ��� ���������'
					while (exists(select top(1) * from #docsnumbers))
						begin
							select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
							print ' ��������� � #sm_docsr ������ ��������� ' + @id
							set @sql = 
								'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
							exec (@sql)
							delete from #docsnumbers where id_dochead = cast (@id as int)
						end

					print ' ��������� ����� � ���������� � ���������� �� ���� ���������'
					update #sm_docsr set qty = case when dockind = '0' then qty else qty * (-1) end

					print ' ����������� ��������� ������� �� ������� �����'
					insert into #sm_docso (wmdocnumber, sku, zone, storerkey, qty)
					select wmdocnumber, sku, zone, storerkey, sum(qty) qty 
						from #sm_docsr
						group by wmdocnumber, sku, zone, storerkey
					
					print ' �������� ������ ���������� ������� ����� ��� ���������'
					insert into #docsnumbers select distinct null, ordernumber from #conformdocs 
					
					print ' ��������� ������� ���������� ����� � �������'
					while (exists(select top(1) * from #docsnumbers)) 
						begin
							select top(1) @id = ext_docindex from #docsnumbers
							
							if ((select count (*)
									from #sm_docso sdo join #wm_docs wd 
										on cast(sdo.wmdocnumber as int) = cast(wd.docnumber as int)
										and sdo.storerkey = wd.storerkey
										and sdo.sku = wd.sku
										and sdo.zone = wd.zone
										and sdo.qty = wd.qty
									where sdo.wmdocnumber = @id) = 
								(select count (*)
									from #sm_docso sdo full join #wm_docs wd 
										on cast(sdo.wmdocnumber as int) = cast(wd.docnumber as int)
										and sdo.storerkey = wd.storerkey
										and sdo.sku = wd.sku
										and sdo.zone = wd.zone
										and sdo.qty = wd.qty										
									where sdo.wmdocnumber = @id)
							)
								begin
									print '� ���������� ��� ���������� ������� ��'
									delete from #sm_docso where wmdocnumber = @id 
									delete from #sm_docsr where wmdocnumber = @id
									delete from #wm_docs where cast(docnumber as int) = cast(@id as int)
								end
							print ' ������� ������������ �������� '+@id			
							delete from #docsnumbers where ext_docindex = @id
							
						end					
						
			print '���������� ������ ��� ������ � �����'
			print ' �������� ������ ������� ����� ��� ���������'
			insert into #docsnumbers select distinct null, ordernumber from #conformdocs 
			while (exists(select top(1) * from #docsnumbers))
				begin
					select top(1) @id = ext_docindex from #docsnumbers

					insert into #result
						select distinct
							wd.docnumber, 1 sort, sdr.docnumber smdocnumber,
							sdr.docnumber, sdr.storerkey_name, sdr.storerkey, sdr.storerkey2_name, sdr.storerkey2, su.name_user, sdr.manager, 
							sk.name_dockind, sdr.dockind, sd.name_doctype, sdr.doctype, op.name_operation, sdr.operation, ps.name_post_status, sdr.post_status, sdr.adddate, 0 sm_sum,
							0.0 wm_sum, wd.adddate wmadddate
						from #sm_docsr sdr
							join #wm_docs wd on cast(wd.docnumber as int) = cast(sdr.wmdocnumber as int)
							join #sm_user su on su.id_user = sdr.manager
							join #sm_dk sk on sk.id_dockind = sdr.dockind
							join #sm_dt sd on sd.id_doctype = sdr.doctype
							join #sm_op op on op.id_operation = sdr.operation
							join #sm_ps ps on ps.id_post_status = sdr.post_status
						where sdr.wmdocnumber = @id

					delete from #docsnumbers where ext_docindex = @id
				end
			
			goto endproc
		end
			if @typedocument = 4
			-- ����������� - ����������� -------------------------------------------------------------------
				begin 
					print '����������� ''dockind = 2'''
					print '����� ���������� �������'
					set @sql = @sql + @where_mov +''')'
					exec (@sql)

					print '����� ���������� �����'
					insert into #wm_docs
					select cast(i.itrnkey as int) docnumber, null smdocnumber, i.storerkey storerkey, null storerkey2, i.adddate date, '' zone,
						i.sku sku, 0 unitprice, 0 nds, i.qty qty, 0 qtybrack
						from wh1.itrn i 
						where cast(i.itrnkey as int) in (select distinct ext_docindex from #docsnumbers)

					print ' ������� ��������� �������, ����������� � �����'
					delete from dn
						from #docsnumbers dn full join #wm_docs wd on cast(dn.ext_docindex as varchar(15)) = wd.docnumber 
						where dn.ext_docindex is null

					insert into #conformdocs select * from #docsnumbers

					print '����� ������� ���������� ��� ���������'
					while (exists(select top(1) id_dochead from #docsnumbers))
						begin
							select top (1) @id = id_dochead from #docsnumbers
							print ' ��������� � #sm_docsr ������ ��������� ' +@id
							set @sql = 
								'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
							exec (@sql)
							delete from #docsnumbers where id_dochead = @id
						end

					print '����� ������� ���������� ��� ���������'
					insert into #docsnumbers select distinct * from #conformdocs
					while (exists(select top(1) ext_docindex from #docsnumbers))
						begin
							select top(1) @id = ext_docindex from #docsnumbers

							print ' �������� ����������� ����������'
							if (exists(
								select * 
									from #wm_docs wd full join #sm_docsr sdr on wd.docnumber = sdr.wmdocnumber and wd.sku = sdr.sku
									where wd.docnumber = @id and (wd.storerkey = sdr.storerkey
									and (wd.qty-sdr.qty) = 0)))
								begin 
									print ' � ���������� ��� �����������, ������� '
									delete from #wm_docs where docnumber = @id
									delete from #sm_docsr where wmdocnumber = @id
								end
							delete from #docsnumbers where ext_docindex = @id
						end
					print ' �������� � ����������� ������ ���������'
					update wd set wd.smdocnumber = 'SM'+sdr.docnumber
						from #wm_docs wd join #sm_docsr sdr on wd.docnumber = sdr.wmdocnumber
				end 
		end

/* >>> ������ SMarket >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
	if @typeverification = 3
		begin
			print 'SMarket ''@typeverification = 3'''
			-- ������ - ������ ������� ----------------------------------------------------------------------
			if @typedocument = 0
				begin 
					print '��������� ��������� ''@typedocument = 0'''
					print ' ����� ������� ��������� ����������'
					set @sql = @sql + @where_receipt
					exec(@sql)

					print ' ������� ��������� �������, ������������ � �����'
					delete from dn
						from #docsnumbers dn join wh1.po p on 'SM'+cast(dn.id_dochead as varchar(15)) = p.externpokey 

					while (exists(select top(1) * from #docsnumbers))
						begin
							select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
							print ' ��������� � #sm_docsr ������ ��������� ' +@id
							set @sql = 
								'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
							exec (@sql)
							delete from #docsnumbers where id_dochead = cast (@id as int)
						end

				end

			if @typedocument = 1
			-- ������ - ������ ������� ----------------------------------------------------------------------
				begin 
					print '��������� ��������� ''@typedocument = 1'''
					print ' ����� ������� ��������� ����������'
					set @sql = @sql + @where_order
					exec(@sql)

					print ' ������� ��������� �������, ������������ � �����'
					delete from dn
						from #docsnumbers dn join wh1.orders o on 'SM'+cast(dn.id_dochead as varchar(15)) = o.externorderkey 

					while (exists(select top(1) * from #docsnumbers))
						begin
							select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers
							print ' ��������� � #sm_docsr ������ ��������� ' +@id
							set @sql = 
								'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
							exec (@sql)
							delete from #docsnumbers where id_dochead = cast (@id as int)
						end
				end
				
			if @typedocument = 3
			-- ��������� - ������ ������� ----------------------------------------------------------------------
				begin 
					print '��������� ''dockind = 0,1'''
					print '����� ���������� �������'
					set @sql = @sql + @where_recount +''')' 
					exec (@sql)

					print ' �������� ���������� � �������� �������� ���������� '
					delete from dn 
						from #docsnumbers dn left join da_adjustment da on dn.ext_docindex = cast(da.batchkey as int)
						where da.batchkey is not null
					insert into #conformdocs select * from #docsnumbers

					print '����� ������� ���������� ��� ���������'
					while (exists(select top(1) id_dochead from #docsnumbers))
						begin
							select top (1) @id = id_dochead from #docsnumbers
							print ' ��������� � #sm_docsr ������ ��������� ' +@id
							set @sql = 
								'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
							exec (@sql)
							delete from #docsnumbers where id_dochead = @id
						end					
				end
				
			if @typedocument = 4
			-- ����������� - ������ ������� -------------------------------------------------------------------
				begin 
					print '����������� ''dockind = 2'''
					print '����� ���������� �������'
					set @sql = @sql + @where_mov +''')'
					exec (@sql)

					print ' ������� ��������� �������, ������������ � �����'
					delete from dn
						from #docsnumbers dn join wh1.itrn i on dn.ext_docindex = i.itrnkey

					insert into #conformdocs select * from #docsnumbers

					print '����� ������� ���������� ��� ���������'
					while (exists(select top(1) id_dochead from #docsnumbers))
						begin
							select top (1) @id = id_dochead from #docsnumbers
							print ' ��������� � #sm_docsr ������ ��������� ' +@id
							set @sql = 
								'insert into #sm_docsr ' + @sql_seldoc + @id+''')'
							exec (@sql)
							delete from #docsnumbers where id_dochead = @id
						end
				end 
		end

/* >>> ������ infor WM >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
	if @typeverification = 4
		begin
			print 'Infor WM ''@typeverification = 4'''
--			 ������ - ������ ����� ----------------------------------------------------------------------
			if @typedocument = 0
				begin 
					print '��������� ��������� ''@typedocument = 0'''
					print ' ����� ���������� ����� �� ������� ��������'
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
							pd.qtyrejected,
							'' zone
						from wh1.po po join wh1.podetail pd on po.pokey = pd.pokey 
						where (po.storerkey = '92' or po.storerkey = '219') and
							po.adddate > @startdate and po.adddate < @enddate

					print ' �������� ������ ���������� ����� ��� ���������'
					insert into #conformdocs select distinct cast(substring(smdocnumber,3,100) as int),null from #wm_docs

					print ' ������� ��������� ������������ � �������'
					while (exists(select top(1) receiptnumber from #conformdocs)) 
						begin
							select top(1) @id = cast(receiptnumber as varchar(50)) from #conformdocs  
							print '�������� '+@id
							set @sql = 
								@sql_docnum + @id+''')'
							exec (@sql)

							if ((select count(id_dochead) from #docsnumbers ) > 0)
								begin
									print ' ���� �������� � �������, �������'
									delete from #docsnumbers
									delete from #wm_docs where smdocnumber = 'SM'+cast(@id as varchar(20))
								end
							delete from #conformdocs where receiptnumber = cast(@id as int)
						end

					print ' ���������� ��������� ���������� �����'
						insert into #wmsum
							select docnumber, smdocnumber, sum(qty*unitprice) wm_sum, null
							from #wm_docs group by docnumber, smdocnumber
										
					insert into #result (wmdocnumber,wm_sum)
						select docnumber,wm_sum from #wmsum
				end

			if @typedocument = 1
--	������ - ������ ����� ----------------------------------------------------------------------
				begin 
					print '��������� ��������� ''@typedocument = 1'''
					print ' ����� ���������� ����� �� ������� ��������'
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
							0,
							'' zone
						from wh1.orders o join wh1.orderdetail od on o.orderkey = od.orderkey 
						where --substring(o.externorderkey,1,2) = 'SM' 
							--and 
							(o.storerkey = '92' or o.storerkey = '219')
							and o.type != '26'
							and o.adddate > @startdate and o.adddate < @enddate

					print ' �������� ������ ���������� ����� ��� ���������'
					insert into #conformdocs select distinct cast(substring(smdocnumber,3,100) as int),null from #wm_docs

					print ' ������� ��������� ������������ � �������'
					while (exists(select top(1) receiptnumber from #conformdocs)) 
						begin
							select top(1) @id = cast(receiptnumber as varchar(50)) from #conformdocs  
							print '�������� '+@id
							set @sql = 
								@sql_docnum + @id+''')'
							exec (@sql)

							if ((select count(id_dochead) from #docsnumbers ) > 0)
								begin
									print ' ���� �������� � �������, �������'
									delete from #docsnumbers
									delete from #wm_docs where smdocnumber = 'SM'+cast(@id as varchar(20))
								end
							delete from #conformdocs where receiptnumber = cast(@id as int)
						end

					print ' ���������� ��������� ���������� �����'
						insert into #wmsum
							select docnumber, smdocnumber, sum(qty*unitprice) wm_sum, null
							from #wm_docs group by docnumber, smdocnumber
										
					insert into #result (wmdocnumber,wm_sum)
						select docnumber,wm_sum from #wmsum
				end

			if @typedocument = 3
			-- ��������� - ������ ����� -----------------------------------------------------------------
				begin
					print '��������� ''dockind = 0,1'''
					print ' ����� ���������� �����'
					insert into #wm_docs (docnumber)
						select distinct 
							da.batchkey docnumber
						from da_adjustment da 
						where  
							editdate > @start_infor_date
							and da.editdate >= @startdate
							and da.editdate <= @enddate
							and da.storerkey like case when isnull(@storerkey,'') = '' then '%' else @storerkey end -- �������� �� ���������� �� ���������� � �����
						group by da.batchkey, storerkey, da.sku, da.zone

 					print ' ������� ���� ���������� �����'
					update wd set adddate = (select max(editdate) 
						from da_adjustment da where da.batchkey = wd.docnumber)
						from #wm_docs wd

					print ' �������� ������ ���������� ������� ����� ��� ������ '
					insert into #docsnumbers select distinct cast(docnumber as int) id_dochead, null from #wm_docs

					while (exists(select top(1) * from #docsnumbers))
						begin
							select top(1) @id = cast(id_dochead as varchar (15)) from #docsnumbers order by id_dochead
							
							print '�������� '+@id
							set @sql = 
								'insert into #sm_docsr (docnumber) SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
								''select id_dochead from dochead where ext_docindex = '''''+@id+''''''')'
							exec (@sql)
							
							if (@@rowcount != 0)
								begin
									print ' � �������� ���� ��������� �� ������, �������'
									delete from #wm_docs where cast(docnumber as int) = @id
								end
							delete from #docsnumbers where id_dochead = cast (@id as int)
						end
			goto endproc 
 				end

			if @typedocument = 4
			-- ����������� - ������ ����� -------------------------------------------------------------------
				begin 
					print '����� ���������� �����'
					insert into #wm_docs
					select cast(i.itrnkey as int) docnumber, '' smdocnumber, i.storerkey storerkey, '' storerkey2, i.adddate adddate, 
						i.sku, 0 unitprice, 0 nds, i.qty, 0 qtybrack, '' zone
					from wh1.itrn i
						inner join wh1.loc l on l.loc = i.toloc
						inner join wh1.loc l2 on l2.loc = i.fromloc
					where 
						i.adddate > @start_infor_date
						and i.adddate >= @startdate
						and i.adddate <= @enddate
						and i.storerkey like case when isnull(@storerkey,'') = '' then '%' else @storerkey end -- �������� �� ���������� �� ���������� � �����
						and (i.toloc <> 'BRAKPRIEM') and (i.fromloc <> 'BRAKPRIEM')					-- ����� �� ��������� da_move
						and ( (l.putawayzone like 'BRAK%' and l2.putawayzone not like 'BRAK%')		-- ����� �� ��������� da_move
							 or (l2.putawayzone like 'BRAK%' and l.putawayzone not like 'BRAK%'))	-- ����� �� ��������� da_move
						and i.trantype = 'MV'

					print '����� ������� ���������� ��� ���������'
					insert into #conformdocs select distinct docnumber, null from #wm_docs

					print ' ������� ��������� ������������ � �������'
					while (exists(select top(1) receiptnumber from #conformdocs)) 
						begin
							select top(1) @id = cast(receiptnumber as varchar(50)) from #conformdocs  
							print '�������� '+@id
							set @sql = 
								'insert into #docsnumbers SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'',
								''select id_dochead, ext_docindex from dochead where ext_docindex = '''''+@id+''''''')'
							exec (@sql)

							if ((select count(id_dochead) from #docsnumbers ) > 0)
								begin
									print ' ���� �������� � �������, �������'
									delete from #docsnumbers
									delete from #wm_docs where docnumber = cast(@id as varchar(20))
								end
							delete from #conformdocs where receiptnumber = cast(@id as int)
						end

					print ' ���������� ���������� ����������� �����'
					insert into #wmsum
						select docnumber, smdocnumber, sum(qty*unitprice) wm_sum, null
							from #wm_docs group by docnumber, smdocnumber
										
					insert into #result (wmdocnumber,wm_sum)
						select docnumber,wm_sum from #wmsum
				end 
		end

print ' ��������� ��������� �������'
	insert into #result
		select 
			'          ' wmdocnumber, 0 sort, sdr.docnumber smdocnumber,
			sdr.docnumber, sdr.storerkey_name, sdr.storerkey, sdr.storerkey2_name, sdr.storerkey2, su.name_user, sdr.manager, 
			sk.name_dockind, sdr.dockind, sd.name_doctype, sdr.doctype, op.name_operation, sdr.operation, ps.name_post_status, sdr.post_status, sdr.adddate, sum(qty*unitprice) sm_sum,
			0.0 wm_sum, null wmadddate
		from #sm_docsr sdr 
			join #sm_user su on su.id_user = sdr.manager
			join #sm_dk sk on sk.id_dockind = sdr.dockind
			join #sm_dt sd on sd.id_doctype = sdr.doctype
			join #sm_op op on op.id_operation = sdr.operation
			join #sm_ps ps on ps.id_post_status = sdr.post_status
		group by sdr.docnumber, sdr.storerkey_name, sdr.storerkey, sdr.storerkey2_name, sdr.storerkey2, su.name_user, sdr.manager, 
			sk.name_dockind, sdr.dockind, sd.name_doctype, sdr.doctype, op.name_operation, sdr.operation, ps.name_post_status, sdr.post_status, sdr.adddate 

print ' ��������� ��������� �������'
	insert into #result
		select distinct
			'          ' wmdocnumber, 1 sort, cd.receiptnumber smdocnumber,
			sdo.docnumber, sdo.storerkey_name, sdo.storerkey, sdo.storerkey2_name, sdo.storerkey2, su.name_user, sdo.manager, 
			sk.name_dockind, sdo.dockind, sd.name_doctype, sdo.doctype, op.name_operation, sdo.operation, ps.name_post_status, sdo.post_status, sdo.adddate, sum(qty*unitprice) sm_sum,
			0.0 wm_sum, null wmadddate
		from #sm_docso sdo join #conformdocs cd on sdo.docnumber = cd.ordernumber
			join #sm_user su on sdo.manager=su.id_user
			join #sm_dk sk on sk.id_dockind = sdo.dockind
			join #sm_dt sd on sd.id_doctype = sdo.doctype
			join #sm_op op on op.id_operation = sdo.operation
			join #sm_ps ps on ps.id_post_status = sdo.post_status
		group by cd.receiptnumber, sdo.docnumber, sdo.storerkey_name, sdo.storerkey, sdo.storerkey2_name, sdo.storerkey2, su.name_user, sdo.manager, 
			sk.name_dockind, sdo.dockind, sd.name_doctype, sdo.doctype, op.name_operation, sdo.operation, ps.name_post_status, sdo.post_status, sdo.adddate

print ' ���������� ��������� ���������� �����'
	insert into #wmsum
--		select docnumber, smdocnumber, sum(round(qty,2)*round(unitprice,2)) wm_sum, adddate wmadddate
		select docnumber, smdocnumber, sum(qty*unitprice) wm_sum, adddate wmadddate
		from #wm_docs 
		group by docnumber, smdocnumber, adddate

--select * from #wmsum

 print ' ���������� ������ �� ���������� �����'
	update r
		set r.wmdocnumber = wd.docnumber, r.wm_sum = wd.wm_sum, r.wmadddate = wd.wmadddate
		from #wmsum wd join #result r on 'SM'+r.docnumber = wd.smdocnumber

endproc:
--����� �����������
select * from #result order by smdocnumber, sort--, adddate


drop table #result
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
drop table #smsumm
