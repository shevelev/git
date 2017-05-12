-- ЗО --
ALTER PROCEDURE [WH1].[proc_DA_ShipmentOrder_OX]
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
declare @externorderkey varchar(20)
--declare @id int
declare @susr4 varchar (30)
declare @susr2 varchar (30),
	@susr1 varchar (30)
declare @orderkey varchar (15)
declare @consigneekey varchar (15)
declare @carriercode varchar (15),
	@routedeleted varchar(3)

declare	@Load varchar (10), -- необходимость формирования загрузок
	@loadid varchar (10), -- номер загрузки
	@loadstopid int, -- идентификатор стопа (остановки маршрута) в загрузке
	@loadorderdetailid int -- идентификатор строки с заказом в загрузке

declare @loaddate datetime
declare @shipdate datetime
declare @adddate datetime
declare @deadtime int -- время дедлайна для нестабильных маршрутов
declare @dayweek int,
	@maxid int,
	@sign int = 0

set @send_error = 0
set @msg_errdetails = ''
set @enter = char(10)+char(13)
set @loadid = ''
select @deadtime = short from wh1.CODELKUP where LISTNAME = 'sysvar'and code = 'DLINESH'
declare @bs varchar(3) select @bs = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'
declare @bsanalit varchar(3) select @bsanalit = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'BSANALIT'

--return 

BEGIN TRY
--	select @allowUpdate = allowUpdate from dbo.DA_MessageTypes where MessageKey = 'ordercard'
	--while (exists (select id from DA_ShipmentOrderHead))
		begin
			set @sign = 1
			
			print ' выбираем запись из обменной таблицы DA_ShipmentOrderHead'
			select * into #DA_ShipmentOrderHead from DA_ShipmentOrderHead where id=@id --order by id desc
			
			print ' обновление NULL значений'
			update #DA_ShipmentOrderHead set
				storerkey = left(isnull(rtrim(ltrim(consigneekey)),''),10),
				C_CONTACT1 = left(isnull(rtrim(ltrim(C_CONTACT1)),''),30),
				SUSR2 = left(isnull(rtrim(ltrim(SUSR2)),''),30),
				susr4 = left(isnull(rtrim(ltrim(susr4)),''),30),
				externorderkey = left(isnull(rtrim(ltrim(externorderkey)),''),32),
				[type] = left(isnull(rtrim(ltrim([type])),''),10),			
				susr3 = left(isnull(rtrim(ltrim(susr3)),''),30),
				REQUESTEDSHIPDATE = ISNULL(REQUESTEDSHIPDATE,getutcdate()),				
				consigneekey = left(isnull(rtrim(ltrim(consigneekey)),''),10),
				susr1 = left(isnull(rtrim(ltrim(susr1)),''),30),
				routedeleted = left(isnull(rtrim(ltrim(routedeleted)),''),2)
				
			--select @susr2=SUSR2 from #DA_ShipmentOrderHead

			--if @susr2!=''
			--	begin
			--		update #DA_ShipmentOrderHead set
			--			consigneekey = @susr2,
			--			SUSR2 = ''
			--	end				
				
			
		set @msg_errdetails1 =''
			print ' проверка входных данных'
			select 
				@msg_errdetails1 = @msg_errdetails1 --externorderkey empty
					+case when o.externorderkey = ''
						then 'er#001ORDER. ВнешнийНомер=*Пустой*.'+@enter
						else ''
					end,				
				@msg_errdetails1 = @msg_errdetails1 --storerkey EMPTY
					+case when o.storerkey = ''
						then 'er#002ORDER. ВнешнийНомер=*'+o.externorderkey+'*. Владелец=*пустой*.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --storerkey in STORER
					+case when (not exists(select s.* from wh1.storer s where s.storerkey = o.storerkey))
						then 'er#003ORDER. ВнешнийНомер=*'+o.externorderkey+'*. Владелец=*'+o.storerkey+'* отсутвует в справочнике STORER.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --c_contact1 EMPTY
					+case when o.c_contact1 = ''
						then 'er#004ORDER. Накладная=*пустая*.'+@enter
						else ''
					end,
				--@msg_errdetails1 = @msg_errdetails1 --carriercode in STORER
				--	+case when (not exists(select s.* from wh1.storer s where s.storerkey = o.carriercode))
				--		then 'ORDER. CARRIERcode='+o.carriercode+' отсутвует в справочнике STORER.'+@enter
				--		else ''
				--	end,
				@msg_errdetails1 = @msg_errdetails1 --type empty
					+case when o.type = ''
						then 'er#005ORDER. ВнешнийНомер=*'+o.externorderkey+'*. ТипДокумента=*пустой*.'+@enter
						else ''
					end,
				--@msg_errdetails1 = @msg_errdetails1 --type !=1 & !=101 & !=102
				--/* VC 04/09/2011 */
				--	--+case when ltrim(rtrim(o.type)) != '1' and ltrim(rtrim(o.type)) != '101' and ltrim(rtrim(o.type)) != '102'
				--	+case when not ltrim(rtrim(o.type)) in ('1','101','102','103','104')
				--		then 'ORDER. externorderkey='+o.externorderkey+'. TYPEkey not in (1,101,102,103,104)'+@enter
				--		else ''
				--	end,
				@msg_errdetails1 = @msg_errdetails1 --SUSR1 empty
					+case when o.susr1 = ''
						then 'er#006ORDER. ВнешнийНомер=*'+o.externorderkey+'*. СкладОтгрузки=*пустой*'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --SUSR2 empty
					+case when o.susr2 = ''
						then 'er#007ORDER. ВнешнийНомер=*'+o.externorderkey+'*. SUSR2=*empty*.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --SUSR4 empty
					+case when o.susr4 = ''
						then 'er#008ORDER. ВнешнийНомер=*'+o.externorderkey+'*. Маршрут(SUSR4)=*пустой*.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --routedeleted empty
					+case when o.routedeleted = ''
						then 'er#009ORDER. ВнешнийНомер=*'+o.externorderkey+'*. routedeleted=*empty*.'+@enter
						else ''
					end,
				--@msg_errdetails1 = @msg_errdetails1 --SUSR4 empty
				--	+case when ltrim(rtrim(o.susr4)) = '' and ltrim(rtrim(o.type)) != '101'
				--		then 'ORDER. externorderkey='+o.externorderkey+'. SUSR4=empty.'+@enter
				--		else ''
				--	end,-----------проверка маршрута
				--@msg_errdetails1 = @msg_errdetails1 --consigneekey empty
				--	+case when ltrim(rtrim(o.consigneekey)) = '' and ltrim(rtrim(o.type)) != '101'
				--		then 'ORDER. externorderkey='+o.externorderkey+'. CONSIGNEEkey=empty.'+@enter
				--		else ''
				--	end, -----------проверка грузополучателя
				@msg_errdetails1 = @msg_errdetails1 --consigneekey in STORER
					+ 
					case when (not exists(select s.* from wh1.storer s where s.storerkey = o.consigneekey)) 
						then 'er#010ORDER. ВнешнийНомер=*'+o.externorderkey+'*. КлиентДоставки=*'+o.consigneekey+'* отсутвует в справочнике STORER.'+@enter
						else ''						
					end,
				@msg_errdetails1 = @msg_errdetails1
					+case when oo.externorderkey is not null and cast(oo.STATUS as int) > 9 
						then 'er#011ORDER. ВнешнийНомер=*'+oo.externorderkey+'* SUSR2= *' + oo.susr2 +'*. Документ в обработке, обновление невозможно.'+@enter
						else ''
					end--,
				--@msg_errdetails1 = @msg_errdetails1 --consigneekey in STORER
				--	+case when ltrim(rtrim(o.type)) = '101' 
				--		then '' 
				--		else 
				--			case when (not exists(select s.* from wh1.storer s where s.storerkey = o.consigneekey)) 
				--				then 'ORDER. externorderkey='+o.externorderkey+'. CONSIGNEEkey='+o.consigneekey+' отсутвует в справочнике STORER.'+@enter
				--				else ''
				--		end
				--	end,
				--@msg_errdetails1 = @msg_errdetails1 --b_company empty
				--	+case when ltrim(rtrim(o.b_company)) = '' and ltrim(rtrim(o.type)) != '101'
				--		then 'ORDER. externorderkey='+o.externorderkey+'. b_company=empty.'+@enter
				--		else ''
				--	end, -------------проверка грузополучателя
				--@msg_errdetails1 = @msg_errdetails1 --b_company in STORER
				--	+case when ltrim(rtrim(o.type)) = '101'
				--		then ''
				--		else 
				--			case when (not exists(select s.* from wh1.storer s where s.storerkey = o.b_company))
				--				then 'ORDER. externorderkey='+o.externorderkey+'. b_company='+o.b_company+' отсутвует в справочнике STORER.'+@enter
				--				else ''
				--			end
				--	end					
--				@msg_errdetails1 = @msg_errdetails1 --RMA 
--					+case when ltrim(rtrim(o.rma)) = ''
--						then 'ORDER. externorderkey='+o.externorderkey+'. RMA=empty.'+@enter
--						else ''
--					end
			from	#DA_ShipmentOrderHead o
				left join wh1.ORDERS oo
				    on o.externorderkey = oo.EXTERNORDERKEY
				   -- and o.susr2 = oo.SUSR2	
			
			
			if (@msg_errdetails1 = '')
			begin
				print ' проверка на уникальность документов в обменной таблице'
				if ((select count (o.externorderkey) from DA_ShipmentOrderHead o join #DA_ShipmentOrderHead do on o.externorderkey = do.externorderkey) > 1)
					set @msg_errdetails1 = 'er#012ORDER. externorderkey=*'+(select externorderkey from #DA_ShipmentOrderHead)+'*. Не уникальный документ в обменной таблице.'+@enter
			end

			if (@msg_errdetails1 = '') 
			begin
				print ' контроль входных данных шапки документа пройден успешно'
				print ' выбираем externorderkey'
				select @storerkey = storerkey, @externorderkey = externorderkey, @susr2 = susr2,@susr1 = susr1 from #DA_ShipmentOrderHead
				print ' выбираем детали документа'
				
				select	identity(int,1,1) as id,
					do.* 
				into	#DA_ShipmentOrderDetail 
				from	DA_ShipmentOrderDetail do 
					join #DA_ShipmentOrderHead o 
					    on do.externorderkey = o.externorderkey 
				where	o.externorderkey = @externorderkey
				

				print ' обновление NULL значений в деталях документа'
				update #DA_ShipmentOrderDetail set
					externorderkey = left(isnull(rtrim(ltrim(externorderkey)),''),32),
					storerkey = case	when (left(isnull(rtrim(ltrim(storerkey)),''),15)) = 'SZ' then '001' 
									else (left(isnull(rtrim(ltrim(storerkey)),''),15)) 
							end,						
					sku = left(isnull(rtrim(ltrim(sku)),''),50),
					lottable02 = left(isnull(rtrim(ltrim(lottable02)),''),50),
					lottable05= case when lottable05='19000101' then null else lottable05 end, ---Шевелев 24.03.2015
					lottable06 = left(isnull(rtrim(ltrim(lottable06)),''),40),
					lottable06_A = left(isnull(rtrim(ltrim(lottable06)),''),40),  -- Шевелев 19.11.2015 Обрезание партий, которые имеют префикс _A%% на конце
					lottable04= case when lottable04='19000101' then null else lottable04 end, ---Шевелев 24.03.2015
					qtyexpected = isnull(nullif(
							    replace(replace(replace(qtyexpected,',','.'),' ',''),CHAR(160),'')
							    ,''),0)

	
--------------------- Замениям владельца в шапке документа ----------- Шевелев 23.06.2016 ------------------------------------------
				update	s
					set	s.storerkey=d.storerkey
					from	     #DA_ShipmentOrderDetail s
							join #DA_ShipmentOrderHead d 			on d.EXTERNORDERKEY = s.EXTERNORDERKEY
--------------------- Замениям владельца в шапке документа ----------- Шевелев 23.06.2016 ------------------------------------------
			select * from #DA_ShipmentOrderHead
			select * from #DA_ShipmentOrderDetail
			
-------------------------18.11.2015 Шевелев С.С. Обрезание партий, которые имеют префикс _A%% на конце -----------------------------
					update #DA_ShipmentOrderDetail set
						lottable06 =LEFT(lottable06,(len(lottable06)-4)) 
					where left(right(lottable06, 3),1)='A'
-------------------------18.11.2015 Шевелев С.С. Обрезание партий, которые имеют префикс _A%% на конце -----------------------------
			

				--select * into ttt from #DA_ShipmentOrderDetail

				print ' выбор идентификаторов строк'
				
				select id into #id from #da_shipmentorderdetail
				print ' проверка строк документа'
				while (exists (select * from #id))
				begin
				      select @id = id from #id
				    print ' строкаID='+cast(@id as varchar(10))+'.'
				    select @msg_errdetails1 = ''
				    select 
					    @msg_errdetails1 = @msg_errdetails1 --storerkey
						    +case when od.storerkey = ''
							    then 'er#013ORDER. STORERkey=*empty*'+@enter
							    else ''
						    end,
					    @msg_errdetails1 = @msg_errdetails1 --storer in STORER
						    +case when (not exists(select s.* from wh1.storer s where s.storerkey = od.storerkey))
							    then 'er#014ORDER. EXTERNORDERkey=*'+od.externorderkey+'*. STORER отсутвует в справочнике STORER.'+@enter
							    else ''
						    end,
					    @msg_errdetails1 = @msg_errdetails1 --extrnorderkey
						    +case when od.externorderkey = ''
							    then 'er#015ORDER. EXTERNLINENO=*empty*.'+@enter
							    else ''
						    end,
					    @msg_errdetails1 = @msg_errdetails1 --sku=empty
						    +case when (od.sku = '')
							    then 'er#016ORDER. EXTERNORDERkey=*'+od.storerkey+'*, SKU=*empty*'+@enter
							    else ''
						    end,
					    @msg_errdetails1 = @msg_errdetails1 --storer+sku in SKU
						    +case when (not exists(select s.* from wh1.sku s where s.storerkey = od.storerkey and s.sku = od.sku))
							    then 'er#017ORDER. EXTERNORDERkey=*'+od.externorderkey+'*. SKU=*'+od.sku+'*. SKU+STORER отсутвует в справочнике SKU.'+@enter
							    else ''
						    end,
					    @msg_errdetails1 = @msg_errdetails1 --qtyexpected
						    +case when (od.qtyexpected <= cast(0 as numeric(22,5)))
							    then 'er#018ORDER. EXTERNORDERkey=*'+od.externorderkey+'* SKU=*'+od.sku+'*. Не корректное значение qtyexpected.'+@enter
							    else ''
						    end					    
				    from    #DA_ShipmentOrderDetail od 						
				    where   od.id = @id

				    if @msg_errdetails1 != ''
				    begin
					    print ' ошибка в строке документа'
					    set @msg_errdetails = @msg_errdetails + 'er#019Ошибки в строке документа. '+@externorderkey+@enter+@msg_errdetails1
					    select @msg_errdetails1 = ''
					    set @send_error = 1
				    end
--							
				    delete from #id where id = @id
				end
				
				if (@msg_errdetails = '')
				begin
					print ' проверка на существование документа в базе'
        				
					select	@routedeleted = s.routedeleted 
					from	#DA_ShipmentOrderHead s
						join wh1.ORDERS o
						    on o.EXTERNORDERKEY = s.externorderkey
						    --and o.SUSR2 = s.susr2
						    
					if @routedeleted <> ''
					BEGIN
						print ' документ существует в базе'
						
						if @routedeleted = '1'
						BEGIN
							print '@routedeleted = 1'
							--begin tran
							
							update o
							set	o.C_CONTACT1 = s.C_CONTACT1,
								o.susr4 = s.susr4,
								o.SUSR3 = s.susr3,
								o.REQUESTEDSHIPDATE = s.REQUESTEDSHIPDATE,
								o.CONSIGNEEKEY = s.CONSIGNEEKEY,
								o.SUSR1 = s.susr1
							from	wh1.ORDERS o
								join #DA_ShipmentOrderHead s
								    on o.EXTERNORDERKEY = s.externorderkey
								    --and o.SUSR2 = s.susr2
							
							if @@ERROR = 0
							BEGIN
							--	rollback tran
							--END
							--else
							--BEGIN
								
								update o
								set	o.LOTTABLE02 = s.LOTTABLE02,
									o.LOTTABLE05 = s.LOTTABLE05,
									o.LOTTABLE06 = s.LOTTABLE06,
									o.LOTTABLE04 = s.LOTTABLE04,
									o.OPENQTY = s.qtyexpected								
								from	wh1.ORDERDETAIL o
									join #DA_ShipmentOrderDetail s
									    on o.EXTERNORDERKEY = s.externorderkey
									    
								if @@ERROR = 0
								BEGIN
								--	rollback tran
								--END
								--else
								--BEGIN
									select	@maxid = max(cast(recid as int)) 
									from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputUpdateOrders
									
									insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputUpdateOrders
									(dataareaid, docid, doctype, operationtypeheader, invoiceid,
									salesidbase,wmspickingrouteid, demandshipdate, consigneeAccount_ru,
									inventlocationid, --pickoperation, 
									status, recid)
									
									select	'SZ',externorderkey as docid,type,'1' as operationtypeheader,susr3 as invoiceid,
										C_CONTACT1 as salesidbase, susr2 as wmspickingrouteid,REQUESTEDSHIPDATE as demandshipdate,CONSIGNEEKEY as consigneeAccount_ru,
										susr1 as inventlocationid,--'1',
										'5' as status,@maxid+1 as recid
									from	#DA_ShipmentOrderHead
									where	externorderkey = @externorderkey
										--and susr2 = @susr2
									
									if @@ERROR = 0
									BEGIN
									--	rollback tran
									--END
									--else
									--BEGIN
										
										select	@maxid = max(cast(recid as int)) 
										from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputUpdOrderlines
										
										insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputUpdOrderlines
										(dataareaid,salesidbase,docid,itemid,wmsrouteid,
										operationtypeheader,orderedqty,inventlocationid,
										inventbatchid,inventserialid,inventexpiredate,
										inventserialproddate,status,recid)
										
										
										select	'SZ' as dataareaid, ss.C_CONTACT1 as salesidbase,s.externorderkey as docid,s.sku,ss.susr2 as wmsrouteid,
											'1' as operationtypeheader,s.qtyexpected,susr1 as inventlocationid,
											s.lottable06 as inventbatchid,s.lottable02 as inventserialid, s.lottable05 as inventexpiredate,
											s.lottable04 as inventserialproddate,'5' as status,@maxid + s.id as recid
										from	#DA_ShipmentOrderDetail s
											join #DA_ShipmentOrderHead ss
											    on s.externorderkey = ss.externorderkey
										where	ss.externorderkey = @externorderkey
											--and ss.susr2 = @susr2
											    
										--if @@ERROR <> 0
										--BEGIN
										--	rollback tran
										--END
										
									END								
										
									
								END
								
							END	    
								    
							--commit tran
							
						END
						
						if @routedeleted = '0'
						BEGIN
							
							print '@routedeleted = 0'
							
							begin tran
														
							update	wh1.ORDERDETAIL
							set	STATUS = '98'	-- Отменен внешне
							where	EXTERNORDERKEY = @externorderkey
							
							if @@ERROR <> 0
							BEGIN
							--	rollback tran
							--END
							--else
							--BEGIN
								update	wh1.ORDERS
								set	STATUS = '98'	-- Отменен внешне
								where	EXTERNORDERKEY = @externorderkey
								
								if @@ERROR <> 0
								BEGIN
								--	rollback tran
								--END
								--else
								--BEGIN
									
									select	@maxid = max(cast(recid as int)) 
									from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputUpdateOrders
									
									insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputUpdateOrders
									(dataareaid, docid, doctype, operationtypeheader, invoiceid,
									salesidbase,wmspickingrouteid, demandshipdate, consigneeAccount_ru,
									inventlocationid, --pickoperation, 
									status, recid)
									
									select	'SZ',externorderkey as docid,type,'1' as operationtypeheader,susr3 as invoiceid,
										C_CONTACT1 as salesidbase, susr2 as wmspickingrouteid,REQUESTEDSHIPDATE as demandshipdate,CONSIGNEEKEY as consigneeAccount_ru,
										susr1 as inventlocationid,--'1',
										'5' as status,@maxid+1 as recid
									from	#DA_ShipmentOrderHead
									where	externorderkey = @externorderkey
										--and susr2 = @susr2
									
									if @@ERROR <> 0
									BEGIN
									--	rollback tran
									--END
									--else
									--BEGIN
										
										select	@maxid = max(cast(recid as int)) 
										from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputUpdOrderlines
										
										insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputUpdOrderlines
										(dataareaid,salesidbase,docid,itemid,wmsrouteid,
										operationtypeheader,orderedqty,inventlocationid,
										inventbatchid,inventserialid,inventexpiredate,
										inventserialproddate,status,recid)
										
										
										select	'SZ' as dataareaid, ss.C_CONTACT1 as salesidbase,s.externorderkey as docid,s.sku,ss.susr2 as wmsrouteid,
											'1' as operationtypeheader,s.qtyexpected,susr1 as inventlocationid,
											s.lottable06 as inventbatchid,s.lottable02 as inventserialid, s.lottable05 as inventexpiredate,
											s.lottable04 as inventserialproddate,'5' as status,@maxid + s.id as recid
										from	#DA_ShipmentOrderDetail s
											join #DA_ShipmentOrderHead ss
											    on s.externorderkey = ss.externorderkey
										where	ss.externorderkey = @externorderkey
											--and ss.susr2 = @susr2
											    
										--if @@ERROR <> 0
										--BEGIN
										--	rollback tran
										--END							
										
										
									END									
									
									
								END
							END
							
							--commit tran
							
							
						END					
						
					END
					else
					begin
					
					    print ' получаем новый номер документа'
					    exec dbo.DA_GetNewKey 'WH1','order',@orderkey output

					    print ' вставляем шапку документа'
					    
					    insert into wh1.orders 
					    (whseid,orderkey,storerkey,	externorderkey,[type],
					    SUSR1,SUSR2,SUSR3,SUSR4,consigneekey,
					    C_CONTACT1,REQUESTEDSHIPDATE,TRANSPORTATIONMODE,C_ZIP, EXTERNALORDERKEY2)
					    
					    select  top (1) 'WH1' whseid, @orderkey, o.storerkey, o.externorderkey, o.[type], 
						    o.susr1, o.susr2, o.susr3, o.susr4,o.consigneekey, 
						    o.c_contact1,o.REQUESTEDSHIPDATE,'0',o.mp, case o.mp WHEN 0 then 'СЗ' else 'МП' end 
					    from    #DA_ShipmentOrderHead o 
						 --   join #DA_ShipmentOrderDetail dod 
							--on o.externorderkey = dod.externorderkey
							
					    if @@rowcount = 0 
					    begin
						    set @msg_errdetails = @msg_errdetails+'er#020ORDER. EXTERNORDERkey=*'+@externorderkey+'*. Неудалось выполнить вставку записи (шапка документа).'+char(10)+char(13)
						    set @send_error = 1
					    end	
					    else
					    BEGIN
					    	
					    	 print ' вставляем строки документа'
					    	    
						    insert into wh1.orderdetail 
						    (
						    whseid,orderkey,
						    orderlinenumber,
						    externorderkey,
						    externlineno,
						    storerkey,sku,
						    packkey,LOTTABLE02,LOTTABLE04,LOTTABLE05,lottable06,NOTES,
						    openqty,originalqty,uom,allocatestrategykey,     
						    preallocatestrategykey,allocatestrategytype,cartongroup						    
						    ) 
						    select  'WH1' as whseid,@orderkey,
							    REPLICATE('0',5 - LEN(dod.id)) + CAST(dod.id as varchar(10)) as orderlinenumber,
							    dod.externorderkey, 
							    REPLICATE('0',5 - LEN(dod.id)) + CAST(dod.id as varchar(10)) as externlineno,
							    dod.storerkey,dod.sku, 
							    s.packkey,dod.LOTTABLE02,dod.LOTTABLE04,dod.LOTTABLE05,dod.LOTTABLE06 as LOTTABLE06,	dod.LOTTABLE06_A as notes,				   
							    dod.qtyexpected,dod.qtyexpected, 
							    'EA', 
							    --st.allocatestrategykey, 
							    --case when @susr1 not in ('СкладПродаж','СД') then 'STD55' else st.allocatestrategykey end as allocatestrategykey,
							    sr.strategy as allocatestrategykey, --Правка Шевелев 16.03.2015
							    st.preallocatestrategykey, 
							    ast.allocatestrategytype, 
							    s.cartongroup							    
						    from    #DA_ShipmentOrderDetail dod							
							    join wh1.sku s 						on s.sku = dod.sku and s.storerkey = dod.storerkey
							    join wh1.strategy st 				on s.strategykey = st.strategykey 
							    join wh1.allocatestrategy ast 		on ast.allocatestrategykey = st.allocatestrategykey
							    join dbo.stdrezerv sr				on sr.sklad=@susr1 --Правка Шевелев 16.03.2015
						    where   dod.externorderkey = @externorderkey
														
						    if @@rowcount = 0
						    begin
							    set @msg_errdetails = @msg_errdetails+'er#021ORDER. EXTERNORDERkey=*'+@externorderkey+'*. Неудалось выполнить вставку строк документа, либо нет строк.'+char(10)+char(13)
							    set @send_error = 1
						    end	
						    else 
						    begin
							    print 'обрабатываем загрузки'
							    
							    select  @shipdate = REQUESTEDSHIPDATE,
								   -- @loaddate = REQUESTEDSHIPDATE, 
								    @susr4 = susr4, 
								    @consigneekey = CONSIGNEEKEY, 
								    @adddate = GETDATE()  
							    from    #DA_ShipmentOrderHead 
							    
							    
							    set @loaddate = convert(datetime,convert(int,@shipdate))
							    set @dayweek = /*case*/ DATEPART (dw,  @loaddate) 
										    --when 1 then 7
										    --when 2 then 1
										    --when 3 then 2
										    --when 4 then 3
										    --when 5 then 4
										    --when 6 then 5
										    --when 7 then 6
							       --            end
							                   
							    print 'Маршрут '+@susr4
							    														
							    if @susr4 != ''
							    begin -- маршрут заполнен, работаем с загрузками
                                                                        										
								print 'выбираем ближайшую дату загрузки'
								
								if exists(select * from loadgroup lg where ROUTEID = @susr4)
								begin
									while 
									(
									select	COUNT (serialkey)
									from	loadgroup lg
									where	ROUTEID = @susr4
										and case @dayweek	
											when 1 then @loaddate +lg.[1]
											when 2 then @loaddate +lg.[2]
											when 3 then @loaddate +lg.[3]
											when 4 then @loaddate +lg.[4]
											when 5 then @loaddate +lg.[5]
											when 6 then @loaddate +lg.[6]
											when 7 then @loaddate +lg.[7]
										    end > @shipdate 
										    and
											case @dayweek	
												when 1 then dateadd(hh,-lg.[10],@loaddate +lg.[1])
												when 2 then dateadd(hh,-lg.[20],@loaddate +lg.[2])
												when 3 then dateadd(hh,-lg.[30],@loaddate +lg.[3])
												when 4 then dateadd(hh,-lg.[40],@loaddate +lg.[4])
												when 5 then dateadd(hh,-lg.[50],@loaddate +lg.[5])
												when 6 then dateadd(hh,-lg.[60],@loaddate +lg.[6])
												when 7 then dateadd(hh,-lg.[70],@loaddate +lg.[7])
											end > @adddate	
									) = 0
									begin
										set @loaddate = dateadd(dd,1,@loaddate)
										set @dayweek = /*case*/ DATEPART (dw, @loaddate) 
												--    when 1 then 7
												--    when 2 then 1
												--    when 3 then 2
												--    when 4 then 3
												--    when 5 then 4
												--    when 6 then 5
												--    when 7 then 6
												--end
									end		

									select  @loaddate = @loaddate +
										case @dayweek	
											when 1 then lg.[1]
											when 2 then lg.[2]
											when 3 then lg.[3]
											when 4 then lg.[4]
											when 5 then lg.[5]
											when 6 then lg.[6]
											when 7 then lg.[7]
											end		
									from loadgroup lg
									where ROUTEID = @susr4
                                            		
									select	@loadid = loadid 
									from	wh1.LOADHDR
									where	[ROUTE] = @susr4 and [STATUS] != '9' 
										and DEPARTURETIME = @loaddate
                                            										
								end							
								else
								begin -- маршрут не регулярный
									select	@loadid = loadid 
									from	wh1.LOADHDR
									where	[ROUTE] = @susr4 
										and [STATUS] != '9' 
										and @adddate < dateadd(hh,-@deadtime,DEPARTURETIME)
                                                                        	
								end					
							    end
							    
							    print 'Лоад ид '+@loadid
            						
							    if isnull(@loadid,'') = '' 
							    begin --создаем загрузку
								    print ' получаем новый номер загрузки'
								    
								    exec dbo.DA_GetNewKey 'wh1','CARTONID',@loadid output
								    	
								    print '6.1.1. добавляем шапку загрузки'											
								    
								    insert wh1.loadhdr 
								    (whseid,loadid, externalid,[route],[status],DEPARTURETIME,door)
								    
								    select 'WH1',@loadid,@carriercode, @susr4, '0',@loaddate, 'VOROTA2'
								    
								    if @@rowcount = 0
								    begin
									    set @msg_errdetails = @msg_errdetails+'er#022ORDER. EXTERNORDERkey=*'+@externorderkey+'*. Неудалось выполнить вставку шапки загрузки.'+char(10)+char(13)
									    set @send_error = 1
								    end
								    else
								    BEGIN
								    	
								    	    print ' получаем новый номер стопа в загрузке'
								    
									    exec dbo.DA_GetNewKey 'wh1','LOADSTOPID',@loadstopid output
        								    
									    print '6.1.2. добавляем СТОП в загрузку'
        								    
									    insert wh1.loadstop (whseid,loadid,loadstopid,[stop],[status])
									    
									    select  'WH1',@loadid,@loadstopid,1,'0'											
        								    
									    if @@rowcount = 0
									    begin
										    set @msg_errdetails = @msg_errdetails+'er#023ORDER. EXTERNORDERkey=*'+@externorderkey+'*. Неудалось выполнить вставку СТОПа в загрузку.'+char(10)+char(13)
										    set @send_error = 1
									    end	  
								    	
								    END	
							    end
							    else
							    begin --загрузка существует
								    select  @loadstopid = loadstopid 
								    from    wh1.LOADSTOP
								    where   LOADID = @loadid
								    
								    if @loadstopid is null
								    begin
									    print ' получаем новый номер стопа в загрузке'
									    
									    exec dbo.DA_GetNewKey 'wh1','LOADSTOPID',@loadstopid output								
									    
									    print '6.1.2. добавляем СТОП в загрузку'
									    
									    insert wh1.loadstop (whseid,loadid,loadstopid,[stop],[status])
									    select 'WH1', @loadid, @loadstopid,1,'0'	
								    end													
							    end

							    print '6.2. добавляем заказ на отгрузку в загрузку'
        							
							    exec dbo.DA_GetNewKey 'wh1','LOADORDERDETAILID',@loadorderdetailid output
        								
							    insert wh1.loadorderdetail 
							    (whseid,loadstopid,loadorderdetailid,storer, 
							    shipmentorderid, customer, OHTYPE)
        							
							    select 'WH1',@loadstopid,@loadorderdetailid,@storerkey,@orderkey,@consigneekey, '1'
        							
							    if @@rowcount = 0
							    begin
								    set @msg_errdetails = @msg_errdetails+'er#024ORDER. EXTERNORDERkey=*'+@externorderkey+'*. Неудалось выполнить вставку ЗАКАЗа в СТОП.'+char(10)+char(13)
								    set @send_error = 1
							    end	
							    else
							    begin -- заказ вставлен, обновляем заказ.
							    
								    update o 
								    set o.loadid = @loadid, 
									o.door = isnull(lg.LOCEXPEDITION,''), 
									o.stop = '1', 
									o.route = o.SUSR4
								    from    wh1.ORDERS o 
									    left join loadgroup lg 
										on o.SUSR4 = lg.ROUTEID
								    where   o.ORDERKEY = @orderkey
        								 
							    end										
            								
            							
						    end
					    	
					    	
					    END
					    
					
					end						
        				
				end			
				else
				begin
					print ' в строках документов обнаружены ошибки'
					print @msg_errdetails
				end
			end
			else
			begin
				print ' контроль входных данных не пройден'
				set @msg_errdetails = @msg_errdetails1 + @msg_errdetails
				set	@send_error = 1
				print @msg_errdetails
			end
			
			print ' удаление обработанных данных'
			delete from do
				from DA_ShipmentOrderHead do join #DA_ShipmentOrderHead o on (do.externorderkey = o.externorderkey) or (do.id = o.id)
			delete do
				from DA_ShipmentOrderDetail do join #DA_ShipmentOrderHead o on do.externorderkey = o.externorderkey
			
			--drop table #DA_ShipmentOrderHead
			--drop table #DA_ShipmentOrderDetail
			--drop table #id
		end
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
		
		update	s
		set	status = '15',
			error = @msg_errdetails
		from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpOutputOrderLinesToWMS s
			join #DA_ShipmentOrderHead d
			    on d.externorderkey = s.DocId
		where	s.status = '5'
		
		
		update	s
		set	status = '15',
			error = @msg_errdetails
		from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpOutputOrdersToWMS s
			join #DA_ShipmentOrderHead d
				on d.externorderkey = s.DocId				
		where	s.status = '5'
		
	--*************************************************************************

		update	s
		set	status = '15',
			error = @msg_errdetails
		from	[SQL-dev].[PRD2].[dbo].DA_ShipmentOrderHead_archive s
			join #DA_ShipmentOrderHead d
			    on d.externorderkey = s.externorderkey			
		where	s.status = '5'		
		
		update	s
		set	status = '15',
			error = @msg_errdetails
		from	[SQL-dev].[PRD2].[dbo].DA_ShipmentOrderDetail_archive s
			join #DA_ShipmentOrderHead d
			    on d.externorderkey = s.externorderkey				
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
		
		update	s
		set	status = '10'
		from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpOutputOrderLinesToWMS s
			join #DA_ShipmentOrderHead d
			    on d.externorderkey = s.DocId
		where	s.status = '5'
		
		
		update	s
		set	status = '10'
		from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpOutputOrdersToWMS s
			join #DA_ShipmentOrderHead d
				on d.externorderkey = s.DocId				
		where	s.status = '5'
		
	--*************************************************************************

		update	s
		set	status = '10'
		from	[SQL-dev].[PRD2].[dbo].DA_ShipmentOrderHead_archive s
			join #DA_ShipmentOrderHead d
			    on d.externorderkey = s.externorderkey			
		where	s.status = '5'		
		
		update	s
		set	status = '10'
		from	[SQL-dev].[PRD2].[dbo].DA_ShipmentOrderDetail_archive s
			join #DA_ShipmentOrderHead d
			    on d.externorderkey = s.externorderkey				
		where	s.status = '5'	


	end



end



IF OBJECT_ID('tempdb..#DA_ShipmentOrderHead') IS NOT NULL DROP TABLE #DA_ShipmentOrderHead
IF OBJECT_ID('tempdb..#DA_ShipmentOrderDetail') IS NOT NULL DROP TABLE #DA_ShipmentOrderDetail
IF OBJECT_ID('tempdb..#id') IS NOT NULL DROP TABLE #id

