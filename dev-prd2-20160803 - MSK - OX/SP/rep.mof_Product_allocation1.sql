-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 13.04.2010 (НОВЭКС)
-- Описание: Куда был размещен товар по ПУО
--	...
-- =============================================
ALTER PROCEDURE [rep].[mof_Product_allocation1] ( 
	@wh varchar(30),								
	@ASNkey varchar(15)
	
)
as




select  RD.receiptkey ASNKey,
		RD.toid ID,
		RD.sku Sku,
		isnull(I.toloc,'Не размещен') Loc,
		I.addwho Who
from wh2.RECEIPTDETAIL RD
left join wh2.ITRN I on RD.storerkey=I.storerkey
						and RD.sku=I.sku
						and RD.tolot=I.lot
						and RD.toid=I.fromid
						and RD.toloc=I.fromloc
where RD.receiptkey=@ASNkey
		and RD.qtyexpected=0
		and RD.toid<>''
order by RD.toid




