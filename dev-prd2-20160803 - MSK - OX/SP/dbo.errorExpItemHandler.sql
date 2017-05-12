ALTER PROCEDURE [dbo].[errorExpItemHandler]
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


DECLARE 
	@RECID bigint,
	@MANUFACTUREID varchar(30),--������������� (Busr1)
	@ITEMID varchar(50), --(SKU)
	@DATAAREAID varchar(20),--�������� (Storerkey)
	@BARCODE varchar(50);--����� ��� (ALTSKU)

	SELECT top 1 @MANUFACTUREID=left(isnull(rtrim(ltrim(busr1)),''),30),
				 @RECID=recid,
				 @ITEMID = left(isnull(rtrim(ltrim(sku)),''),50),
				 @BARCODE = left(isnull(rtrim(ltrim(altsku)),''),50),
				 @DATAAREAID=CASE WHEN (left(isnull(rtrim(ltrim(storerkey)),''),15)) = 'SZ' then '001' 
							  ELSE (left(isnull(rtrim(ltrim(storerkey)),''),15)) END							  				 
	FROM dbo.DA_SKU_archive
	ORDER BY id DESC;
	
	
	DECLARE iterator CURSOR LOCAL FOR
	SELECT parseByEnter
	FROM @table;

	DECLARE @what VARCHAR(300);

	OPEN iterator;
	FETCH NEXT FROM iterator INTO @what;
	
--����������� ������ ������	

	DECLARE @errCode VARCHAR(6); --��� ������ ����� ��������
	
	
	WHILE @@FETCH_STATUS=0 BEGIN	
	
		SET @errCode = LEFT(@what,6);
		print @errCode
		IF @errCode = 'er#006'
			SELECT @toInfor =@toInfor + CHAR(13) + '������������� ������. ����� SKU='+@ITEMID, 
				   @toDax = @toDax + CHAR(13) +'������������� ������. ����� ITEMID='+@ITEMID;
		
		IF @errCode = 'er#008'	
		BEGIN	
				IF (EXISTS(SELECT  *
					      FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpVendCusttoWMS
					      WHERE Vendcustid=@MANUFACTUREID AND STATUS = 10) AND 
					EXISTS(SELECT top(1) ws.* 
						   FROM wh1.storer ws 
						   WHERE ws.storerkey = @MANUFACTUREID))
				BEGIN		   
						   print '���������'
						   SELECT @toInfor = @toInfor + @enter + '������������� ���������� � ����������� STORER, �� ������������ � �������� ������� (�� �������� 10) ������������ SZ_ExpVendCusttoWMS.';
						   						   
						   --UPDATE [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_EXPITEMTOWMS
						   --SET STATUS = 5
						   --WHERE RECID = @RECID;							   
				END
				ELSE 
			    
				SELECT @toInfor = @toInfor + @enter + '.������������� ���������� � ����������� STORER. ����� SKU='+@ITEMID, 
					  @toDax = @toDax + @enter +'.������������� ���������� � �������� ������� ������������ SZ_ExpVendCusttoWMS. ����� ITEMID='+@ITEMID; 	
		END
		
		IF @errCode = 'er#005'
				SELECT @toInfor = @toInfor + CHAR(13) + '.����� ������ ����� ���� �� 1 �� 8. ����� SKU='+@ITEMID, 
					   @toDax = @toDax + @enter +'.����� ������ ����� ���� �� 1 �� 8. ����� ITEMID='+@ITEMID; 	
		IF @errCode = 'er#007'
		BEGIN
			SELECT @toInfor = @toInfor + @enter + '.��: ' + @BARCODE +  ' ��� ��� ������ SKU='+@ITEMID+' �� ����� ���� ����������, ��� ��� �� ���������� �� ����� SKU='+SKU+'.',
				   @toDax = @toDax + @enter + '.��: ' + @BARCODE +  ' ��� ��� ������ ITEMID='+@ITEMID+' �� ����� ���� ����������, ��� ��� �� ���������� �� ����� ITEMID='+SKU+'.'
			FROM WH1.ALTSKU
			WHERE ALTSKU = @BARCODE;
		END;
		
		IF @errCode NOT IN('er#005','er#006','er#007','er#008')
			SELECT @toInfor = @toInfor + @enter + @what,
				   @toDax = @toDax + @enter + @what
		
		FETCH NEXT FROM iterator INTO @what;
	END;	
--����������� ������ ����� --CONVERT(VARCHAR(20), @bignum1)
	
	CLOSE iterator;
	DEALLOCATE iterator;
	SET @toInfor =  'Infor: '+@toInfor + CHAR(13) + 'RECID='+CONVERT(VARCHAR(50),@RECID);
	SET @toDax = 'Dax: '+@toDax + CHAR(13) +'RECID='+CONVERT(VARCHAR(50),@RECID);
	
	print @toInfor;
	print @toDax;
print @@ERROR
   -- SET @toInfor =  @toInfor + @enter + '����� ������:' + @@ERROR;
    

exec dbo.sendmail 'itprjct-supravpredp-list@sev-zap.ru', @subject, @toDax			-- !!��������� �������
exec dbo.sendmail 'vnedrenie3@sev-zap.ru', @subject, @toInfor		-- ������� �.�.
exec dbo.sendmail 'petrov@sev-zap.ru', @subject, @toInfor		-- ������ �.�.
exec dbo.sendmail 'kovalevich@sev-zap.ru', @subject, @toInfor		-- ����������� �.�.	(�����)
exec dbo.sendmail 'soloveva@sev-zap.ru', @subject, @toInfor			-- ��������� �.�.	(�����)
exec dbo.sendmail 'lyd@sev-zap.ru', @subject, @toInfor				-- ����� �.�.		(���������)
exec dbo.sendmail 'zamgeneral@sev-zap.ru', @subject, @toInfor		-- ������ �.�.		(���������)
exec dbo.sendmail 'arc@sev-zap.ru', @subject, @toInfor				-- ��������� �.�.	(���������)
exec dbo.sendmail 'dde@sev-zap.ru', @subject, @toInfor				-- ������� �.�.		(���������)
exec [wh1].[newGLPI] 'sku'


