


ALTER PROCEDURE [rep].[Total_qty_orders_in_weekday2]
@date_start datetime,
@date_end datetime,
@weekday int,
@ROUTE varchar(10)
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


SELECT COUNT(ORDERKEY)/@qty_days_in_range qty_per_weekday,CONVERT (VARCHAR,DATEPART(HOUR,ORDERDATE)) hour,ROUTE
into #tmp
FROM WH1.ORDERS
WHERE  @ROUTE = ROUTE AND DATEPART(WEEKDAY,ORDERDATE) = @weekday AND ORDERDATE BETWEEN @date_start AND  @date_end
GROUP BY DATEPART(HOUR,ORDERDATE),ROUTE;


CREATE TABLE #tmp1
(
hour int
)
DECLARE @count int = 0
while (@count<24)
BEGIN
	insert into #tmp1
	Values (@count);
	set @count=@count+1;
END;



INSERT INTO #tmp(qty_per_weekday,hour,ROUTE)
SELECT 0.0,hour,@ROUTE
FROM #tmp1 outr
WHERE NOT EXISTS(Select 1 FROM #tmp ins WHERE outr.hour=ins.hour);


DECLARE @sql VARCHAR(max)='
SELECT qty_per_weekday,CONVERT(int,hour) hour,
CASE WHEN ['+CONVERT(VARCHAR,@weekday)+'] is NULL THEN ''nope''
ELSE  CONVERT(VARCHAR,['+CONVERT(VARCHAR,@weekday)+'],108)end time
FROM #tmp JOIN dbo.LoadGroup
ON ROUTE = ROUTEID
ORDER by 2;'

exec (@sql)


DROP TABLE #tmp;
DROP TABLE #tmp1

