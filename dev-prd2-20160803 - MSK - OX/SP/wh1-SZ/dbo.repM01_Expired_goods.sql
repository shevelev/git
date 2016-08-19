
ALTER PROCEDURE [dbo].[repM01_Expired_goods] (@datetm DATETIME)
AS 
SELECT  l.SKU,
		s.DESCR,
		cell.LOC CELL,
		COUNT(s.DESCR) CNT,
		lot_atrb.LOTTABLE02 series,
		CONVERT(VARCHAR,lot_atrb.LOTTABLE05,103) working_life

FROM WH1.LOT l JOIN WH1.SKU s
		ON l.SKU = s.SKU JOIN WH1.LOTxLOCxID cell
		ON l.LOT = cell.LOT JOIN WH1.LOTATTRIBUTE lot_atrb
		ON l.LOT = lot_atrb.LOT 

WHERE  @datetm > lot_atrb.LOTTABLE05
GROUP BY s.DESCR,cell.LOC,l.SKU,lot_atrb.LOTTABLE02, CONVERT(VARCHAR,lot_atrb.LOTTABLE05,103);
