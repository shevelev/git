ALTER PROCEDURE [dbo].[proc_DA_ShipmentOrder]
	@source varchar(500) = null
as
begin
declare @wh varchar(30), @id int

	while (exists (select id from dbo.DA_ShipmentOrderHead))
	begin
		
			print ' �������� ������ �� �������� ������� DA_ShipmentOrderHead'
			select top 1 @id = id, @wh=SUSR1  
			from dbo.DA_ShipmentOrderHead 
			order by id desc
			
			--if @wh like 'MSK[_]%' 
			--	begin
			--		print '2'
			--		exec [WH2].[proc_DA_ShipmentOrder] @id
					
			--	end
			--else
			--	begin
			--		if @wh = '�����������������'
			--			begin
			--				print '3'
			--				exec [WH1].[proc_DA_ShipmentOrder_OX] @id
							
			--			end
			--		else			
			--			begin
			--				print '1'
			--				exec [WH1].[proc_DA_ShipmentOrder] @id
							
			--			end
			--	end
			
			if @wh like '��[_]�����%' 
				begin
					print '��-��'
					--exec [WH2].[proc_DA_ShipmentOrder_OX] @id
				end
			else if	(@wh like '��[_]%' or @wh='������')
				begin
						print 'MC'
						exec [WH2].[proc_DA_ShipmentOrder] @id
				end
			if @wh like '��[_]�����%' 
				begin
					print '��-��'
				end
			else if	(@wh like '��[_]%' or @wh='��������')
				begin
						print 'M�'
				end
			if @wh like '��[_]�����%' 
				begin
					print '��-��'
				end
			else if	(@wh like '��[_]%' or @wh='����')
				begin
						print '��'
				end
			if @wh like '��[_]�����%' 
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
					exec [WH1].[proc_DA_ShipmentOrder_OX] @id
				end
			else if @wh in ('�����������','��','���������','������������','�������','����������������')
				begin			
					print 'SPB'
					exec [WH1].[proc_DA_ShipmentOrder] @id
				end
			
	end
end

