ALTER PROCEDURE [rep].[Total_qty_selection_in_weekday]
--DECLARE
@date_start datetime,-- = '26.09.2013',
@date_end datetime ,--= '01.12.2013',
@weekday int ,--= 1,
@ROUTE varchar(10)='99999',
@USER varchar(40) = 'any'-- = 'burmistrova'
AS
DECLARE
@tmp_date datetime = @date_start,
@qty_days_in_range float = 0

while (@tmp_date<=@date_end) --»щим количество ѕн или ¬т и т.п.
BEGIN
 IF (DATEPART(WEEKDAY,@tmp_date)=@weekday )
 BEGIN
 set @qty_days_in_range = @qty_days_in_range + 1;
 END 
 set @tmp_date = @tmp_date + 1;
END
DECLARE @count int = 0;
DECLARE @sql1 NVARCHAR(max)='
	SELECT COUNT(o.SERIALKEY)/@qty_days_in_range qty_per_weekday,DATEPART(HOUR,t.EDITDATE) hour'+CASE WHEN @ROUTE like '99999' THEN '' ELSE ' ,t.ROUTE ' END+'
	into #tmp
	FROM WH1.TASKDETAIL t JOIN WH1.ORDERS o
	ON t.ORDERKEY = o.ORDERKEY
	WHERE '+CASE WHEN @USER like 'any' THEN '' else '@USER = t.EDITWHO AND' END+' '+CASE WHEN @ROUTE like '99999' THEN '' ELSE ' @ROUTE = t.ROUTE AND' END+' t.STATUS like ''9'' AND DATEPART(WEEKDAY,t.EDITDATE) = @weekday and t.EDITDATE BETWEEN @date_start and @date_end
	GROUP BY DATEPART(HOUR,t.EDITDATE)'+CASE WHEN @ROUTE like '99999' THEN '' ELSE ',t.ROUTE' END+';
	
	CREATE TABLE #tmp1
	(
	hour int
	)
	
	while (@count<24)
	BEGIN
		insert into #tmp1
		Values (@count);
		set @count=@count+1;
	END;
	
INSERT INTO #tmp(qty_per_weekday,hour'+CASE WHEN @ROUTE like '99999' THEN '' ELSE ' ,ROUTE ' END+')
SELECT 0.0,hour'+CASE WHEN @ROUTE like '99999' THEN '' ELSE ' ,@ROUTE ' END+'
FROM #tmp1 outr
WHERE NOT EXISTS(Select 1 FROM #tmp ins WHERE outr.hour=ins.hour);

SELECT qty_per_weekday, hour,
'+CASE WHEN @ROUTE like '99999' THEN '''nope'' time' else '
CASE WHEN ['+CONVERT(VARCHAR,@weekday)+'] is NULL THEN ''nope''
ELSE  CONVERT(VARCHAR,['+CONVERT(VARCHAR,@weekday)+'],108)end time'
END +'
FROM #tmp '+CASE WHEN @ROUTE like '99999' THEN '' ELSE ' JOIN dbo.LoadGroup
ON ROUTE = ROUTEID ' END+';'
	
EXEC sp_executesql
@statement = @sql1,
@params = N'@qty_days_in_range float, @USER varchar(40), @ROUTE varchar(10), @weekday int, @date_start datetime, @date_end datetime, @count int',
@qty_days_in_range = @qty_days_in_range, @USER = @USER, @ROUTE = @ROUTE, @weekday = @weekday, @date_start = @date_start, @date_end = @date_end, @count = @count;











