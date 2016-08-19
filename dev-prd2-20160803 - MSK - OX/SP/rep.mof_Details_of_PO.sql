

ALTER PROCEDURE [rep].[mof_Details_of_PO](
 	@pk  varchar (50),--='0000030565',
 	@extn varchar (50)--='00003732_324'
 	)
AS

SELECT @pk=POKEY,@extn=EXTERNPOKEY 
FROM wh2.PO	
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
	wh2.PO p JOIN 
	wh2.PODETAIL pd ON pd.POKEY = p.POKEY JOIN 
	wh2.CODELKUP ck ON pd.STATUS = ck.CODE and ck.LISTNAME = 'postatus'
WHERE p.POKEY like @pk AND p.EXTERNPOKEY like @extn;

ALTER TABLE #tmp
	ADD QTYORDERED INTEGER NULL,
		QTYRECEIVED INTEGER NULL,
		QTYREJECTED INTEGER NULL

UPDATE #tmp
	 SET 
		QTYORDERED =  ISNULL(
					   (SELECT SUM(QTYORDERED) zak 
						FROM wh2.PODETAIL
						WHERE POKEY like @pk and EXTERNPOKEY like @extn and SKU = e.SKU
						GROUP BY SKU),0),
				
		QTYRECEIVED = ISNULL(
					   (SELECT SUM(QTYRECEIVED)
						FROM wh2.PODETAIL
						WHERE POKEY like @pk and SKU = e.SKU and SUSR4 in ('GENERAL','BRAKPRIEM','PRETENZ','OVERPRIEM')
						GROUP BY SKU),0),
				
		QTYREJECTED = ISNULL(
					   (SELECT SUM(QTYRECEIVED)
						FROM wh2.PODETAIL
						WHERE POKEY like @pk and EXTERNPOKEY like @extn and
						SKU = e.SKU and SUSR4 like 'BRAKPRIEM'
						GROUP BY SKU),0)	
	 FROM #tmp e

SELECT *
FROM #tmp

DROP TABLE #tmp

/*SELECT pokey,sku,QTYORDERED,QTYRECEIVED,SUSR4
FROM wh2.PODETAIL
WHERE POKEY like @pk--EXTERNPOKEY = @extn*/
