
ALTER PROCEDURE [rep].[act_of_differences_in_PO](
@pk varchar(15)-- = '0000030573'
)
AS
SELECT DISTINCT
	SKU,
	SKUDESCRIPTION,
	POKEY
INTO #tmp
FROM 
	WH1.PODETAIL
WHERE POKEY like @pk

ALTER TABLE #tmp
	ADD zak INTEGER NULL,
		brak INTEGER NULL,
		otgr INTEGER NULL,
		izl INTEGER NULL,
		ned INTEGER NULL

UPDATE #tmp
	SET
		zak =  ISNULL(
					(SELECT SUM(QTYORDERED) zak 
					FROM WH1.PODETAIL
					WHERE POKEY like @pk and SKU = e.SKU
					GROUP BY SKU),0),
					
		otgr = ISNULL(
					(SELECT SUM(QTYRECEIVED)
					FROM WH1.PODETAIL
					WHERE POKEY like @pk and SKU = e.SKU and SUSR4 like 'GENERAL'
					GROUP BY SKU),0),
					
		brak = ISNULL(
					(SELECT SUM(QTYRECEIVED)
					FROM WH1.PODETAIL
					WHERE POKEY like @pk and SKU = e.SKU and SUSR4 like 'BRAKPRIEM'
					GROUP BY SKU),0)					 				
	FROM #tmp e

UPDATE #tmp
		SET
		izl = ISNULL(
					(SELECT sum(QTYRECEIVED)
					 FROM WH1.PODETAIL
					 WHERE SUSR4 like 'OVERPRIEM' AND SKU = e.SKU
					 GROUP BY SKU),
					(SELECT CASE WHEN otgr - zak - brak  > 0						
							THEN otgr - zak - brak 
							ELSE 0 END
					 FROM #tmp
					 WHERE POKEY like @pk and SKU = e.SKU))
		FROM #tmp e
			 
UPDATE #tmp
		SET
		ned = ISNULL(
					(SELECT sum(QTYRECEIVED)
					 FROM WH1.PODETAIL
					 WHERE SUSR4 like 'LOSTPRIEM' AND SKU = e.SKU
					 GROUP BY SKU),
					(SELECT CASE WHEN zak - otgr - brak  > 0 and otgr > 0 
							THEN zak - otgr - brak 
							ELSE 0 END
					 FROM #tmp
					 WHERE POKEY like @pk and SKU = e.SKU))
		FROM #tmp e

SELECT *
FROM #tmp	
	
DROP TABLE #tmp;


/*SELECT SKU,POKEY,QTYORDERED,QTYRECEIVED,SUSR4
FROM WH1.PODETAIL
WHERE POKEY like @pk*/
