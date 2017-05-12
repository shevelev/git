ALTER PROCEDURE [dbo].[errorExpPOHandler]
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

DECLARE @str nvarchar(300); --����� ������� ������ �� ������ ����� ����

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

Select *
from @table;

	DECLARE @DOCID varchar(20);--externpokey

	DECLARE @what VARCHAR(300);
	
	SELECT top 1 @what = parseByEnter
	from @table
	where parseByEnter LIKE '%EXTERNPOkey%';
	
	IF(@what is not null)
	BEGIN
			SET @posStart = CHARINDEX('*',@what);
			SET @posEnd = CHARINDEX('*',@what,@posStart+1);
			SET @DOCID = SUBSTRING(@what,@posStart + 1,@posEnd - @posStart - 1);	
	END;
	
	IF(EXISTS(SELECT *
			  FROM @table
			  WHERE parseByEnter LIKE '%er#003%'))
			DELETE FROM @table
			WHERE parseByEnter LIKE '%er#004%';
		 
	DECLARE iterator CURSOR LOCAL FOR
	SELECT parseByEnter
	FROM @table;

	

	OPEN iterator;
	FETCH NEXT FROM iterator INTO @what;
	
--����������� ������ ������	

	DECLARE @errCode VARCHAR(6); --��� ������

	
	
	WHILE @@FETCH_STATUS=0 BEGIN	
	
		SET @errCode = LEFT(@what,6);
		

		IF(@errCode = 'er#014') 
		BEGIN
			SET @posStart = CHARINDEX('SKU=*',@what) + 5;
			SET @posEnd = CHARINDEX('*',@what,@posStart);
			DECLARE @ITEMID VARCHAR(50) = SUBSTRING(@what,@posStart,@posEnd - @posStart);	
			IF EXISTS(SELECT * 
					  FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_EXPITEMTOWMS 
					  WHERE ITEMID=@ITEMID AND STATUS = 10)
			BEGIN
			SELECT @toInfor=@toInfor + @enter +'�����('+@ITEMID+') ����������� � ����������� ������� wh1.sku, �� ������������ � �������� ������� SZ_EXPITEMTOWMS';
			
			--UPDATE [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInputOrdersToWMS
			--SET STATUS = 5
			--WHERE DOCID = @DOCID and @DOCID not in('empty','');
			
			--UPDATE [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_EXPINPUTORDERLINESTOWMS
			--SET STATUS = 5
			--WHERE DOCID = @DOCID and @DOCID not in('empty','');
	
			END
			ELSE
				SELECT @toInfor=@toInfor + @enter + '�����('+@ITEMID+') ����������� � ����������� ������� wh1.sku.',
					   @toDax = @toDax + @enter + '�����('+@ITEMID+') ����������� (��� ��� status!=10) � �������� ������� SZ_EXPITEMTOWMS';	
		END;
		
		IF(@errCode = 'er#003')
			SELECT @toInfor=@toInfor + @enter + 'SellerName ������.',
				   @toDax = @toDax + @enter + 'VendAccoun ������.';	
		IF(@errCode = 'er#004')-- ��� �� vendcustid
		BEGIN
			
			SET @posStart = CHARINDEX('SellerName=*',@what) + LEN('SellerName=')+1;
			SET @posEnd = CHARINDEX('*',@what,@posStart);
			DECLARE @VendAccoun varchar(15)= SUBSTRING(@what,@posStart,@posEnd - @posStart);	
			
			
			IF EXISTS(SELECT *
					  FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpVendCustToWMS 
					  WHERE status = 10 AND VENDCUSTID = @VendAccoun)
			BEGIN
			SELECT @toInfor=@toInfor + @enter +'��� ����������('+@VendAccoun+') ����������� � ����������� wh1.STORER, �� ������������ � �������� ������� SZ_ExpVendCustToWMS';
		 
			
			--UPDATE [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInputOrdersToWMS
			--SET STATUS = 5
			--WHERE DOCID = @DOCID and @DOCID not in('empty','');
			
			--UPDATE [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_EXPINPUTORDERLINESTOWMS
			--SET STATUS = 5
			--WHERE DOCID = @DOCID and @DOCID not in('empty','');
			
			END;
			ELSE
				SELECT @toInfor=@toInfor + @enter +'��� ����������('+@VendAccoun+') ����������� � ����������� wh1.STORER.',
					   @toDax=@toDax + @enter +'��� ����������('+@VendAccoun+') ����������� (��� ��� status!=10) � �������� ������� SZ_ExpVendCustToWMS.';	
		END;
		IF(@errCode = 'er#007')
			SELECT @toInfor=@toInfor + @enter +'�������� ��� ���������� � ����.',
				   @toDax=@toDax + @enter +'�������� ��� ���������� � ����.';	
			
		
		--���� ���
		IF @errCode NOT IN('er#003','er#014','er#004','er#007')
			SELECT @toInfor = @toInfor + @enter + @what,
				   @toDax = @toDax + @enter + @what				   
		FETCH NEXT FROM iterator INTO @what;
	END;	
--����������� ������ �����
	
	CLOSE iterator;
	DEALLOCATE iterator;
	SET @toInfor =  'Infor: '+@toInfor + @enter + CASE WHEN @DOCID is NOT NULL THEN 'ExternPoKey='+@DOCID ELSE '' END;
	SET @toDax = 'Dax: '+@toDax + @enter + CASE WHEN @DOCID is NOT NULL THEN 'DocId='+@DOCID ELSE '' END;
	
	print @toInfor;
	print @toDax;

exec dbo.sendmail 'itprjct-supravpredp-list@sev-zap.ru', @subject, @toDax			-- !!��������� �������
exec dbo.sendmail 'vnedrenie3@sev-zap.ru', @subject, @toInfor		-- ������� �.�.
exec dbo.sendmail 'petrov@sev-zap.ru', @subject, @toInfor			-- ������ �.�.
exec dbo.sendmail 'kovalevich@sev-zap.ru', @subject, @toInfor		-- ����������� �.�.	(�����)
exec dbo.sendmail 'soloveva@sev-zap.ru', @subject, @toInfor			-- ��������� �.�.	(�����)
exec dbo.sendmail 'lyd@sev-zap.ru', @subject, @toInfor				-- ����� �.�.		(���������)
exec dbo.sendmail 'zamgeneral@sev-zap.ru', @subject, @toInfor		-- ������ �.�.		(���������)
exec dbo.sendmail 'arc@sev-zap.ru', @subject, @toInfor				-- ��������� �.�.	(���������)
exec dbo.sendmail 'dde@sev-zap.ru', @subject, @toInfor				-- ������� �.�.		(���������)
exec [wh1].[newGLPI] 'po'



