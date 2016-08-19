--################################################################################################
--                   процедура отправляет сообщения об ошибках на почту
--################################################################################################
ALTER PROCEDURE [dbo].[app_DA_SendMail] 
	@object varchar (255),
	@body varchar (max)
AS

IF(	@object Like 'SCHEMA=''WH1'', TRANSMITLOGKEY=%' OR 
	@object Like 'Заказ не запущен. Ожидается истечение таймаута')
	RETURN;


	declare @subject varchar(300)
	set @subject = 'Infor: ' + @object


if @body='No dataset returned.'
	begin
	print 'ничего не шлем'
	end
	
	else 
	begin
	
	IF(@object='Товары')
		exec dbo.errorExpItemHandler @body,@subject;
	IF(@object='Приёмка')
		exec dbo.errorExpPOHandler @body,@subject;
	IF(@object='Отгрузка')
		exec dbo.errorExpOrdersHandler 	@body,@subject;
	IF( @object not in ('Товары','Приёмка','Отгрузка'))
	BEGIN
	
		exec dbo.sendmail 'vnedrenie3@sev-zap.ru', @Subject, @body		-- Шевелев С.С.
		--exec dbo.sendmail 'msv@itprojct.ru', @Subject, @body		-- Майоров С.С.
	END	
	end


