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
	
--Составление письма НАЧАЛО	

	DECLARE @errCode VARCHAR(6); --код ошибки

	
	
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
			SELECT @toInfor=@toInfor + @enter +'Товар('+@ITEMID+') отсутствует в справочнике товаров wh1.sku, но присутствует в обменной таблице SZ_EXPITEMTOWMS';
			
			--UPDATE [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInputOrdersToWMS
			--SET STATUS = 5
			--WHERE DOCID = @DOCID and @DOCID not in('empty','');
			
			--UPDATE [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_EXPINPUTORDERLINESTOWMS
			--SET STATUS = 5
			--WHERE DOCID = @DOCID and @DOCID not in('empty','');
	
			END
			ELSE
				SELECT @toInfor=@toInfor + @enter + 'Товар('+@ITEMID+') отсутствует в справочнике товаров wh1.sku.',
					   @toDax = @toDax + @enter + 'Товар('+@ITEMID+') отсутствует (или его status!=10) в обменной таблице SZ_EXPITEMTOWMS';	
		END;
		
		IF(@errCode = 'er#003')
			SELECT @toInfor=@toInfor + @enter + 'SellerName пустой.',
				   @toDax = @toDax + @enter + 'VendAccoun пустой.';	
		IF(@errCode = 'er#004')-- ищу по vendcustid
		BEGIN
			
			SET @posStart = CHARINDEX('SellerName=*',@what) + LEN('SellerName=')+1;
			SET @posEnd = CHARINDEX('*',@what,@posStart);
			DECLARE @VendAccoun varchar(15)= SUBSTRING(@what,@posStart,@posEnd - @posStart);	
			
			
			IF EXISTS(SELECT *
					  FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpVendCustToWMS 
					  WHERE status = 10 AND VENDCUSTID = @VendAccoun)
			BEGIN
			SELECT @toInfor=@toInfor + @enter +'Код поставщика('+@VendAccoun+') отсутствует в справочнике wh1.STORER, но присутствует в обменной таблице SZ_ExpVendCustToWMS';
		 
			
			--UPDATE [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInputOrdersToWMS
			--SET STATUS = 5
			--WHERE DOCID = @DOCID and @DOCID not in('empty','');
			
			--UPDATE [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_EXPINPUTORDERLINESTOWMS
			--SET STATUS = 5
			--WHERE DOCID = @DOCID and @DOCID not in('empty','');
			
			END;
			ELSE
				SELECT @toInfor=@toInfor + @enter +'Код поставщика('+@VendAccoun+') отсутствует в справочнике wh1.STORER.',
					   @toDax=@toDax + @enter +'Код поставщика('+@VendAccoun+') отсутствует (или его status!=10) в обменной таблице SZ_ExpVendCustToWMS.';	
		END;
		IF(@errCode = 'er#007')
			SELECT @toInfor=@toInfor + @enter +'Документ уже существует в базе.',
				   @toDax=@toDax + @enter +'Документ уже существует в базе.';	
			
		
		--пока что
		IF @errCode NOT IN('er#003','er#014','er#004','er#007')
			SELECT @toInfor = @toInfor + @enter + @what,
				   @toDax = @toDax + @enter + @what				   
		FETCH NEXT FROM iterator INTO @what;
	END;	
--Составление письма КОНЕЦ
	
	CLOSE iterator;
	DEALLOCATE iterator;
	SET @toInfor =  'Infor: '+@toInfor + @enter + CASE WHEN @DOCID is NOT NULL THEN 'ExternPoKey='+@DOCID ELSE '' END;
	SET @toDax = 'Dax: '+@toDax + @enter + CASE WHEN @DOCID is NOT NULL THEN 'DocId='+@DOCID ELSE '' END;
	
	print @toInfor;
	print @toDax;

exec dbo.sendmail 'itprjct-supravpredp-list@sev-zap.ru', @subject, @toDax			-- !!поддержка аксапты
exec dbo.sendmail 'vnedrenie3@sev-zap.ru', @subject, @toInfor		-- Шевелев С.С.
exec dbo.sendmail 'petrov@sev-zap.ru', @subject, @toInfor			-- Петров П.А.
exec dbo.sendmail 'kovalevich@sev-zap.ru', @subject, @toInfor		-- Прохновская Н.В.	(Склад)
exec dbo.sendmail 'soloveva@sev-zap.ru', @subject, @toInfor			-- Соловьева М.В.	(Склад)
exec dbo.sendmail 'lyd@sev-zap.ru', @subject, @toInfor				-- Лепля Ю.Д.		(Маркетинг)
exec dbo.sendmail 'zamgeneral@sev-zap.ru', @subject, @toInfor		-- Сомова А.А.		(Маркетинг)
exec dbo.sendmail 'arc@sev-zap.ru', @subject, @toInfor				-- Аверьянов Р.С.	(Маркетинг)
exec dbo.sendmail 'dde@sev-zap.ru', @subject, @toInfor				-- Данцкер Д.Е.		(Маркетинг)
exec [wh1].[newGLPI] 'po'



