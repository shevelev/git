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
			
				
			if @wh like 'МС[_]Ответ%' 
				begin
					print 'МС-ОХ'
					--exec [WH2].[proc_DA_ShipmentOrder_OX] @id
				end
			else if	(@wh like 'МС[_]%' or @wh='Москва')
				begin
						print 'Входим в ветку склад москва, дата: '  + convert(varchar(max),getdate())
						exec [WH2].[proc_DA_ShipmentOrder] @id
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
					exec [WH1].[proc_DA_ShipmentOrder_OX] @id
				end
			else if @wh in ('СкладПродаж','СД','ПТВСклада','ПТВПостащика','БлокФСН','НедовложенияПост')
				begin			
					print 'SPB'
					exec [WH1].[proc_DA_ShipmentOrder] @id
				end
			else
				begin
					print 'никуда не зашли'
					return
				end
			
	end
end

