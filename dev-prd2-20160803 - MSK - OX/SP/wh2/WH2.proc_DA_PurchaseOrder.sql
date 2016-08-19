
/*************************************************************************************/
ALTER PROCEDURE [WH2].[proc_DA_PurchaseOrder]
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

--declare @bs varchar(3) select @bs = short from WH2.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'
--declare @bsanalit varchar(3) select @bsanalit = short from WH2.CODELKUP where LISTNAME='sysvar' and CODE = 'bsanalit'


set @send_error = 0
set @msg_errdetails = ''
set @enter = char(10)+char(13)

BEGIN TRY
	--while (exists (select id from DA_PO))
		begin
		
			select @sign = 1
			
			print ' выбираем запись из обменной таблицы DA_PurchaseOrderHead'
			select top(1) *
			into #DA_PO 
			from dbo.DA_PO 
			where id = @id
			--order by id desc
			
			print ' обновление NULL значений в шапке документа'
			update #DA_PO 
			set
				storerkey = case	when (left(isnull(rtrim(ltrim(storerkey)),''),15)) = 'sz' then '001' 
									else (left(isnull(rtrim(ltrim(storerkey)),''),15)) 
							end,
				externpokey = left(isnull(rtrim(ltrim(externpokey)),''),20),
				potype = left(isnull(rtrim(ltrim(potype)),''),10),
				SELLERNAME = left(isnull(rtrim(ltrim(SELLERNAME)),''),15),
				BUYERADDRESS4 = left(isnull(rtrim(ltrim(BUYERADDRESS4)),''),20),
				SUSR2 = left(isnull(rtrim(ltrim(SUSR2)),''),30)			
				
			set @msg_errdetails1 =''
			print ' проверка входных данных шапки'
			select 
				@msg_errdetails1 = @msg_errdetails1 --storerkey EMPTY
					+case when ltrim(rtrim(r.storerkey)) = ''
						then 'er#001PO. STORERkey=*empty*.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --storerkey in STORER
					+case when (not exists(select s.* from WH2.storer s where s.storerkey = r.storerkey))
						then 'er#002PO. STORERkey=*'+r.storerkey+'* отсутвует в справочнике STORER.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --sellername EMPTY
					+case when r.sellername = ''
						then 'er#003PO. externpokey=*'+r.externpokey+'*. SellerName пустой.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --sellername in STORER
					+case when (not exists(select s.* from WH2.storer s where s.storerkey = r.sellername))
						then 'er#004PO. externpokey=*'+r.externpokey+'*.SellerName=*' + r.sellername + '* отсутвует в справочнике STORER.'+@enter
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
						then 'er#007PO. externpokey=*'+r.externpokey+'*. Документ уже существует в базе.'+@enter
						else ''
					end
			from	#DA_PO r
					left join WH2.PO p
						on p.EXTERNPOKEY = r.EXTERNPOKEY
						--and p.POTYPE = r.POTYPE
						
			if (@msg_errdetails1 = '')			
			begin
				print ' проверка на уникальность документов в обменной таблице'
				if ((select count (o.EXTERNPOKEY) from dbo.DA_PO o join #DA_PO do on o.EXTERNPOKEY = do.EXTERNPOKEY and o.potype = do.potype) > 1)
					set @msg_errdetails1 = 'er#008PO. EXTERNPOKEY=*'+(select EXTERNPOKEY from #DA_PO)+'*. Не уникальный документ в обменной таблице.'+@enter
			end

			if (@msg_errdetails1 = '')
			begin
			
				--print ' обновляем наименование и адрес поставщика'		
				--update r set r.selleraddress1 = left(isnull(s.company,''),44),
				--			r.selleraddress2 = isnull(s.ADDRESS1,''),
				--			r.selleraddress3 = isnull(s.ADDRESS2,''),
				--			r.selleraddress4 = isnull(s.ADDRESS3,'')	
				--	from #DA_PO r join WH2.storer s on  r.sellername = s.storerkey
					
				--print ' обновляем наименование и адрес получателя (СевроЗапад)'		
				--update r set r.buyername = left(isnull(s.company,''),44),
				--			r.buyeraddress1 = isnull(s.ADDRESS1,''),
				--			r.buyeraddress2 = isnull(s.ADDRESS2,''),
				--			r.buyeraddress3 = isnull(s.ADDRESS3,''),	
				--			r.buyeraddress4 = isnull(s.ADDRESS4,'')											
				--	from #DA_PO r join WH2.storer s on  r.STORERKEY = s.storerkey			

				
				--if (@msg_errdetails1 = '') 
				--	begin
				print ' контроль входных данных пройден успешно'
				
				
				print ' выбираем externpokey'
				select @storerkey = storerkey, @externpokey = externpokey, @type = potype from #DA_PO
				
				print ' выбираем детали документа'
				select	dr.* 
				into	#DA_PODetail 
				from	dbo.DA_PODetail dr 
						join #DA_PO r 
							on dr.externpokey = r.externpokey
				
				------------- Если тип документ 0, то серию+даты мы не прогружаем ----------- Шевелев 20.05.2015
				update	s
					set	s.Lottable02='',
						s.Lottable04=null,
						s.Lottable05=null
					from	     #DA_PODetail s
							join #DA_PO d 			on d.ExternPOkey = s.ExternPOkey
					where	d.POType = '0'
				------------- Если тип документ 0, то серию+даты мы не прогружаем ----------- Шевелев 20.05.2015
				
				print ' обновление NULL значений в деталях документа'
				update #DA_PODetail 
				set
					storerkey = case when (left(isnull(rtrim(ltrim(storerkey)),''),15)) = 'sz' then '001' else (left(isnull(rtrim(ltrim(storerkey)),''),15)) end,
					externpokey = left(isnull(rtrim(ltrim(externpokey)),''),20),								
					sku = left(isnull(rtrim(ltrim(sku)),''),50),
					externlinenumber = cast(cast(left(isnull(rtrim(ltrim(externlinenumber)),'0'),5) as numeric) as int),
					LOTTABLE01 = '',--left(isnull(rtrim(ltrim(LOTTABLE01)),''),40),
					QTYORDERED = isnull(nullif(
								    replace(replace(replace(QTYORDERED,',','.'),' ',''),CHAR(160),'')
								    ,''),0),
					LOTTABLE06 = left(isnull(rtrim(ltrim(LOTTABLE06)),''),40),
					LOTTABLE02 = left(isnull(rtrim(ltrim(LOTTABLE02)),''),40)--,
					--LOTTABLE05 = case when ISNULL(LOTTABLE05,GETUTCDATE()) <= cast('1900-01-01' as DATETIME) then null
					--		    else ISNULL(LOTTABLE05,GETUTCDATE()) end,
					--LOTTABLE04 = case when ISNULL(LOTTABLE04,GETUTCDATE()) <= cast('1900-01-01' as DATETIME) then null
					--		    else ISNULL(LOTTABLE04,GETUTCDATE()) end
					----packkey = case when (isnull(packkey,'') = '') then (select top(1) s.packkey from WH2.SKU s where s.SKU= sku and s.STORERKEY = STORERKEY) else ltrim(rtrim(packkey)) end,
					
					
					
				print ' выбор идентификаторов строк'
				select id into #id from #DA_PODetail
				print ' проверка строк документа'


				while (exists (select * from #id))
					begin
						select @id = id from #id
						print ' строкаID='+cast(@id as varchar(10))+'.'

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
									then 'er#011PO. EXTERNPOkey=*'+rd.externpokey+'*, EXTERNLINENO=*'+rd.externlinenumber+'*. STORER = *null*.'+@enter
									else ''
								end,
							@msg_errdetails1 = @msg_errdetails1 --storer in STORER
								+case when (not exists(select s.* from WH2.storer s where s.storerkey = rd.storerkey))
									then 'er#012PO. EXTERNPOkey=*'+rd.externpokey+'*, EXTERNLINENO=*'+rd.externlinenumber+'*. STORER отсутвует в справочнике STORER.'+@enter
									else ''
								end,
							@msg_errdetails1 = @msg_errdetails1 --sku null
								+case when rd.sku = ''
									then 'er#013PO. EXTERNPOkey=*'+rd.externpokey+'*, EXTERNLINENO=*'+rd.externlinenumber+'*. SKU = *null*.'+@enter
									else ''
								end,
							@msg_errdetails1 = @msg_errdetails1 --sku in SKU
								+case when (not exists(select s.* from WH2.sku s where s.storerkey = rd.storerkey and s.SKU = rd.sku))
									then 'er#014PO. EXTERNPOkey=*'+rd.externpokey+'*, EXTERNLINENO=*'+rd.externlinenumber+'*. SKU=*' + rd.sku + '* отсутвует в справочнике SKU.'+@enter
									else ''
								end,
							
							@msg_errdetails1 = @msg_errdetails1 --qtyexpected = 0
								+case when (rd.QTYORDERED <= cast(0 as numeric(22,5)))
										then 'er#015PO. EXTERNPOkey=*'+rd.externpokey+'*, EXTERNLINENO=*'+rd.externlinenumber+'*. Не корректное значение QTYORDERED.'+@enter
										else ''
								end
						from	#DA_PODetail rd 
								join #DA_PO r 
									on rd.externpokey = r.externpokey
						where rd.id = @id
--							
						if (@msg_errdetails1 != '')
						begin
							print ' ошибка в строке документа'							
							set @msg_errdetails = @msg_errdetails + @msg_errdetails1
							--print @msg_errdetails
							select @msg_errdetails1 = ''
							set @send_error = 1
						end
						delete from #id where id = @id
					end
					
				if not exists (select 1 from #DA_PODetail)
					begin
						print ' ошибка! не существуют строки документа'
						set @msg_errdetails1 = @msg_errdetails1 + 'er#016Ошибки в строке документа. '+@enter+ 'В заказе=*'+@externpokey + '* не существуют строки документа. '+@enter
						set @msg_errdetails = @msg_errdetails +@enter+@msg_errdetails1
						print @msg_errdetails
						set @send_error = 1
					end	

				if @msg_errdetails = '' 
					begin						
						print ' получаем новый номер документа'
						exec dbo.DA_GetNewKey 'WH2','po',@pokey output

						print ' вставляем шапку документа'
						insert into WH2.po
							(whseid,pokey,storerkey,externpokey, potype, --podate, EFFECTIVEDATE,  
							status, addwho, sellername, 
							--BUYERNAME, 
							SELLERADDRESS1, SELLERADDRESS2,SELLERADDRESS3, SELLERADDRESS4, 
							--BUYERADDRESS1, BUYERADDRESS2, BUYERADDRESS3, 
							BUYERADDRESS4, 
							--VESSEL, VESSELDATE, 
							SUSR2)
						
						
						select	'WH2' as whseid,@pokey,
								r.storerkey,r.externpokey,r.potype, --r.expecteddate, r.departuredate,
								'0','dkadapter', r.sellername, 
								isnull(ss.ADDRESS1,''),isnull(ss.ADDRESS2,''),isnull(ss.ADDRESS3,''),isnull(ss.ADDRESS4,''),
								--r.buyername, r.SELLERADDRESS1, r.SELLERADDRESS2, r.SELLERADDRESS3, 
								--r.SELLERADDRESS4, r.BUYERADDRESS1, r.BUYERADDRESS2, r.BUYERADDRESS3, 
								r.BUYERADDRESS4,
								 --r.VESSEL, r.DEPARTUREDATE, 
								 r.SUSR2
						from	#DA_PO r								
								left join WH2.storer ss 
									on ss.STORERKEY = r.sellername
									
						if @@rowcount = 0
					    begin
						    set @msg_errdetails = @msg_errdetails+'er#017PO.externpokey=*'+@externpokey+'*. Неудалось выполнить вставку записи (шапка документа).'+char(10)+char(13)
						    set @send_error = 1
					    end
					    else
					    begin
					    
					    				    				
				
							
							
							print ' вставляем строки документа'
							insert into WH2.poDetail
								(	whseid,pokey,polinenumber,externpokey,externlineno,storerkey,     
									sku,qtyordered,packkey,UOM,--status,unitprice,unit_cost,
									LOTTABLE01,LOTTABLE02,LOTTABLE04,LOTTABLE05,LOTTABLE06,
									skudescription,ADDWHO,ADDDATE,EDITDATE,EDITWHO								
								)
							select 'WH2' whseid, @pokey,
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
									join WH2.sku s 
										on s.sku = drd.sku 
										and s.storerkey = drd.storerkey
										
							if @@ERROR <> 0
							begin
								set @msg_errdetails = @msg_errdetails+'er#018PO.externpokey=*'+@externpokey+'*. Неудалось выполнить вставку записи (строки документа).'+char(10)+char(13)
								set @send_error = 1
							end
						end
					end
				else
					begin
						print ' в строках документов обнаружены ошибки'
					end

					--end		
			end			
			else
				begin
					print ' контроль входных данных не пройден'
					set @msg_errdetails = @msg_errdetails + @msg_errdetails1 
					set	@send_error = 1
					print @msg_errdetails

				end
			print ' удаление обработанных данных'
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
		print 'Ставим документ в обменной таблице DAX в ошибку'
		
		set @msg_errdetails=left(@msg_errdetails,200)
		
		update	s
		set		status = '15',
				error = @msg_errdetails
		from	[spb-sql1201].[DAX2009_1].[dbo].SZ_ExpInputOrderLinesToWMS s
				join #DA_PO d
					on d.ExternPOkey = s.DocId
		where	s.status = '5'
		
		
		update	s
		set		status = '15',
				error = @msg_errdetails
		from	[spb-sql1201].[DAX2009_1].[dbo].SZ_ExpInputOrdersToWMS s
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


		print 'отправляем сообщение об ошибке по почте'
		print @msg_errdetails
		--raiserror (@msg_errdetails, 16, 1)
		
		--insert into DA_InboundErrorsLog (source,msg_errdetails) values (@source,@msg_errdetails)		
		--exec app_DA_SendMail 'Приёмка', @msg_errdetails
	end
	else
	begin

		print 'Ставим статус документа в обменной таблице DAX в ОБРАБОТАН'
		
		update	s
		set		status = '10'
		from	[spb-sql1201].[DAX2009_1].[dbo].SZ_ExpInputOrderLinesToWMS s
				join #DA_PO d
					on d.ExternPOkey = s.DocId
		where	s.status = '5'
		
		
		update	s
		set		status = '10'
		from	[spb-sql1201].[DAX2009_1].[dbo].SZ_ExpInputOrdersToWMS s
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





