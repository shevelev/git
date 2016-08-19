ALTER PROCEDURE [dbo].[SZ_MVTask] 
AS

delete from wh1.taskdetail where STATUS = '0' and TASKTYPE = 'MV' and ADDWHO = 'dareplen'
print 'выбираем заказы, которые не запущены и не зарезервированы'
select o.*, lh.DEPARTURETIME into #orders 
from wh1.orders o join wh1.LOADORDERDETAIL lo on o.ORDERKEY = lo.SHIPMENTORDERID
join wh1.LOADSTOP ls on lo.LOADSTOPID = ls.LOADSTOPID
join wh1.loadhdr lh on ls.loadid = lh.loadid
where  o.STATUS >= '0' and o.STATUS <= '09'--/* and o.orderkey = '0000001138' --and o.orderkey = '0000000952'  and isnull(o.susr5,'') = ''  and lh.DEPARTURETIME >= GETDATE() */ and lh.DEPARTURETIME <= dateadd(hh,240,GETDATE())

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
lottable08 varchar (30) null
)

print 'выбираем необходимое количетсво товара'
insert	into #orderdetail
select SUM(od.ORIGINALQTY) qty, 
	--SUM(od.ORIGINALQTY) - floor(SUM(od.ORIGINALQTY)/case when isnull(p.casecnt,1) = 0 then 1 else isnull(p.casecnt,1) end)*p.casecnt eaqty, 
	od.SKU, 
	od.STORERKEY, 
	od.packkey, 
	p.casecnt,
	--od.LOTTABLE01, 
	od.LOTTABLE02, 
	'OK' lottable03, 
	od.LOTTABLE04, 
	od.LOTTABLE05, 
	case when o.TYPE = '101' then 'BRAK' else 'OK' end lottable07,
	'OK' lottable08
		from wh1.ORDERDETAIL od join #orders o on o.ORDERKEY = od.ORDERKEY
		join wh1.pack p on p.PACKKEY = od.PACKKEY
		where od.ORIGINALQTY != 0
		group by od.sku, od.storerkey, p.casecnt,
			--od.LOTTABLE01, 
			od.LOTTABLE02, od.LOTTABLE04, od.LOTTABLE05, o.TYPE, od.packkey

--select * from #orderdetail

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
	select --ih.id, lxl.id,*
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
		p.CASECNT,
		od.LOTTABLE02, od.LOTTABLE03, od.LOTTABLE04, od.LOTTABLE05, od.LOTTABLE07, od.LOTTABLE08, 
		lli.lot, 
		lxl.ID, 
		l.LOGICALLOCATION 
	from #ORDERDETAIL od join wh1.LOTATTRIBUTE lli on 
					od.sku = lli.SKU and od.storerkey = lli.STORERKEY 
					and lli.LOTTABLE02 = case when isnull(od.LOTTABLE02,'') = '' then lli.LOTTABLE02 else od.LOTTABLE02 end
					and lli.LOTTABLE03 = od.LOTTABLE03
					and lli.LOTTABLE04 = case when isnull(od.LOTTABLE02,'') = '' then lli.LOTTABLE04 else od.LOTTABLE04 end
					and lli.LOTTABLE05 = case when isnull(od.LOTTABLE02,'') = '' then lli.LOTTABLE05 else od.LOTTABLE05 end
					and lli.LOTTABLE07 = od.LOTTABLE07
					and lli.LOTTABLE08 = od.LOTTABLE08
					join wh1.LOTXLOCXID lxl on lli.LOT = lxl.LOT 
					join wh1.loc l on l.LOC = lxl.loc
					left join wh1.INVENTORYHOLD ih on ih.loc = lxl.LOC or ih.LOT = lxl.LOT --or isnull(ih.ID,'') = isnull(lxl.id,'')
					join wh1.PACK p on lli.LOTTABLE01 = p.PACKKEY
					where lxl.qty != 0 and (l.LOC != 'LOST')
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

	print 'удаляем товары из остатков по EA_IN'
	
	delete sq
	--select *
		from #skuqty sq 
			join wh1.LOTXLOCXID lli on sq.sku = lli.SKU and sq.storerkey = lli.STORERKEY
			join wh1.LOTATTRIBUTE la on lli.LOT = la.LOT and	
					sq.sku = la.SKU and sq.storerkey = la.STORERKEY 
					and la.LOTTABLE02 = case when isnull(sq.LOTTABLE02,'') = '' then la.LOTTABLE02 else sq.LOTTABLE02 end
					and la.LOTTABLE03 = sq.LOTTABLE03
					and la.LOTTABLE04 = case when isnull(sq.LOTTABLE02,'') = '' then la.LOTTABLE04 else sq.LOTTABLE04 end
					and la.LOTTABLE05 = case when isnull(sq.LOTTABLE02,'') = '' then la.LOTTABLE05 else sq.LOTTABLE05 end
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

while exists(select sku from #orderdetail)
	begin print'есть необработанные товары'
	
		--select top(1) @odid = ID, @qtypickneed = qty from #orderdetail --выбор строки товара из заказа. 15:31 2011/06/08
--		select top(1) @sku = sku, @odid = ID, @qtypickneed = qty - floor(qty/case when casecnt = 0 or isnull(casecnt,0) = 0 then 1 else casecnt end)*isnull(casecnt,0) from #orderdetail --выбор строки товара из заказа.		
select top(1) @sku = sku, @odid = ID, @qtypickneed = qty -
case when (case when casecnt = 0 or isnull(casecnt,0) = 0 then 1 else casecnt end) = 1 then 0 else 
floor(qty/casecnt)*casecnt end
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
					and fq.LOTTABLE02 = case when isnull(od.LOTTABLE02,'') = '' then fq.LOTTABLE02 else od.LOTTABLE02 end
					and fq.LOTTABLE03 = od.LOTTABLE03
					and fq.LOTTABLE04 = case when isnull(od.LOTTABLE02,'') = '' then fq.LOTTABLE04 else od.LOTTABLE04 end
					and fq.LOTTABLE05 = case when isnull(od.LOTTABLE02,'') = '' then fq.LOTTABLE05 else od.LOTTABLE05 end
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


drop table #orderdetail
drop table #orders
drop table #skuqty
drop table #skuqtysku



--select * 
--	from wh1.LOTXLOCXID lli join #orderdetail od on
--	lli.

--select * from wh1.taskdetail where TASKTYPE = 'MV' and STATUS = 0
--select * from wh1.ORDERDETAIL where ORDERKEY = '0000001082'

--24775
--11433
--5936
