


ALTER PROCEDURE [dbo].[errorExpOrdersHandler]
(
	@body VARCHAR(max),
	@subject varchar(255)
)
AS

DECLARE 
	@table TABLE 
	(
		parseByEnter VARCHAR(300)
	);
	
	
DECLARE
	@toInfor VARCHAR(max)='',
	@toDax VARCHAR(max)='';

DECLARE @enter varchar(10)=char(13)+char(10);

SET @body = REPLACE(@body,@enter,'');--������� ������� �������� � �������� �������

--��������� @body �� ��������. ������ ������� ����� ���������� � 'er#'
DECLARE @delimeter varchar(3) = 'er#'; --�����������

DECLARE
		@posStart int = charindex(@delimeter,@body,1),
		@posEnd int = charindex(@delimeter,@body,7);

DECLARE @str nvarchar(300); --����� ������� ���� ������, ��� ������ �����
--��������� ���� �� ������ ������
WHILE (@posEnd!=0)
BEGIN
    SET @str = SUBSTRING(@body, @posStart, @posEnd-1);
    
    insert into @table (parseByEnter) 
	values(@str);
    
    SET @body = SUBSTRING(@body,@posEnd,LEN(@body)); --��������� �������� ������ �� ������ ������ @str
	
    SET @posStart = CHARINDEX(@delimeter,@body,1);
    SET @posEnd = CHARINDEX(@delimeter,@body,7); 
end
	SET @str = SUBSTRING(@body,@posStart,LEN(@body));
	insert into @table (parseByEnter) 
	values(@str);
--��������� ���� �� ������ �����

Select *
from @table;

	DECLARE @DOCID varchar(30);--externorderkey

	DECLARE @what VARCHAR(300);
	
	SELECT top 1 @what = parseByEnter
	from @table
	where parseByEnter LIKE '%EXTERNORDERKEY%' OR parseByEnter LIKE '%������������%';
	
	IF(@what is not null)
	BEGIN
			SET @posStart = CHARINDEX('*',@what);
			SET @posEnd = CHARINDEX('*',@what,@posStart+1);
			SET @DOCID = SUBSTRING(@what,@posStart + 1,@posEnd - @posStart - 1);	
	END;
		 
	DECLARE iterator CURSOR LOCAL FOR
	SELECT parseByEnter
	FROM @table;

	

	OPEN iterator;
	FETCH NEXT FROM iterator INTO @what;
	
--����������� ������ ������	

	DECLARE @errCode VARCHAR(6); --��� ������
	WHILE @@FETCH_STATUS=0 BEGIN	
	
		SET @errCode = LEFT(@what,6);
		
		SELECT @toInfor = @toInfor + @enter + CASE @errCode	WHEN 'er#012' THEN '�� ���������� �������� � �������� �������.' 
															WHEN 'er#008' THEN '�� ����� ������� (SUSR4).'
															WHEN 'er#001' THEN '����� ����������� ��������� (ExternOrderKey) ������.'
															WHEN 'er#004' THEN '����� ������ (c_contact1) �� ������� (���������) ������.'
															WHEN 'er#010' THEN '��� ��������������� (�������) (ConsigneeKey) ����������� � ����������� STORER.'
															WHEN 'er#011' THEN '�������� � ���������, ���������� ����������.'
															ELSE @what END;
		
		SELECT @toDax = @toDax + @enter + CASE @errCode	WHEN 'er#012' THEN '�� ���������� �������� � �������� �������.' 
														WHEN 'er#008' THEN '�� ����� ������� (ROUTEID).'
														WHEN 'er#001' THEN '����� ����������� ��������� (DOCID) ������.'
														WHEN 'er#004' THEN '����� ������ (SalesIdBase) �� ������� (���������) ������.'
														WHEN 'er#010' THEN '��� ��������������� (�������) (ConsigneeAccount_RU) ����������� � ����������� STORER.'
														WHEN 'er#011' THEN '�������� � ���������, ���������� ����������.'
														ELSE @what END;
		FETCH NEXT FROM iterator INTO @what;
	END;	
--����������� ������ �����
	
	CLOSE iterator;
	DEALLOCATE iterator;
	
	
	SET @toInfor =  'Infor: '+@toInfor + @enter + CASE WHEN @DOCID IS not NULL THEN 'ExternOrderKey='+@DOCID ELSE '' END;
	SET @toDax = 'Dax: '+@toDax + @enter + CASE WHEN @DOCID IS not NULL THEN 'DocId='+@DOCID ELSE '' END;
	
	print @toInfor;
	print @toDax;

exec dbo.sendmail 'support-ax@sev-zap.ru', @subject, @toDax			-- !!��������� �������
exec dbo.sendmail 'vnedrenie3@sev-zap.ru', @subject, @toInfor		-- ������� �.�.
exec dbo.sendmail 'kovalevich@sev-zap.ru', @subject, @toInfor		-- ����������� �.�.	(�����)
exec dbo.sendmail 'soloveva@sev-zap.ru', @subject, @toInfor			-- ��������� �.�.	(�����)





