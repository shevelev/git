ALTER PROCEDURE [dbo].[check_]
	@startdate datetime, --��������� ���� ������� ������
	@enddate datetime,	--�������� ���� ������� ������
	@typeverification int, -- ��� ������ 
				-- 1-��������� ������� ����������� � ����� �������� � �� ������� ����������� 
				-- 2-��������� ������� ����������� �� � ������������� (�����������, ����, ����������, ���������� � ������ � �.�.)
				-- 3-��������� S-������, �� ������� ������������ � Infor WM
				-- 4-��������� Infor WM, �� ������� ������������ � S-������
	@typedocument int, -- ��� ���������
				-- 0-�������
				-- 1-������
				-- 3-���������
				-- 4-�����������
				-- 5-��������������
	@storerkey varchar (20), -- ��� ���������
	@manager varchar (20) -- ��� ��������� Smarket

as

--declare
--	@startdate datetime, --��������� ���� ������� ������
--	@enddate datetime,	--�������� ���� ������� ������
--	@typeverification int, -- ��� ������ 
--				-- 1-��������� ������� ����������� � ����� �������� � �� ������� ����������� 
--				-- 2-��������� ������� ����������� �� � ������������� (�����������, ����, ����������, ���������� � ������ � �.�.)
--				-- 3-��������� S-������, �� ������� ������������ � Infor WM
--				-- 4-��������� Infor WM, �� ������� ������������ � S-������
--	@typedocument int, -- ��� ���������
--				-- 0-�������
--				-- 1-������
--				-- 3-���������
--				-- 4-�����������
--	@storerkey varchar (20), -- ��� ���������
--	@manager varchar (20) -- ��� ��������� Smarket
--
--	set @startdate = N'2009-11-16'
--	set @enddate = N'2009-11-16'
--	set @typeverification = 2
--	set @typedocument = 1
--	set @storerkey ='' -- '', ''92, '219'
--	set @manager = '' -- ''

set @enddate = @enddate + 1 

declare @sql nvarchar(4000),
		@const_sql nvarchar (2000),
		@one_const_sql nvarchar (2000),
		@start_infor_date datetime,
		@artstor varchar (50), -- ���� sku+storerkey
		@qty decimal (22,5), -- ����������
		@unitprice decimal (22,5), -- ����
		@nds decimal (22,5), -- ���
		@operation_0 varchar (150),
		@operation_1 varchar (150),
		@operation_3 varchar (150), -- ��� ���������� �������� ��� �������� (dockind = 0/1)
		@operation_4 varchar (150),	-- ��� ���������� ����������� ��� �������� (dockind = 2)
		@dockey int,	-- ����� ��������������� ��������� �� �������
		@dockey_vch varchar (15) -- ����� ��������������� ��������� �� ������� (������)

-- ���������� ���������� ����������� � ��������� �� �������
set @operation_0 = ' and (dh.doctype != 1470 and dh.doctype != 1472) and dh.dockind = 0'
set @operation_1 = ' and (dh.doctype != 1471 and dh.doctype != 1473) and dh.dockind = 1'

-- ������� ���� ��������� ��������� ������ ��� �������
set @operation_3 = case when isnull(@storerkey,'') = '' then ' and (dh.doctype = 1470 or dh.doctype = 1472 or dh.doctype = 1471 or dh.doctype = 1473)' else case when @storerkey = 92 then ' and (dh.doctype = 1470 or dh.doctype = 1471) ' else ' and (dh.doctype = 1472 or dh.doctype = 1473)' end end + ' and (dh.dockind = 1 or dh.dockind = 0)'

-- ������� ���� ��������� ����������� ��� �������
set @operation_4 = case when isnull(@storerkey,'') = '' then ' and (dh.doctype = 1148 or dh.doctype = 1431)' else case when @storerkey = 92 then ' and dh.doctype = 1148' else ' and dh.doctype = 1431' end end + ' and dh.dockind = 2'

-- ���� ������ ��������� ���������� (������ �����)
set @start_infor_date = '2009-10-01 00:00:00.000'

-- �������� ��������� ������� ��� ���������� ���������� ��������� �� �������
SELECT * into #sm_dh FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select dh.*, cl.name_clients from dochead dh join clients cl on dh.client_index = cl.id_clients where 1 = 2')

-- ������� ���������� ������������ ������� ������ ��������� � ���� ������� �� ����������
set @one_const_sql = 'insert into #sm_dh SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'','''+
					'select dh.*, cl.name_clients from dochead dh join clients cl on dh.client_index = cl.id_clients
					where dh.doc_date > ''''' + convert(varchar(23),@start_infor_date,121) + ''''''

-- ������� ���������� ������������ ������� � ���� ������� �� ���������� ����������
set @const_sql = 'insert into #sm_dh SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'','''+
					'select dh.*, cl.name_clients from dochead dh join clients cl on dh.client_index = cl.id_clients
					where dh.doc_date > ''''' + convert(varchar(23),@start_infor_date,121) + '''''' +
					' and dh.doc_date >= ''''' + convert(varchar(23),@startdate,121) + 
				''''' and dh.doc_date <= ''''' + convert(varchar(23),@enddate,121) + '''''' +
					' and dh.post_status > 0' + case when isnull(@storerkey,'') =  '' then '' else 
					' and dh.shopindex = ' + @storerkey + '' end + case when isnull(@manager,'') = '' then '' else 
					' and dh.manager = ' + @manager + '' end

-- ��������� ������� � ���������������� �������
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

-- ��������� ������� ������ ������������ � ����� ��������
if @typeverification = 1
	begin
		print '���������, ������� ����������� � ����� �������� ''@typeverification = 1'''
		if @typedocument = 0
-- ������ - ������ ������������ --------------------------------------------------------------------
			begin 
				print '��������� ��������� ''dockind = 0'''
				set @sql = @const_sql + @operation_0 +''')'
				exec (@sql)

				print '������� �������������� ���������� �� ������ �� ������ ��������� ��'
				select * into #iwm_dh10 
					from wh1.po p 
						inner join #sm_dh s on 
						p.externpokey = 'SM'+cast(s.id_dochead as varchar(10)) -- ����� ��������� 
						and p.sellersreference = 'SM'+cast(s.client_index as varchar(10))-- ��� �������

				print '������� ���������, ��� ������� �� ������� ���� � ������'
				delete from s
					from #iwm_dh10 p right join #sm_dh s on p.externpokey = 'SM'+cast(s.id_dochead as varchar(10))
					where p.serialkey is null

				print '��������� ���������� ����������'
				-- �������� ��������� ������� Smarket
				SELECT * into #sm_ds10 FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select articul, shopindex as storerkey, quantity as qty, pricerub as unitprice, nds from docspec where id_dochead = 0')
				-- �������� ��������� ������� Infor
				select sku articul, storerkey, qtyadjusted qty, unitprice, unit_cost nds into #iwm_ds10	from wh1.podetail where externpokey = '0'
				-- ������� ������ ������� ����������
				select id_dochead into #dockey10 from #sm_dh

				while ((select count(id_dochead) from #dockey10) != 0)
					begin
						select top(1) @dockey = id_dochead from #dockey10 -- ����� ������ ���������
						-- ����� ������� ��������� �������
						set @sql = 'insert into #sm_ds10 SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'','''+
							'select articul, shopindex storerkey, quantity qty, pricerub unitprice, nds from docspec where id_dochead = '+cast(@dockey as varchar(10))+''')'
						exec (@sql)
						-- ����� ������� ���������� �����
						insert into #iwm_ds10 select sku articul, storerkey, case when [status] = '11' then qtyadjusted else qtyordered end qty, unitprice,  unit_cost nds
							from wh1.podetail where externpokey = 'SM'+cast(@dockey as varchar(10))

						-- ��������� ������� ����������
						if ((select round(sum(sm.qty + round(sm.unitprice,10) + case when sm.qty = 0 or sm.unitprice = 0 then 0 else round((sm.nds/((sm.qty*sm.unitprice-sm.nds)/100)),0) end),10) from #sm_ds10 sm) 
								!= 
							(select round(sum(iwm.qty + round(iwm.unitprice,10) + iwm.nds),10) from #iwm_ds10 iwm))
							begin
								print '�������� ���������� � ������������� ' + cast (@dockey as varchar (15))
								delete from #iwm_dh10 where externpokey = 'SM'+cast(@dockey as varchar(10))
								delete from #sm_dh where id_dochead = @dockey
							end

						-- �������� ������������� ������ ���������
						delete from #dockey10 where id_dochead = @dockey

						-- ������� ������ ������� ����������
						delete from #sm_ds10
						delete from #iwm_ds10
					end
				drop table #dockey10
				drop table #sm_ds10
				drop table #iwm_ds10
--select * from #iwm_dh10

				select	po.pokey dockey, 
						po.adddate,
						dh.id_dochead, 
						dh.name_clients,
						dh.client_index,
						dh.doc_date,
						so.name_operation+' (' + cast(dh.operation as varchar(10)) + ')' operation, 
						sk.name_dockind+' (' + cast(dh.dockind as varchar(10)) + ')' dokind, 
						sd.name_doctype+' (' + cast(dh.doctype as varchar(10)) + ')' doctype, 
						sp.name_post_status+' (' + cast(dh.post_status as varchar(10)) + ')' post_status, 
						su.name_user+' (' + cast(dh.manager as varchar(10)) + ')' manager
					from #iwm_dh10 po 
						inner join #sm_dh dh on po.externpokey = 'SM'+cast(dh.id_dochead as varchar(10)) 
						join #sm_user su on dh.manager = su.id_user
						join #sm_ps sp on dh.post_status = sp.id_post_status
						join #sm_dt sd on dh.doctype = sd.id_doctype
						join #sm_dk sk on dh.dockind = sk.id_dockind
						join #sm_op so on dh.operation = so.id_operation
--select * from #sm_dh
				drop table #iwm_dh10
			end
		if @typedocument = 1
-- ������ - ������ ������������ --------------------------------------------------------------------
			begin 
				print '��������� ��������� ''dockind = 1'''
				set @sql = @const_sql + @operation_1 +''')'
				exec (@sql)

				print '������� �������������� ���������� �� ������ �� ������ ��������� ��'
				select * into #iwm_dh11 
					from wh1.orders o 
						inner join #sm_dh s on 
						o.externorderkey = 'SM'+cast(s.id_dochead as varchar(10)) -- ����� ��������� 
						and o.consigneekey = 'SM'+cast(s.client_index as varchar(10))-- ��� �������

				print '������� ���������, ��� ������� �� ������� ���� � ������'
				delete from s
					from #iwm_dh11 o right join #sm_dh s on o.externorderkey = 'SM'+cast(s.id_dochead as varchar(10))
					where o.serialkey is null

				print '��������� ���������� ����������'
				-- �������� ��������� ������� Smarket
				SELECT * into #sm_ds11 FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select articul, shopindex as storerkey, quantity as qty, pricerub as unitprice, nds from docspec where id_dochead = 0')
				-- �������� ��������� ������� Infor
				select sku articul, storerkey, shippedqty qty, unitprice, tax01 nds into #iwm_ds11 from wh1.orderdetail where externorderkey = '0'
				-- ������� ������ ������� ����������
				select id_dochead into #dockey11 from #sm_dh

				while ((select count(id_dochead) from #dockey11) != 0)
					begin
						select top(1) @dockey = id_dochead from #dockey11 -- ����� ������ ���������
						-- ���������� ��������� �������
						set @sql = 'insert into #sm_ds11 SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'','''+
							'select articul, shopindex storerkey, quantity qty, pricerub unitprice, nds from docspec where id_dochead = '+cast(@dockey as varchar(10))+''')'
						exec (@sql)
						-- ���������� ��������� �����
						insert into #iwm_ds11 select sku articul, storerkey, case when [status] >= '16' then shippedqty else openqty end qty, unitprice, tax01 nds
							from wh1.orderdetail where externorderkey = 'SM'+cast(@dockey as varchar(10))

						-- ��������� ������� ����������
						if ((select round(sum(sm.qty + round(sm.unitprice,10) + case when sm.qty = 0 or sm.unitprice = 0 then 0 else round((sm.nds/((sm.qty*sm.unitprice-sm.nds)/100)),0) end),10) from #sm_ds11 sm) 
								!= 
							(select round(sum(iwm.qty + round(iwm.unitprice,10) + iwm.nds),10) from #iwm_ds11 iwm))
							begin
								print '�������� ���������� � ������������� ' + cast (@dockey as varchar (15))
								delete from #iwm_dh11 where externorderkey = 'SM'+cast(@dockey as varchar(10))
								delete from #sm_dh where id_dochead = @dockey
							end

						-- ������� ��������� ������� � �������� ����������
						delete from #sm_ds11
						delete from #iwm_ds11
						-- ������� ����� ������������� ���������
						delete from #dockey11 where id_dochead = @dockey
					end
				drop table #dockey11
				drop table #sm_ds11
				drop table #iwm_ds11

				select	o.orderkey dockey, 
						o.adddate,
						dh.id_dochead, 
						dh.name_clients,
						dh.client_index,
						dh.doc_date,
						so.name_operation+' (' + cast(dh.operation as varchar(10)) + ')' operation, 
						sk.name_dockind+' (' + cast(dh.dockind as varchar(10)) + ')' dokind, 
						sd.name_doctype+' (' + cast(dh.doctype as varchar(10)) + ')' doctype, 
						sp.name_post_status+' (' + cast(dh.post_status as varchar(10)) + ')' post_status, 
						su.name_user+' (' + cast(dh.manager as varchar(10)) + ')' manager
					from #iwm_dh11 o 
						inner join #sm_dh dh on o.externorderkey = 'SM'+cast(dh.id_dochead as varchar(10))
						join #sm_user su on dh.manager = su.id_user
						join #sm_ps sp on dh.post_status = sp.id_post_status
						join #sm_dt sd on dh.doctype = sd.id_doctype
						join #sm_dk sk on dh.dockind = sk.id_dockind
						join #sm_op so on dh.operation = so.id_operation
--select * from #sm_dh
				drop table #iwm_dh11
			end
	if @typedocument = 3
-- ��������� - ������ ������������ --------------------------------------------------------------------
		begin 

print '�������� ��������� ������� ��� ���������� �������'
	SELECT * into #sm_ad
		FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3',
		'select cast(dh.id_dochead as varchar(15)) sm_dockey, cast(dh.ext_docindex as int) iwm_dockey, ds.articul sku, dh.shopindex storerkey, dh.client2_index zone, ds.quantity qty, dh.doc_date from dochead dh join docspec ds on dh.id_dochead = ds.id_dochead where 1=2')

print '�������� ��������� ������� ��� ���������� �����'
	select '                ' sm_dockey, cast(iad.batchkey as int) iwm_dockey, iad.sku,iad.storerkey, iad.zone, sum (iad.deltaqty) qty
	into #iwm_ad 	
	from da_adjustment iad --join #iwm_dockey idk on iad.batchkey = idk.iwm_dockey 
where 1=2
		group by iad.batchkey, iad.sku, iad.storerkey, iad.zone

print '�������� ��������� ������� ��� ������� ���������� infor'
select iwm_dockey into #iwm_dockey from #iwm_ad where 1=2

print '������� ���������� �� ������ �� �������'
	INSERT INTO #sm_ad SELECT * 
		FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3',
		'select cast(dh.id_dochead as varchar(15)), cast(dh.ext_docindex as int), ds.articul, dh.shopindex, dh.client2_index, case when dockind = 0 then ds.quantity else ds.quantity * (-1) end, dh.doc_date 
			from dochead dh join docspec ds on dh.id_dochead = ds.id_dochead
			where 
				dh.doc_date > ''2009-10-30'' and dh.doc_date < ''2009-11-20'' 
				and (dh.doctype = 1470 or dh.doctype = 1471 or dh.doctype = 1472 or dh.doctype = 1473)')

print '������� ���������� �� �����'
insert into #iwm_ad
select '' sm_dockey, cast(iad.batchkey as int) iwm_dockey, iad.sku,iad.storerkey, iad.zone, sum (iad.deltaqty) qty
	from da_adjustment iad 
	where iad.batchkey in (select distinct iwm_dockey from #sm_ad) --where isnull(iwm_dockey,'') != '')
	group by iad.batchkey, iad.sku, iad.storerkey, iad.zone

print '�������� �������� ���������� smarket'
delete from sad
	from #iwm_ad iad right join #sm_ad sad on iad.iwm_dockey = sad.iwm_dockey
	where iad.iwm_dockey is null

print  '�������� ����� ���������� ����� � ���������� �������'
update iad set iad.sm_dockey = sad.sm_dockey
	from #iwm_ad iad inner join #sm_ad sad on iad.iwm_dockey = sad.iwm_dockey and iad.storerkey = sad.storerkey and iad.sku = sad.sku and iad.zone = sad.zone

print '����� ������� ����������'
insert into #iwm_dockey select distinct iwm_dockey from #iwm_ad

while ( (select count (iwm_dockey) from #iwm_dockey) > 0)
	begin
		print '����� ������ ��������� ��� ���������'
		select top (1) @dockey_vch =iwm_dockey from #iwm_dockey

		print '��������� ����������� ����������'
		if ((select count (sad.iwm_dockey)+count (iad.iwm_dockey) from #sm_ad sad full join #iwm_ad iad 
			on sad.qty = iad.qty and 
			sad.sku = iad.sku and 
			sad.storerkey = iad.storerkey and 
				sad.iwm_dockey = iad.iwm_dockey and
				sad.zone = iad.zone
				where (sad.iwm_dockey is null or iad.iwm_dockey is null) and 
			(sad.iwm_dockey = @dockey_vch or iad.iwm_dockey = @dockey_vch)) != 0)
			begin
				delete from #sm_ad where iwm_dockey = @dockey_vch
				delete from #iwm_ad where iwm_dockey = @dockey_vch
			end
		print '�������� ������������� ������ ���������'
		delete from #iwm_dockey where iwm_dockey = @dockey_vch
	end

				select distinct
					da.iwm_dockey dockey, 
--					da.editdate adddate, ''
dh.doc_date adddate,
					dh.sm_dockey, 
					dh.name_clients,
					dh.storerkey client_index,
					dh.doc_date,
					so.name_operation+' (' + cast(dh.operation as varchar(10)) + ')' operation, 
					sk.name_dockind+' (' + cast(dh.dockind as varchar(10)) + ')' dokind, 
					sd.name_doctype+' (' + cast(dh.doctype as varchar(10)) + ')' doctype, 
					sp.name_post_status+' (' + cast(dh.post_status as varchar(10)) + ')' post_status, 
					su.name_user+' (' + cast(dh.manager as varchar(10)) + ')' manager 
				from #iwm_ad da 
					inner join #sm_ad dh on da.iwm_dockey = dh.iwm_dockey
					join #sm_user su on dh.manager = su.id_user
					join #sm_ps sp on dh.post_status = sp.id_post_status
					join #sm_dt sd on dh.doctype = sd.id_doctype
					join #sm_dk sk on dh.dockind = sk.id_dockind
					join #sm_op so on dh.operation = so.id_operation
drop table #sm_ad
drop table #iwm_ad
drop table #iwm_dockey

--			print '�������� ��������� Infor WM'
--				set @sql = @const_sql + @operation_3 + ''')'
--				exec(@sql)
--
--				print '������� �������������� ���������� �� ������ �� ������ ��������� ��'
--				select * into #iwm_dh13
--					from da_adjustment a 
--						inner join #sm_dh s on 
--						cast(a.batchkey as int) = s.ext_docindex -- ����� ��������� 
--
--				print '������� ���������, ��� ������� �� ������� ���� � ������'
--				delete from s
--					from #iwm_dh13 a right join #sm_dh s on cast(a.batchkey as int) = s.ext_docindex
--					where a.id is null
--
--				print '��������� ���������� ����������'
--				-- �������� ��������� ������� Smarket
--				SELECT * into #sm_ds13 FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select articul, shopindex as storerkey, quantity as qty from docspec where id_dochead = 0')
--				-- �������� ��������� ������� Infor
--				select sku articul, storerkey, deltaqty qty into #iwm_ds13 from da_adjustment where batchkey = '0'
--				-- ������� ������ ������� ����������
--				select id_dochead into #dockey13 from #sm_dh
--
--				while ((select count(id_dochead) from #dockey13) != 0)
--					begin
--						select top(1) @dockey = id_dochead from #dockey13 -- ����� ������ ���������
--						-- ���������� ��������� �������
--						set @sql = 'insert into #sm_ds13 SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'','''+
--							'select articul, shopindex storerkey, quantity qty from docspec where id_dochead = '+cast(@dockey as varchar(10))+''')'
--						exec (@sql)
--						-- ���������� ��������� �����
--						insert into #iwm_ds13 select sku articul, storerkey, sum(deltaqty) qty
--							from da_adjustment where batchkey = cast(@dockey as varchar(10))
--							group by sku, storerkey
--
--						-- ���������� ���������� ����������
--
--
--						-- ������� �� ����������� ��������
--						if ((select count (sku) from #sm_ds13) != 0 or (select count (sku) from #iwm_ds13) != 0)
--							begin
--								delete from #sm_dh where id_dochead = @dockey
--								delete from #iwm_dh13 where cast(batchkey as int) = @dockey
--							end
--						-- ������� ��������� ������� � �������� ����������
--						delete from #sm_ds13
--						delete from #iwm_ds13
--						-- ������� ����� ������������� ���������
--						delete from #dockey13 where id_dochead = @dockey
--					end
--				drop table #dockey13
--				drop table #sm_ds13
--				drop table iwm_ds13

--				select top(1) 
--					da.batchkey dockey, 
--					da.editdate adddate,
--					dh.id_dochead, 
--					dh.name_clients,
--					dh.client_index,
--					dh.doc_date,
--					so.name_operation+' (' + cast(dh.operation as varchar(10)) + ')' operation, 
--					sk.name_dockind+' (' + cast(dh.dockind as varchar(10)) + ')' dokind, 
--					sd.name_doctype+' (' + cast(dh.doctype as varchar(10)) + ')' doctype, 
--					sp.name_post_status+' (' + cast(dh.post_status as varchar(10)) + ')' post_status, 
--					su.name_user+' (' + cast(dh.manager as varchar(10)) + ')' manager 
--				from da_adjustment da 
--					inner join #sm_dh dh on cast(da.batchkey as int) = dh.ext_docindex
--					join #sm_user su on dh.manager = su.id_user
--					join #sm_ps sp on dh.post_status = sp.id_post_status
--					join #sm_dt sd on dh.doctype = sd.id_doctype
--					join #sm_dk sk on dh.dockind = sk.id_dockind
--					join #sm_op so on dh.operation = so.id_operation
--select * from #sm_dh
--			drop table #iwm_dh13
		end

	if @typedocument = 4
-- ����������� - ������ ������������ --------------------------------------------------------------------
		begin 
			print '�������� ����������� Infor WM'
				set @sql = @const_sql + @operation_4 + ''')'
				exec(@sql)

				print '������� �������������� ���������� �� ������ �� ������ ��������� ��'
				select * into #iwm_dh14
					from wh1.itrn i
						inner join #sm_dh s on 
						cast(i.itrnkey as int) = s.ext_docindex -- ����� ��������� 

				print '������� ���������, ��� ������� �� ������� ���� � ������'
				delete from s
					from #iwm_dh14 i right join #sm_dh s on cast(i.itrnkey as int) = s.ext_docindex
					where i.serialkey is null

				print '��������� ���������� ����������'
				-- �������� ��������� ������� Smarket
				SELECT * into #sm_ds14 FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select articul, shopindex as storerkey, quantity as qty from docspec where id_dochead = 0')
				-- �������� ��������� ������� Infor
				select sku articul, storerkey, qty into #iwm_ds14 from wh1.itrn where itrnkey = '0'
				print '������� ������ ������� ����������'
				select id_dochead into #dockey14 from #sm_dh

				while ((select count(id_dochead) from #dockey14) != 0)
					begin
						select top(1) @dockey = id_dochead from #dockey14 -- ����� ������ ���������
						-- ���������� ��������� �������
						set @sql = 'insert into #sm_ds14 SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'','''+
							'select articul, shopindex as storerkey, quantity qty from docspec where id_dochead = '+cast(@dockey as varchar(10))+''')'
						exec (@sql)
						-- ���������� ��������� �����
						insert into #iwm_ds14 select sku articul, storerkey, qty
							from wh1.itrn where cast(itrnkey as int) = (select ext_docindex from #sm_dh where id_dochead = @dockey)

						-- ���������� ���������� ����������
						if ((select sum(sm.qty - iwm.qty) from #sm_ds14 sm join #iwm_ds14 iwm on sm.articul = iwm.articul and sm.storerkey = iwm.storerkey) != 0)
							begin
								print '�������� ���������� � ������������� ' + cast (@dockey as varchar (15))
								delete from #iwm_dh14 where itrnkey =(select ext_docindex from #sm_dh where id_dochead = @dockey)
								delete from #sm_dh where id_dochead = @dockey
							end

						-- ������� ��������� ������� � �������� ����������
						delete from #sm_ds14
						delete from #iwm_ds14
						-- ������� ����� ������������� ���������
						delete from #dockey14 where id_dochead = @dockey
					end
				drop table #dockey14
				drop table #sm_ds14
				drop table #iwm_ds14
				select 
					i.itrnkey dockey, 
					i.adddate,
					dh.id_dochead, 
					dh.name_clients,
					dh.client_index,
					dh.doc_date,
					so.name_operation+' (' + cast(dh.operation as varchar(10)) + ')' operation, 
					sk.name_dockind+' (' + cast(dh.dockind as varchar(10)) + ')' dokind, 
					sd.name_doctype+' (' + cast(dh.doctype as varchar(10)) + ')' doctype, 
					sp.name_post_status+' (' + cast(dh.post_status as varchar(10)) + ')' post_status, 
					su.name_user+' (' + cast(dh.manager as varchar(10)) + ')' manager 
				from #iwm_dh14 i 
					inner join #sm_dh dh on cast(i.itrnkey as int) = dh.ext_docindex
					join #sm_user su on dh.manager = su.id_user
					join #sm_ps sp on dh.post_status = sp.id_post_status
					join #sm_dt sd on dh.doctype = sd.id_doctype
					join #sm_dk sk on dh.dockind = sk.id_dockind
					join #sm_op so on dh.operation = so.id_operation
--select * from #sm_dh
			drop table #iwm_dh14
		end
	end

-- ��������� ������� ����������� �� � �������������
if @typeverification = 2
	begin
		print '��������� ������� ����������� �� � �������������'
		if @typedocument = 0 
		-- ������ - ������ ������������ ����������� --------------------------------------------------------------------
			begin 
				print '��������� ��������� ''dockind = 0'''
				set @sql = @const_sql + @operation_0 +''')'
				exec (@sql)

				print '������� �������������� ���������� �� ������ �� ������ ��������� ��'
				select * into #iwm_dh20 
					from wh1.po p 
						inner join #sm_dh s on 
						p.externpokey = 'SM'+cast(s.id_dochead as varchar(10)) -- ����� ��������� 

				print '������� ���������, ��� ������� �� ������� ���� � ������'
				delete from s
					from #iwm_dh20 p right join #sm_dh s on p.externpokey = 'SM'+cast(s.id_dochead as varchar(10))
					where p.serialkey is null

				print '��������� ���������� ����������'
				-- �������� ��������� ������� Smarket
				SELECT * into #sm_ds20 FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select articul, shopindex as storerkey, quantity as qty, pricerub as unitprice, nds from docspec where id_dochead = 0')
				-- �������� ��������� ������� Infor
				select sku articul, storerkey, qtyadjusted qty, unitprice, unit_cost nds into #iwm_ds20	from wh1.podetail where externpokey = '0'
				-- ������� ������ ������� ����������
				select id_dochead into #dockey20 from #sm_dh

				while ((select count(id_dochead) from #dockey20) != 0)
					begin
						select top(1) @dockey = id_dochead from #dockey20 -- ����� ������ ���������
						-- ����� ������� ��������� �������
						set @sql = 'insert into #sm_ds20 SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'','''+
							'select articul, shopindex storerkey, quantity qty, pricerub unitprice, nds from docspec where id_dochead = '+cast(@dockey as varchar(10))+''')'
						exec (@sql)
						-- ����� ������� ���������� �����
						insert into #iwm_ds20 select sku articul, storerkey, case when [status] = '11' then qtyadjusted else qtyordered end qty, unitprice,  unit_cost nds
							from wh1.podetail where externpokey = 'SM'+cast(@dockey as varchar(10))

						-- ��������� ������� ����������
						if (((select round(sum(sm.qty + round(sm.unitprice,10) + case when sm.qty = 0 or sm.unitprice = 0 then 0 else round((sm.nds/((sm.qty*sm.unitprice-sm.nds)/100)),0) end),10) from #sm_ds20 sm) 
								= 
							(select round(sum(iwm.qty + round(iwm.unitprice,10) + iwm.nds),10) from #iwm_ds20 iwm))
							 and -- �������� �������� ���������� ���������� ����������
							(select count(iwm.externpokey) from #iwm_dh20 iwm inner join #sm_dh sm on
								iwm.externpokey = 'SM'+cast(sm.id_dochead as varchar(10)) and
								iwm.sellersreference = 'SM'+cast(sm.client_index as varchar(10)) -- ��� �������
								where sm.id_dochead = @dockey) 
								= 1)
							begin
								print '�������� ���������� � ������������� ' + cast (@dockey as varchar (15))
								delete from #iwm_dh20 where externpokey = 'SM'+cast(@dockey as varchar(10))
								delete from #sm_dh where id_dochead = @dockey
							end

						-- �������� ������������� ������ ���������
						delete from #dockey20 where id_dochead = @dockey

						-- ������� ������ ������� ����������
						delete from #sm_ds20
						delete from #iwm_ds20
					end
				drop table #dockey20
				drop table #sm_ds20
				drop table #iwm_ds20
--select * from #iwm_dh20

				select	po.pokey dockey, 
						po.adddate,
						dh.id_dochead, 
						dh.name_clients,
						dh.client_index,
						dh.doc_date,
						so.name_operation+' (' + cast(dh.operation as varchar(10)) + ')' operation, 
						sk.name_dockind+' (' + cast(dh.dockind as varchar(10)) + ')' dokind, 
						sd.name_doctype+' (' + cast(dh.doctype as varchar(10)) + ')' doctype, 
						sp.name_post_status+' (' + cast(dh.post_status as varchar(10)) + ')' post_status, 
						su.name_user+' (' + cast(dh.manager as varchar(10)) + ')' manager
					from #iwm_dh20 po 
						inner join #sm_dh dh on po.externpokey = 'SM'+cast(dh.id_dochead as varchar(10)) 
						join #sm_user su on dh.manager = su.id_user
						join #sm_ps sp on dh.post_status = sp.id_post_status
						join #sm_dt sd on dh.doctype = sd.id_doctype
						join #sm_dk sk on dh.dockind = sk.id_dockind
						join #sm_op so on dh.operation = so.id_operation
--select * from #sm_dh
				drop table #iwm_dh20
			end
		if @typedocument = 1
-- ������ - ������ ������������ ����������� --------------------------------------------------------------------
			begin 
				print '��������� ��������� ''dockind = 1'''
				set @sql = @const_sql + @operation_1 + ''')'
				exec (@sql)

				print '������� �������������� ���������� �� ������ �� ������ ��������� ��'
				select * into #iwm_dh21 
					from wh1.orders o 
						inner join #sm_dh s on 
						o.externorderkey = 'SM'+cast(s.id_dochead as varchar(10)) -- ����� ��������� 

				print '������� ���������, ��� ������� �� ������� ���� � ������'
				delete from s
					from #iwm_dh21 o right join #sm_dh s on o.externorderkey = 'SM'+cast(s.id_dochead as varchar(10))
					where o.serialkey is null

				print '��������� ���������� ����������'
				-- �������� ��������� ������� Smarket
				SELECT * into #sm_ds21 FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select articul, shopindex as storerkey, quantity as qty, pricerub as unitprice, nds from docspec where id_dochead = 0')
				-- �������� ��������� ������� Infor
				select sku articul, storerkey, shippedqty qty, unitprice, tax01 nds into #iwm_ds21 from wh1.orderdetail where externorderkey = '0'
				-- ������� ������ ������� ����������
				select id_dochead into #dockey21 from #sm_dh

				while ((select count(id_dochead) from #dockey21) != 0)
					begin
						select top(1) @dockey = id_dochead from #dockey21 -- ����� ������ ���������
						-- ���������� ��������� �������
						set @sql = 'insert into #sm_ds21 SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'','''+
							'select articul, shopindex storerkey, quantity qty, pricerub unitprice, nds from docspec where id_dochead = '+cast(@dockey as varchar(10))+''')'
						exec (@sql)
						-- ���������� ��������� �����
						insert into #iwm_ds21 select sku articul, storerkey, case when [status] >= '16' then shippedqty else openqty end qty, unitprice, tax01 nds
							from wh1.orderdetail where externorderkey = 'SM'+cast(@dockey as varchar(10))
						-- ��������� ������� ����������
						if (((select round(sum(sm.qty + round(sm.unitprice,10) + case when sm.qty = 0 or sm.unitprice = 0 then 0 else round((sm.nds/((sm.qty*sm.unitprice-sm.nds)/100)),0) end),10) from #sm_ds21 sm) 
								= 
							(select round(sum(iwm.qty + round(iwm.unitprice,10) + iwm.nds),10) from #iwm_ds21 iwm))
							 and -- �������� �������� ���������� ���������� ����������
							(select count(iwm.externorderkey) from #iwm_dh21 iwm inner join #sm_dh sm on
								iwm.externorderkey = 'SM'+cast(sm.id_dochead as varchar(10)) and
								iwm.consigneekey = 'SM'+cast(sm.client_index as varchar(10))-- ��� �������
								where sm.id_dochead = @dockey) 
								= 1)
							begin
								print '�������� ���������� ��� ����������� ' + cast (@dockey as varchar (15))
								delete from #iwm_dh21 where externorderkey = 'SM'+cast(@dockey as varchar(10))
								delete from #sm_dh where id_dochead = @dockey
							end

						-- ������� ��������� ������� � �������� ����������
						delete from #sm_ds21
						delete from #iwm_ds21
						-- ������� ����� ������������� ���������
						delete from #dockey21 where id_dochead = @dockey
					end
				drop table #dockey21
				drop table #sm_ds21
				drop table #iwm_ds21

				select	o.orderkey dockey, 
						o.adddate,
						dh.id_dochead, 
						dh.name_clients,
						dh.client_index,
						dh.doc_date,
						so.name_operation+' (' + cast(dh.operation as varchar(10)) + ')' operation, 
						sk.name_dockind+' (' + cast(dh.dockind as varchar(10)) + ')' dokind, 
						sd.name_doctype+' (' + cast(dh.doctype as varchar(10)) + ')' doctype, 
						sp.name_post_status+' (' + cast(dh.post_status as varchar(10)) + ')' post_status, 
						su.name_user+' (' + cast(dh.manager as varchar(10)) + ')' manager
					from #iwm_dh21 o 
						inner join #sm_dh dh on o.externorderkey = 'SM'+cast(dh.id_dochead as varchar(10))
						join #sm_user su on dh.manager = su.id_user
						join #sm_ps sp on dh.post_status = sp.id_post_status
						join #sm_dt sd on dh.doctype = sd.id_doctype
						join #sm_dk sk on dh.dockind = sk.id_dockind
						join #sm_op so on dh.operation = so.id_operation
--select * from #sm_dh
				drop table #iwm_dh21
			end
	if @typedocument = 3
-- ��������� - ������ ������������ ����������� --------------------------------------------------------------------
		begin 
			print '�������� ��������� Infor WM'
				set @sql = @const_sql + @operation_3 + ''')'
				exec(@sql)

				print '������� �������������� ���������� �� ������ �� ������ ��������� ��'
				select * into #iwm_dh23
					from da_adjustment a 
						inner join #sm_dh s on 
						cast(a.batchkey as int) = s.ext_docindex -- ����� ��������� 

				print '������� ���������, ��� ������� �� ������� ���� � ������'
				delete from s
					from #iwm_dh23 a right join #sm_dh s on cast(a.batchkey as int) = s.ext_docindex
					where a.id is null

--				select top (1) 
--					da.batchkey dockey, 
--					da.editdate adddate,
--					dh.id_dochead, 
--					dh.name_clients,
--					dh.client_index,
--					dh.doc_date,
--					so.name_operation+' (' + cast(dh.operation as varchar(10)) + ')' operation, 
--					sk.name_dockind+' (' + cast(dh.dockind as varchar(10)) + ')' dokind, 
--					sd.name_doctype+' (' + cast(dh.doctype as varchar(10)) + ')' doctype, 
--					sp.name_post_status+' (' + cast(dh.post_status as varchar(10)) + ')' post_status, 
--					su.name_user+' (' + cast(dh.manager as varchar(10)) + ')' manager 
--				from da_adjustment da 
--					inner join #sm_dh dh on cast(da.batchkey as int) = dh.ext_docindex
--					join #sm_user su on dh.manager = su.id_user
--					join #sm_ps sp on dh.post_status = sp.id_post_status
--					join #sm_dt sd on dh.doctype = sd.id_doctype
--					join #sm_dk sk on dh.dockind = sk.id_dockind
--					join #sm_op so on dh.operation = so.id_operation
--				where 1=2 -- �.�. ������������ �� ������ ����������� ����� ����������� ���������� � �����
--select * from #sm_dh

		end

	if @typedocument = 4
-- ����������� - ������ ������������ ����������� --------------------------------------------------------------------
		begin 
			print '�������� ����������� Infor WM'
				set @sql = @const_sql + @operation_4 + ''')'
				exec(@sql)

				print '������� �������������� ���������� �� ������ �� ������ ��������� ��'
				select * into #iwm_dh24
					from wh1.itrn i
						inner join #sm_dh s on 
						cast(i.itrnkey as int) = s.ext_docindex -- ����� ��������� 

				print '������� ���������, ��� ������� �� ������� ���� � ������'
				delete from s
					from #iwm_dh24 i right join #sm_dh s on cast(i.itrnkey as int) = s.ext_docindex
					where i.serialkey is null

				print '��������� ���������� ����������'
				-- �������� ��������� ������� Smarket
				SELECT * into #sm_ds24 FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select articul, shopindex as storerkey, quantity as qty from docspec where id_dochead = 0')
				-- �������� ��������� ������� Infor
				select sku articul, storerkey, qty into #iwm_ds24 from wh1.itrn where itrnkey = '0'
				print '������� ������ ������� ����������'
				select id_dochead into #dockey24 from #sm_dh

				while ((select count(id_dochead) from #dockey24) != 0)
					begin
						select top(1) @dockey = id_dochead from #dockey24 -- ����� ������ ���������
						-- ���������� ��������� �������
						set @sql = 'insert into #sm_ds24 SELECT * FROM OPENROWSET(''MSDASQL'',''DSN=SMarket;UID=SYSINFOR;PWD=3'','''+
							'select articul, shopindex as storerkey, quantity qty from docspec where id_dochead = '+cast(@dockey as varchar(10))+''')'
						exec (@sql)
						-- ���������� ��������� �����
						insert into #iwm_ds24 select sku articul, storerkey, qty
							from wh1.itrn where cast(itrnkey as int) = (select ext_docindex from #sm_dh where id_dochead = @dockey)

						-- ���������� ���������� ����������
						if ((select sum(sm.qty - iwm.qty) from #sm_ds24 sm join #iwm_ds24 iwm on sm.articul = iwm.articul and sm.storerkey = iwm.storerkey) = 0)
							begin
								print '�������� ���������� � ������������� ' + cast (@dockey as varchar (15))
								delete from #iwm_dh24 where itrnkey = (select ext_docindex from #sm_dh where id_dochead = @dockey)
								delete from #sm_dh where id_dochead = @dockey
							end

						-- ������� ��������� ������� � �������� ����������
						delete from #sm_ds24
						delete from #iwm_ds24
						-- ������� ����� ������������� ���������
						delete from #dockey24 where id_dochead = @dockey
					end
				drop table #dockey24
				drop table #sm_ds24
				drop table #iwm_ds24
				select 
					i.itrnkey dockey, 
					i.adddate,
					dh.id_dochead, 
					dh.name_clients,
					dh.client_index,
					dh.doc_date,
					so.name_operation+' (' + cast(dh.operation as varchar(10)) + ')' operation, 
					sk.name_dockind+' (' + cast(dh.dockind as varchar(10)) + ')' dokind, 
					sd.name_doctype+' (' + cast(dh.doctype as varchar(10)) + ')' doctype, 
					sp.name_post_status+' (' + cast(dh.post_status as varchar(10)) + ')' post_status, 
					su.name_user+' (' + cast(dh.manager as varchar(10)) + ')' manager 
				from #iwm_dh24 i 
					inner join #sm_dh dh on cast(i.itrnkey as int) = dh.ext_docindex
					join #sm_user su on dh.manager = su.id_user
					join #sm_ps sp on dh.post_status = sp.id_post_status
					join #sm_dt sd on dh.doctype = sd.id_doctype
					join #sm_dk sk on dh.dockind = sk.id_dockind
					join #sm_op so on dh.operation = so.id_operation
--select * from #sm_dh
			drop table #iwm_dh24
		end
	end
-- ��������� S-������, �� ������� ������������ � Infor WM
if @typeverification = 3
	begin
		print '��������� S-������, �� ������� ������������ � Infor WM'
		if @typedocument = 0
-- ������ - ������ ������� --------------------------------------------------------------------
			begin 
				print '��������� ��������� ''dockind = 0'''
				set @sql = @const_sql + @operation_0 + ''')'
				exec (@sql)

				select	po.pokey dockey, 
						po.adddate,
						dh.id_dochead, 
						dh.name_clients,
						dh.client_index,
						dh.doc_date,
						so.name_operation+' (' + cast(dh.operation as varchar(10)) + ')' operation, 
						sk.name_dockind+' (' + cast(dh.dockind as varchar(10)) + ')' dokind, 
						sd.name_doctype+' (' + cast(dh.doctype as varchar(10)) + ')' doctype, 
						sp.name_post_status+' (' + cast(dh.post_status as varchar(10)) + ')' post_status, 
						su.name_user+' (' + cast(dh.manager as varchar(10)) + ')' manager
					from wh1.po po 
						right join #sm_dh dh on po.externpokey = 'SM'+cast(dh.id_dochead as varchar(10))-- and po.serialkey is null
						join #sm_user su on dh.manager = su.id_user
						join #sm_ps sp on dh.post_status = sp.id_post_status
						join #sm_dt sd on dh.doctype = sd.id_doctype
						join #sm_dk sk on dh.dockind = sk.id_dockind
						join #sm_op so on dh.operation = so.id_operation
					where
						po.serialkey is null
--select * from #sm_dh
			end
		if @typedocument = 1
-- ������ - ������ ������� --------------------------------------------------------------------
			begin 
				print '��������� ��������� ''dockind = 1'''
				set @sql = @const_sql + @operation_1 + ''')'
				exec (@sql)

				select	o.orderkey dockey, 
						o.adddate,
						dh.id_dochead, 
						dh.name_clients,
						dh.client_index,
						dh.doc_date,
						so.name_operation+' (' + cast(dh.operation as varchar(10)) + ')' operation, 
						sk.name_dockind+' (' + cast(dh.dockind as varchar(10)) + ')' dokind, 
						sd.name_doctype+' (' + cast(dh.doctype as varchar(10)) + ')' doctype, 
						sp.name_post_status+' (' + cast(dh.post_status as varchar(10)) + ')' post_status, 
						su.name_user+' (' + cast(dh.manager as varchar(10)) + ')' manager
					from wh1.orders o 
						right join #sm_dh dh on o.externorderkey = 'SM'+cast(dh.id_dochead as varchar(10))-- and po.serialkey is null
						join #sm_user su on dh.manager = su.id_user
						join #sm_ps sp on dh.post_status = sp.id_post_status
						join #sm_dt sd on dh.doctype = sd.id_doctype
						join #sm_dk sk on dh.dockind = sk.id_dockind
						join #sm_op so on dh.operation = so.id_operation
					where
						o.serialkey is null
--select * from #sm_dh
			end
	if @typedocument = 3
-- ��������� - ������ ������� --------------------------------------------------------------------
		begin 
			print '�������� ��������� Infor WM'
				set @sql = @const_sql + @operation_3 + ''')'
				exec(@sql)

				select distinct 
					da.batchkey dockey, 
					da.editdate adddate,
					dh.id_dochead, 
					dh.name_clients,
					dh.client_index,
					dh.doc_date,
					so.name_operation+' (' + cast(dh.operation as varchar(10)) + ')' operation, 
					sk.name_dockind+' (' + cast(dh.dockind as varchar(10)) + ')' dokind, 
					sd.name_doctype+' (' + cast(dh.doctype as varchar(10)) + ')' doctype, 
					sp.name_post_status+' (' + cast(dh.post_status as varchar(10)) + ')' post_status, 
					su.name_user+' (' + cast(dh.manager as varchar(10)) + ')' manager 
				from da_adjustment da 
					right join #sm_dh dh on cast (da.batchkey as int) = dh.ext_docindex
					join #sm_user su on dh.manager = su.id_user
					join #sm_ps sp on dh.post_status = sp.id_post_status
					join #sm_dt sd on dh.doctype = sd.id_doctype
					join #sm_dk sk on dh.dockind = sk.id_dockind
					join #sm_op so on dh.operation = so.id_operation
				where
					da.id is null
		end

	if @typedocument = 4
-- ����������� - ������ ������� --------------------------------------------------------------------
		begin 
			print '�������� ����������� Infor WM'
				set @sql = @const_sql + @operation_4 + ''')'
				exec(@sql)

				select 
					i.itrnkey dockey, 
					i.adddate,
					dh.id_dochead, 
					dh.name_clients,
					dh.client_index,
					dh.doc_date,
					so.name_operation+' (' + cast(dh.operation as varchar(10)) + ')' operation, 
					sk.name_dockind+' (' + cast(dh.dockind as varchar(10)) + ')' dokind, 
					sd.name_doctype+' (' + cast(dh.doctype as varchar(10)) + ')' doctype, 
					sp.name_post_status+' (' + cast(dh.post_status as varchar(10)) + ')' post_status, 
					su.name_user+' (' + cast(dh.manager as varchar(10)) + ')' manager 
				from wh1.itrn i 
					right join #sm_dh dh on cast(i.itrnkey as int) = dh.ext_docindex
					join wh1.loc lf on lf.loc = i.fromloc
					join wh1.loc lt on lt.loc = i.toloc
					join #sm_user su on dh.manager = su.id_user
					join #sm_ps sp on dh.post_status = sp.id_post_status
					join #sm_dt sd on dh.doctype = sd.id_doctype
					join #sm_dk sk on dh.dockind = sk.id_dockind
					join #sm_op so on dh.operation = so.id_operation
				where
					i.itrnkey is null 
--select * from #sm_dh
		end
	end

-- ��������� Infor WM, �� ������� ������������ � S-������
if @typeverification = 4
	begin
		print '��������� Infor WM, �� ������� ������������ � S-������'
		if @typedocument = 0
-- ������ - ������ ����� --------------------------------------------------------------------
			begin 
				print '������� ���������� �� ������'
				select * into #iwm_dh40 
					from wh1.po 
					where 
						substring(externpokey,1,2) = 'SM'
						and adddate > @start_infor_date
						and adddate >= @startdate
						and adddate <= @enddate
						and storerkey like case when isnull(@storerkey,'') = '' then '%' else @storerkey end  -- �������� �� ���������� �� ���������� � �����
				select externpokey into #dockey40 from #iwm_dh40
				while ((select count(externpokey) from #dockey40) > 0)
					begin
						select top(1) @dockey_vch = externpokey from #dockey40 -- ����� ���������� ���������

						set @sql = @one_const_sql + @operation_0 + ' and id_dochead = ' + substring(@dockey_vch,3,15) + ''')' -- ����� ����������� ��������� � �������
						exec (@sql)

						delete d -- �������� ��������� ����������
							from #iwm_dh40 d inner join #sm_dh on d.externpokey = 'SM'+cast(id_dochead as varchar(15))

						delete from #sm_dh -- ������� ������� � ����������� �������

						delete from #dockey40 where externpokey = @dockey_vch -- �������� ������ ������������� ���������
					end
				drop table #dockey40

				select	po.pokey dockey, 
						po.adddate,
						'' id_dochead, 
						'' name_clients,
						'' client_index,
						'' doc_date,
						'' operation, 
						'' dokind, 
						'' doctype, 
						'' post_status, 
						'' manager
					from #iwm_dh40 po 
--select * from #sm_dh
				drop table #iwm_dh40
			end
		if @typedocument = 1
-- ������ - ������ ����� --------------------------------------------------------------------
			begin 
				print '������� ���������� �� ������'
				select * into #iwm_dh41 
					from wh1.orders 
					where 
						substring(externorderkey,1,2) = 'SM'
						and adddate > @start_infor_date
						and adddate >= @startdate
						and adddate <= @enddate
						and storerkey like case when isnull(@storerkey,'') = '' then '%' else @storerkey end -- �������� �� ���������� �� ���������� � �����
				select externorderkey into #dockey41 from #iwm_dh41
				while ((select count(externorderkey) from #dockey41) > 0)
					begin
						select top(1) @dockey_vch = externorderkey from #dockey41 -- ����� ���������� ���������

						set @sql = @one_const_sql + @operation_1 + ' and id_dochead = ' + substring(@dockey_vch,3,15) + ''')' -- ����� ����������� ��������� � �������
						exec (@sql)

						delete d -- �������� ��������� ����������
							from #iwm_dh41 d inner join #sm_dh on d.externorderkey = 'SM'+cast(id_dochead as varchar(15))

						delete from #sm_dh -- ������� ������� � ����������� �������

						delete from #dockey41 where externorderkey = @dockey_vch -- �������� ������ ������������� ���������
					end
				drop table #dockey41

				select	o.orderkey dockey, 
						o.adddate,
						'' id_dochead, 
						'' name_clients,
						'' client_index,
						'' doc_date,
						''  operation, 
						'' dokind, 
						'' doctype, 
						'' post_status, 
						'' manager
					from #iwm_dh41 o
--select * from #sm_dh
				drop table #iwm_dh41
			end
	if @typedocument = 3
-- ��������� - ������ ����� --------------------------------------------------------------------
		begin 
			print '�������� ��������� Infor WM'

				select distinct case when isnull(batchkey,'') = '' then '0000000000' else batchkey end batchkey, max (editdate) editdate  into #iwm_dh43
					from da_adjustment 
					where 
						editdate > @start_infor_date
						and editdate >= @startdate
						and editdate <= @enddate
						and storerkey like case when isnull(@storerkey,'') = '' then '%' else @storerkey end -- �������� �� ���������� �� ���������� � �����
					group by batchkey

				select batchkey into #dockey43 from #iwm_dh43
				while ((select count(batchkey) from #dockey43) > 0)
					begin
						select top(1) @dockey_vch = batchkey from #dockey43 -- ����� ���������� ���������

						set @sql = @one_const_sql + @operation_3 + ' and ext_docindex = ''''' + cast(cast(@dockey_vch as int) as varchar (10)) + ''''''')' -- ����� ����������� ��������� � �������
						exec (@sql)

						delete d -- �������� ��������� ����������
							from #iwm_dh43 d inner join #sm_dh on cast(d.batchkey as int) = cast(ext_docindex as int)

						delete from #sm_dh -- ������� ������� � ����������� �������

						delete from #dockey43 where batchkey = @dockey_vch -- �������� ������ ������������� ���������
					end
				drop table #dockey43

				select distinct 
					da.batchkey dockey, 
					da.editdate adddate,
					'' id_dochead, 
					'' name_clients,
					'' client_index,
					'' doc_date,
					'' operation, 
					'' dokind, 
					'' doctype, 
					'' post_status, 
					'' manager 
				from #iwm_dh43 da 
--select * from #sm_dh
			drop table #iwm_dh43
		end

	if @typedocument = 4
-- ����������� - ������ ����� --------------------------------------------------------------------
		begin 
			print '�������� ����������� Infor WM'

				select i.* into #iwm_dh44
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
						and i.trantype = 'MV'														-- ����� �� ��������� da_move

				select itrnkey into #dockey44 from #iwm_dh44
				while ((select count(itrnkey) from #dockey44) > 0)
					begin
						select top(1) @dockey_vch = itrnkey from #dockey44 -- ����� ���������� ���������

						set @sql = @one_const_sql + @operation_4 + ' and ext_docindex = ''''' + cast(cast(@dockey_vch as int) as varchar (10)) + ''''''')' -- ����� ����������� ��������� � �������
						exec (@sql)

						delete d -- �������� ��������� ����������
							from #iwm_dh44 d inner join #sm_dh on cast(d.itrnkey as int) = cast(ext_docindex as int)

						delete from #sm_dh -- ������� ������� � ����������� �������

						delete from #dockey44 where itrnkey = @dockey_vch -- �������� ������ ������������� ���������
					end
				drop table #dockey44

				select 
					i.itrnkey dockey, 
					i.adddate,
					'' id_dochead, 
					'' name_clients,
					'' client_index,
					'' doc_date,
					'' operation, 
					'' dokind, 
					'' doctype, 
					'' post_status, 
					'' manager 
				from #iwm_dh44 i 
--select * from #sm_dh
drop table #iwm_dh44
		end
	end


drop table #sm_dh
drop table #sm_user
drop table #sm_ps
drop table #sm_dt
drop table #sm_dk
drop table #sm_op

