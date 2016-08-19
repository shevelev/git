ALTER PROCEDURE [dbo].[ErrorsExchange2](
--DECLARE
	@dateStart DATETIME,--='01.04.2015',
	@dateEnd DATETIME,-- ='21.04.2015',
	@isError INT,-- = 0,
	@journalId INT--= 20
	)AS


CREATE TABLE #request
(
	createddatetime Datetime,
	docid varchar(30),
	statusID int,
	ERROR varchar(max),
	journalID int
)
CREATE TABLE #tmp
(
	StatusID int primary key,
	StatusName Varchar(20)
);

INSERT INTO #tmp
SELECT 5 ID, 'Создано' Status UNION
SELECT 10, 'Обработано'UNION
SELECT 15, 'Ошибка'UNION
SELECT 20, 'Отменено';

DECLARE @date1 varchar(10) = convert(varchar(10),@dateStart,112),
		@date2 varchar(10) = convert(varchar(10),@dateEnd+1,112);

IF @journalId=0 Begin



--'+ CASE WHEN @isError != 0 THEN 'Status = 15' else '' END+
DECLARE @sql varchar(max)='	
	INSERT INTO #request
	SELECT CREATEDDATETIME, ITEMID,STATUS, ERROR,1 
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpItemgrossparameters
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, VENDCUSTID, STATUS,ERROR,2
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpVendCustToWMS
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, DOCID, STATUS,ERROR,3 
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInputOrdersToWMS
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'

	INSERT INTO #request
	SELECT CREATEDDATETIME, DOCID, STATUS,ERROR,4  
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInputOrderLinesToWMS
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, DOCID, STATUS,ERROR,5 
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInputOrdersFromWMS
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, DOCID, STATUS,ERROR,6
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInputOrderLinesFromWMS
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, DOCID, STATUS,ERROR,7  
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpOutputOrdersToWMS
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, DOCID, STATUS,ERROR,8  
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpOutputOrderLinesToWMS
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, DOCID, STATUS,ERROR,9 
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputOrdersPicking
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, DOCID, STATUS,ERROR,10  
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputOrderLinesPic
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, DOCID, STATUS,ERROR,11  
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputOrdersShip
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, DOCID, STATUS,ERROR,12 
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputOrderLineShip
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	--INSERT INTO #request
	--SELECT CREATEDDATETIME, DOCID, STATUS,ERROR,13  
	--FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputUpdateOrders
	--WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	--INSERT INTO #request
	--SELECT CREATEDDATETIME, DOCID, STATUS,ERROR,14 
	--FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputUpdOrderlines
	--WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, InventJournalId, STATUS,ERROR,15  
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventjournaltrans
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, InventJournalId, STATUS,ERROR,16  
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventjournal
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, InventJournalId, STATUS,ERROR,17 
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInventjournaltrans
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, InventJournalId, STATUS,ERROR,18  
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpInventjournal
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, ITEMID, STATUS, ERROR,19  
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_EXPITEMTOWMS
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, ITEMID, STATUS, ERROR,20  
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_IMPINVENTSUMFROMWMS
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END
	
	
	EXEC (@sql);
	--SELECT a.createddatetime,a.docid,b.StatusName,a.ERROR
	--FROM #request a INNER JOIN #tmp b ON
	--	a.statusID = b.StatusID
	
	
	
	
END
ELSE BEGIN
	CREATE TABLE #tblName
	(
		ID int,
		name varchar(40),
		docid varchar(30)
	)

	insert into #tblName
	SELECT 1, 'SZ_ImpItemgrossparameters','ITEMID' UNION
	SELECT 2, 'SZ_ExpVendCustToWMS','VENDCUSTID' UNION
	SELECT 3, 'SZ_ExpInputOrdersToWMS','DOCID' UNION
	SELECT 4, 'SZ_ExpInputOrderLinesToWMS','DOCID' UNION
	SELECT 5, 'SZ_ImpInputOrdersFromWMS','DOCID' UNION
	SELECT 6, 'SZ_ImpInputOrderLinesFromWMS','DOCID' UNION
	SELECT 7, 'SZ_ExpOutputOrdersToWMS','DOCID' UNION
	SELECT 8, 'SZ_ExpOutputOrderLinesToWMS','DOCID' UNION
	SELECT 9, 'SZ_ImpOutputOrdersPicking','DOCID' UNION
	SELECT 10, 'SZ_ImpOutputOrderLinesPic','DOCID' UNION
	SELECT 11, 'SZ_ImpOutputOrdersShip','DOCID' UNION
	SELECT 12, 'SZ_ImpOutputOrderLineShip','DOCID' UNION
	SELECT 13, 'SZ_ImpOutputUpdateOrders','DOCID' UNION
	SELECT 14, 'SZ_ImpOutputUpdOrderlines','DOCID' UNION
	SELECT 15, 'SZ_ImpInventjournaltrans','InventJournalId' UNION
	SELECT 16, 'SZ_ImpInventjournal','InventJournalId' UNION
	SELECT 17, 'SZ_ExpInventjournaltrans','InventJournalId' UNION
	SELECT 18, 'SZ_ExpInventjournal','InventJournalId' UNION
	SELECT 19, 'SZ_EXPITEMTOWMS','ITEMID' UNION
	SELECT 20, 'SZ_IMPINVENTSUMFROMWMS','ITEMID'
	
	DECLARE 
	@tableName varchar(40),
	@docid varchar(30),
	@sql1 varchar(max);

	SELECT @tableName = name, @docid=docid
	FROM #tblName
	WHERE @journalId = id
	SET @sql1='
	INSERT INTO #request
	SELECT CREATEDDATETIME,'+ @docid+', STATUS,ERROR,'+CONVERT(varchar,@journalId)+' 
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].'+@tableName+'
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END
	
	EXEC (@sql1);
	
	drop table #tblName
		
END;
 
Create table #Journal
(
	id int,
	name varchar(200),
	exchangeTable varchar(250)
)

insert into #Journal
SELECT 1, 'Обновление карточки товара INFOR -> DAX','SZ_ImpItemgrossparameters' UNION
SELECT 2, 'Клиенты DAX -> INFOR','SZ_ExpVendCustToWMS' UNION
SELECT 3, 'Приемка DAX -> INFOR Шапка','SZ_ExpInputOrdersToWMS' UNION
SELECT 4, 'Приемка DAX -> INFOR Детали','SZ_ExpInputOrderLinesToWMS' UNION
SELECT 5, 'Приемка INFOR -> DAX Шапка','SZ_ImpInputOrdersFromWMS' UNION
SELECT 6, 'Приемка INFOR -> DAX Детали','SZ_ImpInputOrderLinesFromWMS' UNION
SELECT 7, 'Отгрузка DAX -> INFOR Шапка','SZ_ExpOutputOrdersToWMS' UNION
SELECT 8, 'Отгрузка DAX -> INFOR Детали','SZ_ExpOutputOrderLinesToWMS' UNION
SELECT 9, 'Комплектация INFOR -> DAX' Шапка,'SZ_ImpOutputOrdersPicking' UNION
SELECT 10, 'Комплектация INFOR -> DAX Детали','SZ_ImpOutputOrderLinesPic' UNION
SELECT 11, 'Отгрузка INFOR -> DAX Шапка','SZ_ImpOutputOrdersShip' UNION
SELECT 12, 'Отгрузка INFOR -> DAX Детали','SZ_ImpOutputOrderLineShip' UNION
SELECT 13, 'Отмена Отгрузки INFOR -> DAX Шапка','SZ_ImpOutputUpdateOrders' UNION
SELECT 14, 'Отмена Отгрузки INFOR -> DAX Детали','SZ_ImpOutputUpdOrderlines' UNION
SELECT 15, 'Трансферты INFOR -> DAX Шапка','SZ_ImpInventjournaltrans' UNION
SELECT 16, 'Трансферты INFOR -> DAX Детали','SZ_ImpInventjournal' UNION
SELECT 17, 'Трансферты DAX -> INFOR Шапка','SZ_ExpInventjournaltrans' UNION
SELECT 18, 'Трансферты DAX -> INFOR Детали','SZ_ExpInventjournal' UNION
SELECT 19, 'Справочник товаров DAX -> INFOR','SZ_EXPITEMTOWMS' UNION
SELECT 20, 'Инвентаризация INFOR -> DAX','SZ_IMPINVENTSUMFROMWMS'

SELECT a.createddatetime,a.docid,b.StatusName,a.ERROR,c.name,c.exchangeTable
FROM #request a INNER JOIN #tmp b ON a.statusID = b.StatusID
	INNER JOIN #Journal c ON a.journalID=c.id

DROP TABLE #tmp;
DROP TABLE #request;
DROP TABLE #Journal;

	


