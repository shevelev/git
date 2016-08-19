ALTER PROCEDURE [dbo].[SP_POSTPHYSICAL_CST0030] 
@wh varchar(15)
AS

-- ��������� ���������� �� DWarehouseManagement.PostPhysicalP1S1.ProcessStep ��� ������������� �������������� �
-- ������� ������� (���� "��������� ��������������"/"Physical parameters" ���� "������� ���������� ���."/"Post physical").

-- � ��������� ����� ������� �����-���� ��������, ������� ����� ��������� ����� ����������� ����������� ��������������.
-- �� ������� "������-�����" ��� - ����������� ������ �� ����. �������������� � �������� �������.

-- ���� ������� �������������� �������� �� ���������, ���� ��������� ����� �������� ������.

SET NOCOUNT ON

declare @currentdate datetime
declare @key int

set @currentdate = GETDATE() -- ������� ����

--�������� ����� ��� ������ � ���
exec dbo.DA_GetNewKey 'wh1','INVENTORYKEY',@key output

--����������, ����� InventoryKey � ����. xxx_CST0030 � � TRANSMITLOG ��������, �.�. ��� �������� ������ ���� ����� ������ �� ����� ������. 
--AppServer ��� ������� ������� � TRANSMITLOG ����� ������� �������� �������� �� �. NCOUNTER.
--������� ����� ����� ����� ������� �������� �������� �� NCOUNTER, � �� ��, ������� ������� ����. DA_GetNewKey.
--����� �������, ��� �������� INVENTORYKEY � �. NCOUNTER �������� ��������� ������� ��������, � �� ������ ���������.
--select @key = right('0000000000' + cast(keycount as varchar),10) from wh1.NCOUNTER where KEYNAME ='INVENTORYKEY'
select @key = keycount from wh1.NCOUNTER where KEYNAME ='INVENTORYKEY'


-- ������� �������
insert into wh1.lotxlocxid_CST0030 (
	[inventoryid_030],
	[adddate_030],
	[SERIALKEY],
	[WHSEID],
	[LOT],
	[LOC],
	[ID],
	[STORERKEY],
	[SKU],
	[QTY],
	[QTYALLOCATED],
	[QTYPICKED],
	[QTYEXPECTED],
	[QTYPICKINPROCESS],
	[PENDINGMOVEIN],
	[ARCHIVEQTY],
	[ARCHIVEDATE],
	[STATUS],
	[ADDDATE],
	[ADDWHO],
	[EDITDATE],
	[EDITWHO])
select 
	@key,
	@currentdate,
	[SERIALKEY],
	[WHSEID],
	[LOT],
	[LOC],
	[ID],
	[STORERKEY],
	[SKU],
	[QTY],
	[QTYALLOCATED],
	[QTYPICKED],
	[QTYEXPECTED],
	[QTYPICKINPROCESS],
	[PENDINGMOVEIN],
	[ARCHIVEQTY],
	[ARCHIVEDATE],
	[STATUS],
	[ADDDATE],
	[ADDWHO],
	[EDITDATE],
	[EDITWHO]
from wh1.lotxlocxid where QTY > 0


update p set 
	[STATUS] = '9'
from (
	select
		[STATUS],
		row_number() over (partition by TEAM, STORERKEY, SKU, LOC, LOT/*, ID*/ order by INVENTORYTAG desc, ADDDATE desc) as RN
	from wh1.PHYSICAL
	where [STATUS] = '0'
) p
where RN > 1



insert into wh1.PHYSICAL_CST0030(
	[PHYSICAL_030] ,
	[adddate_030] ,
	[SERIALKEY],
	[WHSEID] ,
	[TEAM],
	[STORERKEY],
	[SKU],
	[LOC],
	[LOT],
	[ID] ,
	[INVENTORYTAG],
	[QTY],
	[PACKKEY],
	[UOM],
	[STATUS],
	[ADDDATE],
	[ADDWHO],
	[EDITDATE],
	[EDITWHO])
select
	@key,
	@currentdate,
	[SERIALKEY],
	[WHSEID] ,
	[TEAM],
	[STORERKEY],
	[SKU],
	[LOC],
	[LOT],
	[ID] ,
	[INVENTORYTAG],
	[QTY],
	[PACKKEY],
	[UOM],
	[STATUS],
	[ADDDATE],
	[ADDWHO],
	[EDITDATE],
	[EDITWHO]
from WH1.PHYSICAL
where STATUS = 0




--select * from wh1.lotxlocxid_CST0030
--select * from wh1.PHYSICAL_CST0030

--delete from wh1.lotxlocxid_CST0030
--delete from wh1.PHYSICAL_CST0030

RETURN 0

