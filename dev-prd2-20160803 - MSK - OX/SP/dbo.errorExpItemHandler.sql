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

SET @body = REPLACE(@body,@enter,'');--убираем симовлы переноса и возврата каретки

--Разбиваем @body по строчкам. Каждая строчка будет начинаться с 'er#'
DECLARE @delimeter varchar(3) = 'er#'; --разделитель

DECLARE
		@posStart int = charindex(@delimeter,@body,1),
		@posEnd int = charindex(@delimeter,@body,7);

DECLARE @str nvarchar(300); --будем хранить строку из набора строк тела

WHILE (@posEnd!=0)
BEGIN
    SET @str = SUBSTRING(@body, @posStart, @posEnd-1);
    
    insert into @table (parseByEnter) 
	values(@str);
    
    SET @body = SUBSTRING(@body,@posEnd,LEN(@body)); --сокращаем исходную строку на размер строки @str
	
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
	@MANUFACTUREID varchar(30),--Производитель (Busr1)
	@ITEMID varchar(50), --(SKU)
	@DATAAREAID varchar(20),--Владелец (Storerkey)
	@BARCODE varchar(50);--Штрих код (ALTSKU)

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
	
--Составление письма НАЧАЛО	

	DECLARE @errCode VARCHAR(6); --код ошибки будет хранится
	
	
	WHILE @@FETCH_STATUS=0 BEGIN	
	
		SET @errCode = LEFT(@what,6);
		print @errCode
		IF @errCode = 'er#006'
			SELECT @toInfor =@toInfor + CHAR(13) + 'Производитель пустой. Товар SKU='+@ITEMID, 
				   @toDax = @toDax + CHAR(13) +'Производитель пустой. Товар ITEMID='+@ITEMID;
		
		IF @errCode = 'er#008'	
		BEGIN	
				IF (EXISTS(SELECT  *
					      FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpVendCusttoWMS
					      WHERE Vendcustid=@MANUFACTUREID AND STATUS = 10) AND 
					EXISTS(SELECT top(1) ws.* 
						   FROM wh1.storer ws 
						   WHERE ws.storerkey = @MANUFACTUREID))
				BEGIN		   
						   print 'Обновляем'
						   SELECT @toInfor = @toInfor + @enter + 'Производитель отсутствет в справочнике STORER, но присутствует в обменной таблице (со статусом 10) контрагентов SZ_ExpVendCusttoWMS.';
						   						   
						   --UPDATE [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_EXPITEMTOWMS
						   --SET STATUS = 5
						   --WHERE RECID = @RECID;							   
				END
				ELSE 
			    
				SELECT @toInfor = @toInfor + @enter + '.Производитель отсутствет в справочнике STORER. Товар SKU='+@ITEMID, 
					  @toDax = @toDax + @enter +'.Производитель отсутствет в обменной таблице контрагентов SZ_ExpVendCusttoWMS. Товар ITEMID='+@ITEMID; 	
		END
		
		IF @errCode = 'er#005'
				SELECT @toInfor = @toInfor + CHAR(13) + '.Класс товара может быть от 1 до 8. Товар SKU='+@ITEMID, 
					   @toDax = @toDax + @enter +'.Класс товара может быть от 1 до 8. Товар ITEMID='+@ITEMID; 	
		IF @errCode = 'er#007'
		BEGIN
			SELECT @toInfor = @toInfor + @enter + '.ШК: ' + @BARCODE +  ' для для товара SKU='+@ITEMID+' не может быть установлен, так как он установлен на товар SKU='+SKU+'.',
				   @toDax = @toDax + @enter + '.ШК: ' + @BARCODE +  ' для для товара ITEMID='+@ITEMID+' не может быть установлен, так как он установлен на товар ITEMID='+SKU+'.'
			FROM WH1.ALTSKU
			WHERE ALTSKU = @BARCODE;
		END;
		
		IF @errCode NOT IN('er#005','er#006','er#007','er#008')
			SELECT @toInfor = @toInfor + @enter + @what,
				   @toDax = @toDax + @enter + @what
		
		FETCH NEXT FROM iterator INTO @what;
	END;	
--Составление письма КОНЕЦ --CONVERT(VARCHAR(20), @bignum1)
	
	CLOSE iterator;
	DEALLOCATE iterator;
	SET @toInfor =  'Infor: '+@toInfor + CHAR(13) + 'RECID='+CONVERT(VARCHAR(50),@RECID);
	SET @toDax = 'Dax: '+@toDax + CHAR(13) +'RECID='+CONVERT(VARCHAR(50),@RECID);
	
	print @toInfor;
	print @toDax;
print @@ERROR
   -- SET @toInfor =  @toInfor + @enter + 'Номер ошибки:' + @@ERROR;
    

exec dbo.sendmail 'itprjct-supravpredp-list@sev-zap.ru', @subject, @toDax			-- !!поддержка аксапты
exec dbo.sendmail 'vnedrenie3@sev-zap.ru', @subject, @toInfor		-- Шевелев С.С.
exec dbo.sendmail 'petrov@sev-zap.ru', @subject, @toInfor		-- Петров П.А.
exec dbo.sendmail 'kovalevich@sev-zap.ru', @subject, @toInfor		-- Прохновская Н.В.	(Склад)
exec dbo.sendmail 'soloveva@sev-zap.ru', @subject, @toInfor			-- Соловьева М.В.	(Склад)
exec dbo.sendmail 'lyd@sev-zap.ru', @subject, @toInfor				-- Лепля Ю.Д.		(Маркетинг)
exec dbo.sendmail 'zamgeneral@sev-zap.ru', @subject, @toInfor		-- Сомова А.А.		(Маркетинг)
exec dbo.sendmail 'arc@sev-zap.ru', @subject, @toInfor				-- Аверьянов Р.С.	(Маркетинг)
exec dbo.sendmail 'dde@sev-zap.ru', @subject, @toInfor				-- Данцкер Д.Е.		(Маркетинг)
exec [wh1].[newGLPI] 'sku'


