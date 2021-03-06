ALTER PROCEDURE [dbo].[ErrorsExchange](
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
	ERROR varchar(300),
	journalID int
)
CREATE TABLE #tmp
(
	StatusID int primary key,
	StatusName Varchar(20)
);

INSERT INTO #tmp
SELECT 5 ID, '�������' Status UNION
SELECT 10, '����������'UNION
SELECT 15, '������'UNION
SELECT 20, '��������';

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
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].InforIntegrationTable_Shipment
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, DOCID, STATUS,ERROR,10  
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].InforIntegrationLine_Shipment
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, DOCID, STATUS,ERROR,11  
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].InforIntegrationTable_Shipment
	WHERE CREATEDDATETIME BETWEEN '''+@date1+''' and '''+@date2+''' and ' + CASE WHEN @isError != 0 THEN 'Status = 15' else '1=1' END+'
	
	INSERT INTO #request
	SELECT CREATEDDATETIME, DOCID, STATUS,ERROR,12 
	FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].InforIntegrationLine_Shipment
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
	SELECT 9, 'InforIntegrationTable_Shipment','DOCID' UNION
	SELECT 10, 'InforIntegrationLine_Shipment','DOCID' UNION
	SELECT 11, 'InforIntegrationTable_Shipment','DOCID' UNION
	SELECT 12, 'InforIntegrationLine_Shipment','DOCID' UNION
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
	name varchar(200)
)

insert into #Journal
SELECT 19, '���������� ������� DAX -> INFOR' UNION
SELECT 1, '���������� �������� ������ INFOR -> DAX' UNION
SELECT 2, '������� DAX -> INFOR' UNION
SELECT 3, '������� DAX -> INFOR �����' UNION
SELECT 4, '������� DAX -> INFOR ������' UNION
SELECT 5, '������� INFOR -> DAX �����' UNION
SELECT 6, '������� INFOR -> DAX ������' UNION
SELECT 7, '�������� DAX -> INFOR �����' UNION
SELECT 8, '�������� DAX -> INFOR ������' UNION
SELECT 9, '������������ INFOR -> DAX' ����� UNION
SELECT 10, '������������ INFOR -> DAX ������' UNION
SELECT 11, '�������� INFOR -> DAX �����' UNION
SELECT 12, '�������� INFOR -> DAX ������' UNION
SELECT 13, '������ �������� INFOR -> DAX �����' UNION
SELECT 14, '������ �������� INFOR -> DAX ������' UNION
SELECT 15, '���������� INFOR -> DAX �����' UNION
SELECT 16, '���������� INFOR -> DAX ������' UNION
SELECT 17, '���������� DAX -> INFOR �����' UNION
SELECT 18, '���������� DAX -> INFOR ������' UNION
SELECT 20, '�������������� INFOR -> DAX'

SELECT a.createddatetime,a.docid,b.StatusName,a.ERROR,c.name
FROM #request a INNER JOIN #tmp b ON a.statusID = b.StatusID
	INNER JOIN #Journal c ON a.journalID=c.id

DROP TABLE #tmp;
DROP TABLE #request;
DROP TABLE #Journal;

	


