ALTER PROCEDURE [dbo].[proc_DA_Sklad]
	@source varchar(500) = null
as  

--return

--declare @source varchar(500)
declare @allowUpdate int
declare @send_error bit
declare @msg_errdetails varchar(max)
declare @msg_errdetails1 varchar(max)
declare @enter varchar(10) 
declare @storerkey varchar(15)
declare @sku varchar(15)
declare @externpokey varchar(20)
declare @id int
declare @pokey varchar (15),
	@type varchar(10),
	@sign int = 0,
	@inventjournalid varchar(30),
	@lot varchar(40),
	@inventjournalnameid varchar(30),
	@inventlocationid varchar(20),
	@CorrInventLocationID varchar(20),
	@taskdetailkey varchar(20),
	@ManufactureDateFrom datetime,
	@ManufactureDateTo datetime,
	@InventExpireDate datetime,
	@CorrInventExpireDate datetime,
	@InventBatchID nvarchar(40) = null,
	@CorrInventBatchID nvarchar(40) = null,
	@InventSerialID nvarchar(40) = null,
	@CorrInventSerialID nvarchar(40) = null,
	@qty numeric(22,5),
	@signtransfert int = 0
declare @e int	

set @send_error = 0
set @msg_errdetails = ''
set @enter = char(10)+char(13)

BEGIN TRY
	while (exists (select id from DA_Sklad))
	begin
	
		select @sign = 1
		
		print ' выбираем запись из обменной таблицы DA_Sklad'
		select top(1) *
		into #DA_Sklad 
		from dbo.DA_Sklad 
		order by id desc
		
		print ' обновление NULL значений в шапке документа'
		update #DA_Sklad 
		set
		    storerkey = case	when (left(isnull(rtrim(ltrim(storerkey)),''),15)) = 'SZ' then '001' 
							    else (left(isnull(rtrim(ltrim(storerkey)),''),15)) 
					    end,
		    InventJournalNameID = left(isnull(rtrim(ltrim(InventJournalNameID)),''),20),
		    InventJournalID = left(isnull(rtrim(ltrim(InventJournalID)),''),10),
		    InventJournalType = left(isnull(rtrim(ltrim(InventJournalType)),''),2)
			
			
		set @msg_errdetails1 =''
		print ' проверка входных данных шапки'
		select 
			@msg_errdetails1 = @msg_errdetails1 --storerkey EMPTY
				+case when ltrim(rtrim(r.storerkey)) = ''
					then 'Sklad. STORERkey=empty.'+@enter
					else ''
				end,
			@msg_errdetails1 = @msg_errdetails1 --storerkey in STORER
				+case when (not exists(select s.* from wh1.storer s where s.storerkey = r.storerkey))
					then 'Sklad. STORERkey='+r.storerkey+' отсутствует в справочнике STORER.'+@enter
					else ''
				end,
			@msg_errdetails1 = @msg_errdetails1 --sellername EMPTY
				+case when r.InventJournalNameID = ''
					then 'Sklad. InventJournalNameID=empty.'+@enter
					else ''
				end,			
			@msg_errdetails1 = @msg_errdetails1 --InventJournalID empty
				+case when r.InventJournalID = ''
					then 'Sklad. InventJournalID=empty.'+@enter
					else ''
				end,					
			@msg_errdetails1 = @msg_errdetails1 --InventJournalType empty
				+case when r.InventJournalType = ''
					then 'Sklad. InventJournalType=empty.'+@enter
					else ''
				end,
			@msg_errdetails1 = @msg_errdetails1 --InventJournalType <> 2
				+case when r.InventJournalType <> '2'
					then 'Sklad. InventJournalID='+r.InventJournalID+'. Данный вид журнала не обрабатывается.'+@enter
					else ''
				end
		from	#DA_Sklad r				
		

		if (@msg_errdetails1 = '')
		begin
			
			--if (@msg_errdetails1 = '') 
			--	begin
			print ' контроль входных данных пройден успешно'
			
			print ' выбираем externpokey'
			select	@storerkey = storerkey, @inventjournalid = inventjournalid, 
				@inventjournalnameid = inventjournalnameid 
			from	#DA_Sklad
			
			print ' выбираем детали документа'
			select	dr.*,
				identity(int,1,1) as serkey,
				'' as dotransfert
			into	#DA_SkladDetail
			from	dbo.DA_SkladDetail dr
				join #DA_Sklad r 
					on dr.inventjournalid = r.inventjournalid
			
			print ' обновление NULL значений в деталях документа'
			update #DA_SkladDetail 
			set
				InventJournalID = left(isnull(rtrim(ltrim(InventJournalID)),''),30),								
				sku = left(isnull(rtrim(ltrim(sku)),''),50),								
				OrderedQty = isnull(nullif(
							    replace(replace(replace(OrderedQty,',','.'),' ',''),CHAR(160),'')
							    ,''),0),
				InventLocationID = left(isnull(rtrim(ltrim(InventLocationID)),''),20),
				CorrInventLocationID = left(isnull(rtrim(ltrim(CorrInventLocationID)),''),20),
				InventBatchID = left(isnull(rtrim(ltrim(InventBatchID)),''),40),
				CorrInventBatchID = left(isnull(rtrim(ltrim(CorrInventBatchID)),''),40),
				InventSerialID = left(isnull(rtrim(ltrim(InventSerialID)),''),40),
				CorrInventSerialID = left(isnull(rtrim(ltrim(CorrInventSerialID)),''),40)
				
			
				
			print ' выбор идентификаторов строк'
			select id into #id from #DA_SkladDetail
			print ' проверка строк документа'
			

			while (exists (select * from #id))
				begin
					select @id = id from #id
					print ' строкаID='+cast(@id as varchar(10))+'.'

					select 
						@msg_errdetails1 = @msg_errdetails1 --InventJournalID
							+case when rd.InventJournalID = ''
								then 'SkladDetail. InventJournalID=empty.'+@enter
								else ''
							end,
						@msg_errdetails1 = @msg_errdetails1 --Sku
							+case when rd.Sku = ''
								then 'SkladDetail.InventJournalID='+rd.InventJournalID+'. SKU=empty.'+@enter
								else ''
							end,
						@msg_errdetails1 = @msg_errdetails1 --InventLocationID null
							+case when rd.InventLocationID = ''
								then 'SkladDetail.InventJournalID='+rd.InventJournalID+'. InventLocationID = null.'+@enter
								else ''
							end,
						@msg_errdetails1 = @msg_errdetails1 --CorrInventLocationID null
							+case when rd.CorrInventLocationID = ''
								then 'SkladDetail.InventJournalID='+rd.InventJournalID+'. CorrInventLocationID = null.'+@enter
								else ''
							end,	
							
						@msg_errdetails1 = @msg_errdetails1 --InventBatchID null
							+case when rd.InventBatchID = ''
								then 'SkladDetail.InventJournalID='+rd.InventJournalID+'. InventBatchID = null.'+@enter
								else ''
							end,
						@msg_errdetails1 = @msg_errdetails1 --CorrInventBatchID null
							+case when rd.CorrInventBatchID = ''
								then 'SkladDetail.InventJournalID='+rd.InventJournalID+'. CorrInventBatchID = null.'+@enter
								else ''
							end,
						@msg_errdetails1 = @msg_errdetails1 --InventSerialID null
							+case when rd.InventSerialID = ''
								then 'SkladDetail.InventJournalID='+rd.InventJournalID+'. InventSerialID = null.'+@enter
								else ''
							end,
						@msg_errdetails1 = @msg_errdetails1 --CorrInventSerialID null
							+case when rd.CorrInventSerialID = ''
								then 'SkladDetail.InventJournalID='+rd.InventJournalID+'. CorrInventSerialID = null.'+@enter
								else ''
							end,						
						@msg_errdetails1 = @msg_errdetails1 --OrderedQty = 0
							+case when (rd.OrderedQty <= cast(0 as numeric(22,5)))
									then 'SkladDetail.InventJournalID='+rd.InventJournalID+'. Не корректное значение OrderedQty.'+@enter
									else ''
							end
					from	#DA_SkladDetail rd							
					where	rd.id = @id
						and InventJournalID = @inventjournalid
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
				
			if not exists (select 1 from #DA_SkladDetail)
			begin
				print ' ошибка! не существуют строки документа'
				set @msg_errdetails1 = @msg_errdetails1 + 'Ошибки в строке документа. '+@enter+ 'В заказе='+@externpokey + ' не существуют строки документа. '+@enter
				set @msg_errdetails = @msg_errdetails +@enter+@msg_errdetails1
				print @msg_errdetails
				set @send_error = 1
			end	

			if @msg_errdetails = '' 
			begin
				declare @i int = 1,
					@y int = 1,
					@text nvarchar(4000) = '',
					@lot02 varchar(30),
					@lot04 varchar(30),
					@lot05 varchar(30),
					@lot06 varchar(30),					
					@pid varchar(20),
					@loc varchar(20),
					@lotqty varchar(30)	
				--select* from #DA_SkladDetail
				--while exists (select 1 from #DA_SkladDetail)
				while @i <= (select count(*) from #DA_SkladDetail)
				BEGIN
					print '000'
					
					select top 1 @i = id from #DA_SkladDetail
					
					print '001'
					
					select	@inventlocationid = InventLocationID,
						@CorrInventLocationID = CorrInventLocationID,
						@ManufactureDateFrom = ManufactureDateFrom,
						@ManufactureDateTo = ManufactureDateTo,
						@InventExpireDate = InventExpireDate,
						@CorrInventExpireDate = CorrInventExpireDate,
						@InventBatchID = InventBatchID,
						@CorrInventBatchID = CorrInventBatchID,
						@InventSerialID = InventSerialID,
						@CorrInventSerialID = CorrInventSerialID,
						@sku = sku,
						@qty = OrderedQty
					from	#DA_SkladDetail
					where	id = @i				
					
					print '002'
					
					IF OBJECT_ID('tempdb..#t1') IS NOT NULL DROP TABLE #t1
					IF OBJECT_ID('tempdb..#trlot04') IS NOT NULL DROP TABLE #trlot04
					IF OBJECT_ID('tempdb..#trlot04_1') IS NOT NULL DROP TABLE #trlot04_1
					
					create table #t1
					(mess varchar(max))
					
					
					if (@inventlocationid = @CorrInventLocationID)
					    and (@ManufactureDateFrom <> @ManufactureDateTo or 
						@InventExpireDate <> @CorrInventExpireDate or 
						@InventBatchID <> @CorrInventBatchID or 
						@InventSerialID <> @CorrInventSerialID)					    
					begin
						print 'Трансферт'												
								
						select	distinct l.LOT,l.QTYALLOCATED,l.QTYPREALLOCATED,l.QTYPICKED,l.QTY
						into	#trlot04
						from	wh1.LOT l
							join wh1.LOTATTRIBUTE l2
								on l2.LOT = l.LOT
							join wh1.LOTxLOCxID ll
								on ll.LOT = l.LOT								
						where	ll.sku = @sku
							and ll.STORERKEY = @storerkey
							--and l2.LOTTABLE06 = @InventBatchID
							and l2.LOTTABLE02 = @InventSerialID
							and l2.LOTTABLE04 = @ManufactureDateFrom
							and l2.LOTTABLE05 = @InventExpireDate
							
						print '1'			
						--select * from #trlot04
													--cast(0 as numeric(22,5))
						if exists (select 1 from #trlot04 where (QTYALLOCATED > cast(0 as decimal) or QTYPREALLOCATED > cast(0 as decimal)))							
						begin
							print '2'
							set @msg_errdetails = @msg_errdetails+' Inventjournalid='+@inventjournalid+' SKU='+@sku+' InventBatchID='+@InventBatchID+' InventSerialID='+@InventSerialID+' ManufactureDateFrom='+cast(@ManufactureDateFrom as varchar)+' InventExpireDate='+cast(@InventExpireDate as varchar)+'.Невозможно совершить трансферт, есть зарезервированный товар.'+char(10)+char(13)
							set @send_error = 1
						end
						else
						    BEGIN
							    --print '4'
							    --if not EXISTS (select lot from #trlot04 group by lot having @qty <> sum(Qty - ( QtyPreAllocated + QtyAllocated + QtyPicked )) )
							    --BEGIN
								    print '3'							    
								    
								    select  @lot04 = case   when @ManufactureDateFrom = @ManufactureDateTo then convert(varchar(15),@ManufactureDateTo,103)
											    when @ManufactureDateTo is not null and @ManufactureDateFrom is not null 
											    and @ManufactureDateFrom <> @ManufactureDateTo then convert(varchar(15),@ManufactureDateTo,103)
											    else ''
										    end,
									    @lot05 = case   when @InventExpireDate = @CorrInventExpireDate then convert(varchar(15),@CorrInventExpireDate,103)
											    when @InventExpireDate is not null and @CorrInventExpireDate is not null 
											    and @InventExpireDate <> @CorrInventExpireDate then convert(varchar(15),@CorrInventExpireDate,103)
											    else ''
										    end,
									    @lot02 = case   when IsNull(@InventSerialID,'') <> IsNull(@CorrInventSerialID,'') then @CorrInventSerialID
											    else @CorrInventSerialID
										    end,
									    @lot06 = case    when IsNull(@InventBatchID,'') <> IsNull(@CorrInventBatchID,'') then @CorrInventBatchID
											    else @CorrInventBatchID
										    end
								                     
								    print '44'                 
								    
								    select  identity(int,1,1) as ser,
									    ll.lot,
									    ll.LOC, ll.ID, ll.STORERKEY, ll.SKU,ll.QTY,								    
									    @lot04 as lot04
								    into    #trlot04_1
								    from    wh1.LOTxLOCxID ll
									    join #trlot04 t
										on ll.LOT = t.lot
								    where   ll.QTY > cast(0 as numeric(22,5))
								
								    print '55'
								    	
								    while exists (select 1 from #trlot04_1) 
								    BEGIN
								    	  print '66'
								    	  
								    	  select top 1 @y = ser from #trlot04_1							    	  
								    	  
								    	  print 'Создаем трансферт'							    
								    
									  select @signtransfert = 1
									  
									  update #DA_SkladDetail
									  set	dotransfert = '1'
									  where	id = @i
								    	  
								    	  print '77'
								    	   
								    	  select @lot = lot,
								    		 @loc = loc,
								    		 @pid = replace(id,' ',''),
								    		 @lotqty = qty  
								    	  from	 #trlot04_1
								    	  where	 ser = @y
								    	   print '88'
								    	 -- select @text = 'java -classpath c:\DA_Axap\DKInforDA.jar -DconfigPath=c:\DA_Axap\DKInforDA.properties dke.da.trident.ExceedServerCall Transfer PRD2_WH1 Transfer '+@storerkey+','+@sku +','+@loc+',,'+@pid+',,,'+@lotqty+','+@storerkey+','+@sku +','+@loc+','+@pid+',,,'+@lotqty+','+@lot+',,'+@lot02+',,'+@lot04+','+@lot05+','+@lot06+',,,,'
								    	  select @text = 'java -classpath c:\DA_Axap\DKInforDA.jar -DconfigPath=c:\DA_Axap\DKInforDA.properties dke.da.trident.ExceedServerCall Transfer PRD2_WH1 Transfer "'+@storerkey+','+@sku +','+@loc+',,'+@pid+',,,'+@lotqty+','+@storerkey+','+@sku +','+@loc+','+@pid+',,,'+@lotqty+','+@lot+',,'+@lot02+',,'+@lot04+','+@lot05+','+@lot06+',,,,"'
								    	  --select '' as TEST,@text
								    	  --tostorer,tosku,toloc,tolot,toid,topack,touom,toqty,fromstorer,fromsku,fromloc,fromid,frompack,fromuom,fromqty,fromlot,tolottable01,tolottable02,tolottable03,tolottable04,tolottable05,tolottable06,tolottable07,tolottable08,tolottable09,tolottable10

								    	  
							    		  insert into #t1 
									  exec xp_cmdshell @text
									  --java -classpath c:\dataadapter\DKInforDA.jar -DconfigPath=c:\dataadapter\DKInforDA.properties dke.da.trident.ExceedServerCall Transfer PRD2_WH1 Transfer 001,Тов000514,BE01.0.01,, ,,,164.00000,001,Тов000514,BE01.0.01, ,,,164.00000,0000184445,,,,,11/11/2012,,,,,
									  
									  print 'Вставка в dbo.DA_TransfertLOG'
									  
									  insert into dbo.DA_TransfertLOG
									  (inventjournalid,message)	
									  	     		    
									   select  @inventjournalid,mess 
									   from    #t1
									   
									  if not EXISTS (select 1 from #t1 where mess like 'Transfer Result: No Error%')
									  begin
	    									print 'Transfer Result:ERROR'
	    									set @msg_errdetails = @msg_errdetails+' Inventjournalid='+@inventjournalid+' SKU='+@sku+' InventBatchID='+@InventBatchID+' InventSerialID='+@InventSerialID+' ManufactureDateFrom='+cast(@ManufactureDateFrom as varchar)+' InventExpireDate='+cast(@InventExpireDate as varchar)+'.Произошла ошибка при трансферте'+char(10)+char(13)    			
										set @send_error = 1
										--select @msg_errdetails,   @send_error                                                                	    
									  end
									  else
									  	BEGIN	
									  	
									  		print 'удаление старых партий из lotxlocxid'
									  		
									  		delete
									  		from	wh1.lotxlocxid
									  		from	wh1.lotxlocxid l
												join wh1.LOT l2
												    on l2.LOT = l.LOT
									  		where	l2.LOT = @lot
									  			and l2.QTY = 0
									  			
									  		if @@ERROR = 0
									  		BEGIN
									  			print 'удаление старых партий из lot'
									  			
									  			delete
									  			from	wh1.LOT
									  			where	LOT = @lot
									  				and QTY = 0
									  				
									  				
									  			if @@ERROR = 0
									  			BEGIN
									  				if not exists (select 1 from wh1.LOT where LOT = @lot)
									  				begin
									  				    print 'удаление старых партий из LOTATTRIBUTE'
									  				    									  					
									  				    delete
									  				    from	wh1.LOTATTRIBUTE									  				
									  				    where	LOT = @lot
									  				end
									  					
									  				
									  			end									  			
									  		END
									  	     	
									  	     	 
									  		
									  		
									  	END								    	  
								    	  
								    	  
								    	  delete
								    	  from    #trlot04_1
								    	  where   ser = @y
								    	
								    END
								    
								    
								     print '99'
								     	
							    --END
							 --   else
								--BEGIN
								--    print '5'
								--    set @msg_errdetails = @msg_errdetails+' Inventjournalid='+@inventjournalid+' SKU='+@sku+' InventBatchID='+@InventBatchID+' InventSerialID='+@InventSerialID+' ManufactureDateFrom='+cast(@ManufactureDateFrom as varchar)+' InventExpireDate='+cast(@InventExpireDate as varchar)+'.Свободный остаток не равен кол-ву для трансферта.'+char(10)+char(13)
								--    set @send_error = 1
										
								--END
								
						    END
								
						
						
					
					end
					else
						--if (@CorrInventLocationID in ('БлокировкаСПб'))
						if (@CorrInventLocationID in ('БлокФСН'))--,'Склад сертификации')) -- Переделка на разделение блокировок, вместо ячеек (Шевелев С.С., 17.03.2015)
						BEGIN
							print 'Блокировка'
							
							select	--distinct
								identity(int,1,1) as id,
								l.LOT,l.QTYALLOCATED,l.QTYPREALLOCATED,l.QTYPICKED,l.QTY
							into	#lot
							from	wh1.LOT l
								join wh1.LOTATTRIBUTE l2 		on l2.LOT = l.LOT
								join wh1.LOTxLOCxID ll			on ll.LOT = l.LOT								
								join wh1.loc s					on s.loc=ll.loc  -- Переделка на зону, вместо ячеек (Шевелев С.С., 17.03.2015)
							where	ll.sku = @sku
								and ll.STORERKEY = @storerkey
								and l2.LOTTABLE02 = @InventSerialID
								and l2.LOTTABLE04 = @ManufactureDateFrom
								and l2.LOTTABLE05 = @InventExpireDate
								--and ll.loc not in ('NETSERT','BLOKFSN')
								and s.PUTAWAYZONE not in ('NETSERT','BLOKFSN') -- Переделка на зону, вместо ячеек (Шевелев С.С., 17.03.2015)
								
							if exists (select 1 from #lot where (QTYALLOCATED > cast(0 as numeric(22,5)) or QTYPREALLOCATED > cast(0 as numeric(22,5))))							
							begin
								set @msg_errdetails = @msg_errdetails+' Inventjournalid='+@inventjournalid+' SKU='+@sku+' InventSerialID='+@InventSerialID+' ManufactureDateFrom='+@ManufactureDateFrom+' InventExpireDate='+@InventExpireDate+'.Невозможно заблокировать зарезервированный товар.'+char(10)+char(13)
								set @send_error = 1
							end
							else
								BEGIN
							/* --Убираем блокировки		
									if exists (select 1 from wh1.INVENTORYHOLD i join #lot l on l.lot = i.LOT)
									BEGIN
										print 'блокировка существует'
										
										if exists (select 1 from wh1.INVENTORYHOLD i join #lot l on l.lot = i.LOT and i.HOLD = '0')
										BEGIN
											print 'блокировка существует, но HOLD = 0'
											--if not EXISTS (select lot from #lot group by lot having @qty <> sum(Qty - ( QtyPreAllocated + QtyAllocated + QtyPicked)))
											--BEGIN
												update	i
												set	hold = '1'
												from	wh1.INVENTORYHOLD i
													join #lot l 
													    on l.lot = i.LOT
        												    
												if @@ERROR = 0
												BEGIN       												
        														
													UPDATE	i
													Set	Status = 'HOLD', QtyOnHold = @qty
													from	wh1.Lot i
														join #lot l 
														    on l.lot = i.LOT
													
													if @@ERROR = 0
													BEGIN
														
														update	i
														set	status = 'HOLD'
														from	wh1.LOTxLOCxID i
															join #lot l 
															    on l.lot = i.LOT
													
													END
												END
					
											
											
										END 
									END
									
									if exists (select 1 from #lot l left join wh1.INVENTORYHOLD i on l.lot = i.LOT where i.lot is null)
										    and @msg_errdetails = ''
									BEGIN
										print 'создаем новую блокировку'
										
										select * into #lot_1 from #lot
										
										declare @ii int
										
										while exists (select 1 from #lot_1 l left join wh1.INVENTORYHOLD i on l.lot = i.LOT where i.lot is null)
										BEGIN
											
											select	top 1
												@ii = l.id
											from	#lot_1 l 
												left join wh1.INVENTORYHOLD i 
												    on l.lot = i.LOT 
											where	i.lot is null
											
											
											declare @inventorykey nvarchar(10) = null
											exec dbo.DA_GetNewKey 'wh1','INVENTORYHOLDKEY',@inventorykey output
        					
											insert into wh1.INVENTORYHOLD
											(WHSEID,INVENTORYHOLDKEY,LOT,HOLD,STATUS)
        										
											select	'WH1',@inventorykey,l.lot,'1' as hold,@CorrInventLocationID as status
											from	#lot_1 l 
												left join wh1.INVENTORYHOLD i 
												    on l.lot = i.LOT 
											where	i.lot is null
												and l.id = @ii
        											
											if @@ERROR = 0
											BEGIN       												
        														
												UPDATE	i
												Set	Status = 'HOLD', QtyOnHold = @qty
												from	wh1.Lot i
													join #lot_1 l 
													    on l.lot = i.LOT
													    and l.id = @ii
        											
												if @@ERROR = 0
												BEGIN
        												
													update	i
													set	status = 'HOLD'
													from	wh1.LOTxLOCxID i
														join #lot_1 l 
														    on l.lot = i.LOT
														    and l.id = @ii									    
													
        											
												END
											END
        										
        										
											delete	
											from	#lot_1
											where	id = @ii
											
										END									
										
									END									
							
							--Убираем блокировки	*/		
									print 'создаем задачи на перемещение'								
									
									select	identity(int,1,1) as serkey,
										l.lot,l2.LOC,l2.ID, l2.STORERKEY, l2.SKU,
										l2.Qty - ( l2.QtyAllocated + l2.QtyPicked ) as qty
									into	#j
									from	#lot l
										join wh1.LOTxLOCxID l2
											on l2.LOT = l.lot
									where	l2.Qty - ( l2.QtyAllocated + l2.QtyPicked ) > 0
										
									while exists (select 1 from #j)
									BEGIN
										select top 1 @e = serkey from #j
										
										exec dbo.DA_GetNewKey 'wh1','TASKDETAILKEY',@taskdetailkey output
									
										INSERT INTO wh1.TaskDetail 
										(WHSEID,TaskDetailKey, TaskType, Storerkey, 
										Sku, Lot, UOM, UOMQty, qty, FromLoc, FromID, ToLoc, ToID, Status, Priority, 
										Holdkey, UserKey, ListKey, StatusMsg, ReasonKey, CaseId, UserPosition, 
										UserKeyOverride, OrderLineNumber, PickDetailKey, LogicalFromLoc, LogicalToLoc, FinalToLoc,
										MESSAGE01,MESSAGE02,MESSAGE03,ADDWHO ) 
									
										--select	'wh1',@taskdetailkey, 'MV', STORERKEY, 
										--	sku, lot, '6', qty as UOMQty, qty as qty, loc, id, @inventlocationid as toloc, id, '0', '5',
										--	' ', ' ', ' ', ' ', ' ', ' ', '1',
										--	' ', '   ', '   ', @inventlocationid as LogicalFromLoc, @inventlocationid as LogicalToLoc, @inventlocationid as FinalToLoc,
										--	'' as mess01,@inventjournalnameid as mess02,@inventjournalid as mess03, 'sklad_integr' as addwho
										--from	#j l
										--where	serkey = @e
										
										select	'wh1',@taskdetailkey, 'MV', STORERKEY, 
											sku, lot, '6', qty as UOMQty, qty as qty, loc, id, 'BLOKFSN' as toloc, id, '0', '5',
											' ', ' ', ' ', ' ', ' ', ' ', '1',
											' ', '   ', '   ', @inventlocationid as LogicalFromLoc, 'BLOKFSN' as LogicalToLoc, 'BLOKFSN' as FinalToLoc,
											'' as mess01,@inventjournalnameid as mess02,@inventjournalid as mess03, 'sklad_integr' as addwho
										from	#j l
										where	serkey = @e
										
										
										delete	
										from	#j
										where	serkey = @e
										
										
									END										
									
									
								END							 
							
							
						END
						else
							--if (@CorrInventLocationID in ('NETSERTIFICATA','BLOKFSN'))
							--if (@CorrInventLocationID in ('NETSERT','BLOKFSN'))
							--if (@CorrInventLocationID in ('БлокировкаСПб'))
							if (@inventlocationid in ('БлокФСН'))--,'Склад сертификации'))
							
							BEGIN
								print 'РазБлокировка'
								
								select	--distinct
									identity(int,1,1) as id,
									ll.sku,ll.storerkey,
									l.LOT,ll.loc,IsNull(i.HOLD,'0') as hold,
									ll.id as pid,
									ll.Qty - ( ll.QtyAllocated + ll.QtyPicked ) as qty,
									s.PUTAWAYZONE
								into	#lot_9
								from	wh1.LOT l
									join wh1.LOTATTRIBUTE l2		on l2.LOT = l.LOT
									join wh1.LOTxLOCxID ll			on ll.LOT = l.LOT
									left join wh1.INVENTORHOLD i	on i.LOT = l.LOT							
									join wh1.loc s					on s.loc=ll.loc  -- Переделка на зону, вместо ячеек (Шевелев С.С., 17.03.2015)
								where	ll.sku = @sku
									and ll.STORERKEY = @storerkey
									and l2.LOTTABLE02 = @CorrInventSerialID
									and l2.LOTTABLE04 = @ManufactureDateTo
									and l2.LOTTABLE05 = @CorrInventExpireDate
									--and ll.loc not in ('NETSERTIFICATA','BLOKFSN')
									and s.PUTAWAYZONE in ('BLOKFSN') -- Переделка на зону, вместо ячеек (Шевелев С.С., 17.03.2015)		
									

															
								
								/*--	
								while exists (select 1 from #lot_9 where hold = '0')
								BEGIN
									select	top 1
											@lot = lot
									from	#lot_9 
									where	hold = '0'
									
									print 'Ошибка. Нет такой блокировки'
									set @msg_errdetails = @msg_errdetails+' Inventjournalid='+@inventjournalid+' SKU='+@sku+' InventSerialID='+@InventSerialID+' ManufactureDateFrom='+@ManufactureDateFrom+' InventExpireDate='+@InventExpireDate+'.Ошибка. Нет такой блокировки.'+char(10)+char(13)
									set @send_error = 1
									
									delete 
									from	#lot_9
									where	lot = @lot
										
								END
								-- */
								if exists (select 1 from #lot_9)
								BEGIN
									print 'Снимаем блокировку'
									/*	
									update	i
									set	hold = '0'
									from	wh1.INVENTORYHOLD i
										join (select distinct lot from #lot_9) l 
											on l.lot = i.LOT
										    
									if @@ERROR = 0
									BEGIN       												
													
										UPDATE	i
										Set	Status = 'OK'
										from	wh1.Lot i
											join (select distinct lot from #lot_9) l 
												on l.lot = i.LOT
										
										if @@ERROR = 0
										BEGIN
											
											update	i
											set	status = 'OK'
											from	wh1.LOTxLOCxID i
												join (select distinct lot from #lot_9) l 
													on l.lot = i.LOT
										
										END
									END		*/						
									
									
									--while exists (select 1 from #lot_9 where loc in ('NETSERT','BLOKFSN'))
									while exists (select 1 from #lot_9 where PUTAWAYZONE in ('BLOKFSN'))
									BEGIN
										print 'Создаем задачи на перемещения в ячейку EA_IN'
										
										select top 1 @e = id from #lot_9
										
										exec dbo.DA_GetNewKey 'wh1','TASKDETAILKEY',@taskdetailkey output
									
										INSERT INTO wh1.TaskDetail 
										(WHSEID,TaskDetailKey, TaskType, Storerkey, 
										Sku, Lot, UOM, UOMQty, qty, FromLoc, FromID, ToLoc, ToID, Status, Priority, 
										Holdkey, UserKey, ListKey, StatusMsg, ReasonKey, CaseId, UserPosition, 
										UserKeyOverride, OrderLineNumber, PickDetailKey, LogicalFromLoc, LogicalToLoc, FinalToLoc,
										MESSAGE01,MESSAGE02, ADDWHO) 
									
										select	'wh1',@taskdetailkey, 'MV', STORERKEY, 
											sku, lot, '6', qty as UOMQty, qty as qty, loc, id, 'EA_IN' as toloc, id, '0', '5',
											' ', ' ', ' ', ' ', ' ', ' ', '1',
											' ', '   ', '   ', loc as LogicalFromLoc, 'EA_IN' as LogicalToLoc, 'EA_IN' as FinalToLoc,
											@inventjournalnameid as mess01,@inventjournalid as mess02,'sklad_integr' as addwho
										from	#lot_9 l
										where	id = @e
										
										
										delete	
										from	#lot_9
										where	id = @e
										
										
									END
									 
									
								END
								
        							
							END
							else
								if (@inventlocationid <> @CorrInventLocationID)
								BEGIN
									print 'Ошибка. Нельзя перемещать товар'
									set @msg_errdetails = @msg_errdetails+' Inventjournalid='+@inventjournalid+' SKU='+@sku+' InventSerialID='+@InventSerialID+' ManufactureDateFrom='+@ManufactureDateFrom+' InventExpireDate='+@InventExpireDate+'.Ошибка. Нельзя перемещать товар.'+char(10)+char(13)
									set @send_error = 1
								END
					
					print '100'
					select @i = @i + 1				
					 
					 --delete from #DA_SkladDetail where id = @i
					 
					 print '101'
				END
				print '102'						
				
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
			from DA_Sklad dr join #DA_Sklad r on (dr.inventjournalid = r.inventjournalid) or (dr.id = r.id)
		delete dr
			from DA_SkladDetail dr join #DA_Sklad r on dr.inventjournalid = r.inventjournalid
			
		
		
	end
--			
END TRY

BEGIN CATCH
	print 'Неизвестная ошибка'
	declare @error_message nvarchar(4000)
	declare @error_severity int
	declare @error_state int
	
	set @error_message  = ERROR_MESSAGE()
	set @error_severity = ERROR_SEVERITY()
	set @error_state    = ERROR_STATE()
	select @error_message, @error_severity, @error_state
	--set @send_error = 0
	--raiserror (@error_message, @error_severity, @error_state)
END CATCH

select @send_error

if @sign = 1
begin

	if @send_error = 1
	begin
		print 'Ставим документ в обменной таблице DAX в ошибку'
		
		update	s
		set	status = '15',
			error = @msg_errdetails
		from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInventJournalTrans s
			join #da_sklad d
			    on d.inventjournalid = s.inventjournalid
		where	s.status = '5'
		
		
		update	s
		set	status = '15',
			error = @msg_errdetails
		from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInventJournal s
			join #da_sklad d
			    on d.inventjournalid = s.inventjournalid
		where	s.status = '5'
		
	--*************************************************************************

		update	s
		set	status = '15',
			error = @msg_errdetails
		from	[SQL-WMS].[PRD2].[dbo].da_sklad_archive s
			join #da_sklad d
			    on d.inventjournalid = s.inventjournalid
		where	s.status = '5'		
		
		update	s
		set	status = '15',
			error = @msg_errdetails
		from	[SQL-WMS].[PRD2].[dbo].da_skladDetail_archive s
			join #da_sklad d
			    on d.inventjournalid = s.inventjournalid				
		where	s.status = '5'	


		print 'отправляем сообщение об ошибке по почте'
		print @msg_errdetails
		--raiserror (@msg_errdetails, 16, 1)
		
		--insert into DA_InboundErrorsLog (source,msg_errdetails) values (@source,@msg_errdetails)		
		--exec app_DA_SendMail @source, @msg_errdetails
	end
	else
	begin

		print 'Ставим статус документа в обменной таблице DAX в ОБРАБОТАН'
		declare @n bigint
		
		if exists (select 1 from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInventJournal s 
			   join #da_sklad d on d.inventjournalid = s.inventjournalid where s.status = '5')
		begin
			print 'Документ существует, ставим mastersystem = 0'
			update	s
			set	status = '10',
				mastersystem = '0'
			from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInventJournalTrans s
				join #da_sklad d
				    on d.inventjournalid = s.inventjournalid
			where	s.status = '5'
        		
        		
			update	s
			set	status = '10',
				mastersystem = '0'
			from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInventJournal s
				join #da_sklad d
				    on d.inventjournalid = s.inventjournalid
			where	s.status = '5'			
		
		end
		else
			BEGIN
			    print 'Документ не существует, ставим mastersystem = 1, inventjournalid ставим свой'
			    
			    select  @n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
			    from    [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInventJournal
			    
			    insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInventJournal
			    (DataAReaID, inventjournalnameid, transdate, inventjournalid, inventjournaltype,
			     mastersystem,Status,RecID)		
        		
        		    
			    select  'SZ' as dataareaid,
				    inventjournalnameid,				    
				    getdate() as transdate,
				    'I'+ cast(id as varchar(10)) as inventjournalid,
				    inventjournaltype,
				    1 as mastersystem,
				    '5',
				    @n + 1 as recid
			    from    #da_sklad
			    
			    
			    if @@ERROR = 0
			    begin
            		    	
            		    	
	    			select  @n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
				from    [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInventJournalTrans


				insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInventJournalTrans
				(DataAReaID, inventjournalid, transdate,ItemID, manufacturedatefrom,manufacturedateto,inventexpiredate,corrinventexpiredate,
				OrderedQty,inventlocationid,corrinventlocationid,
				InventBatchID,corrinventbatchid,InventSerialID,corrinventserialid,mastersystem,Status,RecID)

				select  'SZ' as dataareaid,
					'I'+ cast(d.id as varchar(10)) as inventjournalid,
					getdate() as transdate,
					s.sku,
					s.manufacturedatefrom,
					s.ManufactureDateTo,
					s.inventexpiredate,
					s.corrinventexpiredate,
					s.orderedqty,
					s.inventlocationid,
					s.corrinventlocationid,
					s.inventbatchid,
					s.corrinventbatchid,
					s.inventserialid,
					s.corrinventserialid,
					1 as mastersystem,
					'5',
					@n + s.serkey as recid	
				from    #DA_SkladDetail s
					join #da_sklad d
					    on d.inventjournalid = s.inventjournalid		    
            			
            		    	
            		    	
			    end			
				
			END
		
		
		

		if @signtransfert = 1
		BEGIN
		    
		   -- if exists (select 1 from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventjournal s 
			  -- join #da_sklad d on d.inventjournalid = s.inventjournalid where s.status = '5')
		   -- BEGIN
		    	
		   -- 	    print '@signtransfert = 1, Документ существует, ставим mastersystem = 0'
			  --  update  s
			  --  set	    status = '10',
				 --   mastersystem = '0'
			  --  from    [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventjournaltrans s
				 --   join #da_sklad d
					--on d.inventjournalid = s.inventjournalid
			  --  where   s.status = '5'
            		
            		
			  --  update  s
			  --  set	    status = '10',
				 --   mastersystem = '0'
			  --  from    [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventjournal s
				 --   join #da_sklad d
					--on d.inventjournalid = s.inventjournalid
			  --  where   s.status = '5'	
		    	
		    	
		    	
		   -- END
		   -- else
		   -- BEGIN
		    	
			    print '@signtransfert = 1,Документ не существует, ставим mastersystem = 1,inventjournalid ставим свой'
			    
			    select  @n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
			    from    [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventjournal


			    insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventjournal
			    (DataAReaID, inventjournalnameid, transdate, inventjournalid, inventjournaltype,
			     mastersystem,Status,RecID)		
        		
        		    
			    select  'SZ' as dataareaid,
				    inventjournalnameid,
				    getdate() as transdate,
				   -- 'I'+ cast(id as varchar(10)) as inventjournalid,
				    inventjournalid,
				    inventjournaltype,
				    0 as mastersystem,
				    '5',
				    @n + 1 as recid
			    from    #da_sklad
        		    
			    if @@ERROR = 0
			    begin
        		    	
        		    	
		    		select  @n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
				from    [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventjournaltrans


				insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventjournaltrans
				(DataAReaID, inventjournalid, transdate,ItemID, manufacturedatefrom,manufacturedateto,inventexpiredate,corrinventexpiredate,
				OrderedQty,inventlocationid,corrinventlocationid,
				InventBatchID,corrinventbatchid,InventSerialID,corrinventserialid,mastersystem,Status,RecID)

				select  'SZ' as dataareaid,
					--'I'+ cast(d.id as varchar(10)) as inventjournalid,
					s.inventjournalid,
					getdate() as transdate,
					s.sku,
					s.manufacturedatefrom,
					s.ManufactureDateTo,
					s.inventexpiredate,
					s.corrinventexpiredate,
					s.orderedqty,
					s.inventlocationid,
					s.corrinventlocationid,
					s.inventbatchid,
					s.corrinventbatchid,
					s.inventserialid,
					s.corrinventserialid,
					0 as mastersystem,
					'5',
					@n + s.serkey as recid	
				from    #DA_SkladDetail s
					join #da_sklad d
					    on d.inventjournalid = s.inventjournalid
				where	s.dotransfert = '1'		    
        			
        		    	
        		    	
			    --end	
		    	
		    		
		    		
		    END
		    
		    
		
		END
		
		
	--*************************************************************************

		update	s
		set	status = '10',
			error = @msg_errdetails
		from	[SQL-WMS].[PRD2].[dbo].da_sklad_archive s
			join #da_sklad d
			    on d.inventjournalid = s.inventjournalid
		where	s.status = '5'
		
		
		update	s
		set	status = '10',
			error = @msg_errdetails
		from	[SQL-WMS].[PRD2].[dbo].da_skladDetail_archive s
			join #da_sklad d
			    on d.inventjournalid = s.inventjournalid				
		where	s.status = '5'	


	end



end



IF OBJECT_ID('tempdb..#da_sklad') IS NOT NULL DROP TABLE #da_sklad
IF OBJECT_ID('tempdb..#da_skladDetail') IS NOT NULL DROP TABLE #da_skladDetail



