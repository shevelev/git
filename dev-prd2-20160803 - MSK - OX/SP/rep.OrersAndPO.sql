ALTER PROCEDURE [rep].[OrersAndPO]
(


	@whatShow varchar(20),
	@externKey varchar(30)
)
AS

IF @whatShow = '��������'
BEGIN
	SELECT od.SKU [��� ������], sku.DESCR [�����], ORIGINALQTY [���������� ����������],SHIPPEDQTY [qty],o.EXTERNORDERKEY [DOCID],o.SUSR1 [�����]
	FROM WH1.orderdetail od JOIN wh1.sku sku 
	ON od.SKU=sku.sku		JOIN wh1.ORDERS o 
	ON O.ORDERKEY = od.ORDERKEY
	WHERE  o.EXTERNORDERKEY like isnull(@externKey,'%')  AND od.ADDDATE between '01.06.2015' and '30.06.2015' AND od.STATUS = 95
	ORDER BY o.EXTERNORDERKEY;
END
ELSE
BEGIN

	SELECT pd.SKU [��� ������],sku.DESCR [�����],SUM(pd.qtyordered) [���������� ����������],SUM(pd.qtyreceived) [qty],p.EXTERNPOKEY [DOCID],
	CASE pd.SUSR4 WHEN 'GENERAL' then '�����������' 
				  WHEN 'BRAKPRIEM' then '������������'
				  WHEN 'PRETENZ' then '�������������������'
				  WHEN 'LOSTPRIEM' then '����������������'
				  WHEN 'OVERPRIEM' then '�������������������'
				  WHEN 'SD' then '��'END [�����]
	FROM wh1.podetail pd JOIN 
		 wh1.po p ON pd.POKEY = p.POKEY JOIN
		 wh1.sku sku ON pd.SKU = sku.SKU
	WHERE p.EXTERNPOKEY like isnull(@externKey,'%') AND p.ADDDATE between '01.06.2015' and '30.06.2015' AND p.STATUS=11
	GROUP by p.EXTERNPOKEY,pd.SKU,sku.DESCR,pd.SUSR4
	ORDER BY p.EXTERNPOKEY;		
END;


--SELECT *
--FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpOUTPUTOrderLinesToWMS



----ORDER BY CREATEDDATETIME DESC;
--WHERE  docid='00000031_14';--CREATEDDATETIME between CONVERT(DATETIME,'01.06.2015',104) and CONVERT(DATETIME,'30.06.2015',104)




--p2.SUSR4 = 'GENERAL' then '�����������'
--when p2.SUSR4 = 'BRAKPRIEM' then '������������'
--when p2.SUSR4 = 'PRETENZ' then '�������������������'
--when p2.SUSR4 = 'LOSTPRIEM' then '����������������'
--when p2.SUSR4 = 'OVERPRIEM' then '�������������������'
--when p2.SUSR4 = 'SD' then '��'


