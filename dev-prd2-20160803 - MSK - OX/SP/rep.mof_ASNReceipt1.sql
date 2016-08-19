ALTER PROCEDURE [rep].[mof_ASNReceipt1] (
/* 01 Задание на приемку (ПУО) */
	@asn varchar(15),
	@receipttype varchar(10)=null
)
--with encryption
as

SELECT  R.RECEIPTKEY, --номер пуо
		dbo.getean128(R.RECEIPTKEY) bcRECEIPKEY, --шк номер пуо
		RD.STORERKEY, -- владелец
		p.EXTERNPOKEY, 
		ST.COMPANY, -- склад
		p.sellername,  -- код поставщика
		st1.COMPANY as pcom, -- название поставщик
		max(R.RECEIPTDATE)RECEIPTDATE
FROM wh2.RECEIPTDETAIL AS RD 
		INNER JOIN wh2.RECEIPT AS R ON R.RECEIPTKEY = RD.RECEIPTKEY 
		INNER JOIN wh2.STORER AS ST ON ST.STORERKEY = RD.STORERKEY
		inner join wh2.PO AS P on p.OTHERREFERENCE=r.RECEIPTKEY
		join wh2.storer as st1 on st1.storerkey = p.sellername 
where RD.RECEIPTKEY like '' + @asn+''
GROUP BY R.RECEIPTKEY,ST.COMPANY, 
		st1.COMPANY, p.sellername,  
		p.EXTERNPOKEY,RD.STORERKEY 
