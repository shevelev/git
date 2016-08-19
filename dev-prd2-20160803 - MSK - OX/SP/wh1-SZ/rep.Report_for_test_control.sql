
ALTER PROCEDURE [rep].[Report_for_test_control]

@caseid varchar(20)=NULL,--'0000462667',
@dropid varchar(18)=NULL--'D001573660'
AS

select
@dropid = nullif(rtrim(@dropid),''),
@caseid = nullif(rtrim(@caseid),'')

CREATE TABLE #tmp
(
ORDERKEY varchar(10),
caseid varchar(20),
dropid varchar(18),
SKU varchar(50),
Altsku varchar(50)
)

IF (@caseid is NULL AND @dropid IS not NULL OR @caseid is NOT NULL and @dropid is  null)
BEGIN
DECLARE
@sql NVARCHAR(max)='	
SELECT o.ORDERKEY, pd.CASEID,pd.DROPID,pd.SKU,ISNULL(alt.ALTSKU,''nope'') Altsku, pd.qty
FROM WH1.ORDERS o JOIN WH1.PICKDETAIL pd
ON o.ORDERKEY = pd.ORDERKEY JOIN WH1.SKU s
ON pd.SKU = s.SKU
join wh1.ALTSKU alt on s.SKU=alt.sku
WHERE ' +case when @caseid is NULL then '' else '@caseid=pd.caseid' end +CASE WHEN @dropid is null then '' else '@dropid = pd.dropid' end 

exec sp_executesql @sql,N'@caseid varchar(20),@dropid varchar(18)',
@caseid=@caseid,@dropid=@dropid
END
else IF (@caseid is not null and @dropid is not null)
	SELECT o.ORDERKEY, pd.CASEID,pd.DROPID,pd.SKU,ISNULL(alt.ALTSKU,'nope') Altsku, pd.QTY
	FROM WH1.ORDERS o JOIN WH1.PICKDETAIL pd
	ON o.ORDERKEY = pd.ORDERKEY JOIN WH1.SKU s
	ON pd.SKU = s.SKU
	join wh1.ALTSKU alt on s.SKU=alt.sku
	WHERE @caseid=pd.caseid AND @dropid = pd.dropid
ELSE
select *
from #tmp
drop table #tmp

