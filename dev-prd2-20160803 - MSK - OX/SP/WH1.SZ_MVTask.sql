ALTER PROCEDURE [WH1].[SZ_MVTask] 
AS

set NOCOUNT on

	--set NOCOUNT on
		delete from wh1.taskdetail where STATUS = '0' and TASKTYPE = 'MV' and ADDWHO = 'dareplen'
	
	print '�������� ������, ������� �� �������� � �� ���������������'
	select o.*, lh.DEPARTURETIME
	into #orders 
	from wh1.orders o 
		join wh1.LOADORDERDETAIL lo on o.ORDERKEY = lo.SHIPMENTORDERID
		join wh1.LOADSTOP ls on lo.LOADSTOPID = ls.LOADSTOPID
		join wh1.loadhdr lh on ls.loadid = lh.loadid
	where o.STATUS >= '00' and o.STATUS <= '09'
		--and o.orderkey = '0000000952'  
		--and isnull(o.susr5,'') = ''  and lh.DEPARTURETIME >= GETDATE()
		and lh.DEPARTURETIME <= dateadd(hh,24,getdate())
	
	/* VC 26/08/2011 - ��������� ������������� ������� */
	
	create table #orderdetail_prepare (
		id int identity(1,1),
		qty float null,
		--eaqty float null,
		sku varchar(10) null,
		storerkey varchar(10) null,
		packkey varchar(10) null,
		casecnt float null,
		lottable02 varchar (50) null,
		lottable05 datetime null, --������� 28.04.2015 +4,5���
		orderkey varchar(18) null,
		ORDERLINENUMBER varchar(10) null --������� 16.06.2015
	)

	create table #orderdetail (
		id int identity(1,1),
		qty float null,
		--eaqty float null,
		sku varchar(10) null,
		storerkey varchar(10) null,
		packkey varchar(10) null,
		casecnt float null,
		lottable02 varchar (50) null,
		lottable05 datetime null  --������� 28.04.2015 +4,5���
	)

	print '�������� ����������� ���������� ������'
	/* VC 26/08/2011 begin*/
	print '   - �������� ������, ��������������� �� �������'
	/* 
		���� � ������ ������ ����� �����������, �� ���� ����� � _prepare �������
		�������� ���� orderlinenumber � �������� ��� � �����������.
	*/
	insert	into #orderdetail_prepare
	select SUM(od.ORIGINALQTY) qty, 
		od.SKU, 
		od.STORERKEY, 
		NULL,--op.PACKKEY,
		isnull(p.CASECNT,op.CASECNT) as CASECNT,
		od.LOTTABLE02, 
-- ATTENTION !!!
		od.LOTTABLE05,   --������� 28.04.2015 +4,5���
-- ATTENTION !!!
		od.ORDERKEY, od.ORDERLINENUMBER
	from	wh1.ORDERDETAIL od
		join #orders o on o.ORDERKEY = od.ORDERKEY
		join wh1.PACK op on op.PACKKEY = od.PACKKEY
		left join (
			select
				la.SKU,
				la.STORERKEY,
				la.LOTTABLE02,
				la.LOTTABLE05,  --������� 28.04.2015 +4,5���
				max(p.CASECNT) as CASECNT
			from wh1.LOT l
				join wh1.LOTATTRIBUTE la on la.LOT = l.LOT
				join wh1.PACK p on p.PACKKEY = la.LOTTABLE01
			where l.QTY > 0 and la.LOTTABLE01 <> 'STD'
			group by
				la.SKU,
				la.STORERKEY,
				la.LOTTABLE02,
				la.LOTTABLE05  --������� 28.04.2015 +4,5���
		) p on p.SKU = od.SKU and p.STORERKEY = od.STORERKEY
			and p.LOTTABLE02 = od.LOTTABLE02
			and (p.LOTTABLE05 = od.LOTTABLE05 or p.LOTTABLE05 is NULL and od.LOTTABLE04 is NULL)  --������� 28.04.2015 +4,5���
			
	where od.ORIGINALQTY != 0
	group by od.sku, od.storerkey,
		isnull(p.CASECNT,op.CASECNT),
		od.LOTTABLE02,/*od.LOTTABLE06, od.LOTTABLE04,*/ od.LOTTABLE05, o.TYPE, od.ORDERKEY, od.ORDERLINENUMBER
		
			 
	print '   - ��������� ������ � ��������� ������ 1 ����� � �����'
	/* ����� ������ ������ ��������������� � ������ �������� � ��� ��� �� ���� ������ ����� ��� ���������� */
	delete from #orderdetail_prepare where casecnt = 1
	
    print '   - ���������� ����� �������'
	update #orderdetail_prepare set
		qty = qty - case when isnull(casecnt,0) = 0 
							then 0 
							else floor(qty/casecnt)*casecnt 
						end
	
	print '   - ������� ������� ���������� ������ �� ������ �������� ������. ����������� �� �������'
	
	insert	into #orderdetail
	select SUM(qty) qty, 
		SKU, 
		STORERKEY, 
		packkey, 
		casecnt,
		LOTTABLE02,
		LOTTABLE05  --������� 28.04.2015 +4,5���
	from #orderdetail_prepare od 
	group by sku, storerkey, casecnt,
		od.LOTTABLE02,/*od.LOTTABLE06, od.LOTTABLE04,*/ od.LOTTABLE05,	od.packkey 
	/* VC 26/08/2011 end */

--select * from #orderdetail where sku = '19117'

	--delete from #orderdetail where sku != '27977'

	create table #skuqty (
		id int identity(1,1),
		casecnt float null,
		qty float null,
		qtycase float null,
		sku varchar(50) null,
		storerkey varchar(10) null,
		loc varchar(10) null,
		locationtype varchar (50) null,
		lottable01 varchar (50) null,
		lottable02 varchar (50) null,
		lottable05 datetime null,  --������� 28.04.2015 +4,5���
		lot varchar(10),
		pid varchar(20),
		locroute varchar (20)
	)
	select * into #skuqtysku from #skuqty where 1=2

	print '�������� ������ �� ��������'
	insert into #skuqty
		select 
			p.CASECNT,
			SUM(lxl.QTY-QTYALLOCATED) qty,
			floor(SUM(lxl.QTY-QTYALLOCATED)/(case when isnull(p.CASECNT,0) = 0 then 1 else p.CASECNT end))*isnull(p.CASECNT,0) ,
			 od.SKU, 
			 od.STORERKEY, 
			 lxl.loc, 
			 l.LOCATIONTYPE,
			p.CASECNT as LOTTABLE01,
			od.LOTTABLE02, /*od.LOTTABLE06,od.LOTTABLE04, */od.LOTTABLE05,	lli.lot, lxl.ID, l.LOGICALLOCATION 
		from #ORDERDETAIL od
			join wh1.LOTATTRIBUTE lli on od.sku = lli.SKU 
				and od.storerkey = lli.STORERKEY 
				and isnull(lli.LOTTABLE02,'') = isnull(od.LOTTABLE02,'')
				and isnull(lli.LOTTABLE05,'') = case when isnull(od.LOTTABLE05,'') = '' then isnull(lli.LOTTABLE05,'') else isnull(od.LOTTABLE05,'') end  --������� 28.04.2015 +4,5���
			join wh1.LOTXLOCXID lxl on lli.LOT = lxl.LOT 
			join wh1.loc l on l.LOC = lxl.loc
			left join wh1.INVENTORYHOLD ih on ih.loc = lxl.LOC or ih.LOT = lxl.LOT 
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

			lxl.LOC,
			od.LOTTABLE02,/*od.LOTTABLE06, od.LOTTABLE04,*/ od.LOTTABLE05 ,	lli.lot, lxl.id, l.LOGICALLOCATION 
		order by lli.lot
--select * from #skuqty order by sku

		print '������� ������ �� �������� �� EA_IN'
		delete sq
		--select *
			from #skuqty sq 
				join wh1.LOTXLOCXID lli on sq.sku = lli.SKU and sq.storerkey = lli.STORERKEY
				join wh1.LOTATTRIBUTE la on lli.LOT = la.LOT and	
						sq.sku = la.SKU and sq.storerkey = la.STORERKEY 
						and isnull(la.LOTTABLE02,'') = isnull(sq.LOTTABLE02,'')
						and isnull(la.LOTTABLE05,'') = case when isnull(sq.LOTTABLE05,'') = '' then isnull(la.LOTTABLE05,'') else isnull(sq.LOTTABLE05,'') end --������� 28.04.2015 +4,5���
			where lli.LOC = 'EA_IN' and lli.QTY != 0


	--select * from #orderdetail
	--select * from #skuqty

	declare @sku varchar (10)
	declare @odid int
	declare @sqid int
	declare @taskkey varchar(10)
	declare @qtypick float --���������� ������ �� ������ � ������
	declare @qtycase float --���������� ������ �� ������ � ��������
	declare @qtypickneed float --���������� ���������� ������

	declare @qtyneed float --����������� ���������� ������ � ���� �������� ������.
	declare @qtyneedcase float --����������� ���������� ������ � ���� �������� ������, ����������� �� �������.
	--declare @sku varchar(20) --��� ������

--select * from #orderdetail where sku = '19117'

	while exists(select sku from #orderdetail)
		begin print'���� �������������� ������'

			select top(1) @sku = sku, @odid = ID, @qtypickneed = qty 
			/* 
			VC 26/08/2011	
				����� ��� �� ������������� ������ ������ ���-�� ������� ��� ���, ������� 
				������ ��������� ����� �������, ������������ �� �������� QTY,
				������� ���������� ����� ����������� ������� �� �������
			*/
			/* - case when (case when casecnt = 0 or isnull(casecnt,0) = 0 then 1 else casecnt end) = 1 
				then 0 
				else floor(qty/casecnt)*casecnt end*/
			from #orderdetail --����� ������ ������ �� ������.		
			print '����������� ���������� ' + cast( @qtypickneed as varchar(20)) + '. ����� ' + @sku
			
			-- ������� ������� �� ������ �� ������
			insert into #skuqtysku
				select 
					fq.casecnt,
					fq.qty,
					fq.qtycase,
					fq.sku,fq.storerkey,fq.loc,fq.locationtype,
					fq.lottable01,
					fq.lottable02,
					fq.lottable05, --������� 28.04.2015 +4,5���
					fq.lot, fq.pid, fq.locroute
				from	#skuqty fq 
					join #orderdetail od 
					    on fq.sku = od.sku 
					    and fq.storerkey = od.storerkey
					    and isnull(fq.LOTTABLE02,'') = isnull(od.LOTTABLE02,'')
					    and isnull(fq.LOTTABLE05,'') = case when isnull(od.LOTTABLE05,'') = '' then isnull(fq.LOTTABLE05,'') else isnull(od.LOTTABLE05,'') end --������� 28.04.2015 +4,5���
				where od.id= @odid
				
				select @qtypick = isnull(SUM(qty),0) from #skuqtysku where locationtype = 'pick'
				
				if @qtypick < @qtypickneed 
					begin -- ���������� ������ � ���� �������� ������ ������ ������������.
						
						print 'qtypick'+cast(isnull(@qtypick,0) as varchar(20))+'. qtyneed '+cast(isnull(@qtyneed,0) as varchar(20))+'. ���������� ������ � ���� �������� ������ ������ ������������.'
						
						set @qtyneed = @qtypickneed - @qtypick --��������� ���������� ������ � ���� �������� ������
						
						--������� ������ �� ������� �����������
						
						delete from #skuqtysku where locationtype = 'pick'
						
						--������� ������ ��� ���������� �����������
						
						while (select COUNT (id) from #skuqtysku) != 0 and @qtyneed != 0
							begin
								--��� ���� ������ �� ������
								select top(1) @sqid = ID, @qtycase = qtycase from #skuqtysku 
								if (@qtycase < @qtyneed)
									begin 
										print 'qtypick '+cast(isnull(@qtypick,0) as varchar(20))+'. qtyneed '+cast(isnull(@qtyneed,0) as varchar(20))+'. ��������� ���������� ������ ����������, ��������� ������ �� ����������� ����� ����������'
										exec dbo.DA_GetNewKey 'wh1','TASKDETAILKEY',@taskkey output

										INSERT INTO wh1.TaskDetail 
											(AddDate, AddWho, EditDate, EditWho, 
											TaskDetailKey, TaskType, Storerkey, 
											Sku, Lot, UOM, UOMQty, qty, FromLoc, FromID, ToLoc, ToID, Status, Priority, 
											Holdkey, UserKey, ListKey, StatusMsg, ReasonKey, CaseId, UserPosition, 
											UserKeyOverride, OrderLineNumber, PickDetailKey, LogicalFromLoc, LogicalToLoc, FinalToLoc ) 
											select
												getdate(), 'DaReplen', getdate(), 'DaReplen',
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
										print '��������� ���������� ������ '
										select @qtyneedcase = @qtyneed
											from #skuqtysku 
											where id = @sqid
										print '������� ����� �� ����������� @qtyneed='+cast(@qtyneed as varchar)
										
										exec dbo.DA_GetNewKey 'wh1','TASKDETAILKEY',@taskkey output
										INSERT INTO wh1.TaskDetail 
											(AddDate, AddWho, EditDate, EditWho, 
											TaskDetailKey, TaskType, Storerkey, 
											Sku, Lot, UOM, UOMQty, QTY, FromLoc, FromID, ToLoc, ToID, Status, Priority, 
											Holdkey, UserKey, ListKey, StatusMsg, ReasonKey, CaseId, UserPosition, 
											UserKeyOverride, OrderLineNumber, PickDetailKey, LogicalFromLoc, LogicalToLoc, FinalToLoc ) 
											select
												getdate(), 'DaReplen', getdate(), 'DaReplen',
												@taskkey, 'MV', '001', 
												sku, lot, '6', 
												CEILING(@qtyneed/casecnt)*casecnt as uomqty, 
												CEILING(@qtyneed/casecnt)*casecnt as qty, 
												--@qtyneed as uomqty, 
												--@qtyneed as qty, 
												loc, pid, 'EA_IN', '', '0', '5',
												' ', ' ', ' ', ' ', ' ', ' ', '1',
												' ', '   ', '   ', locroute, 'EA_IN', ' '
												from #skuqtysku
												where id = @sqid and qty != 0
												
										print '������� ������ � ���'
										INSERT INTO wh1.TaskDetailLog
											(AddDate, AddWho, EditDate, EditWho, 
											TaskDetailKey, TaskType, Storerkey, 
											Sku, Lot, UOM, UOMQty, QTY, FromLoc, FromID, ToLoc, ToID, Status, Priority, 
											Holdkey, UserKey, ListKey, StatusMsg, ReasonKey, CaseId, UserPosition, 
											UserKeyOverride, OrderLineNumber, PickDetailKey, LogicalFromLoc, LogicalToLoc, FinalToLoc ) 
											select
												getdate(), 'DaReplen', getdate(), 'DaReplen',
												@taskkey, 'MV', '001', 
												sku, lot, '6', 
												CEILING(@qtyneed/casecnt)*casecnt as uomqty, 
												CEILING(@qtyneed/casecnt)*casecnt as qty, 
												--@qtyneed as uomqty, 
												--@qtyneed as qty, 
												loc, pid, 'EA_IN', '', '0', '5',
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
					begin -- ���������� ������ � ���� �������� ������ ������������� ����� - ���������� �������.
					print 'qtypick '+cast(isnull(@qtypick,0) as varchar(20))+'. qtyneed '+cast(isnull(@qtyneed,0) as varchar(20))+'. ���������� ������ � ���� �������� ������ ������������� ����� - ���������� �������.'
					end
					
				--print '������� ������ �� ����������'
			delete from #skuqtysku
			delete #orderdetail where ID = @odid
		end


	delete from wh1.TASKDETAIL where TASKTYPE = 'MV' and QTY = 0 and STATUS = 0

	drop table #orderdetail_prepare
	drop table #orderdetail
	drop table #orders
	drop table #skuqty
	drop table #skuqtysku

