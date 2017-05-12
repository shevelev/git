



 --------ЗО --
ALTER PROCEDURE [dbo].[proc_DA_ShipmentOrder]
	@source varchar(500) = null
as  

--select * from DA_ShipmentOrderHead
--select * from DA_ShipmentOrderdetail
--delete from DA_ShipmentOrderHead
--delete from DA_ShipmentOrderdetail
--set dateformat mdy

--declare @source varchar(500)

declare @allowUpdate int
declare @send_error bit
declare @msg_errdetails varchar(max)
declare @msg_errdetails1 varchar(max)
declare @enter varchar(10) 
declare @storerkey varchar(15)
declare @sku varchar(15)
declare @externorderkey varchar(20)
declare @id int
declare @susr4 varchar (30)
declare @orderkey varchar (15)
declare @consigneekey varchar (15)
declare @carriercode varchar (15)

declare
		@Load varchar (10), -- необходимость формирования загрузок
		@loadid varchar (10), -- номер загрузки
		@loadstopid int, -- идентификатор стопа (остановки маршрута) в загрузке
		@loadorderdetailid int -- идентификатор строки с заказом в загрузке

declare @loaddate datetime set @loaddate = null
declare @shipdate datetime set @shipdate = null
declare @adddate datetime set @adddate = null
declare @deadtime int -- время дедлайна для нестабильных маршрутов
declare @dayweek int

set @send_error = 0
set @msg_errdetails = ''
set @enter = char(10)+char(13)
set @loadid = ''
select @deadtime = short from wh1.CODELKUP where LISTNAME = 'sysvar'and code = 'DLINESH'
declare @bs varchar(3) select @bs = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'
declare @bsanalit varchar(3) select @bsanalit = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'BSANALIT'


BEGIN TRY
--	select @allowUpdate = allowUpdate from dbo.DA_MessageTypes where MessageKey = 'ordercard'
	while (exists (select id from DA_ShipmentOrderHead))
		begin
			print ' выбираем запись из обменной таблицы da_receipt'
			select top(1) * into #DA_ShipmentOrderHead from DA_ShipmentOrderHead order by id desc
			
			print ' обновление NULL значений'
			update #DA_ShipmentOrderHead set
				storerkey = isnull(storerkey,''),
				externorderkey = isnull(externorderkey,''),
				[type] = isnull([type],''),
				SUSR1 = ISNULL(ltrim(rtrim(susr1)),''),
				SUSR2 = ISNULL(ltrim(rtrim(susr2)),''),
				susr3 = ISNULL(ltrim(rtrim(susr3)),''),
				susr4 = ISNULL(ltrim(rtrim(susr4)),''),
				susr5 = ISNULL(ltrim(rtrim(susr5)),''),
				consigneekey = isnull(ltrim(rtrim(consigneekey)),''),
				C_CITY = ISNULL(c_city,''),
				C_CONTACT1 = ISNULL(c_contact1,''),
				C_CONTACT2 = ISNULL(c_contact2,''),
				B_COMPANY = ISNULL(b_company,''),
				B_CITY = ISNULL(b_city,''),
				B_CONTACT1 = ISNULL(b_contact1,''),
				B_CONTACT2 = ISNULL(b_contact2,''),
				NOTES = ISNULL(notes,''),
				REQUESTEDSHIPDATE = case when isnull(REQUESTEDSHIPDATE,'') = '' OR ltrim(rtrim(REQUESTEDSHIPDATE)) = '' 
					then convert(varchar(20),GETDATE(),10)
					else right(left(REQUESTEDSHIPDATE,5),2)+right(LEFT(REQUESTEDSHIPDATE,3),1)+left(REQUESTEDSHIPDATE,2)+right(LEFT(REQUESTEDSHIPDATE,3),1)+right(REQUESTEDSHIPDATE,2) end
				--REQUESTEDSHIPDATE = ISNULL(REQUESTEDSHIPDATE,getdate())
				--CARRIERCODE = isnull(carriercode,''),
				--B_ADDRESS = ISNULL(b_address,''),
				--C_ADDRESS = ISNULL(c_address,''),
--				rma = isnull(rma,''),
				--priority = case when isnull(priority,'') = '' or priority not in ('1','2','3','4','5') then '5' else priority end
			
			set @msg_errdetails1 =''
			print ' проверка входных данных'
			select 
				@msg_errdetails1 = @msg_errdetails1 --externorderkey empty
					+case when ltrim(rtrim(o.externorderkey)) = ''
						then 'ORDER. externorderkey=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --externorderkey status != 0
					+case when (select wr.status from wh1.orders wr where wr.externorderkey = o.externorderkey) != '0' 
						then 'ORDER. externorderkey='+o.externorderkey+'. Документ в обработке, обновление невозможно.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --storerkey EMPTY
					+case when ltrim(rtrim(o.storerkey)) = ''
						then 'ORDER. externorderkey='+o.externorderkey+'. STORERkey=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --storerkey in STORER
					+case when (not exists(select s.* from wh1.storer s where s.storerkey = o.storerkey))
						then 'ORDER. externorderkey='+o.externorderkey+'. STORERkey='+o.storerkey+' отсутвует в справочнике STORER.'+@enter
						else ''
					end,
				--@msg_errdetails1 = @msg_errdetails1 --carriercode EMPTY
				--	+case when ltrim(rtrim(o.carriercode)) = ''
				--		then 'ORDER. CARRIERcode=empty.'+@enter
				--		else ''
				--	end,
				--@msg_errdetails1 = @msg_errdetails1 --carriercode in STORER
				--	+case when (not exists(select s.* from wh1.storer s where s.storerkey = o.carriercode))
				--		then 'ORDER. CARRIERcode='+o.carriercode+' отсутвует в справочнике STORER.'+@enter
				--		else ''
				--	end,
				@msg_errdetails1 = @msg_errdetails1 --type empty
					+case when ltrim(rtrim(o.type)) = ''
						then 'ORDER. externorderkey='+o.externorderkey+'. TYPEkey=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --type !=1 & !=101 & !=102
					+case when ltrim(rtrim(o.type)) != '1' and ltrim(rtrim(o.type)) != '101' and ltrim(rtrim(o.type)) != '102'
						then 'ORDER. externorderkey='+o.externorderkey+'. TYPEkey !=1 & !=101 & !=102'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --SUSR1 empty
					+case when ltrim(rtrim(o.susr1)) = ''
						then 'ORDER. externorderkey='+o.externorderkey+'. SUSR1=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --SUSR4 empty
					+case when ltrim(rtrim(o.susr4)) = '' and ltrim(rtrim(o.type)) != '101'
						then 'ORDER. externorderkey='+o.externorderkey+'. SUSR4=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --consigneekey empty
					+case when ltrim(rtrim(o.consigneekey)) = '' and ltrim(rtrim(o.type)) != '101'
						then 'ORDER. externorderkey='+o.externorderkey+'. CONSIGNEEkey=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --consigneekey in STORER
					+case when ltrim(rtrim(o.type)) = '101' 
						then '' 
						else 
							case when (not exists(select s.* from wh1.storer s where s.storerkey = o.consigneekey)) 
								then 'ORDER.externorderkey='+o.externorderkey+'. CONSIGNEEkey='+o.consigneekey+' отсутвует в справочнике STORER.'+@enter
								else ''
						end
					end,
				@msg_errdetails1 = @msg_errdetails1 --b_company empty
					+case when ltrim(rtrim(o.b_company)) = '' and ltrim(rtrim(o.type)) != '101'
						then 'ORDER. externorderkey='+o.externorderkey+'. b_company=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --b_company in STORER
					+case when ltrim(rtrim(o.type)) = '101'
						then ''
						else 
							case when (not exists(select s.* from wh1.storer s where s.storerkey = o.b_company))
								then 'ORDER. externorderkey='+o.externorderkey+'. b_company='+o.b_company+' отсутвует в справочнике STORER.'+@enter
								else ''
							end
					end					
--				@msg_errdetails1 = @msg_errdetails1 --RMA 
--					+case when ltrim(rtrim(o.rma)) = ''
--						then 'ORDER. externorderkey='+o.externorderkey+'. RMA=empty.'+@enter
--						else ''
--					end
			from #DA_ShipmentOrderHead o
			
			if (@msg_errdetails1 = '')
				begin
					print ' проверка на уникальность документов в обменной таблице'
					if ((select count (o.externorderkey) from DA_ShipmentOrderHead o join #DA_ShipmentOrderHead do on o.externorderkey = do.externorderkey) != 1)
						set @msg_errdetails1 = 'ORDER. externorderkey='+(select externorderkey from #DA_ShipmentOrderHead)+'. Не уникальный документ в обменной таблице.'+@enter
				end

			if (@msg_errdetails1 = '') 
				begin
					print ' контроль входных данных шапки документа пройден успешно'
					print ' выбираем externorderkey'
					select @storerkey = storerkey, @externorderkey = externorderkey from #DA_ShipmentOrderHead
					print ' выбираем детали документа'
						select do.* into #DA_ShipmentOrderDetail 
							from DA_ShipmentOrderDetail do join #DA_ShipmentOrderHead o on do.externorderkey = o.externorderkey 
							where o.externorderkey = @externorderkey
					
	
					print ' обновление NULL значений в деталях документа'
					update #DA_ShipmentOrderDetail set
						storerkey = isnull(storerkey,''),
						externorderkey = isnull(externorderkey,''),
						sku = isnull(sku,''),
						PACKKEY = ISNULL(PACKKEY,''),
						--attribute02 = case when ISNULL(attribute02,'') = '' then @bs else attribute02 end,
						attribute02 = case when ISNULL(attribute02,@bsanalit) = @bsanalit 
													or ISNULL(attribute02,@bs) = @bs 
														then '' else attribute02 end,
						--attribute04 = ISNULL(attribute04,''),
						--attribute05 = ISNULL(attribute05,''),
						--attribute04 = ISNULL(right(left(attribute04,5),2)+right(LEFT(attribute04,3),1)+left(attribute04,2)+right(LEFT(attribute04,3),1)+right(attribute04,2),null),
						ATTRIBUTE04 = case when ATTRIBUTE04 IS null  OR ltrim(rtrim(attribute04)) = ''
												then null 
												else right(left(attribute04,5),2)+right(LEFT(attribute04,3),1)+left(attribute04,2)+right(LEFT(attribute04,3),1)+right(attribute04,2)
												end,
						--attribute05 = ISNULL(right(left(attribute05,5),2)+right(LEFT(attribute05,3),1)+left(attribute05,2)+right(LEFT(attribute05,3),1)+right(attribute05,2),null),
						ATTRIBUTE05 = case when attribute05 IS null OR ltrim(rtrim(attribute05)) = ''
												then null
												else right(left(attribute05,5),2)+right(LEFT(attribute05,3),1)+left(attribute05,2)+right(LEFT(attribute05,3),1)+right(attribute05,2)
												end,
						openqty = isnull(openqty,0),
						unitprice = isnull(unitprice,0),
						extendedprice = isnull(unitprice,0),
						tax01 = isnull(tax01,0),
						tax02 = isnull(tax02,0),
						externlineno = case when isnull(externlineno,'') = '' then '' else right('00000'+externlineno,5) end
						--externlineno_2 = case when isnull(externlineno_2,'') = '' then '' else externlineno_2 end,

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
										+case when ltrim(rtrim(od.storerkey)) = ''
											then 'ORDER. STORERkey=empty'+@enter
											else ''
										end,
									@msg_errdetails1 = @msg_errdetails1 --storer in STORER
										+case when (not exists(select s.* from wh1.storer s where s.storerkey = od.storerkey))
											then 'ORDER. EXTERNORDERkey='+od.externorderkey+'. STORER отсутвует в справочнике STORER.'+@enter
											else ''
										end,
									@msg_errdetails1 = @msg_errdetails1 --extrnorderkey
										+case when ltrim(rtrim(od.externorderkey)) = ''
											then 'ORDER. EXTERNLINENO=empty.'+@enter
											else ''
										end,
									@msg_errdetails1 = @msg_errdetails1 --sku=empty
										+case when (od.sku = '')
											then 'ORDER. EXTERNORDERkey='+od.storerkey+', SKU=empty'+@enter
											else ''
										end,
									@msg_errdetails1 = @msg_errdetails1 --storer+sku in SKU
										+case when (not exists(select s.* from wh1.sku s where s.storerkey = od.storerkey and s.sku = od.sku))
											then 'ORDER. EXTERNORDERkey='+od.externorderkey+'. SKU='+od.sku+'. SKU+STORER отсутвует в справочнике SKU.'+@enter
											else ''
										end,
									@msg_errdetails1 = @msg_errdetails1 --openqty
										+case when (od.openqty <= 0)
											then 'ORDER. EXTERNORDERkey='+od.storerkey+'. Не корректное значение OPENQTY.'+@enter
											else ''
										end
									--@msg_errdetails1 = @msg_errdetails1 --price
									--	+case when (od.UNITPRICE < 0)
									--		then 'ORDER. EXTERNORDERkey='+od.storerkey+', EXTERNLINENO='+od.externlineno+'. Не корректное значение unitprice.'+@enter
									--		else ''
									--	end,
									--@msg_errdetails1 = @msg_errdetails1 --tax01
									--	+case when (od.TAX01 < 0)
									--		then 'ORDER. EXTERNORDERkey='+od.storerkey+', EXTERNLINENO='+od.externlineno+'. Не корректное значение tax01.'+@enter
									--		else ''
									--	end,
									--@msg_errdetails1 = @msg_errdetails1 --openqty
									--	+case when (od.openqty <= 0)
									--		then 'ORDER. EXTERNORDERkey='+od.externorderkey+', EXTERNLINENO='+od.externlineno+'. Не корректное значение openqty.'+@enter
									--		else ''
									--	end,
									--@msg_errdetails1 = @msg_errdetails1 --storer in STORER
									--	+case when (not exists(select s.* from wh1.storer s where s.storerkey = od.storerkey))
									--		then 'ORDER. EXTERNORDERkey='+od.externorderkey+', EXTERNLINENO='+od.externlineno+'. STORER отсутвует в справочнике STORER.'+@enter
									--		else ''
									--	end
									--@msg_errdetails1 = @msg_errdetails1 --stage in DA_HostZones
									--	+case when (not exists(select s.* from da_hostzones s where s.hostzone = od.stage))
									--		then 'ORDER. EXTERNORDERkey='+od.externorderkey+', EXTERNLINENO='+od.externlineno+'. Stage отсутвует в справочнике DA_Hostzones.'+@enter
									--		else ''
									--	end,
									--@msg_errdetails1 = @msg_errdetails1 --RMA 
									--	+case when ltrim(rtrim(od.rma)) = ''
									--		then 'ORDER. EXTERNORDERkey='+od.externorderkey+'. RMA=empty.'+@enter
									--		else ''
									--	end,
									--@msg_errdetails1 = @msg_errdetails1 --sku in SKUxSTORER
									--	+case when (not exists(select s.* from wh1.sku s where s.sku = od.sku and s.storerkey = od.storerkey))
									--		then 'ORDER. EXTERNORDERkey='+od.storerkey+', EXTERNLINENO='+od.externlineno+'. SKU='+od.sku+' отсутвует в справочнике SKU со значем STORER='+od.storerkey+'.'+@enter
									--		else ''
									--	end
										from #DA_ShipmentOrderDetail od join #DA_ShipmentOrderHead o on od.externorderkey = o.externorderkey where od.id = @id

								if @msg_errdetails1 != ''
									begin
										print ' ошибка в строке документа'
										set @msg_errdetails = @msg_errdetails + 'Ошибки в строке документа. '+@externorderkey+@enter+@msg_errdetails1
										set @send_error = 1
									end
--							if (exists(select * 
--										from #DA_ShipmentOrderDetail od join #DA_ShipmentOrderHead o on od.externorderkey = o.externorderkey
--										where
--											od.id = @id and
--											(od.price < 0
--											or od.externorderkey = ''
--											or od.externlineno = ''
--											or od.sku = ''
--											or (exists (select * from wh1.sku where sku = od.sku and storerkey = o.storerkey))
--											or od.originalqty = 0)))
--								begin
--									print ' ошибка в строке документа'
--									set @msg_errdetails = @msg_errdetails + 'ORDER. externorderkey='+@externorderkey+', externlineno='+(select externlineno from #DA_ShipmentOrderDetail where id = @id)+'. Ошибка в строке документа.'+@enter
--									set @send_error = 1
--								end
							delete from #id where id = @id
						end

					print ' проверяем, существует ли документ с номером ' + @externorderkey
						if (exists(select * from wh1.orders where externorderkey = @externorderkey))
								begin
									print ' документ существует, обновления запрещены логикой системы'
									set @msg_errdetails = @msg_errdetails + 'ORDER. externorderkey='+@externorderkey+'. Документ существует в базе, обновления запрещены.'+@enter
									set @send_error = 1
								end
					if @msg_errdetails = '' and exists (select * from #DA_ShipmentOrderHead)
						begin
--							print ' удаляем строки существующего документа (если есть)'
--							delete from od
--								from wh1.orderdetail od join #DA_ShipmentOrderHead o on od.externreceipkey = o.externreceiptkey
--							print ' удаляем шапку существующего документа (если есть)'
--							delete dr
--								from wh1.orders do join #DA_ShipmentOrderHead o on do.externorderkey = o.externorderkey
							print ' получаем новый номер документа'
							exec dbo.DA_GetNewKey 'WH1','order',@orderkey output

							print ' вставляем шапку документа'
							insert into wh1.orders 
										(whseid,				orderkey,  storerkey,	externorderkey,		[type], SUSR1,	SUSR2,		SUSR3, SUSR4,	SUSR5, consigneekey,	/*			C_ADDRESS1,					C_ADDRESS2,					 C_ADDRESS3,					C_ADDRESS4,*/		 c_city, C_CONTACT1,	 C_CONTACT2, b_company,		/*			B_ADDRESS1,					B_ADDRESS2,						B_ADDRESS3,					B_ADDRESS4,	*/	B_CITY, B_CONTACT1,	 B_CONTACT2,		NOTES,	 REQUESTEDSHIPDATE/*, CarrierCode susr5, susr1,  priority, susr3*/,transportationmode )--, door) /* susr3 - номер склада */
								select	top (1) 'WH1' whseid,  @orderkey, o.storerkey, o.externorderkey, o.[type], o.susr1, o.susr2, o.susr3, o.susr4, o.susr5, o.consigneekey, /*substring(C_ADDRESS,0, 45), substring(C_ADDRESS,45, 45), substring(C_ADDRESS,90, 45), substring(C_ADDRESS,135, 45),*/ o.c_city, o.c_contact1, o.C_CONTACT2, o.b_company, /*substring(b_ADDRESS,0, 45), substring(C_ADDRESS,45, 45), substring(C_ADDRESS,90, 45), substring(C_ADDRESS,135, 45),*/ o.B_CITY, o.B_CONTACT1, o.B_CONTACT2, o.notes, o.REQUESTEDSHIPDATE/*, o.CARRIERCODE   .orderdate, o.rma, null, o.priority, dod.stage--, 'DOCK'*/,'0'
								from #DA_ShipmentOrderHead o --join wh1.storer s on o.consigneekey = s.storerkey
												join #DA_ShipmentOrderDetail dod on o.externorderkey = dod.externorderkey
							if @@rowcount = 0 
								begin
									set @msg_errdetails = @msg_errdetails+'ORDER. EXTERNORDERkey='+@externorderkey+'. Неудалось выполнить вставку записи (шапка документа).'+char(10)+char(13)
									set @send_error = 1
								end	
							print ' вставляем строки документа'
							insert into wh1.orderdetail 
								(
									whseid,	 
									orderkey, 
									orderlinenumber, 
									externorderkey,     
									externlineno,					
									storerkey,     
									sku, 
									packkey, 
									LOTTABLE01,
									LOTTABLE02,
									lottable03,
									LOTTABLE04,
									LOTTABLE05,
									lottable07, --брак
									lottable08,
									openqty,				
									unitprice, 
									extendedprice, 
									TAX01,
									TAX02,
									originalqty,     
									uom,     
									allocatestrategykey,     
									preallocatestrategykey,     
									allocatestrategytype,     
									cartongroup   
									--lottable03, 
									--susr4, 
									--lottable10
								) /*susr1 - еще один номер строки смаркет*/
								select 
									'WH1' whseid, 
									@orderkey, 
									dod.externlineno, 
									dod.externorderkey, 
									dod.externlineno, 
									dod.storerkey, 
									dod.sku, 
									dod.packkey, 
									'',--case when dod.attribute02 = '' then '' else dod.packkey end,
									--case when dod.attribute02 != @bs then '' else dod.packkey end, 
									dod.attribute02,
									'OK',
									--case when dod.attribute02 != @bs then '' else dod.attribute04 end,
									--case when dod.attribute02 != @bs then '' else dod.attribute05 end,
									--case when dod.attribute02 = '' then null else 
									dod.attribute04,-- end,
									--case when dod.attribute02 = '' then null else 
									dod.attribute05,-- end,
									--case when do.type = '101' then 'BRAK' else 'OK' end,
									'OK',
									'OK',
									dod.OPENQTY, 
									dod.UNITPRICE, 
									dod.extendedPRICE, 
									dod.TAX01,
									dod.TAX02,
									dod.OPENQTY, 
									'EA', 
									st.allocatestrategykey, 
									st.preallocatestrategykey, 
									ast.allocatestrategytype, 
									s.cartongroup
									--dod.stage, 
									--dod.rma, 
									--'std'
								from #DA_ShipmentOrderHead do 
										join #DA_ShipmentOrderDetail dod on do.externorderkey = dod.externorderkey
										join wh1.sku s on s.sku = dod.sku and s.storerkey = do.storerkey
										join wh1.strategy st on s.strategykey = st.strategykey 
										join wh1.allocatestrategy ast on ast.allocatestrategykey = st.allocatestrategykey						
							if @@rowcount = 0
								begin
									set @msg_errdetails = @msg_errdetails+'ORDER. EXTERNORDERkey='+@externorderkey+'. Неудалось выполнить вставку строк документа, либо нет строк.'+char(10)+char(13)
									set @send_error = 1
								end	
							else 
								begin
									print 'обрабатываем загрузки'
									select @shipdate = REQUESTEDSHIPDATE, @susr4 = susr4, @consigneekey = CONSIGNEEKEY, @adddate = GETDATE()  from #DA_ShipmentOrderHead 
									set @loaddate = convert(datetime,convert(varchar(10),@shipdate,101))
									set @dayweek = case DATEPART (dw,  @loaddate) 
														when 1 then 7
														when 2 then 1
														when 3 then 2
														when 4 then 3
														when 5 then 4
														when 6 then 5
														when 7 then 6
														end
									if @susr4 != ''
										begin -- маршрут заполнен, работаем с загрузками
										
print 'выбираем ближайшую дату загрузки'
if exists(select * from loadgroup lg where ROUTEID = @susr4)
	begin
		while 
		(
		select COUNT (serialkey)
		from loadgroup lg
		where ROUTEID = @susr4
		and
		case @dayweek	
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
				set @dayweek = case DATEPART (dw, @loaddate) 
									when 1 then 7
									when 2 then 1
									when 3 then 2
									when 4 then 3
									when 5 then 4
									when 6 then 5
									when 7 then 6
								end
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
			
			select @loadid = loadid from wh1.LOADHDR
				where [ROUTE] = @susr4 and [STATUS] != '9' and DEPARTURETIME = @loaddate
											
	end							
else
	begin -- маршрут не регулярный
		select @loadid = loadid from wh1.LOADHDR
			where [ROUTE] = @susr4 and [STATUS] != '9' --and DEPARTURETIME =  @shipdate
				and @adddate < dateadd(hh,-@deadtime,DEPARTURETIME)

	
	end									
		
											if isnull(@loadid,'') = '' 
												begin --создаем загрузку
													print ' получаем новый номер загрузки'
													exec dbo.DA_GetNewKey 'wh1','CARTONID',@loadid output	
													print '6.1.1. добавляем шапку загрузки'											
													insert wh1.loadhdr (whseid,  loadid, externalid, [route], [status], DEPARTURETIME,  door/*,    carrierid,             trailerid*/)
													select           'WH1', @loadid, @carriercode, @susr4, '0',@loaddate, 'VOROTA2'/*, @carriercode,       '', left(@carriername, 10 )*/
													if @@rowcount = 0
														begin
															set @msg_errdetails = @msg_errdetails+'ORDER. EXTERNORDERkey='+@externorderkey+'. Неудалось выполнить вставку шапки загрузки.'+char(10)+char(13)
															set @send_error = 1
														end	
													print ' получаем новый номер стопа в загрузке'
													exec dbo.DA_GetNewKey 'wh1','LOADSTOPID',@loadstopid output
													
													print '6.1.2. добавляем СТОП в загрузку'
													insert wh1.loadstop (whseid,  loadid,  loadstopid,  [stop], [status])
														select            'WH1', @loadid, @loadstopid, 1,    '0'											
													if @@rowcount = 0
														begin
															set @msg_errdetails = @msg_errdetails+'ORDER. EXTERNORDERkey='+@externorderkey+'. Неудалось выполнить вставку СТОПа в загрузку.'+char(10)+char(13)
															set @send_error = 1
														end												
														
												end
											else
												begin --загрузка существует
													select @loadstopid = loadstopid from wh1.LOADSTOP where LOADID = @loadid
													if @loadstopid is null
														begin
															print ' получаем новый номер стопа в загрузке'
															exec dbo.DA_GetNewKey 'wh1','LOADSTOPID',@loadstopid output								
														end
												end

											print '6.2. добавляем заказ на отгрузку в загрузку'
											exec dbo.DA_GetNewKey 'wh1','LOADORDERDETAILID',@loadorderdetailid output	
											insert wh1.loadorderdetail (whseid, loadstopid, loadorderdetailid, storer, shipmentorderid, customer, OHTYPE)
											select 'WH1', @loadstopid, @loadorderdetailid, @storerkey, @orderkey, @consigneekey, '1'
											if @@rowcount = 0
												begin
													set @msg_errdetails = @msg_errdetails+'ORDER. EXTERNORDERkey='+@externorderkey+'. Неудалось выполнить вставку ЗАКАЗа в СТОП.'+char(10)+char(13)
													set @send_error = 1
												end	
											else
												begin -- заказ вставлен, обновляем заказ.
												update o set o.loadid = @loadid, o.door = isnull(lg.LOCEXPEDITION,''), 
														o.stop = '1', o.route = o.SUSR4
													from wh1.ORDERS o left join loadgroup lg on o.SUSR4 = lg.ROUTEID
													where o.ORDERKEY = @orderkey
												 
												end										
											
										end
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
	
	set @error_message  = ERROR_MESSAGE()--+isnull(@loadid,'null')+'-'+isnull(@loadstopid,'null')
	set @error_severity = ERROR_SEVERITY()
	set @error_state    = ERROR_STATE()

	set @send_error = 0
	raiserror (@error_message, @error_severity, @error_state)
END CATCH

if @send_error = 1
	begin
		print 'отправляем сообщение об ошибке по почте'
		print @msg_errdetails
		insert into DA_InboundErrorsLog (source,msg_errdetails) values (@source,@msg_errdetails)
		exec app_DA_SendMail @source, @msg_errdetails
	end





