-- =============================================
-- �����:		��������� ��������
-- ������:		������, �.�������
-- ���� ��������: 13.04.2010 (������)
-- ��������: ���� ��� �������� ����� �� ���
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV24_ASN_Where] ( 
	@wh varchar(30),								
	@ASNkey varchar(15)
	
)
as

declare @sql varchar(max)

set @sql='
select RD.receiptkey ASNKey,
		RD.toid ID,
		RD.sku Sku,
		isnull(I.toloc,''�� ��������'') Loc,
		I.addwho Who
from '+@wh+'.RECEIPTDETAIL RD
left join '+@wh+'.ITRN I on RD.storerkey=I.storerkey
						and RD.sku=I.sku
						and RD.tolot=I.lot
						and RD.toid=I.fromid
						and RD.toloc=I.fromloc
where RD.receiptkey='''+@ASNkey+'''
		and RD.qtyexpected=0
		and RD.toid<>''''
order by RD.toid
'

print (@sql)
exec (@sql)

