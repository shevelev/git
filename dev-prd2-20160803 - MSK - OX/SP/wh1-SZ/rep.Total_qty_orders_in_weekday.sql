
ALTER PROCEDURE [rep].[Total_qty_orders_in_weekday]
@date_start datetime,
@date_end datetime,
@weekday int 

AS
BEGIN
DECLARE
@tmp_date datetime = @date_start,
@qty_days_in_range int = 0


while (@tmp_date<=@date_end) --»щим количество ѕн или ¬т и т.п.
BEGIN
 IF (DATEPART(WEEKDAY,@tmp_date)=@weekday )
 BEGIN
 set @qty_days_in_range = @qty_days_in_range + 1;
 END 
 set @tmp_date = @tmp_date + 1;
END

SELECT 
[0]/@qty_days_in_range '0:00-1:00',[1]/@qty_days_in_range '1:00-2:00',[2]/@qty_days_in_range '2:00-3:00',
[3]/@qty_days_in_range '3:00-4:00',[4]/@qty_days_in_range '4:00-5:00',[5]/@qty_days_in_range '5:00-6:00',
[6]/@qty_days_in_range '6:00-7:00',[7]/@qty_days_in_range '7:00-8:00',[8]/@qty_days_in_range '8:00-9:00',
[9]/@qty_days_in_range '9:00-10:00',[10]/@qty_days_in_range '10:00-11:00',[11]/@qty_days_in_range '11:00-12:00',
[12]/@qty_days_in_range '12:00-13:00',[13]/@qty_days_in_range '13:00-14:00',[14]/@qty_days_in_range '14:00-15:00',
[15]/@qty_days_in_range '15:00-16:00',[16]/@qty_days_in_range '16:00-17:00',[17]/@qty_days_in_range '17:00-18:00',
[18]/@qty_days_in_range '18:00-19:00',[19]/@qty_days_in_range '19:00-20:00',[20]/@qty_days_in_range '20:00-21:00',
[21]/@qty_days_in_range '21:00-22:00',[22]/@qty_days_in_range '22:00-23:00',[23]/@qty_days_in_range '23:00-24:00',
[24]/@qty_days_in_range '24:00-0:00'
FROM (SELECT ORDERKEY, DATEPART(HOUR,ORDERDATE) l FROM WH1.ORDERS
WHERE DATEPART(weekday,ORDERDATE) = @weekday AND ORDERDATE BETWEEN @date_start and @date_end) x
PIVOT
(COUNT(ORDERKEY)
FOR l
IN([0],[1],[2],[3],[4],[5],[6],[7],[8],[9],
[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],
[20],[21],[22],[23],[24])
) pvt
END


