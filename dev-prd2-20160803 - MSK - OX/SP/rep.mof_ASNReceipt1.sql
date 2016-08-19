ALTER PROCEDURE [rep].[mof_ASNReceipt1] (
/* 01 ������� �� ������� (���) */
	@asn varchar(15),
	@receipttype varchar(10)=null
)
--with encryption
as

SELECT  R.RECEIPTKEY, --����� ���
		dbo.getean128(R.RECEIPTKEY) bcRECEIPKEY, --�� ����� ���
		RD.STORERKEY, -- ��������
		p.EXTERNPOKEY, 
		ST.COMPANY, -- �����
		p.sellername,  -- ��� ����������
		st1.COMPANY as pcom, -- �������� ���������
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
