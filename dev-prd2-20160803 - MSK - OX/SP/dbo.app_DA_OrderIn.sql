--################################################################################################
--         ��������� ������������ ������������� ����� �� �������� �� ������������� ������
--################################################################################################
ALTER PROCEDURE [dbo].[app_DA_OrderIn] 
AS
declare @orderkey varchar (10), -- �����
		@storerkey varchar (15), -- ��� ���������
		@carriercode varchar (15), -- ��� �����������/�����������
		@consigneekey varchar (15), -- ��� �������� �����
		@typework int, -- ��� ���������
		@wavekey varchar (10), -- ����� �����
		@wavedetailkey varchar (10), -- ����� ������ �����
		@wavedescr varchar (15), -- �������� �����
		@qtyorderwave int, -- ���������� ������� � ������������� ����������� �����
--		@dispatchcasepickmethod varchar (10), -- ����� ������������� ����� ����� �����
		@Load varchar (10), -- ������������� ������������ ��������
		@loadid varchar (10), -- ����� ��������
		@loadstopid int, -- ������������� ����� (��������� ��������) � ��������
		@loadorderdetailid int, -- ������������� ������ � ������� � ��������
		@stop int, -- ����� ����� � ��������
		@carriername varchar (45), -- ������������ �����������
		@requestedshipdate varchar(10), -- ����������� ���� ��������
		@b_company varchar (15) -- ��� ����������
--		@Return varchar (30) -- ����� ��������

--set @dispatchcasepickmethod = '1'
print '>>> app_DA_OrderIn >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
print 'DAOI.1.x. ����������� ������� ������ ��� ������������� �������'
	select	@storerkey = case when storerkey is null or ltrim(rtrim(storerkey)) = '' then '' else ltrim(rtrim(storerkey)) end, 
			@carriercode = case when carriercode is null or ltrim(rtrim(carriercode)) = '' then '' else ltrim(rtrim(carriercode)) end, 
			@consigneekey = case when consigneekey is null or ltrim(rtrim(consigneekey)) = '' then '' else ltrim(rtrim(consigneekey)) end,
			@requestedshipdate = case when requestedshipdate is null then '' else convert(varchar(10),requestedshipdate,21) end,
			@b_company = case when b_company is null or ltrim(rtrim(b_company)) = '' then consigneekey else ltrim(rtrim(b_company)) end
		from ##DA_OrderHead where flag = 0

print 'DAOI.2.x. ����������� ���� ��������� ������'
	select @typework = bt.wavetype from wh1.businesstypes bt
		where bt.storerkey = @storerkey
print 'Orderkey: ' + case when convert(varchar(10),@orderkey) is null then '' else convert(varchar(10),@orderkey) end + '. CarrierCode: ' + case when @carriercode is null then '' else @carriercode end + '. Consigneekey: ' + case when @consigneekey is null then '' else @consigneekey end + '. Storerkey:' + case when @storerkey is null then '' else @storerkey end + '. typework:' + case when convert(varchar(10),@typework) is null then '' else convert(varchar(10),@typework) end + '.'

	if @typework = 1
		begin
			print 'DAOI. ��� ��������� 1'
			if (select ltrim(rtrim(upper(susr1))) from wh1.storer where storerkey = @b_company) = '�������'
				begin
					print 'DAOI.5.1.3. ������� ������. b_company: ' + @b_company
					if @carriercode = ''
						begin
							print 'DAOI.5.1.4. ���������� ����������.'
							print 'DAOI.5.1.5.1. ������������ ����������� ������ ��������� ORDERKEY'
							exec dbo.DA_GetNewKey 'wh1','order',@orderkey output
							print 'DAOI.5.1.5.2. ���������� ��������� ���������'
							insert into wh1.orders (orderkey,  storerkey, externorderkey, [type],  consigneekey,  carriercode, intermodalvehicle, requestedshipdate,         deliveryplace,  deliveryadr, susr3, susr4, c_company,  b_company, transportationmode, carriername, c_vat, c_address1, c_address2, c_address3, c_address4,   door)
								select			   @orderkey, @storerkey, externorderkey, [type], @consigneekey, @carriercode,      @carriercode, requestedshipdate, left(deliveryaddr,30), deliveryaddr, susr3, susr4, c_company, @b_company,                '0', carriername, c_vat, c_address1, c_address2, c_address3, c_address4, 'DOCK'
								from ##DA_OrderHead where flag = 0
							print 'DAOI.5.1.5.3. ���������� ������� ���������'
							insert into wh1.orderdetail (orderkey, orderlinenumber,                             externorderkey,     externlineno,     storerkey,     sku, originalqty,     openqty,  uom,     allocatestrategykey,     preallocatestrategykey,     allocatestrategytype,     cartongroup,     packkey,     shelflife)
								 select @orderkey, right('0000'+convert(varchar(5),dod.orderlinenumber),5), dod.externorderkey, dod.externlineno, dod.storerkey, dod.sku, dod.openqty, dod.openqty, 'EA', dod.allocatestrategykey, dod.preallocatestrategykey, dod.allocatestrategytype, dod.cartongroup, dod.packkey, dod.shelflife
								from ##DA_OrderHead doh join ##DA_OrderDetail dod on doh.id = dod.ohid
								where doh.flag = 0 and dod.flag = 0 
						end	
					else
						begin -- ����� ������������������ ������
							print 'DAOI.5.1.4. ���������� ��������. Carriercode: ' + @Carriercode + '. ���� ��������: '+@requestedshipdate + '. B_Company ' + @b_company+'. Consigneekey '+@consigneekey

							select @orderkey = o.orderkey
								from wh1.orders o join wh1.storer s on o.b_company = s.storerkey
								where o.externorderkey = 'consolidation' 
									and o.status < '11' 
									and o.carriercode = @carriercode 
									and convert(varchar(10),o.requestedshipdate,21) = @requestedshipdate
									and ltrim(rtrim(upper(s.susr1))) = '�������'

							if @orderkey is null or rtrim(ltrim(@orderkey)) = ''
								begin
									print 'DAOI.5.1.5. ������������������ ������ � ����� �������� '+@requestedshipdate+' ���. ������� �����.'
									print 'DAOI.5.1.5.1. ������������ ����������� ������ ��������� ORDERKEY'
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
									print 'DAOI.5.1.5. ����������������� ����� ����. ��������� � ���� ������. ��� ���������� ���� �����+�������� ��� ����'
--									print 'DAOI.5.1.5.2. app_DA_OrderCons ' + @Orderkey + ', detail'
									exec app_DA_OrderCons @Orderkey, 'detail'
								end
						end
				end
			else
				begin
					print 'DAOI.5.1.3. ��������� ������. b_Company: ' + @b_company+'. Consigneekey: '+@consigneekey
					-- ����� ����������������� ������
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
							print 'DAOI.5.1.5. ������������������ ������ � ����������� ����� �������� '+@requestedshipdate+' ���. ������� �����.'
							print 'DAOI.5.1.5.1. ������������ ����������� ������ ��������� ORDERKEY'
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
							print 'DAOI.5.1.5. ����������������� ����� ����. ��������� � ���� ������. ��� ���������� ���� �����+�������� ��� ����'

							print 'DAOI.5.1.5.2. app_DA_OrderCons ' + @Orderkey + ', detail'
							exec app_DA_OrderCons @Orderkey, 'detail'
						end
				end
		end	
	else
		begin
			print 'DAOI. ��� ��������� 2'
			print 'DAOI.4. ���������� ����������'
			print 'DAOI.4.1. ������������ ����������� ������ ��������� ORDERKEY'
			exec dbo.DA_GetNewKey 'wh1','order',@orderkey output

			print 'DAOI.4.2. ���������� ��������� ���������'
			insert into wh1.orders (orderkey,  storerkey, externorderkey, [type],  consigneekey,  carriercode, intermodalvehicle, requestedshipdate,         deliveryplace,  deliveryadr, susr3, susr4, c_company,  b_company, transportationmode, carriername, c_vat, c_address1, c_address2, c_address3, c_address4,   door)
				select			   @orderkey, @storerkey, externorderkey, [type], @consigneekey, @carriercode,      @carriercode, requestedshipdate, left(deliveryaddr,30), deliveryaddr, susr3, susr4, c_company, @b_company,                '0', carriername, c_vat, c_address1, c_address2, c_address3, c_address4, 'DOCK'
				from ##DA_OrderHead where flag = 0

			print 'DAOI.4.3. ���������� ������� ���������'
			insert into wh1.orderdetail (orderkey, orderlinenumber,                             externorderkey,     externlineno,     storerkey,     sku, originalqty,     openqty,  uom,     allocatestrategykey,     preallocatestrategykey,     allocatestrategytype,     cartongroup,     packkey,       shelflife)
									select o.orderkey, right('0000'+convert(varchar(5),dod.orderlinenumber),5), dod.externorderkey, dod.externlineno, dod.storerkey, dod.sku, dod.openqty, dod.openqty, 'EA', dod.allocatestrategykey, dod.preallocatestrategykey, dod.allocatestrategytype, dod.cartongroup, dod.packkey, dod.shelflife
				from ##DA_OrderHead doh join ##DA_OrderDetail dod on doh.id = dod.ohid
								join wh1.orders o on o.externorderkey = doh.externorderkey
				where doh.flag = 0 and dod.flag = 0

			print 'DAOI.4.4. ����������� ������������ �����������'
			select @carriername = carriername
				from ##DA_OrderHead where flag = 0

			print 'DAOI.5.2. ��� ��������� 2'
			if (select ltrim(rtrim(upper(susr1))) from wh1.storer where storerkey = @b_company) = '�������'
				begin
					print 'DAOI.5.2.3. ������� ������. b_company: ' + @b_company
					if @carriercode = ''
						begin
							print 'DAOI.5.2.4. ���������� �������.'
							-- ����� �����
							select distinct @wavekey = w.wavekey
								from wh1.wave w join wh1.wavedetail wd on w.wavekey = wd.wavekey
									join wh1.orders o on o.orderkey = wd.orderkey
								where w.descr = '' and w.status = '0'
--									and o.consigneekey = @consigneekey -- ����������� �� ������������
									and o.storerkey = @storerkey and convert(varchar(10),o.requestedshipdate,21) = @requestedshipdate
								group by w.wavekey
								having max (o.status) <= '11' -- �������� ������� ���������� �������
							if @wavekey is null or ltrim(rtrim(@wavekey)) = '' set @wavekey = ''
							-- ������������ ���������� ������� � �����
							select @qtyorderwave = convert(int,description) from wh1.codelkup where listname = 'sysvar' and code = 'qtyorderw'
							if @wavekey = ''
								begin
									print 'DAOI.5.2.5. ����� c ������ DESCR � �������� � ����������� ����� �������� '+@requestedshipdate+' ���'
									set @wavedescr = ''
									exec app_DA_Waves null, @wavedescr, @orderkey, '', 'new'--:
--									goto NewWave
								end
							else
								begin
									print 'DAOI.5.2.5. ����� c ������ DESCR � ����������� ����� �������� '+@requestedshipdate+' ����. Wavekey: ' + @Wavekey
--									set @Return = 'CheckQtyOrderWave'
--									goto NewWaveDetailKey
--								CheckQtyOrderWave:
									exec app_DA_Waves @wavekey, null, @orderkey, @carriercode,'detail'

									if (select count (wd.serialkey) from wh1.wavedetail wd where wd.wavekey = @Wavekey) = @qtyorderwave
										begin
											print 'DAOI.5.2.6. � ����� ������������ ���������� �������. Descr = ' + @Wavekey
											update wh1.wave set descr = @Wavekey where wavekey = @wavekey
										end
								end
						end
					else
						begin
							print 'DAOI.5.2.4. ���������� �����. CarrierKey: ' + @carriercode
							-- ����� �����
							select distinct @wavekey = w.wavekey 
								from wh1.wave w join wh1.wavedetail wd on w.wavekey = wd.wavekey
									join wh1.orders o on o.orderkey = wd.orderkey 
								where w.descr = @carriercode and w.status = '0'
--									and o.consigneekey = @consigneekey -- ����������� �� �����������
									and o.storerkey = @storerkey and convert(varchar(10),o.requestedshipdate,21) = @requestedshipdate
								group by w.wavekey
								having max (o.status) <= '11' -- �������� ������� ���������� �������
							if @wavekey is null or ltrim(rtrim(@wavekey)) = '' set @wavekey = ''
							if @wavekey = ''
								begin 
									print 'DAOI.5.2.5. ������������ ����� ��� ����������� ���'
									set @wavedescr = @carriercode
									set @Load = 'yes'
									exec app_DA_Waves null, @wavedescr, @orderkey, @carriercode,'new'

--									goto NewWave
								end
							else
								begin 
									print 'DAOI.5.2.5. ������������ ����� ��� ����������� ����. Wavekey: ' + @Wavekey
									set @Load = 'yes'
									exec app_DA_Waves @wavekey, null, @orderkey, @carriercode, 'detail'
--									goto NewWaveDetailKey
								end
						end
				end
			else 
				begin
					print 'DAOI.5.2.3. ��������� ������. b_Company: ' + @b_Company
					
--					if @carriercode != ''
--						begin
--							print 'DAOI.5.2.3.1. ���������� �����. Carriercode: ' + @Carriercode
--
--						end
--					else
--						begin
--							print 'DAOI.5.2.3.1. ���������� �� �����.'
--							-- ����� ������������ �����
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
--								having max (o.status) <= '11' -- �������� ������� ���������� �������
--							if @wavekey is null or ltrim(rtrim(@wavekey)) = '' set @wavekey = ''
--							if @wavekey = ''
--								begin
--									print 'DAOI.5.2.4. ������������ ����� � ����������� ����� �������� '+@requestedshipdate+' ��� ������� ���'
--									if @carriercode != '' set @load = 'yes'
--									set @wavedescr = @consigneekey
--									exec app_DA_Waves null, @wavedescr, @orderkey, @carriercode, 'new'
----									goto NewWave
--								end
--							else
--								begin 
--									print 'DAOI.5.2.4. ������������ ����� ��� � ����������� ����� �������� '+@requestedshipdate+' ������� ����. Wavekey: ' + @WaveKey
--									if @carriercode != '' set @load = 'yes'
--									exec app_DA_Waves @wavekey, null, @orderkey, @carriercode, 'detail'
----									goto NewWaveDetailKey
--								end
--						end

					-- ����� ������������ �����
					select @wavekey = w.wavekey 
						from wh1.wave w join wh1.wavedetail wd on w.wavekey = wd.wavekey
							join wh1.orders o on o.orderkey = wd.orderkey
--						where w.descr = @consigneekey and w.status = '0'
						where w.descr = @consigneekey and w.status = '0'
							and o.b_company = @b_company
							and o.storerkey = @storerkey and convert(varchar(10),o.requestedshipdate,21) = @requestedshipdate
							and o.carriercode = @carriercode --:
						group by w.wavekey
						having max (o.status) <= '11' -- �������� ������� ���������� �������
					if @wavekey is null or ltrim(rtrim(@wavekey)) = '' set @wavekey = ''
					if @wavekey = ''
						begin
							print 'DAOI.5.2.4. ������������ ����� � ����������� ����� �������� '+@requestedshipdate+' ��� ������� '+@consigneekey+' � ����������� '+@carriercode+' ���'
							if @carriercode != '' set @load = 'yes'
							set @wavedescr = @consigneekey
							exec app_DA_Waves null, @wavedescr, @orderkey, @carriercode, 'new'
--							goto NewWave
						end
					else
						begin 
							print 'DAOI.5.2.4. ������������ ����� ��� � ����������� ����� �������� '+@requestedshipdate+' ��� ������� '+@consigneekey+' � ����������� '+@carriercode+'����. Wavekey: ' + @WaveKey
							if @carriercode != '' set @load = 'yes'
							exec app_DA_Waves @wavekey, null, @orderkey, @carriercode, 'detail'
--							goto NewWaveDetailKey
						end
				end
		end

NextStep:
print '6. �������� ������������� ������������ ��������'
	if @Load = 'yes'
		begin
			print '6.0. ��������� ���������� �� �������� ��� storerkey: '+@storerkey+' � �������������� ����� �������� '+@requestedshipdate+'. Carriercode: '+@carriercode+'.'
			select top 1 @loadid = lh.loadid, @loadstopid = ls.loadstopid from wh1.loadhdr lh join wh1.loadstop ls on lh.loadid = ls.loadid
				join wh1.loadorderdetail lod on lod.loadstopid = ls.loadstopid
				join wh1.orders o on o.orderkey = lod.shipmentorderid
					where (lh.door is null or ltrim(rtrim(lh.door)) = '') and lh.carrierid = @carriercode and 
						--lh.[route] = @carriercode 
						lh.externalid = @carriercode and o.storerkey = @storerkey and convert(varchar(10),o.requestedshipdate,21) = @requestedshipdate
			if @loadid is null or ltrim(rtrim(@loadid)) = ''
				begin
					print '6.1. �������� � door = '' ��� null ��� carrier: ' + @carriercode + ' � ����������� ����� �������� '+@requestedshipdate+' ���. ������� ��������.'
					exec dbo.DA_GetNewKey 'wh1','CARTONID',@loadid output	
					print '����� �������� loadid: ' + @loadid
					print '6.1.1. ��������� ����� ��������'
					insert wh1.loadhdr (whseid,  loadid,   externalid, [route],    carrierid, status, door,             trailerid)
						select           'WH1', @loadid, @carriercode, @loadid, @carriercode,    '0',   '', left(@carriername, 10)
					print '6.1.2. ��������� ���� � ��������'
					exec dbo.DA_GetNewKey 'wh1','LOADSTOPID',@loadstopid output	
					print '������������� ��������� � �������� loadstopid: ' + convert(varchar(10),@loadstopid)
					set @stop = 1 -- ������ ���� ��������� � ��������
					insert wh1.loadstop (whseid,  loadid,  loadstopid,  stop, status)
						select            'WH1', @loadid, @loadstopid, @stop,    '0'

				end
--			else
--				begin
--					print '6.1. �������� �� status = 0 ��� carrier: ' + @carriercode + ' ����. Loadid: ' + @Loadid
--					-- ����������� ����������� ����������
--					select top 1 @loadid = lh.loadid, @loadstopid = ls.loadstopid from wh1.loadhdr lh join wh1.loadstop ls on lh.loadid = ls.loadid
--						where (lh.door is null or ltrim(rtrim(lh.door)) = '') and lh.carrierid = @carriercode and lh.[route] = @carriercode and ls.stop = 1
--				end
			print '6.2. ��������� ����� �� �������� � ��������'
			exec dbo.DA_GetNewKey 'wh1','LOADORDERDETAILID',@loadorderdetailid output	
			insert wh1.loadorderdetail (whseid, loadstopid, loadorderdetailid, storer, shipmentorderid, customer)
				select 'WH1', @loadstopid, @loadorderdetailid, @storerkey, @orderkey, @consigneekey

			print '6.3. ��������� ���� b_zip � ������ ��� ���������� ��������'
			update wh1.orders set b_zip = @loadid where orderkey = @orderkey

		end
/*
wh1.loadhdr -- ������� ����� ��������
	loadid -- pk ������������� �������� wh1.ncounter.cartonid

wh1.loadorderdetail -- ������� ������� � ���������
	loadorderdetailid -- pk ������������� ������ � ������� ������ � �������� wh1.ncounter.loadorderdetailid
	shipmentorder -- ����� ������ �� ��������
	loadstopid -- ������������� ��������� ��� ������ wh1.loadstop

wh1.loadunitdetail -- ������� ����������� ������ �������
	loadunitdetailid -- pk 

wh1.loadstop -- ������� ���������
	stop -- ����� ���������
	loadstopid -- pk ������������� ��������� wh1.ncounter.loadstopid
	loadid -- ������������� �������� wh1.loadhdr

wh1.loadplanning -- ???
	loadplanningkey -- pk ������������� ??? wh1.ncounter.loadplanning
*/
	else
		print '6.1. �������� �������'

print '<<< app_DA_OrderIn <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'

