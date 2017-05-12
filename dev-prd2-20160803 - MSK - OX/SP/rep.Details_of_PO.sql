

ALTER PROCEDURE [rep].[Details_of_PO](
 	@pk  varchar (50),--='0000030565',
 	@extn varchar (50)--='00003732_324'
 	)
AS

SELECT @pk=POKEY,@extn=EXTERNPOKEY 
FROM WH1.PO	
where (POKEY like '%'+isnull(@pk,'')+'%' and EXTERNPOKEY like '%'+isnull(@extn,'')+'%')

SELECT DISTINCT
	p.EXTERNPOKEY,
	p.POKEY,
	pd.SKU,
	pd.SKUDESCRIPTION,
	ck.DESCRIPTION,
	pd.UOM, 
    pd.SKU_CUBE, 
    pd.SKU_WGT	
INTO #tmp
FROM 
	WH1.PO p JOIN 
	WH1.PODETAIL pd ON pd.POKEY = p.POKEY JOIN 
	WH1.CODELKUP ck ON pd.STATUS = ck.CODE and ck.LISTNAME = 'postatus'
WHERE p.POKEY like @pk AND p.EXTERNPOKEY like @extn;

ALTER TABLE #tmp
	ADD QTYORDERED INTEGER NULL,
		QTYRECEIVED INTEGER NULL,
		QTYREJECTED INTEGER NULL

UPDATE #tmp
	 SET 
		QTYORDERED =  ISNULL(
					   (SELECT SUM(QTYORDERED) zak 
						FROM WH1.PODETAIL
						WHERE POKEY like @pk and EXTERNPOKEY like @extn and SKU = e.SKU
						GROUP BY SKU),0),
				
		QTYRECEIVED = ISNULL(
					   (SELECT SUM(QTYRECEIVED)
						FROM WH1.PODETAIL
						WHERE POKEY like @pk and SKU = e.SKU and SUSR4 in ('GENERAL','BRAKPRIEM','PRETENZ','OVERPRIEM')
						GROUP BY SKU),0),
				
		QTYREJECTED = ISNULL(
					   (SELECT SUM(QTYRECEIVED)
						FROM WH1.PODETAIL
						WHERE POKEY like @pk and EXTERNPOKEY like @extn and
						SKU = e.SKU and SUSR4 like 'BRAKPRIEM'
						GROUP BY SKU),0)	
	 FROM #tmp e


select t.EXTERNPOKEY, t.POKEY, t.SKU, t.DESCRIPTION, t.UOM, t.SKU_CUBE, t.SKU_WGT, t.QTYORDERED,t.QTYRECEIVED, t.QTYREJECTED, s.NOTES1 SKUDESCRIPTION
from #tmp t
join wh1.sku s on s.SKU=t.sku

DROP TABLE #tmp

/*SELECT pokey,sku,QTYORDERED,QTYRECEIVED,SUSR4
FROM WH1.PODETAIL
WHERE POKEY like @pk--EXTERNPOKEY = @extn*/
