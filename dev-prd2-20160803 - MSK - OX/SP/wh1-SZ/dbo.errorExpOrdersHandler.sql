


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

SET @body = REPLACE(@body,@enter,'');--убираем симовлы переноса и возврата каретки

--Разбиваем @body по строчкам. Каждая строчка будет начинаться с 'er#'
DECLARE @delimeter varchar(3) = 'er#'; --разделитель

DECLARE
		@posStart int = charindex(@delimeter,@body,1),
		@posEnd int = charindex(@delimeter,@body,7);

DECLARE @str nvarchar(300); --будем хранить тело письма, как набора строк
--Разбиение тела на строки НАЧАЛО
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
--Разбиение тела на строки Конец

Select *
from @table;

	DECLARE @DOCID varchar(30);--externorderkey

	DECLARE @what VARCHAR(300);
	
	SELECT top 1 @what = parseByEnter
	from @table
	where parseByEnter LIKE '%EXTERNORDERKEY%' OR parseByEnter LIKE '%ВнешнийНомер%';
	
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
	
--Составление письма НАЧАЛО	

	DECLARE @errCode VARCHAR(6); --код ошибки
	WHILE @@FETCH_STATUS=0 BEGIN	
	
		SET @errCode = LEFT(@what,6);
		
		SELECT @toInfor = @toInfor + @enter + CASE @errCode	WHEN 'er#012' THEN 'Не уникальный документ в обменной таблице.' 
															WHEN 'er#008' THEN 'Не введён маршрут (SUSR4).'
															WHEN 'er#001' THEN 'Номер отгрузачной накладной (ExternOrderKey) пустой.'
															WHEN 'er#004' THEN 'Номер заказа (c_contact1) на продажу (накладная) пустой.'
															WHEN 'er#010' THEN 'Код грузополучателя (клиента) (ConsigneeKey) отсутствует в справочнике STORER.'
															WHEN 'er#011' THEN 'Документ в обработке, обновление невозможно.'
															ELSE @what END;
		
		SELECT @toDax = @toDax + @enter + CASE @errCode	WHEN 'er#012' THEN 'Не уникальный документ в обменной таблице.' 
														WHEN 'er#008' THEN 'Не введён маршрут (ROUTEID).'
														WHEN 'er#001' THEN 'Номер отгрузачной накладной (DOCID) пустой.'
														WHEN 'er#004' THEN 'Номер заказа (SalesIdBase) на продажу (накладная) пустой.'
														WHEN 'er#010' THEN 'Код грузополучателя (клиента) (ConsigneeAccount_RU) отсутствует в справочнике STORER.'
														WHEN 'er#011' THEN 'Документ в обработке, обновление невозможно.'
														ELSE @what END;
		FETCH NEXT FROM iterator INTO @what;
	END;	
--Составление письма КОНЕЦ
	
	CLOSE iterator;
	DEALLOCATE iterator;
	
	
	SET @toInfor =  'Infor: '+@toInfor + @enter + CASE WHEN @DOCID IS not NULL THEN 'ExternOrderKey='+@DOCID ELSE '' END;
	SET @toDax = 'Dax: '+@toDax + @enter + CASE WHEN @DOCID IS not NULL THEN 'DocId='+@DOCID ELSE '' END;
	
	print @toInfor;
	print @toDax;

exec dbo.sendmail 'support-ax@sev-zap.ru', @subject, @toDax			-- !!поддержка аксапты
exec dbo.sendmail 'vnedrenie3@sev-zap.ru', @subject, @toInfor		-- Шевелев С.С.
exec dbo.sendmail 'kovalevich@sev-zap.ru', @subject, @toInfor		-- Прохновская Н.В.	(Склад)
exec dbo.sendmail 'soloveva@sev-zap.ru', @subject, @toInfor			-- Соловьева М.В.	(Склад)





