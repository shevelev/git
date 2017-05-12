-- =============================================
-- �����:		������� �����
-- ������:		������, �.�������
-- ���� ��������: 27.10.2009 (������)
-- ��������: ������� ������� SKUXLOC �� ������� ������������� ���������� ������� � ������� ������

-- =============================================
ALTER PROCEDURE [WH1].[novex_DelBadSKUHistory] 
AS


print '1111111111111111111111111111111111111111111111111111111111111111111111111111'
print '�������� ������ SKUXLOC, ������� ����� �������'
select sxl.loc, sxl.storerkey, sxl.sku
into #delSKUxLOC
from wh1.skuxloc sxl
left join wh1.lotxlocxid lld on (sxl.loc=lld.loc and sxl.storerkey=lld.storerkey and sxl.sku=lld.sku)	--������� �� ������� ������
join wh1.loc loc on (sxl.loc=loc.loc)
where 
(sxl.qtylocationminimum=0 and sxl.qtylocationlimit=0 and sxl.allowreplenishfromcasepick=0)
AND
(lld.qty is null or lld.qty=0)
AND
(sxl.qty=0)
AND
sxl.loc like '[1-9]___.[1-9].[1-9]'
AND
loc.locationtype='PICK'
AND
sxl.storerkey<>'000000001'

print '2222222222222222222222222222222222222222222222222222222222222222222222222222'
print '������� ������ �� SKUXLOC'
delete from wh1.skuxloc
from wh1.skuxloc sxl
join #delSKUxLOC DL on (sxl.loc=DL.loc and sxl.storerkey=DL.storerkey and sxl.sku=DL.sku)
where (sxl.qty=0) --��� ������� �� ������ ������, ��� �� �� ���� �������� ��� ���������� �� ������� � ��������� �� ���������

print '3333333333333333333333333333333333333333333333333333333333333333333333333333'
print '������� ��������� ����������, ��� ������������ ������'
update wh1.skuxloc
set qtylocationlimit=0,
	qtylocationminimum=0,
	ALLOWREPLENISHFROMCASEPICK=0,
	ALLOWREPLENISHFROMBULK=0,
	replenishmentseverity=0,
	REPLENISHMENTPRIORITY='9'
where
 locationtype<>'PICK'
AND
(	qtylocationlimit>0
	or qtylocationminimum>0
	or ALLOWREPLENISHFROMCASEPICK=1
	or ALLOWREPLENISHFROMBULK=1)

