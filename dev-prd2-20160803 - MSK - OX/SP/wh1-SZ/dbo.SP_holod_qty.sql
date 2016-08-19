
/*
Отчет: Расположение медикаментов в холодильниках +2+8 и +8+15, и заметка по прохладе.
Автор: Шевелев С.С.
Дата: 03.06.2014
*/

ALTER PROCEDURE [dbo].[SP_holod_qty] 
@fr varchar(20),
@notes2 varchar(20) = null
AS

begin 


select lx.SKU, s.DESCR, la.LOTTABLE02, lx.LOC,lx.QTY
from wh1.LOTxLOCxID lx
join wh1.sku s on lx.SKU=s.SKU
join wh1.LOTATTRIBUTE la on lx.LOT=la.LOT
where lx.QTY>0 and s.FREIGHTCLASS=@fr
		and (@notes2 is NULL or convert(varchar(20),s.notes2) = @notes2)
		--and (@notes2 is NULL or s.notes2 like @notes2)

end

-- exec [dbo].[SP_holod_qty] '1','test'


--select * from wh1.sku where NOTES2 like '%test%'






