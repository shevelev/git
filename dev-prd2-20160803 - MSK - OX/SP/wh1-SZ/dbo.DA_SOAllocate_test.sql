ALTER PROCEDURE [dbo].[DA_SOAllocate_test] (
	@wh varchar(10)	= NULL
)
as

set nocount on



--update wh1.ORDERS set susr5 = '' where orderkey = '0000003483'
--declare @wh varchar(20) set @wh='WH1'


--select orderkey, externorderkey from wh1.orders where orderkey = '0000003167'
--return


declare @status int set @status = 0
declare @bs varchar(3) select @bs = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'
declare @orderkey varchar(20)
declare @statuswait varchar(20) set @statuswait = '����. ������' -- ���������� �� �������������� �����, �� ��� �� �����������������.
declare @statusno varchar(20) set @statusno = '����.����������' -- �����, ��� �������� ��� ������ � ���� ������
declare @statusnosku varchar(20) set @statusnosku = '��� �������' -- �����, ��� �������� ��� ������� �� ��������
declare @statusnoorder varchar(20) set @statusnoorder = '������' -- � ������ ��� �������
declare @statuserror varchar(20) set @statuserror = '������.�������' -- �����, ������� ���������� ��������.
declare @statusrun varchar(20) set @statusrun = '�������' -- ����� �������.



create table #qtyother (
sku varchar (20),
qty float,
id varchar (20))

create table #qtycase	(
id int identity (1,1),
qty float,
casecnt int
)

--print '��������, ���� �� ���������� ������.'
--select top(1) @orderkey = orderkey from wh1.orders where SUSR5 = @statuswait and STATUS > '09'
--	if ISNULL(@orderkey,'') != ''
--		begin 
--			print '����� �������. ��������� ������'
--			update wh1.orders set SUSR5 = @statusrun where ORDERKEY = @orderkey
--			insert into SOAllocateLog (orderkey, susr5) select @orderkey, @statusrun
--		end


print '�������� ������, ������� �� �������� � �� ���������������'
select o.*, lh.DEPARTURETIME into #orders 
from wh1.orders o join wh1.LOADORDERDETAIL lo on o.ORDERKEY = lo.SHIPMENTORDERID
join wh1.LOADSTOP ls on lo.LOADSTOPID = ls.LOADSTOPID
join wh1.loadhdr lh on ls.loadid = lh.loadid
where  o.STATUS >= '0' and o.STATUS <= '09' 
and o.ORDERKEY = '0000011651'
 --and lh.DEPARTURETIME >= GETDATE() 
 and lh.DEPARTURETIME <= dateadd(hh,24,GETDATE())

if @@ROWCOUNT = 0 -- ��� ����� �������
	begin
		print '��� ����� �������'
		goto endproc
	end

declare @t_orderqount int declare @t_orderkey varchar (20)

--select status, SUSR5, * from wh1.orders where orderkey = '0000000846'

--select * from wh1.taskdetail where sku = '17220'

--select * from #orders where susr5 = @statuswait
	
print '��������, ���� �� ������ ������� � ��������������'
	select @t_orderqount = COUNT (*) from #orders where susr5 = @statuswait
	if isnull(@t_orderqount,0) != 0
	begin
		select top(1) @t_orderkey = orderkey from #orders where susr5 = @statuswait order by ORDERKEY
		print '���������� ������� � �������, ��������� ������� = ' + cast(@t_orderqount as varchar(10)) + '. ������ ����� � '+ @t_orderkey +'.'
		
		--select editdate,dateadd(n,5,EDITDATE), * from wh1.ORDERS where ORDERKEY = @t_orderkey and dateadd(n,5,EDITDATE) <= getdate()
		
		
		if (select COUNT(*) from wh1.ORDERS where ORDERKEY = @t_orderkey and dateadd(n,3,EDITDATE) <= getdate()) != 0
		
		--if (select COUNT (*) from da_log 
		--	where (direction = 'SO_ALLOCATE' or direction = 'SO_WAVESTORE' or direction = 'SO_RELEASE') 
		--		and message = 'OK' and  right(objectID,10) = @t_orderkey) != 3
			begin
				update wh1.orders set susr5 = @statuserror, EDITDATE = GETDATE() where orderkey = @t_orderkey
				insert into SOAllocateLog (orderkey, susr5) select @t_orderkey, @statuserror
				print '����� �� ����� ���� ������� � �������������� ������'
				exec app_DA_SendMail '������ ��������������� ������� ������', @t_orderkey
			end
		
		goto endproc
		
	end

print '��������, ���� �� ������ ��������� ��������������'
select top(1) @orderkey = orderkey from #orders where isnull(SUSR5,'') = '' order by PRIORITY, DEPARTURETIME

if @orderkey is null
	begin -- �������, ��������� �������������� - ���.
		if (select COUNT(*) from #orders where susr5 = @statusno or susr5 = @statusnosku or susr5 = @statuserror) != 0
			begin
				print '���������� ������� �������'
				insert into SOAllocateLog (orderkey, susr5) 
					select oo.ORDERKEY, 'reset' from #orders oo where oo.SUSR5 != @statuswait and oo.SUSR5 != @statuserror
						
				update o set o.SUSR5 = '' , EDITDATE = getdate()
					from wh1.ORDERS o join #orders oo on o.ORDERKEY = oo.orderkey
					where oo.SUSR5 != @statuswait --and oo.SUSR5 != @statuserror
					goto endproc
			end
	end


declare @orderlinenumber varchar (10)

print '���� �����  ��� �������� ����������� ��� ��������������.'
select orderlinenumber, orderkey, sku, storerkey, ORIGINALQTY, lottable01, LOTTABLE02, LOTTABLE03, LOTTABLE04, LOTTABLE05, LOTTABLE06, LOTTABLE07, LOTTABLE08, LOTTABLE09, LOTTABLE10 
	into #orderdetail 
	from wh1.ORDERDETAIL 
	where ORDERKEY = @orderkey --and SKU = '24858'--and isnull(lottable01,'') != ''--'0000017585'

if (select COUNT(*) from #orderdetail) = 0
	begin
		print '� ������ � ' + @orderkey + ' ��� �� ����� ���������� �������.'
		update wh1.orders set susr5 = @statusnoorder, EDITDATE = getdate() where orderkey = @orderkey
		insert into SOAllocateLog (orderkey, susr5) select @orderkey, @statusnoorder
		goto endproc
	end

select * from #orderdetail --�������


print '�������� ������� ���������� �������'
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
	into #skuqty
	from wh1.LOTXLOCXID lli join wh1.LOTATTRIBUTE la on lli.LOT = la.LOT
	join #orderdetail od on  
						od.LOTTABLE01 = case when od.LOTTABLE01 = '' 
							then '' 
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
						and (od.LOTTABLE04 = la.LOTTABLE04 or od.LOTTABLE04 = '')
						and (od.LOTTABLE05 = la.LOTTABLE05 or od.LOTTABLE05 = '')
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


select 'skuqty', * from #skuqty --�������

if (select COUNT(*) from #skuqty) = 0
	begin
		print '��� ������ � ' + @orderkey + ' ��� �� ������ ������ �� �������� ������.'
		update wh1.orders set susr5 = @statusnosku, EDITDATE = getdate() where orderkey = @orderkey 
		insert into SOAllocateLog (orderkey, susr5) select @orderkey, @statusnosku		
		goto endproc
	end

--select * from #skuqty --�������

declare @sqqtyall float --���������� ������ �� ��������.
declare @qtyneed float --����������� ��������� ������ �� ������.
declare @sqqtyother float --���������� ������ �� �������� �������.
declare @sqqtycase float --���������� ������ �� �������� �����.
declare @sqqtypick float --���������� ������ �� �������� �����.
declare @orderedqty float --���������� ���������� ������ 
declare @id varchar (10) --�������� �������
declare @packqty int --���� ��������
declare @sku varchar(20) --��� ������

print '������������ ������ ������ �� �������'
while exists(select orderlinenumber from #orderdetail)
	begin
		select top(1) @orderlinenumber = orderlinenumber from #orderdetail

		--print '���������� ����������'
		select @orderedqty = originalqty, @sku = sku from #orderdetail where ORDERLINENUMBER = @orderlinenumber
		--print '���������� ���� � ��������'
		
		
		------------------------------------------------
		select @packqty = isnull(p.casecnt,1) from #orderdetail od left join wh1.pack p on od.lottable01 = p.packkey
			where ORDERLINENUMBER = @orderlinenumber
		print ''
		print '����� '+ @orderkey+'. ������ '+@orderlinenumber+'. ����� '+@sku+'. ���������� '+cast (@orderedqty as varchar(20))
		--'����� ��������� ���������� ������ �� �������� ������.'		
		select @sqqtyall = SUM(sq.qty)
			from #skuqty sq join #orderdetail od on sq.SKU = od.SKU
						and (case when isnull(od.LOTTABLE01,'') = '' OR ISNULL(od.LOTTABLE02,'') = ''
								then
									''
								else 
									od.LOTTABLE01 
								end
							=
							case when isnull(od.LOTTABLE01,'') = '' OR ISNULL(od.LOTTABLE02,'') = ''
								then
									''
								else
									sq.LOTTABLE01
								end)
						and od.LOTTABLE02 = sq.LOTTABLE02
						and od.LOTTABLE03 = sq.LOTTABLE03
						--and (od.LOTTABLE04 = sq.LOTTABLE04 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						--and (od.LOTTABLE05 = sq.LOTTABLE05 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and (od.LOTTABLE04 = sq.LOTTABLE04 or od.LOTTABLE04 = '')
						and (od.LOTTABLE05 = sq.LOTTABLE05 or od.LOTTABLE05 = '')
						--and od.LOTTABLE06 = sq.LOTTABLE06
						and od.LOTTABLE07 = sq.LOTTABLE07
						and od.LOTTABLE08 = sq.LOTTABLE08
						--and od.LOTTABLE09 = sq.LOTTABLE09
						--and od.LOTTABLE10 = sq.LOTTABLE10
						left join wh1.PACK p on p.PACKKEY = sq.lottable01
			where od.ORDERLINENUMBER = @orderlinenumber
			--group by p.casecnt
			
			
		print '### ����� ��������� ���������� ������ �� �������� ������ = ' + cast(isnull(@sqqtyall,0) as varchar(20))

			if isnull(@sqqtyall,0) = 0 
				begin 
					print '������ ��� ��������� �� ������'
					goto EndWorkOneLine 
				end
				
			set @qtyneed = @sqqtyall - @orderedqty

		print '����� ��������� ���������� ������ �� �������� ������ �������.'		
		--select sq.sku, sq.qty, sq.id into #qtyother
		insert into #qtyother
			select sq.sku, sq.qty, sq.id 
			from #skuqty sq join #orderdetail od on sq.SKU = od.SKU
						--and (case when isnull(od.LOTTABLE01,'') = '' 
						--		then sq.LOTTABLE01 
						--		else case when ISNULL(od.LOTTABLE02,'') = '' then '' else od.LOTTABLE01 end
						--		end 
						and (case when isnull(od.LOTTABLE01,'') = '' OR ISNULL(od.LOTTABLE02,'') = ''
								then
									''
								else 
									od.LOTTABLE01 
								end
							=
							case when isnull(od.LOTTABLE01,'') = '' OR ISNULL(od.LOTTABLE02,'') = ''
								then
									''
								else
									sq.LOTTABLE01
								end)
						and od.LOTTABLE02 = sq.LOTTABLE02
						and od.LOTTABLE03 = sq.LOTTABLE03
						--and (od.LOTTABLE04 = sq.LOTTABLE04 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						--and (od.LOTTABLE05 = sq.LOTTABLE05 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and (od.LOTTABLE04 = sq.LOTTABLE04 or od.LOTTABLE04 = '')
						and (od.LOTTABLE05 = sq.LOTTABLE05 or od.LOTTABLE05 = '')
						and od.LOTTABLE07 = sq.LOTTABLE07
						and od.LOTTABLE08 = sq.LOTTABLE08
			where od.ORDERLINENUMBER = @orderlinenumber and sq.LOCATIONTYPE = 'other'

--select * from #skuqty			
--select * from #qtyother --�������

		print '������� ����� ��������.'
		while exists(select top(1) id from #qtyother where qty <= @orderedqty) and @orderedqty != 0
			begin
				--print ''
				select top(1) @id = id from #qtyother where qty <= @orderedqty
				set @orderedqty = @orderedqty - (select qty from #qtyother where @id = id)
				delete from #qtyother where ID = @id
			end

		--print '����� ��������� ���������� ������ �� �������� ������ �����.'	
		delete from #qtycase		
		insert into #qtycase	
		select 
			SUM(sq.qty) qty, p.casecnt
			from #skuqty sq join #orderdetail od on sq.SKU = od.SKU
						and (case when isnull(od.LOTTABLE01,'') = '' OR ISNULL(od.LOTTABLE02,'') = ''
								then
									''
								else 
									od.LOTTABLE01 
								end
							=
							case when isnull(od.LOTTABLE01,'') = '' OR ISNULL(od.LOTTABLE02,'') = ''
								then
									''
								else
									sq.LOTTABLE01
								end)
						and od.LOTTABLE02 = sq.LOTTABLE02
						and od.LOTTABLE03 = sq.LOTTABLE03
						--and (od.LOTTABLE04 = sq.LOTTABLE04 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						--and (od.LOTTABLE05 = sq.LOTTABLE05 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and (od.LOTTABLE04 = sq.LOTTABLE04 or od.LOTTABLE04 = '')
						and (od.LOTTABLE05 = sq.LOTTABLE05 or od.LOTTABLE05 = '')						
						--and od.LOTTABLE06 = sq.LOTTABLE06
						and od.LOTTABLE07 = sq.LOTTABLE07
						and od.LOTTABLE08 = sq.LOTTABLE08
						--and od.LOTTABLE09 = sq.LOTTABLE09
						--and od.LOTTABLE10 = sq.LOTTABLE10
						left join wh1.pack p on p.packkey = sq.lottable01
			where od.ORDERLINENUMBER = @orderlinenumber and sq.LOCATIONTYPE = 'case'
			group by p.casecnt
			
--select * from #qtycase	--�������		
		select @sqqtycase = SUM(qty) from #qtycase
		set @sqqtycase = isnull(@sqqtycase,0)

		print '����� ��������� ���������� ������ �� �������� ������ ����� ' + cast((@sqqtycase/ @packqty) as varchar(20))

declare @caseid int --��������� ������ ������� � ��������

		
while (select COUNT (id) from #qtycase) != 0
	begin
		--������������ ���������� ������ �������, ��������� �� ������
		select top(1) @caseid = ID, @sqqtycase = qty,  @packqty = isnull(casecnt,0) from #qtycase order by id

		--if @packqty = 0 
		--	begin
		--		declare @errormsg = '����� ' + @sku
		--		exec app_DA_SendMail '������ ��������������� ������� ������', @errormsg
		--	end
		
		if (floor((@sqqtycase / @packqty))*@packqty - floor((@orderedqty / @packqty))*@packqty) < 0
			begin
				print '����������� ���������� ('+cast (@orderedqty as varchar(20))+') �������'
				set @orderedqty = @orderedqty - floor((@sqqtycase / @packqty))*@packqty
				print '������ ��� ��������� ('+cast(@sqqtycase as varchar(20))+')'
			end
		else
			begin
				print '������������ ��������� ('+cast (@orderedqty as varchar(20))+') �������'
				set @orderedqty = @orderedqty - floor((@orderedqty / @packqty))*@packqty
				print '������ ��� ��������� ('+cast(@sqqtycase as varchar(20))+')'
				goto qtypick
			end		
	
		delete from #qtycase where id = @caseid
	end

qtypick:
print '���������� ����������� ���������� '+cast (@orderedqty as varchar(20))


--print '����� ��������� ���������� ������ �� �������� ������ �����.'		
		select @sqqtypick = SUM(sq.qty)
			from #skuqty sq join #orderdetail od on sq.SKU = od.SKU
						and (case when isnull(od.LOTTABLE01,'') = '' OR ISNULL(od.LOTTABLE02,'') = ''
								then
									''
								else 
									od.LOTTABLE01 
								end
							=
							case when isnull(od.LOTTABLE01,'') = '' OR ISNULL(od.LOTTABLE02,'') = ''
								then
									''
								else
									sq.LOTTABLE01
								end)
						and od.LOTTABLE02 = sq.LOTTABLE02
						and od.LOTTABLE03 = sq.LOTTABLE03
						--and (od.LOTTABLE04 = sq.LOTTABLE04 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						--and (od.LOTTABLE05 = sq.LOTTABLE05 OR ISNULL(od.LOTTABLE02,'') = '')-- OR ISNULL(od.LOTTABLE02,@bs) = @bs)
						and (od.LOTTABLE04 = sq.LOTTABLE04 or od.LOTTABLE04 = '')
						and (od.LOTTABLE05 = sq.LOTTABLE05 or od.LOTTABLE05 = '')						
						--and od.LOTTABLE06 = sq.LOTTABLE06
						and od.LOTTABLE07 = sq.LOTTABLE07
						and od.LOTTABLE08 = sq.LOTTABLE08
						--and od.LOTTABLE09 = sq.LOTTABLE09
						--and od.LOTTABLE10 = sq.LOTTABLE10
			where od.ORDERLINENUMBER = @orderlinenumber and sq.LOCATIONTYPE = 'pick'

			set @sqqtypick = isnull(@sqqtypick,0)
		print '����� ��������� ���������� ������ �� �������� ������ �����. '	+ cast(@sqqtypick as varchar(20))
		print '���������� ������ �� ������ �� �������� ������ '+cast (@qtyneed as varchar(20))

		if (@sqqtypick - @orderedqty) >= 0 
			begin
				print '����������� ���������� ������ ���� ���������� - ���������� ���������'
				goto EndWorkOneLine
			end
		else
			begin
				if @qtyneed < 0
					begin
						print '������������ ��������� ������ ��� ��������� � ������ ��� ��������� �� ������ - ������������ ��������� ������'
						goto EndWorkOneLine
					
					end
				else
					begin
						print '����������� ���������� ������ ��� �������� � ������ ��� ��������� �� ������ - ���� ����������'
						update wh1.orders set susr5 = @statusno, EDITDATE = getdate() where orderkey = @orderkey
						insert into SOAllocateLog (orderkey, susr5) select @orderkey, @statusno
						--exec dbo.SZ_MVTask
						goto EndProc
					end
			end

		EndWorkOneLine:		
		delete from #orderdetail where orderlinenumber = @orderlinenumber
	end

if not exists(select orderlinenumber from #orderdetail) --and @status = 1
	begin
		print '��� ������ ����, ������ ����� ������ � ����� ������'
		update wh1.orders set susr5 = @statuswait, EDITDATE = getdate() where orderkey = @orderkey
		insert into SOAllocateLog (orderkey, susr5) select @orderkey, @statuswait
		select orderkey, externorderkey from wh1.orders where orderkey = @orderkey
	end


endproc:

--drop table #orders
--drop table #orderdetail
--drop table #skuqty
--drop table #qtyother 
--drop table #qtycase


/*
select adddate, editdate, susr5,status,adddate,* from wh1.orders where status <= '09'--5orderkey = '0000000658'
select  adddate, editdate, susr5,status,* from wh1.orders where status <= '09' and susr5 = ''
select o.susr5,o.status,o.editdate,l.DEPARTURETIME, * 
from wh1.orders o join wh1.loadhdr l on o.loadid = l.loadid
 where o.orderkey = '0000003344' and o.susr5 = '������.�������'
 */
 
 --select LOADID, * from wh1.orders where orderkey = '0000003379'
 --update wh1.orders set status = '78' where ORDERKEY = '0000003188'
 
--select top(20) * from soallocatelog order by adddate desc
--select * from da_log where objectID  like '%0000001757%'
--select adddate, * from wh1.TASKDETAIL where tasktype = 'MV' and STATUS = '0' order by serialkey
--select * from wh1.LOTXLOCXID where LOC = 'ea_in' and QTY > 0
--select adddate, *  from wh1.taskdetaillog 
--select adddate, susr5,status,adddate,* from wh1.orders where status <= '09' order by adddate desc
--select td.adddate, la.* from wh1.TASKDETAIL td join wh1.lotattribute la on td.lot = la.lot where td.tasktype = 'MV' and td.STATUS = '0' order by td.adddate desc



--select listname,* from wh1.codelkup where CODE = '9' or CODE = '3' or CODE = '0' group by listname
--delete from wh1.taskdetaillog 

--select status, adddate, * from wh1.TASKDETAIL where tasktype = 'MV' and ADDDATE > '2011-11-07 23:00:00'

--update wh1.ORDERS
--set externorderkey = case when isnull(externorderkey ,'') = '' then 'ext_'+ORDERKEY else externorderkey end
--	where STATUS < '14'

--select ORDERKEY, EXTERNORDERKEY
--	from wh1.ORDERS 	where STATUS < '14'

--update wh1.ORDERS set susr5 = '' 
--select editdate, status from wh1.orders where orderkey = '0000003483'


