ALTER PROCEDURE [dbo].[rep01_ASNReceipt2] (
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
FROM WH1.RECEIPTDETAIL AS RD 
		INNER JOIN WH1.RECEIPT AS R ON R.RECEIPTKEY = RD.RECEIPTKEY 
		INNER JOIN WH1.STORER AS ST ON ST.STORERKEY = RD.STORERKEY
		inner join wh1.PO AS P on p.OTHERREFERENCE=r.RECEIPTKEY
		join wh1.storer as st1 on st1.storerkey = p.sellername 
where RD.RECEIPTKEY like '' + @asn+''
GROUP BY R.RECEIPTKEY,ST.COMPANY, 
		st1.COMPANY, p.sellername,  
		p.EXTERNPOKEY,RD.STORERKEY 
