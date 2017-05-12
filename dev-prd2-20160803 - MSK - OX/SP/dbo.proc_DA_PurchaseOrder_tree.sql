ALTER PROCEDURE [dbo].[proc_DA_PurchaseOrder_tree]
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
			
			--if  @wh like 'MSK[_]%' 
			--	exec [WH2].[proc_DA_PurchaseOrder] @id
			--else
			--	begin
			--		if @wh='ОтветХранениеПост'
			--			begin
			--				exec [WH1].[proc_DA_PurchaseOrder_OX] @id
			--			end
			--		else 
			--			exec [WH1].[proc_DA_PurchaseOrder] @id
			--	end
			
			
			if @wh like 'МС[_]Ответ%' 
				begin
					print 'МС-ОХ'
					--exec [WH1].[proc_DA_PurchaseOrder_OX] @id
				end
			else if	(@wh like 'МС[_]%' or @wh='Москва')
				begin
						print 'MC'
						--exec [WH2].[proc_DA_PurchaseOrder] @id
				end
			else if @wh like 'МР[_]Ответ%' 
				begin
					print 'МР-ОХ'
				end
			else if	(@wh like 'МР[_]%' or @wh='Мурманск')
				begin
						print 'MР'
				end
			else if @wh like 'КР[_]Ответ%' 
				begin
					print 'КР-ОХ'
				end
			else if	(@wh like 'КР[_]%' or @wh='Крым')
				begin
						print 'КР'
				end
			else if @wh like 'КЛ[_]Ответ%' 
				begin
					print 'КЛ-ОХ'
				end
			else if	(@wh like 'КЛ[_]%' or @wh='Калининград')
				begin
						print 'КЛ'
				end
			else if @wh like 'ОтветХранениеПост'
				begin
					print 'SPB-OX'
				end
			else if @wh in ('СкладПродаж','СД','ПТВСклада','ПТВПостащика','БлокФСН','НедовложенияПост')
				begin			
					print 'SPB'
					exec [WH1].[proc_DA_PurchaseOrder] @id
				end
			else
				begin
					print 'никуда не зашли'
					return
				end
			
			
	end
end

