ALTER PROCEDURE [dbo].[proc_DA_PurchaseOrder]
	@source varchar(500) = null
as
begin
declare @wh varchar(30), @id int, @dt varchar(10)

	while (exists (select id from DA_PO))
	begin
			print ' выбираем запись из обменной таблицы DA_PurchaseOrderHead'
			select top 1 @id = id, @wh=SUSR2 
			from dbo.DA_PO 
			order by id desc
			
			if  @wh like 'MSK[_]%' 
				exec [WH2].[proc_DA_PurchaseOrder] @id
			else
				begin
					if @wh='ќтвет’ранениеѕост'
						begin
							exec [WH1].[proc_DA_PurchaseOrder_OX] @id
						end
					else 
						exec [WH1].[proc_DA_PurchaseOrder] @id
				end
			
	end
end

