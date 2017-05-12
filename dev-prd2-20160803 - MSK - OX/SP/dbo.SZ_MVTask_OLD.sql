ALTER PROCEDURE [dbo].[SZ_MVTask_OLD] 
AS
	set NOCOUNT on

--select * from wh1.taskdetail where STATUS = 0 and/**/ SKU = '19117'
--select * from wh1.ORDERDETAIL where ORDERKEY in ('0000007806','0000007809')
--select * from wh1.lotxlocxid where SKU = '19117' and QTY > 0

	set NOCOUNT on
	delete from wh1.taskdetail where STATUS = '0' and TASKTYPE = 'MV' and ADDWHO = 'dareplen'
	print 'выбираем заказы, которые не запущены и не зарезервированы'
	select o.*, lh.DEPARTURETIME
	into #orders 
	from wh1.orders o 
		join wh1.LOADORDERDETAIL lo on o.ORDERKEY = lo.SHIPMENTORDERID
		join wh1.LOADSTOP ls on lo.LOADSTOPID = ls.LOADSTOPID
		join wh1.loadhdr lh on ls.loadid = lh.loadid
	where o.STATUS >= '00' and o.STATUS <= '09'
		--and o.orderkey = '0000000952'  
		--and isnull(o.susr5,'') = ''  and lh.DEPARTURETIME >= GETDATE()
		and lh.DEPARTURETIME <= dateadd(hh,24,GETDATE())
	
	/* VC 26/08/2011 - добавлена промежуточная таблица */
	
	create table #orderdetail_prepare (
		id int identity(1,1),
		qty float null,
		--eaqty float null,
		sku varchar(10) null,
		storerkey varchar(10) null,
		packkey varchar(10) null,
		casecnt float null,
		--lottable01 varchar (30) null,
		lottable02 varchar (30) null,
		lottable03 varchar (30) null,
		lottable04 datetime null,
		lottable05 datetime null,
		lottable07 varchar (30) null,
		lottable08 varchar (30) null,
		orderkey varchar(18) null
	)

	create table #orderdetail (
		id int identity(1,1),
		qty float null,
		--eaqty float null,
		sku varchar(10) null,
		storerkey varchar(10) null,
		packkey varchar(10) null,
		casecnt float null,
		--lottable01 varchar (30) null,
		lottable02 varchar (30) null,
		lottable03 varchar (30) null,
		lottable04 datetime null,
		lottable05 datetime null,
		lottable07 varchar (30) null,
		lottable08 varchar (30) null--,
		--orderkey varchar(18) null
	)

	print 'выбираем необходимое количетсво товара'
	/* VC 26/08/2011 begin*/
	print '   - выбираем детали, сгруппированные по заказно'
	/* 
		Если в заказе товары могут повторяться, то надо будет в _prepare таблицу
		добавить поле orderlinenumber и добавить его в группировку.
	*/
	insert	into #orderdetail_prepare
	select SUM(od.ORIGINALQTY) qty, 
		--SUM(od.ORIGINALQTY) - floor(SUM(od.ORIGINALQTY)/case when isnull(p.casecnt,1) = 0 then 1 else isnull(p.casecnt,1) end)*p.casecnt eaqty, 
		od.SKU, 
		od.STORERKEY, 
		NULL,--od.PACKKEY,
		isnull(p.CASECNT,op.CASECNT) as CASECNT,
		--od.LOTTABLE01, 
		od.LOTTABLE02, 
-- ATTENTION !!!
		'OK' lottable03,  /* тут непонятно - зачем расчет атрибута??  получается при пополнении всегда считается что атрибут = ОК, 
							независимо от того что в заказе */
		od.LOTTABLE04, 
		od.LOTTABLE05, 
-- ATTENTION !!!
		/* VC 05/09/2011 
			заменен расчет атрибутов 07,08 на их значения из строки заказа.
			в противном случае всегда считается что 8й атр = ОК, а 7й зависит от типа заказа
			и в случае изменения/появления нового типа приводит к правке и в этом месте. */
		--case when o.TYPE = '101' then 'BRAK' else 'OK' end lottable07,
		--'OK' lottable08,
		od.LOTTABLE07,
		od.LOTTABLE08,
		
		od.ORDERKEY
	from wh1.ORDERDETAIL od
		join #orders o on o.ORDERKEY = od.ORDERKEY
		join wh1.PACK op on op.PACKKEY = od.PACKKEY
		left join (
			select
				la.SKU,
				la.STORERKEY,
				la.LOTTABLE02,
				la.LOTTABLE03,
				la.LOTTABLE04,
				la.LOTTABLE05,
				la.LOTTABLE07,
				la.LOTTABLE08,
				max(p.CASECNT) as CASECNT
			from wh1.LOT l
				join wh1.LOTATTRIBUTE la on la.LOT = l.LOT
				join wh1.PACK p on p.PACKKEY = la.LOTTABLE01
			where l.QTY > 0 and la.LOTTABLE01 <> 'STD'
			group by
				la.SKU,
				la.STORERKEY,
				la.LOTTABLE02,
				la.LOTTABLE03,
				la.LOTTABLE04,
				la.LOTTABLE05,
				la.LOTTABLE07,
				la.LOTTABLE08
		) p on p.SKU = od.SKU and p.STORERKEY = od.STORERKEY
			and p.LOTTABLE02 = od.LOTTABLE02
			and p.LOTTABLE03 = od.LOTTABLE03
			and (p.LOTTABLE04 = od.LOTTABLE04 or p.LOTTABLE04 is NULL and od.LOTTABLE04 is NULL)
			and (p.LOTTABLE05 = od.LOTTABLE05 or p.LOTTABLE05 is NULL and od.LOTTABLE04 is NULL)
			and p.LOTTABLE07 = od.LOTTABLE07
			and p.LOTTABLE08 = od.LOTTABLE08
	where od.ORIGINALQTY != 0
	group by od.sku, od.storerkey,
		isnull(p.CASECNT,op.CASECNT),
		--od.LOTTABLE01, 
		od.LOTTABLE02, od.LOTTABLE04, od.LOTTABLE05, od.LOTTABLE07, od.LOTTABLE08,
		o.TYPE, od.ORDERKEY
			 
	print '   - исключаем строки с упаковкой равной 1 штука в ящике'
	/* такие строки должны резервироваться с склада хранения и для них не надо искать товар для пополнения */
	delete from #orderdetail_prepare where casecnt = 1
	
    print '   - откидываем целые коробки'
	update #orderdetail_prepare set
		qty = qty - case when isnull(casecnt,0) = 0 
							then 0 
							else floor(qty/casecnt)*casecnt 
						end
	
	print '   - считаем сколько необходимо товара на складе штучного отбора. Группировка по товарам'
	insert	into #orderdetail
	select SUM(qty) qty, 
		SKU, 
		STORERKEY, 
		packkey, 
		casecnt,
		LOTTABLE02, 
		lottable03, 
		LOTTABLE04, 
		LOTTABLE05, 
		lottable07,
		lottable08
	from #orderdetail_prepare od 
	group by sku, storerkey, casecnt,
			od.LOTTABLE02, od.LOTTABLE03, od.LOTTABLE04, od.LOTTABLE05,lottable07,lottable08, od.packkey 
	/* VC 26/08/2011 end */

--select * from #orderdetail where sku = '19117'

	--delete from #orderdetail where sku != '27977'

	create table #skuqty (
		id int identity(1,1),
		casecnt float null,
		qty float null,
		qtycase float null,
		sku varchar(10) null,
		storerkey varchar(10) null,
		loc varchar(10) null,
		locationtype varchar (10) null,
		lottable01 varchar (30) null,
		lottable02 varchar (30) null,
		lottable03 varchar (30) null,
		lottable04 datetime null,
		lottable05 datetime null,
		lottable07 varchar (30) null,
		lottable08 varchar (30) null,
		lot varchar(10),
		pid varchar(20),
		locroute varchar (20)
	)
	select * into #skuqtysku from #skuqty where 1=2

	print 'выбираем товары на остатках'
	insert into #skuqty
		select 
			--ih.id, lxl.id,*
			p.CASECNT,
			SUM(lxl.QTY-QTYALLOCATED) qty,
			floor(SUM(lxl.QTY-QTYALLOCATED)/(case when isnull(p.CASECNT,0) = 0 then 1 else p.CASECNT end))*isnull(p.CASECNT,0) ,
			--0 qtycase,
			--(lxl.QTY-QTYALLOCATED) qty,
			--(lxl.QTY-QTYALLOCATED)/p.CASECNT*p.CASECNt qtycase,		
			 od.SKU, 
			 od.STORERKEY, 
			 lxl.loc, 
			 l.LOCATIONTYPE,
			--lli.LOTTABLE01, 
			p.CASECNT as LOTTABLE01,
			od.LOTTABLE02, od.LOTTABLE03, od.LOTTABLE04, od.LOTTABLE05, od.LOTTABLE07, od.LOTTABLE08, 
			lli.lot, 
			lxl.ID, 
			l.LOGICALLOCATION 
		from #ORDERDETAIL od
			join wh1.LOTATTRIBUTE lli on od.sku = lli.SKU 
				and od.storerkey = lli.STORERKEY 
				and isnull(lli.LOTTABLE02,'') = case when isnull(od.LOTTABLE02,'') = '' then isnull(lli.LOTTABLE02,'') else isnull(od.LOTTABLE02,'') end
				--and lli.LOTTABLE02 = isnull(od.LOTTABLE02,'')
				and lli.LOTTABLE03 = od.LOTTABLE03
				and isnull(lli.LOTTABLE04,'') = case when isnull(od.LOTTABLE04,'') = '' then isnull(lli.LOTTABLE04,'') else isnull(od.LOTTABLE04,'') end
				and isnull(lli.LOTTABLE05,'') = case when isnull(od.LOTTABLE05,'') = '' then isnull(lli.LOTTABLE05,'') else isnull(od.LOTTABLE05,'') end
				and lli.LOTTABLE07 = od.LOTTABLE07
				and lli.LOTTABLE08 = od.LOTTABLE08
			join wh1.LOTXLOCXID lxl on lli.LOT = lxl.LOT 
			join wh1.loc l on l.LOC = lxl.loc
			left join wh1.INVENTORYHOLD ih on ih.loc = lxl.LOC or ih.LOT = lxl.LOT --or isnull(ih.ID,'') = isnull(lxl.id,'')
			join wh1.PACK p on lli.LOTTABLE01 = p.PACKKEY
		where lxl.qty != 0 
			and (l.LOC != 'LOST')
			and l.LOCATIONTYPE in ('pick','case','other')
			and isnull(ih.HOLD,'') != 1
		group by		
			p.CASECNT, 
			od.sku, 
			od.storerkey, 
			lxl.LOC,
			l.LOCATIONTYPE, 
			p.CASECNT,
			--lli.LOTTABLE01, 
			lxl.LOC,
			od.LOTTABLE02, od.lottable03, od.LOTTABLE04, od.LOTTABLE05 , od.LOTTABLE07, od.LOTTABLE08, 
			lli.lot, 
			lxl.id, 
			l.LOGICALLOCATION 
		order by lli.lot
--select * from #skuqty order by sku

		print 'удаляем товары из остатков по EA_IN'
		delete sq
		--select *
			from #skuqty sq 
				join wh1.LOTXLOCXID lli on sq.sku = lli.SKU and sq.storerkey = lli.STORERKEY
				join wh1.LOTATTRIBUTE la on lli.LOT = la.LOT and	
						sq.sku = la.SKU and sq.storerkey = la.STORERKEY 
						and isnull(la.LOTTABLE02,'') = case when isnull(sq.LOTTABLE02,'') = '' then isnull(la.LOTTABLE02,'') else isnull(sq.LOTTABLE02,'') end
						and la.LOTTABLE03 = sq.LOTTABLE03
						and isnull(la.LOTTABLE04,'') = case when isnull(sq.LOTTABLE04,'') = '' then isnull(la.LOTTABLE04,'') else isnull(sq.LOTTABLE04,'') end
						and isnull(la.LOTTABLE05,'') = case when isnull(sq.LOTTABLE05,'') = '' then isnull(la.LOTTABLE05,'') else isnull(sq.LOTTABLE05,'') end
						and la.LOTTABLE07 = sq.LOTTABLE07
						and la.LOTTABLE08 = sq.LOTTABLE08
			where lli.LOC = 'EA_IN' and lli.QTY != 0


	--select * from #orderdetail
	--select * from #skuqty

	declare @sku varchar (10)
	declare @odid int
	declare @sqid int
	declare @taskkey varchar(10)
	declare @qtypick float --количество товара на складе в штуках
	declare @qtycase float --количество товара на складе в коробках
	declare @qtypickneed float --заказанное количество товара

	declare @qtyneed float --недостающее количество товара в зоне штучного отбора.
	declare @qtyneedcase float --недостающее количество товара в зоне штучного отбора, округленное до коробок.
	--declare @sku varchar(20) --код товара

--select * from #orderdetail where sku = '19117'

	while exists(select sku from #orderdetail)
		begin print'есть необработанные товары'
		
			--select top(1) @odid = ID, @qtypickneed = qty from #orderdetail --выбор строки товара из заказа. 15:31 2011/06/08
	--		select top(1) @sku = sku, @odid = ID, @qtypickneed = qty - floor(qty/case when casecnt = 0 or isnull(casecnt,0) = 0 then 1 else casecnt end)*isnull(casecnt,0) from #orderdetail --выбор строки товара из заказа.		
	select top(1) @sku = sku, @odid = ID, @qtypickneed = qty 
	/* 
	VC 26/08/2011	
		здесь уже не принципиально кратно данное кол-во коробке или нет, поэтому 
		убрано вычитание целых коробок, используется то значение QTY,
		которое получилось после группировки деталей по товарам
	*/
	/* - case when (case when casecnt = 0 or isnull(casecnt,0) = 0 then 1 else casecnt end) = 1 
		then 0 
		else floor(qty/casecnt)*casecnt end*/
	from #orderdetail --выбор строки товара из заказа.		
			print 'необходимое количество ' + cast( @qtypickneed as varchar(20)) + '. товар ' + @sku
			--select sku, ID, qty, casecnt, qty - floor(qty/case when casecnt = 0 or isnull(casecnt,0) = 0 then 1 else casecnt end)*isnull(casecnt,0) 
			--from #orderdetail --выбор строки товара из заказа.		
			
			
			-- вставка товаров по товару из заказа
			insert into #skuqtysku
				select 
				fq.casecnt,
				fq.qty,
				fq.qtycase,
				fq.sku,fq.storerkey,fq.loc,fq.locationtype,fq.lottable01,
					fq.lottable02,fq.lottable03,fq.lottable04,fq.lottable05,fq.lottable07,fq.lottable08,fq.lot, fq.pid, fq.locroute
				from #skuqty fq join #orderdetail od on fq.sku = od.sku and fq.storerkey = od.storerkey
						and isnull(fq.LOTTABLE02,'') = case when isnull(od.LOTTABLE02,'') = '' then isnull(fq.LOTTABLE02,'') else isnull(od.LOTTABLE02,'') end
						and fq.LOTTABLE03 = od.LOTTABLE03
						and isnull(fq.LOTTABLE04,'') = case when isnull(od.LOTTABLE04,'') = '' then isnull(fq.LOTTABLE04,'') else isnull(od.LOTTABLE04,'') end
						and isnull(fq.LOTTABLE05,'') = case when isnull(od.LOTTABLE05,'') = '' then isnull(fq.LOTTABLE05,'') else isnull(od.LOTTABLE05,'') end
						--and fq.LOTTABLE06 = 
						and fq.LOTTABLE07 = od.LOTTABLE07
						and fq.LOTTABLE08 = od.LOTTABLE08
						--and fq.LOTTABLE09 = 
						--and fq.LOTTABLE10 = 
				where od.id= @odid
				
				select @qtypick = isnull(SUM(qty),0) from #skuqtysku where locationtype = 'pick'
				--select 'qqqq',* from #skuqtysku
				--select SUM(qty) from #skuqtysku where locationtype = 'PICK'			
				
				if @qtypick < @qtypickneed 
					begin -- количество товара в зоне штучного отбора меньше необходимого.
						print 'qtypick'+cast(isnull(@qtypick,0) as varchar(20))+'. qtyneed '+cast(isnull(@qtyneed,0) as varchar(20))+'. количество товара в зоне штучного отбора меньше необходимого.'
						set @qtyneed = @qtypickneed - @qtypick --требуемое количество товара в зоне штучного отбора
						--удаляем строки со штучным количеством
						delete from #skuqtysku where locationtype = 'pick'
						--выбрать строки для выполнения перемещений
						while (select COUNT (id) from #skuqtysku) != 0 and @qtyneed != 0
							begin
								--еще есть товары на складе
								select top(1) @sqid = ID, @qtycase = qtycase from #skuqtysku 
								if @qtycase < @qtyneed
									begin 
										print 'qtypick '+cast(isnull(@qtypick,0) as varchar(20))+'. qtyneed '+cast(isnull(@qtyneed,0) as varchar(20))+'. требуемое количество больше доступного, формируем задачу на перемещение всего количества'
										exec dbo.DA_GetNewKey 'wh1','TASKDETAILKEY',@taskkey output

										INSERT INTO wh1.TaskDetail 
											(AddDate, AddWho, EditDate, EditWho, 
											TaskDetailKey, TaskType, Storerkey, 
											Sku, Lot, UOM, UOMQty, qty, FromLoc, FromID, ToLoc, ToID, Status, Priority, 
											Holdkey, UserKey, ListKey, StatusMsg, ReasonKey, CaseId, UserPosition, 
											UserKeyOverride, OrderLineNumber, PickDetailKey, LogicalFromLoc, LogicalToLoc, FinalToLoc ) 
											select
												GETDATE(), 'DaReplen', GETDATE(), 'DaReplen',
												@taskkey, 'MV', '001', 
												sku, lot, '6', @qtycase UOMQty, @qtycase qty, loc, pid, 'EA_IN', '', '0', '5',
												' ', ' ', ' ', ' ', ' ', ' ', '1',
												' ', '   ', '   ', locroute, 'EA_IN', ' '
												from #skuqtysku
												where id = @sqid and qty != 0
										set @qtyneed = @qtyneed - @qtycase
									
									end
								else
									begin
										print 'требуемое количество меньше '
										select @qtyneedcase = @qtyneed
											from #skuqtysku 
											where id = @sqid
										
										exec dbo.DA_GetNewKey 'wh1','TASKDETAILKEY',@taskkey output
										INSERT INTO wh1.TaskDetail 
											(AddDate, AddWho, EditDate, EditWho, 
											TaskDetailKey, TaskType, Storerkey, 
											Sku, Lot, UOM, UOMQty, QTY, FromLoc, FromID, ToLoc, ToID, Status, Priority, 
											Holdkey, UserKey, ListKey, StatusMsg, ReasonKey, CaseId, UserPosition, 
											UserKeyOverride, OrderLineNumber, PickDetailKey, LogicalFromLoc, LogicalToLoc, FinalToLoc ) 
											select
												GETDATE(), 'DaReplen', GETDATE(), 'DaReplen',
												@taskkey, 'MV', '001', 
												sku, lot, '6', CEILING(@qtyneed/casecnt)*casecnt uomqty, CEILING(@qtyneed/casecnt)*casecnt qty, loc, pid, 'EA_IN', '', '0', '5',
												' ', ' ', ' ', ' ', ' ', ' ', '1',
												' ', '   ', '   ', locroute, 'EA_IN', ' '
												from #skuqtysku
												where id = @sqid and qty != 0
												
										print 'вставка задачи в лог'
										INSERT INTO wh1.TaskDetailLog
											(AddDate, AddWho, EditDate, EditWho, 
											TaskDetailKey, TaskType, Storerkey, 
											Sku, Lot, UOM, UOMQty, QTY, FromLoc, FromID, ToLoc, ToID, Status, Priority, 
											Holdkey, UserKey, ListKey, StatusMsg, ReasonKey, CaseId, UserPosition, 
											UserKeyOverride, OrderLineNumber, PickDetailKey, LogicalFromLoc, LogicalToLoc, FinalToLoc ) 
											select
												GETDATE(), 'DaReplen', GETDATE(), 'DaReplen',
												@taskkey, 'MV', '001', 
												sku, lot, '6', CEILING(@qtyneed/casecnt)*casecnt uomqty, CEILING(@qtyneed/casecnt)*casecnt qty, loc, pid, 'EA_IN', '', '0', '5',
												' ', ' ', ' ', ' ', ' ', ' ', '1',
												' ', '   ', '   ', locroute, 'EA_IN', ' '
												from #skuqtysku
												where id = @sqid and qty != 0		
																					
										set @qtyneed = 0
									end
								delete from #skuqtysku where id = @sqid							
							end
					end
				else
					begin -- количество товара в зоне штучного отбора удовлетворяет спрос - пополнение ненужно.
					print 'qtypick '+cast(isnull(@qtypick,0) as varchar(20))+'. qtyneed '+cast(isnull(@qtyneed,0) as varchar(20))+'. количество товара в зоне штучного отбора удовлетворяет спрос - пополнение ненужно.'
					end
					
				--print 'вставка задачи на пополнение'
			delete from #skuqtysku
			delete #orderdetail where ID = @odid
		end


	delete from wh1.TASKDETAIL where TASKTYPE = 'MV' and QTY = 0 and STATUS = 0

	drop table #orderdetail_prepare
	drop table #orderdetail
	drop table #orders
	drop table #skuqty
	drop table #skuqtysku

--select * from wh1.taskdetail where tasktype = 'MV' and STATUS = 0 --and/**/-- SKU = '19117'

	--select * 
	--	from wh1.LOTXLOCXID lli join #orderdetail od on
	--	lli.

	--select * from wh1.taskdetail where TASKTYPE = 'MV' and STATUS = 0
	--select * from wh1.ORDERDETAIL where ORDERKEY = '0000001082'
	--select * from wh1.ORDERs where externORDERKEY like '%11111%'

	--select * from wh1.LOTXLOCXID where LOC = 'ea_in' and QTY != 0 and SKU = '40213'

	--24775
	--11433
	--5936
exec dbo.notrezerv

declare @current_date datetime 	set @current_date =getdate()
		
select @current_date date,COUNT(*) a into #a from wh1.TASKDETAIL 	where TASKTYPE = 'MV'		and [STATUS] = '0'
select @current_date date,COUNT(*) b into #b from wh1.lotxlocxid where LOC='EA_IN' and QTY>0


insert into test_ttt
select a.date,a.a, b.b, 0
	from #a a 		join #b b on a.date=b.date 	

drop table #a
drop table #b
