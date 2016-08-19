ALTER PROCEDURE [dbo].[rep52_PODiv] (
	/*   Акт расхождений при приемке ЗЗ */
	@pk varchar(15)
)AS

select 
		SKU, 
		SKUDESCRIPTION, 
		sum(QTYORDERED) zak,
		sum(QTYRECEIVED) otgr,
		case when sum(pd.qtyordered)-sum(pd.qtyreceived)>0 
				then sum(pd.qtyordered)-sum(pd.qtyreceived) 
			else 0 
		end as ned,
		case 
			when sum(pd.qtyordered)-sum(pd.qtyreceived)<0 
			then sum(pd.qtyreceived)-sum(pd.qtyordered)
			else 0 
		end as izl,
		sum(pd.qtyrejected) brak

from wh1.podetail pd
where POKEY = @pk

group by SKU, SKUDESCRIPTION
