--################################################################################################
--                   ��������� ���������� ��������� �� ������� �� �����
--################################################################################################
ALTER PROCEDURE [dbo].[app_DA_SendMail] 
	@object varchar (255),
	@body varchar (max)
AS
	declare @subject varchar(300)
	set @subject = 'Infor: ' + @object


if @body='No dataset returned.'
	begin
	print '������ �� ����'
	end
	
	else 
	begin

	exec dbo.sendmail 'vnedrenie3@sev-zap.ru', @Subject, @body		-- ������� �.�.
	exec dbo.sendmail 'msv@itprojct.ru', @Subject, @body		-- ������� �.�.
	end


