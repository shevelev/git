ALTER PROCEDURE [dbo].[DA_SOAllocate_searchSO] (
	@wh varchar(10)	
)
as
declare @bs varchar(3) select @bs = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'
declare @orderkey varchar(20)
declare @statuswait varchar(20) set @statuswait = '����. ������' -- ���������� �� �������������� �����, �� ��� �� �����������������.
declare @statusno varchar(20) set @statusno = '����.����������' -- �����, ��� �������� ��� ������ � ���� ������


print '�������� ������, ������� �� �������� � �� ���������������'
select o.*, lh.DEPARTURETIME into #orders 
from wh1.orders o join wh1.LOADORDERDETAIL lo on o.ORDERKEY = lo.SHIPMENTORDERID
join wh1.LOADSTOP ls on lo.LOADSTOPID = ls.LOADSTOPID
join wh1.loadhdr lh on ls.loadid = lh.loadid
where o.STATUS < 9 and lh.DEPARTURETIME >= GETDATE() and lh.DEPARTURETIME <= dateadd(hh,24,GETDATE())

if @@ROWCOUNT = 0 -- ��� ����� �������
	goto endproc
	
print '��������, ���� �� ������ ������� � ��������������'
if exists(select * from #orders where susr5 = @statuswait) 
	goto endproc

print '��������, ���� �� ������ ��������� ��������������'
select top(1) @orderkey = orderkey from #orders where isnull(SUSR5,'') = '' order by DEPARTURETIME

if @orderkey = null
	begin -- �������, ��������� �������������� - ���.
		select * from #orders where susr5 = @statusno
		if @@ROWCOUNT != 0
			update o set o.SUSR5 = '' 
				from wh1.ORDERS o join #orders oo on o.ORDERKEY = oo.orderkey
				where oo.SUSR5 = @statusno
				goto endproc
	end


declare @orderlinenumber varchar (10)

print '���� �����  ��� �������� ����������� ��� ��������������.'
select orderlinenumber, orderkey, sku, storerkey, ORIGINALQTY, lottable01, LOTTABLE02, LOTTABLE03, LOTTABLE04, LOTTABLE05, LOTTABLE06, LOTTABLE07, LOTTABLE08, LOTTABLE09, LOTTABLE10 
	into #orderdetail 
	from wh1.ORDERDETAIL 
	where ORDERKEY = @orderkey and isnull(lottable01,'') != ''--'0000017585'

print '�������� ������� ���������� �������'
select sum(lli.QTY - lli.qtyallocated) qty, 
						od.LOTTABLE01,
						od.LOTTABLE02,
						od.LOTTABLE03,
						od.LOTTABLE04,
						od.LOTTABLE05,
						--od.LOTTABLE06,
						od.LOTTABLE07,
						od.LOTTABLE08,
						--od.LOTTABLE09,
						--od.LOTTABLE10,
	lli.sku, lli.loc, l.locationtype, lli.id
	into #skuqty
	from wh1.LOTXLOCXID lli join wh1.LOTATTRIBUTE la on lli.LOT = la.LOT
	join #orderdetail od on (od.LOTTABLE01 = la.LOTTABLE01 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and od.LOTTABLE02 = la.LOTTABLE02
						and od.LOTTABLE03 = la.LOTTABLE03
						and (od.LOTTABLE04 = la.LOTTABLE04 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and (od.LOTTABLE05 = la.LOTTABLE05 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						--and od.LOTTABLE06 = la.LOTTABLE06
						and od.LOTTABLE07 = la.LOTTABLE07
						and od.LOTTABLE08 = la.LOTTABLE08
						--and od.LOTTABLE09 = la.LOTTABLE09
						--and od.LOTTABLE10 = la.LOTTABLE10
						and od.sku = lli.SKU
						and od.storerkey = lli.STORERKEY
	join wh1.loc l on l.loc = lli.loc
	left join wh1.INVENTORYHOLD ih on ih.loc = lli.LOC or ih.LOT = lli.LOT or ih.ID = lli.id
	where lli.QTY > 0 and isnull(ih.HOLD,'') != 1
	group by lli.sku, lli.loc, l.LOCATIONTYPE, od.LOTTABLE01, od.LOTTABLE02, od.LOTTABLE03, od.LOTTABLE04, od.LOTTABLE05,
						--od.LOTTABLE06,
						od.LOTTABLE07, od.LOTTABLE08, lli.ID
						--od.LOTTABLE09, od.LOTTABLE10

print '������������ ������ ������ �� �������'
declare @sqqtyall float --���������� ������ �� ��������.
declare @qtyneed float --����������� ��������� ������ �� ������.
declare @sqqtyother float --���������� ������ �� �������� �������.
declare @sqqtycase float --���������� ������ �� �������� �����.
declare @sqqtypick float --���������� ������ �� �������� �����.
declare @orderedqty float --���������� ���������� ������ 
declare @id varchar (10) --�������� �������
declare @packqty int --���� ��������


while exists(select orderlinenumber from #orderdetail)
	begin
		select top(1) @orderlinenumber = orderlinenumber from #orderdetail

		print '���������� ����������'
		select @orderedqty = originalqty from #orderdetail where ORDERLINENUMBER = @orderlinenumber
		print '���������� ���� � ��������'
		select @packqty = isnull(p.casecnt,1) from #orderdetail od left join wh1.pack p on od.lottable01 = p.packkey
			where ORDERLINENUMBER = @orderlinenumber

		print '����� ��������� ���������� ������ �� �������� ������.'		
		select @sqqtyall = SUM(sq.qty)
			from #skuqty sq join #orderdetail od on sq.SKU = od.SKU
						and (od.LOTTABLE01 = sq.LOTTABLE01 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and od.LOTTABLE02 = sq.LOTTABLE02
						and od.LOTTABLE03 = sq.LOTTABLE03
						and (od.LOTTABLE04 = sq.LOTTABLE04 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and (od.LOTTABLE05 = sq.LOTTABLE05 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						--and od.LOTTABLE06 = sq.LOTTABLE06
						and od.LOTTABLE07 = sq.LOTTABLE07
						and od.LOTTABLE08 = sq.LOTTABLE08
						--and od.LOTTABLE09 = sq.LOTTABLE09
						--and od.LOTTABLE10 = sq.LOTTABLE10
			where od.ORDERLINENUMBER = @orderlinenumber

			if isnull(@sqqtyall,0) = 0 goto EndWorkOneLine --������ ��� ��������� �� ������
			set @qtyneed = @sqqtyall - @orderedqty

		print '����� ��������� ���������� ������ �� �������� ������ �������.'		
		select sq.sku, sq.qty, sq.id into #qtyother
			from #skuqty sq join #orderdetail od on sq.SKU = od.SKU
						and (od.LOTTABLE01 = sq.LOTTABLE01 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and od.LOTTABLE02 = sq.LOTTABLE02
						and od.LOTTABLE03 = sq.LOTTABLE03
						and (od.LOTTABLE04 = sq.LOTTABLE04 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and (od.LOTTABLE05 = sq.LOTTABLE05 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						--and od.LOTTABLE06 = sq.LOTTABLE06
						and od.LOTTABLE07 = sq.LOTTABLE07
						and od.LOTTABLE08 = sq.LOTTABLE08
						--and od.LOTTABLE09 = sq.LOTTABLE09
						--and od.LOTTABLE10 = sq.LOTTABLE10
			where od.ORDERLINENUMBER = @orderlinenumber and sq.LOCATIONTYPE = 'other'

		print '������� ����� ��������.'
		while exists(select top(1) id from #qtyother where qty <= @orderedqty) and @orderedqty != 0
			begin
				select top(1) @id = id from #qtyother where qty <= @orderedqty
				set @orderedqty = @orderedqty - (select qty from #qtyother where @id = id)
				delete from #qtyother where ID = @id
			end

		print '����� ��������� ���������� ������ �� �������� ������ �����.'		
		select @sqqtycase = SUM(sq.qty)
			from #skuqty sq join #orderdetail od on sq.SKU = od.SKU
						and (od.LOTTABLE01 = sq.LOTTABLE01 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and od.LOTTABLE02 = sq.LOTTABLE02
						and od.LOTTABLE03 = sq.LOTTABLE03
						and (od.LOTTABLE04 = sq.LOTTABLE04 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and (od.LOTTABLE05 = sq.LOTTABLE05 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						--and od.LOTTABLE06 = sq.LOTTABLE06
						and od.LOTTABLE07 = sq.LOTTABLE07
						and od.LOTTABLE08 = sq.LOTTABLE08
						--and od.LOTTABLE09 = sq.LOTTABLE09
						--and od.LOTTABLE10 = sq.LOTTABLE10
			where od.ORDERLINENUMBER = @orderlinenumber and sq.LOCATIONTYPE = 'case'

		if (floor((@sqqtycase / @packqty))*@packqty - floor((@orderedqty / @packqty))*@packqty) < 0
			begin
				print '����������� ���������� ������� ������ ��� ���������'
				set @orderedqty = @orderedqty - floor((@sqqtycase / @packqty))*@packqty
			end
		else
			begin
				print '������������ ��������� ������� ������ ��� ���������'
				set @orderedqty = @orderedqty - floor((@orderedqty / @packqty))*@packqty
			end
			
print '����� ��������� ���������� ������ �� �������� ������ �����.'		
		select @sqqtypick = SUM(sq.qty)
			from #skuqty sq join #orderdetail od on sq.SKU = od.SKU
						and (od.LOTTABLE01 = sq.LOTTABLE01 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and od.LOTTABLE02 = sq.LOTTABLE02
						and od.LOTTABLE03 = sq.LOTTABLE03
						and (od.LOTTABLE04 = sq.LOTTABLE04 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and (od.LOTTABLE05 = sq.LOTTABLE05 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						--and od.LOTTABLE06 = sq.LOTTABLE06
						and od.LOTTABLE07 = sq.LOTTABLE07
						and od.LOTTABLE08 = sq.LOTTABLE08
						--and od.LOTTABLE09 = sq.LOTTABLE09
						--and od.LOTTABLE10 = sq.LOTTABLE10
			where od.ORDERLINENUMBER = @orderlinenumber and sq.LOCATIONTYPE = 'pick'

		if (@sqqtypick - @orderedqty) < 0 
			begin
				print '����������� ���������� ������ ���� ���������� - ���������� ���������'
				goto EndWorkOneLine
			end
		else
			begin
				if @qtyneed < 0
					begin
						print '������������ ��������� ������ ��� ���������
								� ������ ��� ��������� �� ������ - ������������ ��������� ������'
						goto EndWorkOneLine
					
					end
				else
					begin
						print '����������� ���������� ������ ��� ��������
								� ������ ��� ��������� �� ������ - ���� ����������'
						update wh1.orders set susr5 = @statusno where orderkey = @orderkey
						goto EndProc
					end
			end
		


		EndWorkOneLine:		
		delete from #orderdetail where orderlinenumber = @orderlinenumber
	end

if not exists(select orderlinenumber from #orderdetail)
	begin
		print '��� ������ ����, ������ ����� ������ � ����� ������'
		update wh1.orders set susr5 = @statuswait where orderkey = @orderkey
		select @orderkey
	end


endproc:

drop table #orders
drop table #orderdetail
drop table #skuqty

--select susr5,* from #orders
--update wh1.ORDERS
--set externorderkey = case when isnull(externorderkey ,'') = '' then 'ext_'+ORDERKEY else externorderkey end
--	where STATUS < '14'

--select ORDERKEY, EXTERNORDERKEY
--	from wh1.ORDERS 	where STATUS < '14'

