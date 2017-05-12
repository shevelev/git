--################################################################################################
--         ��������� �������������� ����� ��� �����
--################################################################################################
ALTER PROCEDURE [dbo].[Unreserved]
	@wavekey varchar (10) = null, -- ����� �����
	@orderkey varchar (15) = null -- ����� ������
AS
	declare 
			@orderlinenumber varchar (20), @sku varchar (20), @loc varchar (15), @lot varchar (15),
			@i int,
			@j int

select orderkey into #ok from wh1.orders where 1=2

print '-- �������� ���� �� ����� �����'
if ((select count (orderkey) from wh1.wavedetail where wavekey = @wavekey) = 0) 
	begin
		print '-- ����� ���, ���� �� ����� ����� �����'
		if ((select count (orderkey) from wh1.orders where orderkey = @orderkey and status <= '17' and status >= '14') = 0)
			begin
				print '-- ������������������ ������ ���'
				goto endproc
			end
		else
			begin
				print '-- ���� �����'
				insert into #ok (orderkey ) values (@orderkey)
			end
	end
else
	begin
		print '-- ���� �����'
		if ((select count (wd.orderkey) from wh1.wavedetail wd join wh1.orders o on wd.orderkey = o.orderkey where wd.wavekey = @wavekey and status <= '17' and status >= '14') = 0)
			begin
				print '-- ��� ����������������� ������� � �����'
				goto endproc
			end
		else
			begin
				print '-- ���� ����������������� ������ � �����'
				insert into #ok (orderkey) select wd.orderkey from wh1.wavedetail wd join wh1.orders o on wd.orderkey = o.orderkey where wd.wavekey = @wavekey and status <= '17' and status >= '14'
			end
	end


	set @j = 1

while (select count (orderkey) from #ok) > 0
	begin
		select top (1) @orderkey = orderkey from #ok order by orderkey
		print '-- ����� � ' + @orderkey
		select identity (int,1,1) id, orderkey, orderlinenumber, loc, lot, qty, sku into #loc from wh1.pickdetail where orderkey = @orderkey order by orderlinenumber
		set @i = 1
		while @i <= (select count (id) from #loc)
			begin
				print '-- ����� ����� ' + convert(varchar(15),@i)
select @sku = sku, @loc = loc, @lot = lot from #loc where id = @i
print ' -- ����� ' + @sku + ' -- ������ ' + @loc + ' -- lot ' + @lot
				print '-- ���������� ������������������ ���������� ������ lotxlocxid'
				update sxl set sxl.qtyallocated = sxl.qtyallocated - l.qty, editwho = 'report', editdate = getdate() from wh1.lotxlocxid sxl join #loc l on sxl.loc = l.loc and sxl.lot = l.lot where l.id = @i and sxl.qty > 0
				print '-- ���������� ������������������ ���������� ������ skuxloc'
				update sxl set sxl.qtyallocated = sxl.qtyallocated - l.qty, editwho = 'report', editdate = getdate() from wh1.skuxloc sxl join #loc l on sxl.loc = l.loc where l.id = @i and sxl.qty > 0
				print '-- ���������� ������������������ ���������� ������ lot'
				update sxl set sxl.qtyallocated = sxl.qtyallocated - l.qty, editwho = 'report', editdate = getdate() from wh1.lot sxl join #loc l on sxl.lot = l.lot where l.id = @i
				print '-- ���������� ������� � ����������������� ������ ������'
				select @orderlinenumber = orderlinenumber from #loc where id = @i
				print '-- ������ ������ ' + @orderlinenumber
				insert wh1.orderstatushistory (orderlinenumber, orderkey, whseid, ordertype, status, addwho, adddate ,comments)
					values (@orderlinenumber, @orderkey, 'WH1', 'SO', '09', 'report', getdate(), 'Unallocation.UnallocateOrderDetail.. report')
				set @i = @i+1
			end
		print '-- ��������� ������������������ ���������� � ������� ������'
		update wh1.orderdetail set qtyallocated = 0, status = '09', editwho = 'report', editdate = getdate() where orderkey = @orderkey
		print '-- ��������� ������� ������ �� �����������'
		update wh1.orders set status = '09' where orderkey = @orderkey
		print '--  ���������� ������� � ����������������� ������'
		insert wh1.orderstatushistory (orderlinenumber, orderkey, whseid, ordertype, status, addwho, adddate ,comments)
					values ('', @orderkey, 'WH1', 'SO', '09', 'report', getdate(), 'Unallocation.UnallocateOrderDetail.. report')
		print '-- �������� ������� ��� ������'
		delete from wh1.pickdetail where orderkey = @orderkey
		drop table #loc
		delete from #ok where orderkey = @orderkey
	end

drop table #ok
endproc:

