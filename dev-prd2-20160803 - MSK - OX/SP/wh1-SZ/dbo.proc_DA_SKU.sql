
ALTER PROCEDURE [dbo].[proc_DA_SKU]
	@source varchar(500) = null
as  
--declare @source varchar(500)

declare @allowUpdate int
declare @send_error bit
declare @msg_errdetails varchar(max)
declare @msg_errdetails1 varchar(max)
declare @storerkey varchar(15)
declare @sku varchar(15)
declare @barcod varchar(max) -- ����� ���� �� ������
declare @packkey varchar(50),
	@sign int = 0 

--declare @maxcube numeric(20,5) -- ������������ ����� ��� ���������� �� 0 � 1 ������
--set @maxcube = 500
set @packkey = 'STD'

--declare @tarn_in int -- ���������� �������� (packkey)
--declare @tarn_out int -- ������� �������� (rfdefaultpack)
declare @enter varchar(10) 

--create table #tmp_altsku (
--	storerkey varchar(15),
--	sku varchar(15),
--	packkey varchar(15),
--	barcod varchar (50),
--	generation varchar (1))

set @send_error = 0
set @msg_errdetails = ''
set @enter = char(10)+char(13)

BEGIN TRY
	print ' ���������� ����������� ���������� �������'
	select @allowUpdate = allowUpdate from dbo.DA_MessageTypes where MessageKey = 'SkuCard'

	while (exists (select id from da_sku))
	begin
		set @sign = 1
		
		print ' �������� ������ �� �������� ������� da_sku'
		select top(1) * into #da_sku from da_sku order by id desc
		

		print ' ���������� NULL ��������'
		update ds 
		set	storerkey = case    when (left(isnull(rtrim(ltrim(storerkey)),''),15)) = 'SZ' then '001' 
					    else (left(isnull(rtrim(ltrim(storerkey)),''),15)) 
					    end,
			ds.sku = left(isnull(rtrim(ltrim(sku)),''),50),
			ds.descr = left(isnull(rtrim(ltrim(descr)),''),250),
			ds.busr1 = left(isnull(rtrim(ltrim(busr1)),''),30),
			ds.busr2 = left(isnull(rtrim(ltrim(busr2)),''),30),
			ds.altsku = left(isnull(rtrim(ltrim(altsku)),''),50),
			ds.freightclass = left(isnull(rtrim(ltrim(freightclass)),''),10),			
			ds.skugroup = left(isnull(ds.skugroup,''),10)			
			
			--ds.stdcube = isnull(ds.stdcube,0),
			--ds.stdgrosswgt = isnull(ds.stdgrosswgt,0),		
		from #da_sku ds
		
		
		print '������� ������� �������'
		update #da_sku 
		set 
		descr = replace(replace(descr,'"','`'),'''','`')
		

		set @msg_errdetails1 = ''
		print ' �������� ������� ������'
		select 
			@msg_errdetails1 = @msg_errdetails1 --storerkey EMPTY
				+case when s.storerkey = ''
					then 'er#001SKU. STORERkey=empty'+@enter
					else ''
				end,
			@msg_errdetails1 = @msg_errdetails1 --storerkey IN STORER
				+case when (not exists(select top(1) ws.* from wh1.storer ws where ws.storerkey = s.storerkey)) 
					then 'er#002SKU. ��������='+s.storerkey+' ��������� � ����������� STORER.'+@enter
					else '' 
				end,
			@msg_errdetails1 = @msg_errdetails1 --sku EMPTY
				+case when s.sku = ''
					then 'er#003SKU. ��������='+s.storerkey+' �����=������.'+@enter
					else ''
				end,
			@msg_errdetails1 = @msg_errdetails1 --allowupdate = 0
				+case when (exists(select top(1) ws.serialkey from wh1.sku ws where ws.storerkey = s.storerkey and ws.sku = s.sku)
					and @allowupdate = 0)
					then 
						'er#004SKU. STORERkey='+s.storerkey+' SKU='+s.sku+'. ���������� ���������.'+@enter
					else ''
				end,
			@msg_errdetails1 = @msg_errdetails1 --skugroup in STRATEGYXSKU
				+case when (not exists(select top(1) * from wh1.StrategyxSKU ss 
							join wh1.CODELKUP c on c.SHORT = ss.CLASS and c.LISTNAME = 'FREIGHTCLS' where c.CODE = s.freightclass)) 
					then 'er#005SKU. �����='+s.sku+', ��������='+s.storerkey+'. �����������='+s.freightclass+' ��������� � ����������� wh1.StrategyxSku.'+@enter
					else ''
				end,
			@msg_errdetails1 = @msg_errdetails1 --s.busr1 EMPTY
				+case when s.busr1 = ''
					then 'er#006SKU. �����='+s.sku+'�������������=������'+@enter
					else ''
				end,
			--@msg_errdetails1 = @msg_errdetails1 --s.altsku EMPTY
			--	+case when s.altsku = ''
			--		then 'SKU. SKU='+s.sku+', STORERkey='+s.storerkey+ 'altsku= EMPTY '+@enter
			--		else ''
			--	end,
			@msg_errdetails1 = @msg_errdetails1 --s.altsku in another sku
				+case when a.altsku is not null and a.sku <> s.sku
					then 'er#007SKU. �����='+s.sku+', ��������='+s.storerkey+ '�� ����������� ������� ������ '+@enter
					else ''
				end,				
			@msg_errdetails1 = @msg_errdetails1 --s.busr1 IN STORER
				+case when (not exists(select top(1) ws.* from wh1.storer ws where ws.storerkey = s.busr1)) 
					then 'er#008SKU. �����='+s.sku+', �������������='+s.busr1+' ��������� � ����������� STORER.'+@enter
					else '' 
				end
				
			--@msg_errdetails1 = @msg_errdetails1 --skugroup in DA_SKUGROUP2
			--	+case when (not exists(select top(1) * from da_skugroup2 where skugroup2 = s.skugroup2))
			--		then 'SKU. SKU='+s.sku+', STORERkey='+s.storerkey+'. skugroup='+s.skugroup2+' ��������� � ����������� DA_SKUGROUP2.'+@enter
			--		else ''
			--	end,
			--@msg_errdetails1 = @msg_errdetails1 --skugroup in DA_CLASS
			--	+case when (not exists(select top(1) * from da_class where class = s.class)) 
			--		then 'SKU. SKU='+s.sku+', STORERkey='+s.storerkey+'. class='+s.class+' ��������� � ����������� DA_CLASS.'+@enter
			--		else ''
			--	end,
			--@msg_errdetails1 = @msg_errdetails1 --casecnt!=STD
			--	+case when s.casecnt != 'STD'
			--		then 'SKU. SKU='+s.sku+' STORERkey='+s.storerkey+' CASECNT!=STD.'+@enter
			--		else ''
			--	end
			--@msg_errdetails1 = @msg_errdetails1 --stdcube 0
			--	+case when s.stdcube = 0
			--		then 'SKU. SKU='+s.sku+' STORERkey='+s.storerkey+' STDCUBE=0.'+@enter
			--		else ''
			--	end,
			--@msg_errdetails1 = @msg_errdetails1 --stdgrosswgt 0
			--	+case when s.stdgrosswgt = 0
			--		then 'SKU. SKU='+s.sku+' STORERkey='+s.storerkey+' STDGROSSWGT=0.'+@enter
			--		else ''
			--	end
		from	#da_sku s
			left join wh1.altsku a
			    on s.storerkey = a.storerkey
			    and s.altsku = a.altsku		
	
		if (@msg_errdetails1 = '') 
		begin
			print ' �������� ������� ������ ������� �������'
			print ' �������� SKU'
			select @storerkey = storerkey, @sku = sku/*, @packkey = 1, @tarn_in = tarn_in, @tarn_out = tarn_out*/ from #da_sku

			print ' ��������� ������� SKU='+@sku+', STORERkey='+@storerkey+' � ����'
			if (exists (select ws.* from wh1.sku ws where ws.storerkey = @storerkey and ws.sku = @sku))
				begin
					print ' sku='+@sku+' � STORERkey='+@storerkey+' ��� ����������'
					print ' ��������� sku='+@sku+', storer='+@storerkey
					
					update s 
					set 
						s.descr = ds.descr,
						s.notes1 = ds.descr,
						s.busr1 = ds.busr1,
						s.busr2 = ds.busr2,					
						--s.altsku = ds.altsku,					
						s.freightclass = ds.freightclass,
						s.skugroup = ds.skugroup,																							
						--s.rfdefaultpack = ds.casecnt,	
						s.STRATEGYKEY = dsg.strategykey,
						s.putawayzone = dsg.putawayzone,		
						s.PUTAWAYSTRATEGYKEY = dsg.PUTAWAYSTRATEGYKEY						
						--s.stdcube = ds.stdcube,
						--s.stdgrosswgt = ds.stdgrosswgt,																																								
					from	wh1.sku s 
							join #da_sku ds 
								on s.sku = ds.sku and s.storerkey = ds.storerkey
							join wh1.CODELKUP c
								on c.CODE = ds.FreightClass
								and c.LISTNAME = 'FREIGHTCLS'
							join wh1.strategyxsku dsg 
								on dsg.class = c.SHORT
					if @@rowcount = 0 
					begin
						set @msg_errdetails = @msg_errdetails+'SKU. sku='+@sku+', STORERkey='+@storerkey+'. ��������� ��������� ���������� ������������ ������.'+char(10)+char(13)
						set @send_error = 1
					end
					
					declare @transmitlogkey varchar(10)
					exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
		
		--�������� ������ � �������, ��� ���������� �������� ������.
					insert wh1.transmitlog (whseid, transmitlogkey, tablename, ADDWHO,KEY1,key2) 
					values ('WH1', @transmitlogkey, 'commodityupdated',  'commodityupdated',@sku,'001')
					
				end
				else
				begin
					print '��������� ����� sku='+@sku+', storer='+@storerkey
					insert into wh1.sku(
						sku,storerkey,descr,packkey,rfdefaultpack,skugroup,--skugroup2,
						FREIGHTCLASS,
						--stdcube,stdgrosswgt, 
						BUSR1,BUSR2,
						--BUSR3,BUSR4,busr5,
						putawayzone,strategykey,putawaystrategykey,ONRECEIPTCOPYPACKKEY,
						ABC,NOTES1,
						addwho,editwho
						)
					select 
						ds.sku,ds.storerkey,ds.descr,@packkey,@packkey as rfdefaultpack,ds.skugroup,
						--ds.skugroup2,
						ds.FREIGHTCLASS,
						--ds.stdcube,
						--ds.stdgrosswgt,				
						ds.busr1,
						ds.busr2,						
						--ds.busr3,
						--ds.busr4,
						--ds.busr5,
						isnull(dsg.putawayzone,'STD'),
						isnull(dsg.strategykey,'STD'), 
						isnull(dsg.putawaystrategykey,'STD'),
						'1',
						'A',
						ds.descr,
						'dkadapter','dkadapter'
					from	#da_sku ds
						join wh1.CODELKUP c
							on c.CODE = ds.FreightClass
							and c.LISTNAME = 'FREIGHTCLS' 
						join wh1.strategyxsku dsg 
							on c.SHORT = dsg.class
				
					if @@rowcount = 0 
					begin
						set @msg_errdetails = @msg_errdetails+'SKU. sku='+@sku+', STORERkey='+@storerkey+'. ��������� ��������� ������� ����� ������.'+char(10)+char(13)
						set @send_error = 1
					end
				end
			
				if @msg_errdetails = '' --������ ���, ��������� ��
				begin
					print ' ��������� ����������'
					print ' �������� ��������1'
					select @barcod = altsku from #da_sku

					print ' �������� �� ' + @barcod
					
					if @barcod <> ''
					begin						
						if not exists (select 1 from wh1.altsku where sku = @sku and storerkey = @storerkey and altsku = @barcod)
						begin
						    print ' ��������� ����� ���������'
						    insert into wh1.altsku 
						    (whseid, storerkey, sku, altsku, packkey, defaultuom, [type], addwho)
						    select 'wh1' as whseid, 
							    @storerkey as storerkey, 
							    @sku as sku, 
							    @barcod as altsku,						     
							    'std' as packkey,		
							    'EA' as defaultuom,
							    0 as [type], 
							    'dkadapter' as addwho 
        					    
						end						
						
					end
					
					
				end
		end
		else
		begin
			print ' �������� ������� ������ �� �������'
			set @msg_errdetails = @msg_errdetails + @msg_errdetails1 
			set	@send_error = 1

			
		end
		print ' �������� ������������ ������'
		delete from ds
		from da_sku ds join #da_sku s on (ds.storerkey = s.storerkey and ds.sku = s.sku) or (ds.id = s.id)
		--drop table #da_sku
		--delete from #tmp_altsku
	end
END TRY

BEGIN CATCH
	declare @error_message nvarchar(4000)
	declare @error_severity int
	declare @error_state int
	declare @error_line int	

	set @error_message  = ERROR_MESSAGE()
	set @error_severity = ERROR_SEVERITY()
	set @error_state    = ERROR_STATE()
	set @error_line	    = ERROR_LINE()

	set @send_error = 0
	--raiserror (@error_message, @error_severity, @error_state, @error_line)
END CATCH

if @sign = 1
begin
	if @send_error = 1
	begin
		print '������ �������� � �������� ������� DAX � ������'
		
		update	s
		set	status = '15',
			error = left (@msg_errdetails,200)
		from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpItemToWMS s
			join #da_sku d
			    on case when d.storerkey = '001' then 'SZ' else d.storerkey end = s.Dataareaid
			    and d.sku = s.ItemID
		where	s.status = '5'			
		
	--*************************************************************************

		update	s
		set	status = '15',
			error = @msg_errdetails
		from	[SQL-WMS].[PRD2].[dbo].DA_SKU_archive s
			join #da_sku d
			    on case when d.storerkey = '001' then 'SZ' else d.storerkey end = s.storerkey				
			    and d.sku = s.sku
		where	s.status = '5'	
		


		print '���������� ��������� �� ������ �� �����'
		print @msg_errdetails
		--raiserror (@msg_errdetails, 16, 1)
		
		--insert into DA_InboundErrorsLog (source,msg_errdetails) values (@source,@msg_errdetails)		
		exec app_DA_SendMail '������', @msg_errdetails
	end
	else
	begin

		print '������ ������ ��������� � �������� ������� DAX � ���������'
		
		update	s
		set	status = '10'
		from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpItemToWMS s
			join #da_sku d
			    on case when d.storerkey = '001' then 'SZ' else d.storerkey end = s.Dataareaid
			    and d.sku = s.ItemID
		where	s.status = '5'
		
	--*************************************************************************

		update	s
		set	status = '10'
		from	[SQL-WMS].[PRD2].[dbo].DA_SKU_archive s
			join #da_sku d
			    on case when d.storerkey = '001' then 'SZ' else d.storerkey end = s.storerkey				
			    and d.sku = s.sku				
		where	s.status = '5'


	end
end

IF OBJECT_ID('tempdb..#da_sku') IS NOT NULL DROP TABLE #da_sku










