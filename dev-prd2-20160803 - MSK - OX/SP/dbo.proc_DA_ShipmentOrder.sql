ALTER PROCEDURE [dbo].[proc_DA_ShipmentOrder]
	@source varchar(500) = null
as
begin
declare @wh varchar(30), @id int

	while (exists (select id from dbo.DA_ShipmentOrderHead))
	begin
		
			print ' выбираем запись из обменной таблицы DA_ShipmentOrderHead'
			select top 1 @id = id, @wh=SUSR1  
			from dbo.DA_ShipmentOrderHead 
			order by id desc
			
			if @wh like 'MSK[_]%' 
			begin
				exec [WH2].[proc_DA_ShipmentOrder] @id
				print 2
			end
			else
			begin
				if @wh = 'ќтвет’ранениеѕост'
					begin
						exec [WH1].[proc_DA_ShipmentOrder_OX] @id
						print 3
					end
				else			
					begin
						exec [WH1].[proc_DA_ShipmentOrder] @id
						print 1
					end
			end
	end
end

