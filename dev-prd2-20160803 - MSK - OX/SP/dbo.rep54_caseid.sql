/* Список ЗЗ с браком */
ALTER PROCEDURE [dbo].[rep54_caseid](
 	--@dat1  datetime,
 	--@dat2  datetime,
 	--@marsh   varchar (50),
 	--@nz   varchar (50),
 	@cid varchar (50)
)
AS


SELECT     pd.CASEID, dbo.GetEAN128(pd.CASEID) AS shkcase, pd.ORDERKEY, tt.EXTERNORDERKEY, tt.CONSIGNEEKEY, tt.C_COMPANY, pd.DOOR, dbo.GetEAN128(pd.DOOR) 
                      AS shkvor, pd.ROUTE, tt.C_ADDRESS1, tt.REQUESTEDSHIPDATE, tt.ORDERDATE
FROM         WH1.ORDERS AS tt INNER JOIN
                      WH1.ORDERDETAIL AS od ON tt.ORDERKEY = od.ORDERKEY INNER JOIN
                      WH1.PICKDETAIL AS pd ON tt.ORDERKEY = pd.ORDERKEY
WHERE     (pd.CASEID = @cid)


