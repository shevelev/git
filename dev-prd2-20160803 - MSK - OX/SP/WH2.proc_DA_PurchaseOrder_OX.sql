-- �� ��� �������������--
ALTER PROCEDURE [WH2].[proc_DA_PurchaseOrder_OX]
	@id int
as  

--declare @source varchar(500)
declare @allowUpdate int
declare @send_error bit
declare @msg_errdetails varchar(max)
declare @msg_errdetails1 varchar(max)
declare @enter varchar(10) 
declare @storerkey varchar(15)
declare @sku varchar(15)
declare @externpokey varchar(20)
--declare @id int
declare @pokey varchar (15),
		@type varchar(10),
		@sign int = 0
	




set @send_error = 0
set @msg_errdetails = ''
set @enter = char(10)+char(13)

BEGIN TRY
	--while (exists (select id from DA_PO))
		begin
		
			select @sign = 1
			
			print ' �������� ������ �� �������� ������� DA_PurchaseOrderHead_OX'
			select top(1) *
			into #DA_PO 
			from dbo.DA_PO 
			where id = @id
			--order by id desc
			
			print ' ���������� NULL �������� � ����� ���������'
			update #DA_PO 
			set
				storerkey = left(isnull(rtrim(ltrim(SELLERNAME)),''),15),
				externpokey = left(isnull(rtrim(ltrim(externpokey)),''),20),
				potype = left(isnull(rtrim(ltrim(potype)),''),10),
				SELLERNAME = left(isnull(rtrim(ltrim(SELLERNAME)),''),15),
				BUYERADDRESS4 = left(isnull(rtrim(ltrim(BUYERADDRESS4)),''),20),
				SUSR2 = left(isnull(rtrim(ltrim(SUSR2)),''),30)			
		

	
		set @msg_errdetails1 =''
			print ' �������� ������� ������ �����'
			select 
				@msg_errdetails1 = @msg_errdetails1 --storerkey EMPTY
					+case when ltrim(rtrim(r.storerkey)) = ''
						then 'er#001PO. STORERkey=*empty*.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --storerkey in STORER
					+case when (not exists(select s.* from wh2.storer s where s.storerkey = r.storerkey))
						then 'er#002PO. STORERkey=*'+r.storerkey+'* ��������� � ����������� STORER.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --sellername EMPTY
					+case when r.sellername = ''
						then 'er#003PO. externpokey=*'+r.externpokey+'*. SellerName ������.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --sellername in STORER
					+case when (not exists(select s.* from wh2.storer s where s.storerkey = r.sellername))
						then 'er#004PO. externpokey=*'+r.externpokey+'*.SellerName=*'+r.sellername+'* ��������� � ����������� STORER.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --externpokey empty
					+case when r.externpokey = ''
						then 'er#005PO. externpokey=*empty*.'+@enter
						else ''
					end,					
				@msg_errdetails1 = @msg_errdetails1 --type empty
					+case when r.POTYPE = ''
						then 'er#006PO. POTYPE=*empty*.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --externpokey status != 0
					+case when p.EXTERNPOKEY IS not null 
						then 'er#007PO. externpokey=*'+r.externpokey+'*. �������� ��� ���������� � ����.'+@enter
						else ''
					end
			from	#DA_PO r
					left join wh2.PO p
						on p.EXTERNPOKEY = r.EXTERNPOKEY
						--and p.POTYPE = r.POTYPE
						
			if (@msg_errdetails1 = '')			
			begin
				print ' �������� �� ������������ ���������� � �������� �������'
				if ((select count (o.EXTERNPOKEY) from dbo.DA_PO o join #DA_PO do on o.EXTERNPOKEY = do.EXTERNPOKEY and o.potype = do.potype) > 1)
					set @msg_errdetails1 = 'er#008PO. EXTERNPOKEY=*'+(select EXTERNPOKEY from #DA_PO)+'*. �� ���������� �������� � �������� �������.'+@enter
			end

			if (@msg_errdetails1 = '')
			begin
			
				print ' �������� ������� ������ ������� �������'
				
				
				print ' �������� externpokey'
				select @storerkey = storerkey, @externpokey = externpokey, @type = potype from #DA_PO
				
				print ' �������� ������ ���������'
				select	dr.* 
				into	#DA_PODetail 
				from	dbo.DA_PODetail dr 
						join #DA_PO r 
							on dr.externpokey = r.externpokey
				
				--------------- �������� ��������� � ����� ��������� ----------- ������� 21.06.2016
				update	s
					set	s.storerkey=d.storerkey
					from	     #DA_PODetail s
							join #DA_PO d 			on d.ExternPOkey = s.ExternPOkey
					where	d.POType = '8' or d.POType = '9' or d.POType = '0'
				--------------- �������� ��������� � ����� ��������� ----------- ������� 21.06.2016
				
				
				--------------- ����������� ��������� ��� 1 ----------- ������� 21.06.2016
				update	s
					set	s.type=1
					from	     wh2.storer s
							join #DA_PO d 			on s.STORERKEY = d.storerkey
					where	d.POType = '8' or d.POType = '9'
				--------------- ����������� ��������� ��� 1 ----------- ������� 21.06.2016
				
				
				
				print ' ���������� NULL �������� � ������� ���������'
				update #DA_PODetail 
				set
					--storerkey = case when (left(isnull(rtrim(ltrim(storerkey)),''),15)) = 'sz' then '001' else (left(isnull(rtrim(ltrim(storerkey)),''),15)) end,
					storerkey = left(isnull(rtrim(ltrim(storerkey)),''),10),
					externpokey = left(isnull(rtrim(ltrim(externpokey)),''),20),								
					sku = left(isnull(rtrim(ltrim(sku)),''),50),
					externlinenumber = cast(cast(left(isnull(rtrim(ltrim(externlinenumber)),'0'),5) as numeric) as int),
					LOTTABLE01 = '',--left(isnull(rtrim(ltrim(LOTTABLE01)),''),40),
					QTYORDERED = isnull(nullif(
								    replace(replace(replace(QTYORDERED,',','.'),' ',''),CHAR(160),'')
								    ,''),0),
					LOTTABLE06 = left(isnull(rtrim(ltrim(LOTTABLE06)),''),40),
					LOTTABLE02 = left(isnull(rtrim(ltrim(LOTTABLE02)),''),40)
		
					
------------------------------------------------------------------------------------------------------------			
				print '���������� ������ � �� � ����'					
				
select * into #sku_xo from #DA_PODetail				

select * from #sku_xo

declare @id_xo varchar(10), 
		@storerkey_xo varchar(10), 
		@sku_xo varchar(10)

--select * from wh2.sku where SKU='10005'

while (exists (select id from #sku_xo))
	begin
		select top 1 @id_xo=id, @storerkey_xo=storerkey, @sku_xo=Sku from #sku_xo
		print '���� ������ � �������� ������� �� ������' + @id_xo + ' : ' + @storerkey_xo
		
		print '��������� ���� �� ����� ����� + �������� � ���� ������� �� wh2.sku '
		
			if (exists (select ws.* from wh2.sku ws where ws.storerkey = @storerkey_xo and ws.sku = @sku_xo))
					begin
						print ' sku='+@sku_xo+' � STORERkey='+@storerkey_xo+' ��� ����������'
						print ' ��������� wh2.sku='+@sku_xo+', storer='+@storerkey_xo
					end
			else 
					begin
						print ' sku='+@sku_xo+' � STORERkey='+@storerkey_xo+' ��� � ����'
						print ' ������� ����� �������� ������='+@sku_xo+' ��� ���������='+@storerkey_xo
							insert into wh2.sku ([WHSEID],[STORERKEY],[SKU],[HAZMATCODESKEY],[DESCR],[SUSR1],[SUSR2],[SUSR3],[SUSR4],[SUSR5]
											,[MANUFACTURERSKU],[RETAILSKU],[ALTSKU],[PACKKEY],[STDGROSSWGT],[STDNETWGT],[STDCUBE],[TARE],[CLASS]
											,[ACTIVE],[SKUGROUP],[TARIFFKEY],[BUSR1],[BUSR2],[BUSR3],[BUSR4],[BUSR5],[LOTTABLE01LABEL],[LOTTABLE02LABEL]
											,[LOTTABLE03LABEL],[LOTTABLE04LABEL],[LOTTABLE05LABEL],[LOTTABLE06LABEL],[LOTTABLE07LABEL],[LOTTABLE08LABEL],[LOTTABLE09LABEL]
											,[LOTTABLE10LABEL],[PICKCODE],[STRATEGYKEY],[CARTONGROUP],[PUTCODE],[PUTAWAYLOC],[PUTAWAYZONE]
											,[INNERPACK],[CUBE],[GROSSWGT],[NETWGT],[ABC],[CYCLECOUNTFREQUENCY],[LASTCYCLECOUNT],[REORDERPOINT],[REORDERQTY]
											,[STDORDERCOST],[CARRYCOST],[PRICE],[COST],[ONRECEIPTCOPYPACKKEY],[RECEIPTHOLDCODE],[RECEIPTINSPECTIONLOC],[ROTATEBY]
											,[DATECODEDAYS],[DEFAULTROTATION],[SHIPPABLECONTAINER],[IOFLAG],[TAREWEIGHT],[LOTXIDDETAILOTHERLABEL1],[LOTXIDDETAILOTHERLABEL2]
											,[LOTXIDDETAILOTHERLABEL3],[AVGCASEWEIGHT],[TOLERANCEPCT],[SHELFLIFEINDICATOR],[SHELFLIFE],[TRANSPORTATIONMODE],[SKUGROUP2]
											,[SUSR6],[SUSR7],[SUSR8],[SUSR9],[SUSR10],[BUSR6],[BUSR7],[BUSR8],[BUSR9],[BUSR10],[MINIMUMSHELFLIFEONRFPICKING]
											,[FREIGHTCLASS],[ICWFLAG],[ICWBY],[IDEWEIGHT],[ICDFLAG],[ICDLABEL1],[ICDLABEL2],[ICDLABEL3]
											,[OCWFLAG],[OCWBY],[ODEWEIGHT],[OACOVERRIDE],[OCDFLAG],[OCDLABEL1],[OCDLABEL2],[OCDLABEL3]
											,[OTAREWEIGHT],[OAVGCASEWEIGHT],[OTOLERANCEPCT],[RFDEFAULTPACK],[RFDEFAULTUOM],[SHELFLIFECODETYPE],[SHELFLIFEONRECEIVING]
											,[LOTTABLEVALIDATIONKEY],[ALLOWCONSOLIDATION],[MINIMUMWAVEQTY],[BULKCARTONGROUP],[PICKUOM],[EACHKEY],[CASEKEY],[TYPE]
											,[EFFECSTARTDATE],[EFFECENDDATE],[CONVEYABLE],[FLOWTHRUITEM],[NOTES1],[NOTES2],[VERT_STORAGE],[CWFLAG]
											,[VERIFYLOT04LOT05],[PUTAWAYSTRATEGYKEY],[RETURNSLOC],[QCLOC],[RECEIPTVALIDATIONTEMPLATE],[SKUTYPE],[ADDDATE],[ADDWHO]
											,[EDITDATE],[EDITWHO],[INSTANTCOUNT],[CYCLEONINSTANT],[MAXPICKCNT],[CARTONIZATIONTEMPLATEKEY],[REPLPRIORITY]
											,[LPNREMAINQTY],[LPNREMAINQTYWO],[MAXEACOUNT])
							select 
											[WHSEID],@storerkey_xo,[SKU],[HAZMATCODESKEY],[DESCR],[SUSR1],[SUSR2],[SUSR3],[SUSR4],[SUSR5],[MANUFACTURERSKU],[RETAILSKU],[ALTSKU]
											,[PACKKEY],[STDGROSSWGT],[STDNETWGT],[STDCUBE],[TARE],[CLASS],[ACTIVE],[SKUGROUP],[TARIFFKEY],[BUSR1],[BUSR2],[BUSR3],[BUSR4],[BUSR5]
											,[LOTTABLE01LABEL],[LOTTABLE02LABEL],[LOTTABLE03LABEL],[LOTTABLE04LABEL],[LOTTABLE05LABEL],[LOTTABLE06LABEL],[LOTTABLE07LABEL],[LOTTABLE08LABEL]
											,[LOTTABLE09LABEL],[LOTTABLE10LABEL],[PICKCODE],[STRATEGYKEY],[CARTONGROUP],[PUTCODE],[PUTAWAYLOC],[PUTAWAYZONE],[INNERPACK],[CUBE],[GROSSWGT]
											,[NETWGT],[ABC],[CYCLECOUNTFREQUENCY],[LASTCYCLECOUNT],[REORDERPOINT],[REORDERQTY],[STDORDERCOST],[CARRYCOST],[PRICE],[COST],[ONRECEIPTCOPYPACKKEY]
											,[RECEIPTHOLDCODE],[RECEIPTINSPECTIONLOC],[ROTATEBY],[DATECODEDAYS],[DEFAULTROTATION],[SHIPPABLECONTAINER],[IOFLAG],[TAREWEIGHT],[LOTXIDDETAILOTHERLABEL1]
											,[LOTXIDDETAILOTHERLABEL2],[LOTXIDDETAILOTHERLABEL3],[AVGCASEWEIGHT],[TOLERANCEPCT],[SHELFLIFEINDICATOR],[SHELFLIFE],[TRANSPORTATIONMODE],[SKUGROUP2]
											,[SUSR6],[SUSR7],[SUSR8],[SUSR9],[SUSR10],[BUSR6],[BUSR7],[BUSR8],[BUSR9],[BUSR10],[MINIMUMSHELFLIFEONRFPICKING],[FREIGHTCLASS],[ICWFLAG],[ICWBY]
											,[IDEWEIGHT],[ICDFLAG],[ICDLABEL1],[ICDLABEL2],[ICDLABEL3],[OCWFLAG],[OCWBY],[ODEWEIGHT],[OACOVERRIDE],[OCDFLAG],[OCDLABEL1],[OCDLABEL2],[OCDLABEL3]
											,[OTAREWEIGHT],[OAVGCASEWEIGHT],[OTOLERANCEPCT],[RFDEFAULTPACK],[RFDEFAULTUOM],[SHELFLIFECODETYPE],[SHELFLIFEONRECEIVING],[LOTTABLEVALIDATIONKEY],[ALLOWCONSOLIDATION]
											,[MINIMUMWAVEQTY],[BULKCARTONGROUP],[PICKUOM],[EACHKEY],[CASEKEY],[TYPE],[EFFECSTARTDATE],[EFFECENDDATE],[CONVEYABLE],[FLOWTHRUITEM],[NOTES1],[NOTES2],[VERT_STORAGE]
											,[CWFLAG],[VERIFYLOT04LOT05],[PUTAWAYSTRATEGYKEY],[RETURNSLOC],[QCLOC],[RECEIPTVALIDATIONTEMPLATE],[SKUTYPE],GETDATE(),'sku_copy',GETDATE(),'sku_copy',[INSTANTCOUNT]
											,[CYCLEONINSTANT],[MAXPICKCNT],[CARTONIZATIONTEMPLATEKEY],[REPLPRIORITY],[LPNREMAINQTY],[LPNREMAINQTYWO],[MAXEACOUNT]
						
							from wh2.sku where SKU=@sku_xo and STORERKEY='001'
						 
						 
						 print '��������� �� ��� ����� ������'
							insert into wh2.altsku    (whseid, storerkey, sku, altsku, packkey, defaultuom, [type], addwho)
							select whseid,  @storerkey_xo as storerkey, sku, altsku, packkey, defaultuom, [type], 'sku_xo' as addwho 
							from wh2.ALTSKU where SKU=@sku_xo and STORERKEY='001'
							  
					end
		
		delete #sku_xo where id=@id_xo
		print '������� ������' + @id_xo
	end	

			drop table #sku_xo					
					
					
------------------------------------------------------------------------------------------------------------					
				print ' ����� ��������������� �����'
				select id into #id from #DA_PODetail
				print ' �������� ����� ���������'


				while (exists (select * from #id))
					begin
						select @id = id from #id
						print ' ������ID='+cast(@id as varchar(10))+'.'

						select 
							@msg_errdetails1 = @msg_errdetails1 --extrnpokey
								+case when rd.externpokey = ''
									then 'er#009PO. EXTERNPOkey=*empty*.'+@enter
									else ''
								end,
							@msg_errdetails1 = @msg_errdetails1 --externlinenumber
								+case when rd.externlinenumber = 0
									then 'er#010PO. EXTERNPOkey=*'+rd.externpokey+'*. EXTERNLINENO=*empty*.'+@enter
									else ''
								end,
							@msg_errdetails1 = @msg_errdetails1 --storer null
								+case when rd.storerkey = ''
									then 'er#011PO. EXTERNPOkey=*'+rd.externpokey+'*, EXTERNLINENO=*'+rd.externlinenumber+'*. STORER=*null*.'+@enter
									else ''
								end,
							@msg_errdetails1 = @msg_errdetails1 --storer in STORER
								+case when (not exists(select s.* from wh2.storer s where s.storerkey = rd.storerkey))
									then 'er#012PO. EXTERNPOkey=*'+rd.externpokey+'*, EXTERNLINENO=*'+rd.externlinenumber+'*. STORER ��������� � ����������� STORER.'+@enter
									else ''
								end,
							@msg_errdetails1 = @msg_errdetails1 --sku null
								+case when rd.sku = ''
									then 'er#013PO. EXTERNPOkey=*'+rd.externpokey+'*, EXTERNLINENO=*'+rd.externlinenumber+'*. SKU=*null*.'+@enter
									else ''
								end,
							@msg_errdetails1 = @msg_errdetails1 --sku in SKU
								+case when (not exists(select s.* from wh2.sku s where s.storerkey = rd.storerkey and s.SKU = rd.sku))
									then 'er#014PO. EXTERNPOkey=*'+rd.externpokey+'*, EXTERNLINENO=*'+rd.externlinenumber+'*. SKU=*'+rd.sku+' === ' + rd.storerkey +' ===* ��������� � ����������� SKU.'+@enter
									else ''
								end,
							
							@msg_errdetails1 = @msg_errdetails1 --qtyexpected = 0
								+case when (rd.QTYORDERED <= cast(0 as numeric(22,5)))
										then 'er#015PO. EXTERNPOkey=*'+rd.externpokey+'*, EXTERNLINENO=*'+rd.externlinenumber+'*. �� ���������� �������� QTYORDERED.'+@enter
										else ''
								end
						from	#DA_PODetail rd 
								join #DA_PO r 
									on rd.externpokey = r.externpokey
						where rd.id = @id
--							
						if (@msg_errdetails1 != '')
						begin
							print ' ������ � ������ ���������'							
							set @msg_errdetails = @msg_errdetails + @msg_errdetails1
							--print @msg_errdetails
							select @msg_errdetails1 = ''
							set @send_error = 1
						end
						delete from #id where id = @id
					end
					
				if not exists (select 1 from #DA_PODetail)
					begin
						print ' ������! �� ���������� ������ ���������'
						set @msg_errdetails1 = @msg_errdetails1 + '������ � ������ ���������. '+@enter+ '� ������='+@externpokey + ' �� ���������� ������ ���������. '+@enter
						set @msg_errdetails = @msg_errdetails +@enter+@msg_errdetails1
						print @msg_errdetails
						set @send_error = 1
					end	

				if @msg_errdetails = '' 
					begin						
						print ' �������� ����� ����� ���������'
						exec dbo.DA_GetNewKey 'wh2','po',@pokey output

						print ' ��������� ����� ���������'
						insert into wh2.po
							(whseid,pokey,storerkey,externpokey, potype, --podate, EFFECTIVEDATE,  
							status, addwho, sellername, 
							SELLERADDRESS1, SELLERADDRESS2,SELLERADDRESS3, SELLERADDRESS4, 
							BUYERADDRESS4, SUSR2)
						
						
						select	'wh2' as whseid,@pokey,
								r.storerkey,r.externpokey,r.potype, 
								'0','dkadapter', r.sellername, 
								isnull(ss.ADDRESS1,''),isnull(ss.ADDRESS2,''),isnull(ss.ADDRESS3,''),isnull(ss.ADDRESS4,''),
								r.BUYERADDRESS4, r.SUSR2
						from	#DA_PO r								
								left join wh2.storer ss 
									on ss.STORERKEY = r.sellername
									
						if @@rowcount = 0
					    begin
						    set @msg_errdetails = @msg_errdetails+'er#017PO.externpokey=*'+@externpokey+'*. ��������� ��������� ������� ������ (����� ���������).'+char(10)+char(13)
						    set @send_error = 1
					    end
					    else
					    begin
					    
					    				    				
				
							
							
							print ' ��������� ������ ���������'
							insert into wh2.poDetail
								(	whseid,pokey,polinenumber,externpokey,externlineno,storerkey,     
									sku,qtyordered,packkey,UOM,--status,unitprice,unit_cost,
									LOTTABLE01,LOTTABLE02,LOTTABLE04,LOTTABLE05,LOTTABLE06,
									skudescription,ADDWHO,ADDDATE,EDITDATE,EDITWHO								
								)
							select 'wh2' whseid, @pokey,
									REPLICATE('0',5 - LEN(drd.externlinenumber)) + CAST(drd.externlinenumber as varchar(10)) as polinenumber,
									drd.externpokey,
									REPLICATE('0',5 - LEN(drd.externlinenumber)) + CAST(drd.externlinenumber as varchar(10)) as externlinenumber,
									drd.storerkey, 
									drd.sku, drd.QTYORDERED,s.packkey, s.rfdefaultuom,--s.rfdefaultpack,
									--'0', drd.unitprice, drd.unit_cost,
									drd.LOTTABLE01,drd.LOTTABLE02,drd.LOTTABLE04,drd.LOTTABLE05,drd.LOTTABLE06,
									left(s.descr,60) as skudescription,'dkadapter' as addwho,GETUTCDATE(),GETUTCDATE(),'dkadapter'
							from	#DA_PODetail drd 
									join #DA_PO drh 
										on drd.externpokey = drh.externpokey
									join wh2.sku s 
										on s.sku = drd.sku 
										and s.storerkey = drd.storerkey
										
							if @@ERROR <> 0
							begin
								set @msg_errdetails = @msg_errdetails+'PO.externpokey='+@externpokey+'. ��������� ��������� ������� ������ (������ ���������).'+char(10)+char(13)
								set @send_error = 1
							end
						end
					end
				else
					begin
						print ' � ������� ���������� ���������� ������'
						print @msg_errdetails
					end

					--end		
			end			
			else
				begin
					print ' �������� ������� ������ �� �������'
					set @msg_errdetails = @msg_errdetails + @msg_errdetails1 
					set	@send_error = 1
					print @msg_errdetails

				end
			print ' �������� ������������ ������'
			delete from dr
				from DA_PO dr join #DA_PO r on (dr.externpokey = r.externpokey) or (dr.id = r.id)
			delete dr
				from DA_POdetail dr join #DA_PO r on dr.externpokey = r.externpokey
				
			
			
		end
--			
END TRY

BEGIN CATCH
	declare @error_message nvarchar(4000)
	declare @error_severity int
	declare @error_state int
	
	set @error_message  = ERROR_MESSAGE()
	set @error_severity = ERROR_SEVERITY()
	set @error_state    = ERROR_STATE()

	set @send_error = 0
	--raiserror (@error_message, @error_severity, @error_state)
END CATCH


if @sign = 1
begin

	if @send_error = 1
	begin
		print '������ �������� � �������� ������� DAX � ������'
		
		set @msg_errdetails=left(@msg_errdetails,200)
		
		update	s
		set		status = '15',
				error = @msg_errdetails
		from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInputOrderLinesToWMS s
				join #DA_PO d
					on d.ExternPOkey = s.DocId
		where	s.status = '5'
		
		
		update	s
		set		status = '15',
				error = @msg_errdetails
		from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInputOrdersToWMS s
				join #DA_PO d
					on d.ExternPOkey = s.DocId
					and d.potype = s.doctype
		where	s.status = '5'
		
	--*************************************************************************

		update	s
		set		status = '15',
				error = @msg_errdetails
		from	[SQL-dev].[PRD2].[dbo].DA_PO_archive s
				join #DA_PO d
					on d.ExternPOkey = s.ExternPOkey
					and d.potype = s.potype
		where	s.status = '5'		
		
		update	s
		set		status = '15',
				error = @msg_errdetails
		from	[SQL-dev].[PRD2].[dbo].DA_PODetail_archive s
				join #DA_PO d
					on d.ExternPOkey = s.ExternPOkey				
		where	s.status = '5'	


		print '���������� ��������� �� ������ �� �����'
		print @msg_errdetails
		--raiserror (@msg_errdetails, 16, 1)
		
		--insert into DA_InboundErrorsLog (source,msg_errdetails) values (@source,@msg_errdetails)		
		--exec app_DA_SendMail @source, @msg_errdetails
	end
	else
	begin

		print '������ ������ ��������� � �������� ������� DAX � ���������'
		
		update	s
		set		status = '10'
		from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInputOrderLinesToWMS s
				join #DA_PO d
					on d.ExternPOkey = s.DocId
		where	s.status = '5'
		
		
		update	s
		set		status = '10'
		from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInputOrdersToWMS s
				join #DA_PO d
					on d.ExternPOkey = s.DocId
					and d.potype = s.doctype
		where	s.status = '5'
		
	--*************************************************************************

		update	s
		set		status = '10',
				error = @msg_errdetails
		from	[SQL-dev].[PRD2].[dbo].DA_PO_archive s
				join #DA_PO d
					on d.ExternPOkey = s.ExternPOkey
					and d.potype = s.potype
		where	s.status = '5'
		
		
		update	s
		set		status = '10',
				error = @msg_errdetails
		from	[SQL-dev].[PRD2].[dbo].DA_PODetail_archive s
				join #DA_PO d
					on d.ExternPOkey = s.ExternPOkey				
		where	s.status = '5'	


	end



end



IF OBJECT_ID('tempdb..#DA_PO') IS NOT NULL DROP TABLE #DA_PO
IF OBJECT_ID('tempdb..#DA_PODetail') IS NOT NULL DROP TABLE #DA_PODetail

