ALTER PROCEDURE [dbo].[proc_DA_PurchaseOrder_tree]
	@source varchar(500) = null
as
begin
declare @wh varchar(30), @id int, @dt varchar(10)

	while (exists (select id from DA_PO))
	begin
			print ' �������� ������ �� �������� ������� DA_PurchaseOrderHead'
			select top 1 @id = id, @wh=SUSR2 
			from dbo.DA_PO 
			order by id desc
			
			--if  @wh like 'MSK[_]%' 
			--	exec [WH2].[proc_DA_PurchaseOrder] @id
			--else
			--	begin
			--		if @wh='�����������������'
			--			begin
			--				exec [WH1].[proc_DA_PurchaseOrder_OX] @id
			--			end
			--		else 
			--			exec [WH1].[proc_DA_PurchaseOrder] @id
			--	end
			
			
			if @wh like '��[_]�����%' 
				begin
					print '��-��'
					--exec [WH1].[proc_DA_PurchaseOrder_OX] @id
				end
			else if	(@wh like '��[_]%' or @wh='������')
				begin
						print 'MC'
						--exec [WH2].[proc_DA_PurchaseOrder] @id
				end
			else if @wh like '��[_]�����%' 
				begin
					print '��-��'
				end
			else if	(@wh like '��[_]%' or @wh='��������')
				begin
						print 'M�'
				end
			else if @wh like '��[_]�����%' 
				begin
					print '��-��'
				end
			else if	(@wh like '��[_]%' or @wh='����')
				begin
						print '��'
				end
			else if @wh like '��[_]�����%' 
				begin
					print '��-��'
				end
			else if	(@wh like '��[_]%' or @wh='�����������')
				begin
						print '��'
				end
			else if @wh like '�����������������'
				begin
					print 'SPB-OX'
				end
			else if @wh in ('�����������','��','���������','������������','�������','����������������')
				begin			
					print 'SPB'
					exec [WH1].[proc_DA_PurchaseOrder] @id
				end
			else
				begin
					print '������ �� �����'
					return
				end
			
			
	end
end

