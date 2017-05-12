ALTER PROCEDURE [dbo].[rep08_ttns] (
	@wh varchar(30),
	@orderkey varchar(15),
	@NumOfPlaces varchar (10)
)
as
declare @sql varchar(max)

SELECT     
	CONVERT(datetime, CONVERT(varchar(10), ord.EDITDATE, 104), 104) AS EditDate, 
	od.ORDERKEY, s.DESCR, s.SKU, SUM(od.QTY) AS shippedqty, 
	SUM(ISNULL(s.PRICE, 0)) AS price, 
	SUM(ISNULL(s.PRICE, 0) * od.QTY) AS cost,
    (SELECT     ISNULL(COMPANY, '') + ', »ÕÕ ' + ISNULL(VAT, '') + ', ' 
			+ ISNULL(ADDRESS1, '') + ' ' + ISNULL(ADDRESS2, '') + ' ' + ISNULL(ADDRESS3, '')+ ' ' + ISNULL(ADDRESS4, '')
			+ ', ' + ISNULL(PHONE1, '') + ', ' + ISNULL(FAX1, '') AS Expr1
        FROM WH40.STORER
        WHERE (STORERKEY = 'ST6661018350')) AS Storer, 
ISNULL(st.COMPANY, '') + ', »ÕÕ ' + ISNULL(st.VAT, '') + ', ' + ord.DeliveryAdr
        + ', ' + ISNULL(st.PHONE1, '') 
        + ', ' + ISNULL(st.FAX1, '')  DeliveryAdr,
    ISNULL(st.COMPANY, '') + ', »ÕÕ ' + ISNULL(st.VAT, '') + ', ' + ISNULL(st.ADDRESS1, '') 
        + ' ' + ISNULL(st.ADDRESS2, '') + ' ' + ISNULL(st.ADDRESS3, '') + ' ' + ISNULL(st.ADDRESS4, '') 
        + ', ' + ISNULL(st.PHONE1, '') 
        + ', ' + ISNULL(st.FAX1, '') AS CLIENT,
    sum(od.QTY*s.stdgrosswgt)/1000 grossWeightTonn,
    sum(od.QTY*s.stdnetwgt)/1000 netWeightTonn,
    case when isnull(@NumOfPlaces,0)=0 then '' else cast(@NumOfPlaces as varchar(10)) end NumOfPlaces
    
into #ttn
FROM WH40.pickDETAIL AS od
	join wh40.PackLoadSend pls on pls.serialkey = od.serialkey
	left JOIN WH40.SKU AS s ON s.SKU = od.SKU AND s.STORERKEY = od.STORERKEY 
	left JOIN WH40.ORDERS AS ord ON ord.ORDERKEY = od.ORDERKEY
	left JOIN WH40.STORER AS st ON st.STORERKEY = ord.consigneeKEY 
WHERE  (od.ORDERKEY = @orderkey) and od.status=9
GROUP BY CONVERT(datetime, CONVERT(varchar(10), ord.EDITDATE, 104), 104), 
	od.ORDERKEY, st.COMPANY, od.ORDERKEY, s.DESCR, s.SKU, st.COMPANY,  ord.DeliveryAdr,
	st.VAT, st.ADDRESS1, st.ADDRESS2, st.ADDRESS3, st.ADDRESS4, st.PHONE1, st.FAX1
ORDER BY s.DESCR

select sum(grossWeightTonn)totalGross, sum(netWeightTonn)totalNet into #total from #ttn

select * from #ttn, #total

drop table #ttn
drop table #total

