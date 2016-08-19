ALTER PROCEDURE [dbo].[DA_SOAllocate] (
	--@wh varchar(10)	= NULL
	@source varchar(500) = null,
	@orderkey1 varchar(20) = ''
)
as

set nocount on

declare @status int set @status = 0
declare @bs varchar(3) select @bs = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'


declare @orderkey varchar(20)

declare @status_wait varchar(20) set @status_wait = 'ожид. запуск' -- запущенный на резервирование заказ, но еще не зарезервированный.
declare @status_repl varchar(20) set @status_repl = 'ожид.пополнение' -- заказ, для которого нет товара в зоне отбора
declare @status_nosku varchar(20) set @status_nosku = 'нет товаров' -- заказ, для которого нет товаров на остатках
declare @status_noorder varchar(20) set @status_noorder = 'пустой' -- в заказе нет позиций
declare @status_error varchar(20) set @status_error = 'ошибка подготовки' -- заказ, который невозможно заустить.
declare @status_run varchar(20) set @status_run = 'запущен' -- заказ запущен.
declare @status_timeout varchar(20) set @status_timeout = 'таймаут'

declare @departtime datetime 
	set @departTime = dateadd(hh,24,GETDATE())
	
	
if IsNull(@orderkey1,'') = ''
begin
	
	
	print 'выбираем заказы, которые не запущены и не зарезервированы'
	select o.*, lh.DEPARTURETIME 
	into #orders 
	from wh1.orders o 
		join wh1.LOADORDERDETAIL lo on o.ORDERKEY = lo.SHIPMENTORDERID
		join wh1.LOADSTOP ls on lo.LOADSTOPID = ls.LOADSTOPID
		join wh1.loadhdr lh on ls.loadid = lh.loadid
	where  o.STATUS >= '02' and o.STATUS <= '09' 
		and lh.DEPARTURETIME between getdate() and @departTime -- 
		-- and departuretime >= '20110901' -- для тестирования
		and ( -- а также исключаем заказы, ожидающие пополнения и с таймаутом
			susr5 not in (@status_wait, @status_timeout, @status_repl)
			-- но оставляем заказы с истекшим сроком
			or dateadd(n, case when o.susr5 = @status_timeout then 3 else 10 end, o.editdate) <= getdate()
		)
		
	print 'сбрасываем статусы заказов которые зарезервировались'
	update wh1.orders set susr5 = @status_run where status > '09' and susr5 != '' and EDITDATE between dateadd(hh,-24, @departTime) and GETDATE()

	
	print 'сбрасываем статус таймаута (3 минуты) и пополнения (10 минут) , если он истек'
	update o set susr5 = '' 
	from wh1.orders o
		join #orders t on t.ORDERKEY = o.ORDERKEY 
	where t.susr5 in (@status_timeout, @status_repl) and dateadd(n, case when o.susr5 = @status_timeout then 3 else 10 end, o.editdate) <= getdate()
	
	update #orders set susr5 = '' 
	where susr5 in (@status_timeout, @status_repl) and dateadd(n, case when susr5 = @status_timeout then 3 else 10 end, editdate) <= getdate()

	

	if not exists(select top 1 * from #orders) -- нет новых заказов
	begin
		print 'нет новых заказов'
		goto endproc
	end

	--declare @orderCount int 
	--declare @orderkey varchar (20)

create table #qtyother (
				sku varchar (20),
				qty float,
				id varchar (20))

create table #qtycase	(
				id int identity (1,1),
				qty float,
				casecnt int)


create table #orderdetail (
	orderlinenumber varchar(5), 
	orderkey varchar(10), 
	sku varchar(50), 
	storerkey varchar(15), 
	ORIGINALQTY decimal(22,5), 
	[LOTTABLE01] [varchar](50) NOT NULL,
	[LOTTABLE02] [varchar](50) NOT NULL,
	[LOTTABLE03] [varchar](50) NOT NULL,
	[LOTTABLE04] [datetime] NULL,
	[LOTTABLE05] [datetime] NULL,
	[LOTTABLE06] [varchar](50) NOT NULL,
	[LOTTABLE07] [varchar](50) NOT NULL,
	[LOTTABLE08] [varchar](50) NOT NULL,
	[LOTTABLE09] [varchar](50) NOT NULL,
	[LOTTABLE10] [varchar](50) NOT NULL,
)

create table #skuqty (
	qty decimal(22,5),
	[LOTTABLE01] [varchar](50) NOT NULL,
	[LOTTABLE02] [varchar](50) NOT NULL,
	[LOTTABLE03] [varchar](50) NOT NULL,
	[LOTTABLE04] [datetime] NULL,
	[LOTTABLE05] [datetime] NULL,
	--[LOTTABLE06] [varchar](50) NOT NULL,
	[LOTTABLE07] [varchar](50) NOT NULL,
	[LOTTABLE08] [varchar](50) NOT NULL,
	--[LOTTABLE09] [varchar](50) NOT NULL,
	--[LOTTABLE10] [varchar](50) NOT NULL,
	sku varchar(50), 
	loc varchar(10), 
	locationtype varchar(10),
	id varchar(18)
)
	print 'проверка, есть ли ожидающие резервирования заказы (среди заказов которые уже были в обработке)'
	--select @orderCount = COUNT (*) from #orders where susr5 in (@status_wait, @status_timeout, @status_repl)
	--if isnull(@orderCount,0) != 0
	--begin
		--print 'Заказы есть'
		declare @editdate datetime
		declare @susr5 varchar(20)
		declare @doNext bit
		set @doNext = 1
		while @doNext=1 and exists(select top 1 * from #orders where susr5 in ( @status_wait, @status_repl))--(@orderCount > 0)
		begin
			--declare @status varchar(20)
			select top(1) @orderkey = orderkey, @editdate = editdate, @susr5 = susr5 from #orders where susr5 in ( @status_wait, @status_repl) order by ORDERKEY
--select SUSR5,* from #orders where susr5 in ( @status_wait, @status_repl)
			--print 'количество заказов в очереди, ожидающих резервирования = ' + cast(@orderCount as varchar(10)) + '. Заказ № '+ @orderkey +'.'
			print 'Заказ № '+ @orderkey +'.'
			if (dateadd(n,case when @susr5 = @status_wait then 3 else 10 end, @editdate) <= getdate())  
			-- старое условие: (select COUNT(*) from wh1.ORDERS where ORDERKEY = @orderkey and dateadd(n,3,EDITDATE) <= getdate()) != 0
			begin
				update wh1.orders set susr5 = @status_timeout /*а вот тут трабла - если заказ был проверен до истечения таймаута, то он может зависнуть тут надолго. убрано /--, EDITDATE = GETDATE()--/ */ 
					where orderkey = @orderkey and SUSR5 = @status_wait
				--insert into SOAllocateLog (orderkey, susr5) values( @orderkey, @status_timeout)
				print 'заказ ожидает истечения 3х-минутного таймаута'
				exec app_DA_SendMail 'Заказ не запущен. Ожидается истечение таймаута', @orderkey
				print 'удаляем заказ из очереди и переходим к следующему заказу '
				delete from #orders where orderkey = @orderkey
				--set @orderCount = @orderCount - 1
				select @orderkey = null, @editdate = null
			end
			else
			begin
				print 'Заказ готов к резервированию, выходим из цикла'
				set @doNext = 0
			end
		end -- end while @doNext
--	end -- if isnull(@orderCount,0) != 0
--	else
--	begin
--		print 'Среди обрабатывавшихся заказов нет заказов, готовых к резервированию'
--	end
nextOrder:
	if @orderkey is null
	begin
		print 'Среди обрабатывавшихся заказов нет заказов, готовых к резервированию'
--		set @doNext = 1

--		while (@doNext=1 and exists (select top 1 * from #orders where isnull(susr5,'')=''))
--		begin
		print 'Если заказ не был найден на предыдущем шаге ищем среди "немеченных" заказов '
		select top(1) @orderkey = orderkey from #orders where isnull(SUSR5,'') = '' order by PRIORITY, DEPARTURETIME

		if @orderkey is null
		begin -- заказов, ожидающих резервирования - нет.
			print 'если заказов по прежнему нет, проверяем заказы с "проблемными" статусами '
			if (select COUNT(*) from #orders where susr5 in (/*@statusno,*/@status_nosku, @status_error)) != 0
			begin
				print 'сбрасываем "проблемные" статусы заказов'
				insert into SOAllocateLog (orderkey, susr5) 
					select oo.ORDERKEY, 'reset' from #orders oo where susr5 not in (@status_Repl, @status_timeout, @status_wait, @status_run)
						
				update o set o.SUSR5 = '' , EDITDATE = getdate()
					from wh1.ORDERS o join #orders oo on o.ORDERKEY = oo.orderkey
					where oo.SUSR5 not in (@status_repl, @status_timeout, @status_wait, @status_run)  --and oo.SUSR5 != @statuserror
			end
			print 'Завершаем процедуру без ошибок и без выдачи какого либо заказа для резервирвания . Возможно он появится при следующем запуске'
			goto endproc 
		end -- if @orderkey is null
--		end -- while (@doNext and exists......
	end -- if @orderkey is null

	declare @orderlinenumber varchar (10)


	print 'Найден заказ №' + @orderkey
	print 'Проверяем наличие в нем строк'
	truncate table #orderdetail
	insert into #orderdetail (orderlinenumber, orderkey, sku, storerkey, ORIGINALQTY, lottable01, LOTTABLE02, LOTTABLE03, LOTTABLE04, LOTTABLE05, LOTTABLE06, LOTTABLE07, LOTTABLE08, LOTTABLE09, LOTTABLE10 )
	select orderlinenumber, orderkey, sku, storerkey, ORIGINALQTY, lottable01, LOTTABLE02, LOTTABLE03, LOTTABLE04, LOTTABLE05, LOTTABLE06, LOTTABLE07, LOTTABLE08, LOTTABLE09, LOTTABLE10 
	from wh1.ORDERDETAIL 
	where ORDERKEY = @orderkey --and SKU = '24858'--and isnull(lottable01,'') != ''--'0000017585'

	if not exists (select top 1 * from #orderdetail)
	begin
		print 'В заказе № ' + @orderkey + ' нет ни одной позиции.'
		update wh1.orders set susr5 = @status_noorder, EDITDATE = getdate() where orderkey = @orderkey
		insert into SOAllocateLog (orderkey, susr5) values(@orderkey, @status_noorder)
		--			goto endproc
		delete from #orders where orderkey = @orderkey
		goto nextOrder
	end
	
	
	print 'Обрабатываем товары для заказа ' + @orderkey
	print 'Ищем остатки заказанных товаров'



	/* оставлено без изменений */
	truncate table #skuqty
	insert into #skuqty
	select sum(lli.QTY - lli.qtyallocated) qty, 
			la.LOTTABLE01,
			la.LOTTABLE02,
			la.LOTTABLE03,
			la.LOTTABLE04,
			la.LOTTABLE05,
			--od.LOTTABLE06,
			la.LOTTABLE07,
			la.LOTTABLE08,
			--od.LOTTABLE09,
			--od.LOTTABLE10,
			lli.sku, lli.loc, l.locationtype, lli.id
	--into #skuqty
	from wh1.LOTXLOCXID lli 
		join wh1.LOTATTRIBUTE la on lli.LOT = la.LOT
		join #orderdetail od on  od.LOTTABLE01 = 
							case when od.LOTTABLE01 = '' then '' 
							else 
								case when ISNULL(od.LOTTABLE02,'') = '' 
									then ''
									else la.LOTTABLE01
									end
							end -- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and od.LOTTABLE02 = la.LOTTABLE02
						and od.LOTTABLE03 = la.LOTTABLE03
						--and (od.LOTTABLE04 = la.LOTTABLE04 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						--and (od.LOTTABLE05 = la.LOTTABLE05 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and (od.LOTTABLE04 = la.LOTTABLE04 or od.LOTTABLE04 is NULL)
						and (od.LOTTABLE05 = la.LOTTABLE05 or od.LOTTABLE05 is NULL)
						--and od.LOTTABLE06 = la.LOTTABLE06
						and od.LOTTABLE07 = la.LOTTABLE07
						and od.LOTTABLE08 = la.LOTTABLE08
						--and od.LOTTABLE09 = la.LOTTABLE09
						--and od.LOTTABLE10 = la.LOTTABLE10
						and od.sku = lli.SKU
						and od.storerkey = lli.STORERKEY
		join wh1.loc l on l.loc = lli.loc
	--!!!!!!!!!!!!!!!left join wh1.INVENTORYHOLD ih on ih.loc = lli.LOC or ih.LOT = lli.LOT or ih.ID = lli.id
	where lli.QTY > 0 
	--!!!!!!!!!!!!!!!and isnull(ih.HOLD,'') != 1 
	and (lli.QTY - lli.qtyallocated) > 0
	and --l.LOCATIONTYPE != 'STAGED' and 
	l.LOCATIONTYPE != 'PICKTO' and l.LOC != 'LOST' and l.LOC != 'OVER'
	group by lli.sku, lli.loc, l.LOCATIONTYPE, la.LOTTABLE01, la.LOTTABLE02, la.LOTTABLE03, la.LOTTABLE04, la.LOTTABLE05,
						--od.LOTTABLE06,
						la.LOTTABLE07, la.LOTTABLE08, lli.ID
						--od.LOTTABLE09, od.LOTTABLE10
	
	if (select COUNT(*) from #skuqty) = 0
	begin
		print 'Для заказа № ' + @orderkey + ' нет ни одного товара на остатках склада.'
		update wh1.orders set susr5 = @status_nosku, EDITDATE = getdate() where orderkey = @orderkey 
		insert into SOAllocateLog (orderkey, susr5) select @orderkey, @status_nosku	
		print 'Удаляем заказ из очереди и переходим к следующему заказу'
		delete from #orders where orderkey = @orderkey
		set @orderkey = null
		goto nextOrder
	end


declare @sqqtyall float --количество товара на остатках.
declare @qtyneed float --недостающее колчество товара на складе.
declare @sqqtyother float --количество товара на остатках паллеты.
declare @sqqtycase float --количество товара на остатках ящики.
declare @sqqtypick float --количество товара на остатках штуки.
declare @orderedqty float --заказанное количество товара 
declare @id varchar (10) --значение паллеты
declare @packqty int --ключ упаковки
declare @sku varchar(20) --код товара


truncate table #qtyother
truncate table #qtycase

	while exists(select orderlinenumber from #orderdetail)
	begin
		select top(1) @orderlinenumber = orderlinenumber from #orderdetail

		--print 'заказанное количество'
		select @orderedqty = originalqty, @sku = sku from #orderdetail where ORDERLINENUMBER = @orderlinenumber
		--print 'количество штук в упаковке'
		
		------------------------------------------------
		-- определяем ключ упаковки
		select @packqty = isnull(p.casecnt,1) 
		from #orderdetail od 
			left join wh1.pack p on od.lottable01 = p.packkey
		where ORDERLINENUMBER = @orderlinenumber

		print '### заказ '+ @orderkey+'. строка '+@orderlinenumber+'. товар '+@sku+'. количество '+cast (@orderedqty as varchar(20))

		--'общее свободное количество товара на остатках склада.'		
		select @sqqtyall = SUM(sq.qty)
		from #skuqty sq 
			join #orderdetail od on sq.SKU = od.SKU
					and (case when isnull(od.LOTTABLE01,'') = '' OR ISNULL(od.LOTTABLE02,'') = ''
							then ''
							else od.LOTTABLE01 
						end
						=
						case when isnull(od.LOTTABLE01,'') = '' OR ISNULL(od.LOTTABLE02,'') = ''
							then ''
							else sq.LOTTABLE01
						end)
					and od.LOTTABLE02 = sq.LOTTABLE02
					and od.LOTTABLE03 = sq.LOTTABLE03
					--and (od.LOTTABLE04 = sq.LOTTABLE04 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
					--and (od.LOTTABLE05 = sq.LOTTABLE05 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
					and (od.LOTTABLE04 = sq.LOTTABLE04 or od.LOTTABLE04 is NULL)
					and (od.LOTTABLE05 = sq.LOTTABLE05 or od.LOTTABLE05 is NULL)
					--and od.LOTTABLE06 = sq.LOTTABLE06
					and od.LOTTABLE07 = sq.LOTTABLE07
					and od.LOTTABLE08 = sq.LOTTABLE08
					--and od.LOTTABLE09 = sq.LOTTABLE09
					--and od.LOTTABLE10 = sq.LOTTABLE10
			left join wh1.PACK p on p.PACKKEY = sq.lottable01
		where od.ORDERLINENUMBER = @orderlinenumber
			--group by p.casecnt
			
			
		print 'общее свободное количество товара на остатках склада = ' + cast(isnull(@sqqtyall,0) as varchar(20))

		if isnull(@sqqtyall,0) = 0 
		begin 
			print 'товара нет физически на складе'
			goto EndWorkOneLine 
		end
			
		set @qtyneed = @sqqtyall - @orderedqty

		print 'общее свободное количество товара на остатках склада паллеты.'		
		--select sq.sku, sq.qty, sq.id into #qtyother
		insert into #qtyother
			select sq.sku, sq.qty, sq.id 
			from #skuqty sq 
				join #orderdetail od on sq.SKU = od.SKU
						and (case when isnull(od.LOTTABLE01,'') = '' OR ISNULL(od.LOTTABLE02,'') = ''
								then ''
								else od.LOTTABLE01 
							end
							=
							case when isnull(od.LOTTABLE01,'') = '' OR ISNULL(od.LOTTABLE02,'') = ''
								then ''
								else sq.LOTTABLE01
							end)
						and od.LOTTABLE02 = sq.LOTTABLE02
						and od.LOTTABLE03 = sq.LOTTABLE03
						--and (od.LOTTABLE04 = sq.LOTTABLE04 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						--and (od.LOTTABLE05 = sq.LOTTABLE05 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and (od.LOTTABLE04 = sq.LOTTABLE04 or isnull(od.LOTTABLE04,'') = '')
						and (od.LOTTABLE05 = sq.LOTTABLE05 or isnull(od.LOTTABLE05,'') = '')
						and od.LOTTABLE07 = sq.LOTTABLE07
						and od.LOTTABLE08 = sq.LOTTABLE08
			where od.ORDERLINENUMBER = @orderlinenumber and sq.LOCATIONTYPE = 'other'

--select * from #skuqty			
--select * from #qtyother --отладка

		print 'подбрка целых поддонов.'
		while exists(select top(1) id from #qtyother where qty <= @orderedqty) and @orderedqty != 0
		begin
			--print ''
			select top(1) @id = id from #qtyother where qty <= @orderedqty
			set @orderedqty = @orderedqty - (select qty from #qtyother where @id = id)
			delete from #qtyother where ID = @id
		end

		--print 'общее свободное количество товара на остатках склада ящики.'	
		delete from #qtycase		
		insert into #qtycase	
		select 
			SUM(sq.qty) qty, p.casecnt
			from #skuqty sq 
				join #orderdetail od on sq.SKU = od.SKU
						and (case when isnull(od.LOTTABLE01,'') = '' OR ISNULL(od.LOTTABLE02,'') = ''
								then ''
								else od.LOTTABLE01 
							end
							=
							case when isnull(od.LOTTABLE01,'') = '' OR ISNULL(od.LOTTABLE02,'') = ''
								then ''
								else sq.LOTTABLE01
								end)
						and od.LOTTABLE02 = sq.LOTTABLE02
						and od.LOTTABLE03 = sq.LOTTABLE03
						--and (od.LOTTABLE04 = sq.LOTTABLE04 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						--and (od.LOTTABLE05 = sq.LOTTABLE05 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and (od.LOTTABLE04 = sq.LOTTABLE04 or od.LOTTABLE04 is NULL)
						and (od.LOTTABLE05 = sq.LOTTABLE05 or od.LOTTABLE05 is NULL)						
						--and od.LOTTABLE06 = sq.LOTTABLE06
						and od.LOTTABLE07 = sq.LOTTABLE07
						and od.LOTTABLE08 = sq.LOTTABLE08
						--and od.LOTTABLE09 = sq.LOTTABLE09
						--and od.LOTTABLE10 = sq.LOTTABLE10
				left join wh1.pack p on p.packkey = sq.lottable01
			where od.ORDERLINENUMBER = @orderlinenumber and sq.LOCATIONTYPE = 'case'
			group by p.casecnt
			
			
			
			
--select * from #qtycase	--отладка		
		select @sqqtycase = SUM(qty) from #qtycase
		set @sqqtycase = isnull(@sqqtycase,0)

		print 'общее свободное количество товара на остатках склада ящики ' + cast((@sqqtycase/ @packqty) as varchar(20))

declare @caseid int --указатель строки товаров в коробках

		
		while (select COUNT (id) from #qtycase) != 0
		begin
			--обрабатываем поочередно партии товаров, имеющихся на складе
			select top(1) @caseid = ID, @sqqtycase = qty,  @packqty = isnull(casecnt,0) from #qtycase order by id

			--if @packqty = 0 
			--	begin
			--		declare @errormsg = 'товар ' + @sku
			--		exec app_DA_SendMail 'Ошибка автоматического запуска заказа', @errormsg
			--	end
			
			if (floor((@sqqtycase / @packqty))*@packqty - floor((@orderedqty / @packqty))*@packqty) < 0
			begin
				print 'необходимое количество ('+cast (@orderedqty as varchar(20))+') коробок'
				set @orderedqty = @orderedqty - floor((@sqqtycase / @packqty))*@packqty
				print 'больше чем имеющееся ('+cast(@sqqtycase as varchar(20))+')'
			end
			else
			begin
				print 'необходиомое колиество ('+cast (@orderedqty as varchar(20))+') коробок'
				set @orderedqty = @orderedqty - floor((@orderedqty / @packqty))*@packqty
				print 'меньше чем имеющееся ('+cast(@sqqtycase as varchar(20))+')'
				goto qtypick
			end		
		
			delete from #qtycase where id = @caseid
		end

qtypick:
		print 'оставшееся необходимое количество '+cast (@orderedqty as varchar(20))


--print 'общее свободное количество товара на остатках склада штуки.'		
		select @sqqtypick = SUM(sq.qty)
			from #skuqty sq 
				join #orderdetail od on sq.SKU = od.SKU
						and (case when isnull(od.LOTTABLE01,'') = '' OR ISNULL(od.LOTTABLE02,'') = ''
								then ''
								else od.LOTTABLE01 
							end
							=
							case when isnull(od.LOTTABLE01,'') = '' OR ISNULL(od.LOTTABLE02,'') = ''
								then ''
								else sq.LOTTABLE01
							end)
						and od.LOTTABLE02 = sq.LOTTABLE02
						and od.LOTTABLE03 = sq.LOTTABLE03
						--and (od.LOTTABLE04 = sq.LOTTABLE04 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						--and (od.LOTTABLE05 = sq.LOTTABLE05 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and (od.LOTTABLE04 = sq.LOTTABLE04 or od.LOTTABLE04 is NULL)
						and (od.LOTTABLE05 = sq.LOTTABLE05 or od.LOTTABLE05 is NULL)
						--and od.LOTTABLE06 = sq.LOTTABLE06
						and od.LOTTABLE07 = sq.LOTTABLE07
						and od.LOTTABLE08 = sq.LOTTABLE08
						--and od.LOTTABLE09 = sq.LOTTABLE09
						--and od.LOTTABLE10 = sq.LOTTABLE10
			where od.ORDERLINENUMBER = @orderlinenumber and sq.LOCATIONTYPE = 'pick'

			set @sqqtypick = isnull(@sqqtypick,0)
		print 'общее свободное количество товара на остатках склада штуки. '	+ cast(@sqqtypick as varchar(20))
		print 'количество товара по заказу на остатках склада '+cast (@qtyneed as varchar(20))

		if (@sqqtypick - @orderedqty) >= 0 
		begin
			print 'необходимое количество по заказу <= доступного - пополнение не нужно,товар есть - продолжаем обработку со след строки'
			goto EndWorkOneLine
		end
		else
		begin
			if @qtyneed < 0
			begin
				print 'необходимое количество больше, чем доступное и больше чем имеющееся на складе - пополнение не нужно, товара в принципе недостаточно - обрабатываем следующую строку'
				goto EndWorkOneLine
			end
			else
			begin
				print 'необходимое количество больше чем доступно и меньше чем имеющееся на складе - ждем пополнения'
				update wh1.orders set susr5 = @status_repl, EDITDATE = getdate() where orderkey = @orderkey
				insert into SOAllocateLog (orderkey, susr5) values (@orderkey, @status_repl)
				--exec dbo.SZ_MVTask
				delete from #orders where orderkey = @orderkey
				set @orderkey = null
				goto nextOrder
			end
		end

		EndWorkOneLine:		
		delete from #orderdetail where orderlinenumber = @orderlinenumber
	end


	if not exists(select orderlinenumber from #orderdetail) --and @status = 1
	begin
		print 'все товары есть, выдаем номер заказа и меням статус'
		update wh1.orders set susr5 = @status_wait, EDITDATE = getdate() where orderkey = @orderkey
		insert into SOAllocateLog (orderkey, susr5) select @orderkey, @status_wait
		select orderkey, externorderkey from wh1.orders where orderkey = @orderkey
	end
end
else
	begin

		select 1 from wh1.orders where orderkey = @orderkey1
	end	



endproc:
--drop table #orderdetail
--drop table #skuqty
--drop table #orders
--drop table #qtyother 
--drop table #qtycase

/*версия 1.0.1*/

