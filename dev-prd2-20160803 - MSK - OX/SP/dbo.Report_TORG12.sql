ALTER PROCEDURE [dbo].[Report_TORG12] (
@wh varchar (15), @orderkey varchar (15))
as
declare @sql varchar (max)
set @sql =
'SELECT     CONVERT(datetime, CONVERT(varchar(10), ord.EDITDATE, 104), 104) AS EditDate, st.SUSR3 AS OKPO, ord.SUSR4 AS SMnum, o.ORDERKEY, s.DESCR, s.SKU, s.STDGROSSWGT, (o.QTYPICKED+o.shippedqty) AS shippedqty, 
                      ISNULL(o.UNITPRICE, 0) AS price, ISNULL(o.UNITPRICE, 0) * (o.QTYPICKED+o.shippedqty) AS cost,
                          (SELECT     ISNULL(DESCRIPTION, (ISNULL(COMPANY,''''))) + '', »ÕÕ '' + ISNULL(VAT, '''') + '', '' + ISNULL(ADDRESS1, '''') + '' '' + ISNULL(ADDRESS2, '''') + '' '' + ISNULL(ADDRESS3, '''')
                                                    + '', '' + ISNULL(PHONE1, '''') + '', '' + ISNULL(FAX1, '''') + '', '' + ISNULL(cast(NOTES2 as varchar(max)),'''') AS Expr1
                            FROM          '+@WH+'.STORER
								WHERE      (STORERKEY = ord.B_COMPANY)) 
							AS NORD,
						ISNULL(st.DESCRIPTION, (ISNULL(st.COMPANY,''''))) + '', »ÕÕ '' + ISNULL(st.VAT, '''') + '', '' + ISNULL(st.ADDRESS1, '''') 
                      + '' '' + ISNULL(st.ADDRESS2, '''') + '' '' + ISNULL(st.ADDRESS3, '''') + '', '' + ISNULL(st.PHONE1, '''') + '', '' + ISNULL(st.FAX1, '''') + ISNULL(cast(st.NOTES2 as varchar(max)),'''')
							 AS CLIENT
			
FROM         '+@WH+'.ORDERDETAIL AS o INNER JOIN
                      '+@WH+'.SKU AS s ON s.SKU = o.SKU AND s.STORERKEY = o.STORERKEY INNER JOIN
                      '+@WH+'.STORER AS st ON st.STORERKEY = o.STORERKEY INNER JOIN
                      '+@WH+'.ORDERS AS ord ON ord.ORDERKEY = o.ORDERKEY
WHERE     (o.ORDERKEY = '''+@orderkey+''')
ORDER BY s.DESCR'
exec (@sql)

