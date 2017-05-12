ALTER PROCEDURE [WH1].[sendGLPI] 
AS

begin


declare @count int, -- кол-во записей по дате
		@number_of_errors int = 0, -- кол-во ошибок за день
		@enter varchar(10)=char(13)+char(10), -- перенос строки
		@subj varchar(50), -- Заголовок письма
		@body varchar(max), -- Тело письма
		@id int -- счетчик для тела письма

-- Проверяем есть ли на текущую дату записи в таблице
select @count = COUNT(*) from [WH1].[NGLPI] where adddate = CONVERT(date, GETDATE(), 101)

if @count = 0 
	begin
	
		INSERT INTO [PRD2].[WH1].[NGLPI] (KEYNAME,KEYCOUNT,ADDDATE)
           
           VALUES	('control',0,CONVERT(date, GETDATE(), 101)),
					('sku',0,CONVERT(date, GETDATE(), 101)),
					('move',0,CONVERT(date, GETDATE(), 101)),
					('asnclose',0,CONVERT(date, GETDATE(), 101)),
					('shorder',0,CONVERT(date, GETDATE(), 101)),
					('po',0,CONVERT(date, GETDATE(), 101)),
					('syserror',0,CONVERT(date, GETDATE(), 101)),
					('transfer',0,CONVERT(date, GETDATE(), 101)),
					('orders',0,CONVERT(date, GETDATE(), 101))
	end
else 
	begin
		print 'строки на текущую дату уже добавлены'
	end
	
	print 'Идем дальше'
----- Собираем статистику за предыдущий день

select serialkey	,case    when  keyname = 'asnclose' then 'Закрытие ПУО'
				when  keyname = 'control' then 'Авто-контроль'
				when  keyname = 'move' then 'Авто-перемещение'
				when  keyname = 'orders' then 'Отгрузка-Ошибка интеграции'
				when  keyname = 'po' then 'Приемка-Ошибка интеграции'
				when  keyname = 'shorder' then 'Отгрузка DAX'
				when  keyname= 'sku' then 'Товары-Ошибка интеграции' 
				when  keyname= 'syserror' then 'Системная ошибка'
				when  keyname= 'transfer' then 'Трансфер' end as keyname, keycount 
into #teplates_mail
from [WH1].[NGLPI] where adddate = CONVERT(date, DATEADD(d, -1, getdate()), 101)




-- Подсчитываем кол-во ошибок	

select @number_of_errors = SUM(keycount) from #teplates_mail

if (@number_of_errors = 0) 
	begin
		print 'Выход из процедуры '
		RETURN
	end

-- Удаляем все 0 записи из таблицы
delete #teplates_mail where keycount=0 
-- Формируем письмо
set @subj = 'Исправление ошибок за ' + CONVERT(varchar(30), DATEADD(d, -1, getdate()), 101)
set @body = 'Ошибок: ' +  convert(varchar(20),@number_of_errors) + @enter + @enter

--select * from #teplates_mail

while ((select count(serialkey) from #teplates_mail) != 0)
	begin
		
		select top 1 @id = serialkey from #teplates_mail order by serialkey
		select @body = @body + convert(varchar(10),keycount) + ' - ' + keyname + @enter from #teplates_mail where serialkey=@id
		delete #teplates_mail where serialkey=@id
		
	end


select @subj, @body

exec dbo.SendMail 'support-wms@sev-zap.ru',@subj, @body
	
	
drop table #teplates_mail
	
	
	
	
	

end
