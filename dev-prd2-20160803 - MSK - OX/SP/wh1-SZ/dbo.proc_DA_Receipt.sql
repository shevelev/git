


-- ПУО --
ALTER PROCEDURE [dbo].[proc_DA_Receipt]
	@source varchar(500) = null
as  
----select * from da_receipt
----select * from da_receiptdetail

--select * from #da_receipt

--declare @source varchar(500)
declare @allowUpdate int
declare @send_error bit
declare @msg_errdetails varchar(max)
declare @msg_errdetails1 varchar(max)
declare @enter varchar(10) 
declare @storerkey varchar(15)
declare @sku varchar(15)
declare @externreceiptkey varchar(20)
declare @id int
declare @receiptkey varchar (15)
declare @stage_count int

set @send_error = 0
set @msg_errdetails = ''
set @enter = char(10)+char(13)

BEGIN TRY
--	print ' определяем возможность обновления ПУО'
--	select @allowUpdate = allowUpdate from dbo.DA_MessageTypes where MessageKey = 'SkuCard'
	while (exists (select id from da_receipt))
		begin
			print ' выбираем запись из обменной таблицы da_receipt'
			select top(1) *, '                                             ' carriername into #da_receipt from da_receipt order by id desc
			
			print ' обновление NULL значений'
			update #da_receipt set
				storerkey = isnull(storerkey,''),
				rma = isnull(rma,''),
				externreceiptkey = isnull(externreceiptkey,''),
				receiptdate = isnull(receiptdate,'1900-01-01 00:00:01'),
				[type] = isnull([type],''),
				vendor = isnull(vendor,'')

			set @msg_errdetails1 =''
			print ' проверка входных данных'
			select 
				@msg_errdetails1 = @msg_errdetails1 --storerkey EMPTY
					+case when ltrim(rtrim(r.storerkey)) = ''
						then 'RECEIPT. STORERkey=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --storerkey in STORER
					+case when (not exists(select s.* from wh1.storer s where s.storerkey = r.storerkey))
						then 'RECEIPT. STORERkey='+r.storerkey+' отсутвует в справочнике STORER.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --vendor in STORER
					+case when (not exists(select s.* from wh1.storer s where s.storerkey = r.vendor))
						then 'RECEIPT. VENDORkey='+r.storerkey+' отсутвует в справочнике STORER.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --rma empty
					+case when ltrim(rtrim(r.rma)) = ''
						then 'RECEIPT. RMA=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --externreceiptkey empty
					+case when ltrim(rtrim(r.externreceiptkey)) = ''
						then 'RECEIPT. externreceiptkey=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --externreceiptkey status != 0
					+case when (select r.status from wh1.receipt r join #da_receipt dr on dr.externreceiptkey = r.externreceiptkey) != '0' 
						then 'RECEIPT. externreceiptkey='+r.externreceiptkey+'. Документ в обработке, обновление невозможно.'+@enter
						else ''
					end
			from #da_receipt r

			print ' выбираем детали документа'
				select dr.* into #da_receiptdetail from da_receiptdetail dr join #da_receipt r on dr.externreceiptkey = r.externreceiptkey

			print ' обновляем наименование поставщика'		
			update r set r.carriername = left(isnull(s.company,''),44)
				from #da_receipt r join wh1.storer s on  r.vendor = s.storerkey

			print ' проверка на уникальность '
			if (select count(r.externreceiptkey) from da_receipt r join #da_receipt dr on r.externreceiptkey = dr.externreceiptkey) != 1
				set @msg_errdetails1 = 'RECEIPT. externreceiptkey='+(select externreceiptkey from #da_receipt)+'. Не уникальный документ в обменной таблице.'+@enter

			if (@msg_errdetails1 = '') 
				begin
					print ' контроль входных данных пройден успешно'
					print ' выбираем externreceiptkey'
					select @storerkey = storerkey, @externreceiptkey = externreceiptkey from #da_receipt
					
					print ' обновление NULL значений в деталях документа'
					update #da_receiptdetail set
						externreceiptkey = isnull(externreceiptkey,''),
						externlineno = case when isnull(externlineno,'') = '' then '' else right('00000'+externlineno,5) end,
						sku = isnull(sku,''),
						qtyexpected = isnull(qtyexpected,0),
						unitofmeasure_iso = isnull(unitofmeasure_iso,''),
						price = isnull(price,0),
						extendedprice = isnull(extendedprice, 0),
						stage = isnull(stage,'')
					print ' выбор идентификаторов строк'
					select id into #id from #da_receiptdetail
					print ' проверка строк документа'
/*
					select distinct stage,externreceiptkey into #stage from #da_receiptdetail
					select @stage_count=count(*) from #stage					
					if(@stage_count>1) 
						set @msg_errdetails1 = 'Разные склады в табличной части ПУО'+(select top 1 externreceiptkey from #stage)
					drop table #stage
*/
--select * from #da_receiptdetail
					while (exists (select * from #id))
						begin
							select @id = id from #id
							print ' строкаID='+cast(@id as varchar(10))+'.'

							select 
								@msg_errdetails1 = @msg_errdetails1 --extrnRECEIPTkey
									+case when ltrim(rtrim(rd.externRECEIPTkey)) = ''
										then 'RECEIPT. EXTERNRECEIPTkey='+rd.externRECEIPTkey+'. EXTERNLINENO=empty.'+@enter
										else ''
									end,
								@msg_errdetails1 = @msg_errdetails1 --storer null
									+case when rd.storerkey = ''
										then 'RECEIPT. EXTERNRECEIPTkey='+rd.externRECEIPTkey+', EXTERNLINENO='+rd.externlineno+'. STORER = null.'+@enter
										else ''
									end,
								@msg_errdetails1 = @msg_errdetails1 --storer in STORER
									+case when (not exists(select s.* from wh1.storer s where s.storerkey = rd.storerkey))
										then 'RECEIPT. EXTERNRECEIPTkey='+rd.externRECEIPTkey+', EXTERNLINENO='+rd.externlineno+'. STORER отсутвует в справочнике STORER.'+@enter
										else ''
									end,
								@msg_errdetails1 = @msg_errdetails1 --stage null
									+case when rd.stage = ''
										then 'RECEIPT. EXTERNRECEIPTkey='+rd.externRECEIPTkey+', EXTERNLINENO='+rd.externlineno+'. Stage = null.'+@enter
										else ''
									end,
								@msg_errdetails1 = @msg_errdetails1 --stage in DA_HostZones
									+case when (not exists(select s.* from da_hostzones s where s.hostzone = rd.stage))
										then 'RECEIPT. EXTERNRECEIPTkey='+rd.externreceiptkey+', EXTERNLINENO='+rd.externlineno+'. Stage отсутвует в справочнике DA_Hostzones.'+@enter
										else ''
									end,
								@msg_errdetails1 = @msg_errdetails1 --unitofmeasure_iso
									+case when rd.unitofmeasure_iso != 'PCE'
										then 'RECEIPT. EXTERNRECEIPTkey='+rd.externreceiptkey+', EXTERNLINENO='+rd.externlineno+'. rd.unitofmeasure_iso != ''PCE''.'+@enter
										else ''
									end,
								@msg_errdetails1 = @msg_errdetails1 --sku in SKUxSTORER
									+case when (not exists(select s.* from wh1.sku s where s.sku = rd.sku and s.storerkey = rd.storerkey))
										then 'RECEIPT. EXTERNRECEIPTkey='+rd.externreceiptkey+', EXTERNLINENO='+rd.externlineno+'. SKU='+rd.sku+' отсутвует в справочнике SKU со значем STORER='+rd.storerkey+'.'+@enter
										else ''
									end,
								@msg_errdetails1 = @msg_errdetails1 --qtyexpected = 0
									+case when rd.qtyexpected = 0
										then 'RECEIPT. EXTERNRECEIPTkey='+rd.externreceiptkey+', EXTERNLINENO='+rd.externlineno+'. Ожидаемое количество товара 0.'+@enter
										else ''
									end								
							from #da_receiptdetail rd join #da_receipt r on rd.externreceiptkey = r.externreceiptkey
							where rd.id = @id



--							if (exists(select * from #da_receiptdetail rd join #da_receipt r on rd.externreceiptkey = r.externreceiptkey
--										where
--											rd.id = @id and
--											(rd.externreceiptkey = ''
--											or rd.externlineno = ''
--											or rd.sku = ''
--											or (not exists (select * from da_hostzones where hostzone = rd.stage))
--											or rd.unitofmeasure_iso != 'PCE'
--											or (not exists (select * from wh1.sku where sku = rd.sku and storerkey = r.storerkey))
--											or rd.qtyexpected = 0)))
							if (@msg_errdetails1 != '')
								begin
									print ' ошибка в строке документа'
									set @msg_errdetails = @msg_errdetails + @msg_errdetails1
									set @send_error = 1
								end
							delete from #id where id = @id
						end

					if @msg_errdetails = '' 
						begin
							print ' удаляем строки существующего документа (если есть)'
							delete from rd
								from wh1.receiptdetail rd join #da_receipt d on rd.externreceiptkey = d.externreceiptkey
							print ' удаляем шапку существующего документа (если есть)'
							delete dr
								from wh1.receipt dr join #da_receipt d on dr.externreceiptkey = d.externreceiptkey
							print ' получаем новый номер документа'
							exec dbo.DA_GetNewKey 'wh1','receipt',@receiptkey output

							print ' вставляем шапку документа'
							insert into wh1.receipt
								(whseid,		receiptkey,     storerkey,     externreceiptkey, rma,    [type], receiptdate,   status, addwho, carrierkey, carriername, warehousereference)
							select top (1) 'WH1'whseid, @receiptkey, r.storerkey,		r.externreceiptkey,	r.rma,	r.[type], r.receiptdate,		 '0','dkadapter', r.vendor, r.carriername, drd.stage
								from #da_receipt r join #DA_ReceiptDetail drd on drd.externreceiptkey = r.externreceiptkey
							print ' вставляем строки документа'
							insert into wh1.ReceiptDetail
								(	whseid, 
									receiptkey,
									receiptlinenumber,     
									externreceiptkey,     
									externlineno,     
									storerkey,     
									sku,     
									qtyexpected,         
									packkey,            
									UOM,   
									toloc, 
									status, 
									unitprice, 
									extendedprice, 
									lottable02, 
									lottable03,
									lottable10
								)
							select
								'WH1' whseid, 
								@receiptkey, 
								drd.externlineno, 
								drd.externreceiptkey, 
								drd.externlineno, 
								drd.storerkey, 
								drd.sku, 
								drd.qtyexpected, 
								s.rfdefaultpack, 
								s.rfdefaultuom,  
								case stage
										when 'S001' then 'STAGE'
										when 'S200' then 'STAGE2'
										when 'S003' then 'BRAK'
										when 'S150' then 'TRANSIT'
										when 'S004' then 'NG'
										else 'STAGE'
								end,
								'0', 
								drd.price, 
								drd.extendedprice, 
								isnull(sxv.lottable02default,'') lottable02, 
								stage,
								'std'
							from 
								#DA_ReceiptDetail drd 
								join #DA_Receipt drh on drd.externreceiptkey = drh.externreceiptkey
								join wh1.sku s on s.sku = drd.sku and s.storerkey = drd.storerkey
								left join wh1.skuxvendor sxv on sxv.sku = drd.sku and sxv.storerkey = drd.storerkey and sxv.vendorkey = drh.vendor
						end
					else
						begin
							print ' в строках документов обнаружены ошибки'
						end

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
				from da_receipt dr join #da_receipt r on (dr.externreceiptkey = r.externreceiptkey) or (dr.id = r.id)
			delete dr
				from da_receiptdetail dr join #da_receipt r on dr.externreceiptkey = r.externreceiptkey
			drop table #da_receipt
			drop table #da_receiptdetail
		end
--			select rd.* into #da_receiptdetail from da_receiptdetail rd join #da_receipt r on rd.externreceiptkey = d.externreceiptkey
END TRY

BEGIN CATCH
	declare @error_message nvarchar(4000)
	declare @error_severity int
	declare @error_state int
	
	set @error_message  = ERROR_MESSAGE()
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



