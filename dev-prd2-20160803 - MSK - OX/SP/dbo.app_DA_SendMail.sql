--################################################################################################
--                   процедура отправляет сообщения об ошибках на почту
--################################################################################################
ALTER PROCEDURE [dbo].[app_DA_SendMail] 
	@object varchar (255),
	@body varchar (max)
AS
	declare @subject varchar(300)
	set @subject = 'Infor: ' + @object


if @body='No dataset returned.'
	begin
	print 'ничего не шлем'
	end
	
	else 
	begin

	exec dbo.sendmail 'vnedrenie3@sev-zap.ru', @Subject, @body		-- Шевелев С.С.
	exec dbo.sendmail 'msv@itprojct.ru', @Subject, @body		-- Майоров С.С.
	end


