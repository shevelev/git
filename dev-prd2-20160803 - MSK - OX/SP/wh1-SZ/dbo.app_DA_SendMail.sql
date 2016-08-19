--################################################################################################
--                   ��������� ���������� ��������� �� ������� �� �����
--################################################################################################
ALTER PROCEDURE [dbo].[app_DA_SendMail] 
	@object varchar (255),
	@body varchar (max)
AS

IF(	@object Like 'SCHEMA=''WH1'', TRANSMITLOGKEY=%' OR 
	@object Like '����� �� �������. ��������� ��������� ��������')
	RETURN;


	declare @subject varchar(300)
	set @subject = 'Infor: ' + @object


if @body='No dataset returned.'
	begin
	print '������ �� ����'
	end
	
	else 
	begin
	
	IF(@object='������')
		exec dbo.errorExpItemHandler @body,@subject;
	IF(@object='������')
		exec dbo.errorExpPOHandler @body,@subject;
	IF(@object='��������')
		exec dbo.errorExpOrdersHandler 	@body,@subject;
	IF( @object not in ('������','������','��������'))
	BEGIN
	
		exec dbo.sendmail 'vnedrenie3@sev-zap.ru', @Subject, @body		-- ������� �.�.
		--exec dbo.sendmail 'msv@itprojct.ru', @Subject, @body		-- ������� �.�.
	END	
	end


