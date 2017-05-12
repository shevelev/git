-- =============================================
-- �����:		������� �����
-- ������:		������, �.�������
-- ���� ��������: 27.10.2009 (������)
-- ��������: ������� ���������� ���������� ��� ������� � ������� �������� �� ������ � ������� @ZZ ����
------ ����������� ������� �� �������� SKUxLOC � LOTxLOCxID, � ����� ���������� ������� �� ������� PHYSICAL

-- =============================================
ALTER PROCEDURE [WH1].[novex_ClearPickLoc_for_zero_balance] 
AS

declare @pLOC	varchar(10),
		@ZZ		int			--���������� ���� �� ���������� �������� ����� �������� ��������� ���������� ��� �������
							--� ������� �������� �� ������
--07.12.2009 ������� �.�.: ����������� �� ������������ � ������� �.�.
set @ZZ=3

print '1111111111111111111111111111111111111111111111111111111111111111111111111111'
print '�������� ������, �� ������� �� ������ ���� �������'
select distinct lld.storerkey, lld.sku
into #SKUbalance
from lotxlocxid lld join skuxloc sxl on (lld.loc=sxl.loc and lld.storerkey=sxl.storerkey and lld.sku=sxl.sku)
where (lld.qty>0 or sxl.qty>0)
--drop table #SKUbalance

print '2222222222222222222222222222222222222222222222222222222222222222222222222222'
print '�������� ������ �����+������� �� ������� ��������� �������� ������ � SKUXLOC � LOTxLOCxID'
select distinct sxl.loc, sxl.storerkey, sxl.sku
into #LOCtoCLEAR
from SKUxLOC sxl
join LOTxLOCxID lld on (sxl.loc=lld.loc and sxl.storerkey=lld.storerkey and sxl.sku=lld.sku)
left join PHYSICAL P on (P.status<>'9' and sxl.loc=P.loc and sxl.storerkey=P.storerkey and sxl.sku=P.sku)
left join #SKUbalance SB on (sxl.storerkey=SB.storerkey and sxl.sku=SB.sku)
where (SB.sku is null)						--����� �������, ������� ����������� � ������ ������� � ���������
and (P.sku is null)							--����� �������+�����, �� ������� ��� �� ����������� ������� ��������������
and (cast(getdate()-sxl.editdate as int)>@ZZ ) --����� ����� ������, �� ������� �� ���� �������� ����� @ZZ �����
and (sxl.qty=0 and lld.qty=0) --��� ������� �� ������ ������, ��� �� �� ���� �������� ��� ���������� �� ������� � ��������� �� ���������
--drop table #LOCtoCLEAR
--select * from #LOCtoCLEAR

begin transaction
print '3333333333333333333333333333333333333333333333333333333333333333333333333333'
print '������� ������ �� SKUXLOC'
delete from SKUxLOC 
from SKUxLOC sxl join #LOCtoCLEAR LC 
		on (sxl.loc=LC.loc and sxl.storerkey=LC.storerkey and sxl.sku=LC.sku)
where (sxl.qty=0) --��� ������� �� ������ ������, ��� �� �� ���� �������� ��� ���������� �� ������� � ��������� �� ���������
print '4444444444444444444444444444444444444444444444444444444444444444444444444444'
print '������� ������ �� LOTxLOCxID'
delete from LOTxLOCxID 
from LOTxLOCxID lld join #LOCtoCLEAR LC 
		on (lld.loc=LC.loc and lld.storerkey=LC.storerkey and lld.sku=LC.sku)
where (lld.qty=0) --��� ������� �� ������ ������, ��� �� �� ���� �������� ��� ���������� �� ������� � ��������� �� ���������
commit transaction

print '5555555555555555555555555555555555555555555555555555555555555555555555555555'
print '�������� ������ �� ������� ��������� �������� �������� ���������� ���������� �� ������� ���������� �� ��� ������'
print '������ � ������� ����� ����� ������ X ����������� �� ������������'
select sxl.loc, loc.cubiccapacity, cast(0 as float) skucount
into #selectedLocs
from SKUxLOC sxl join #LOCtoCLEAR LC on (sxl.loc=LC.loc)
				 join LOC on (LOC.loc=LC.LOC)
				 join SKU on (sxl.storerkey=SKU.storerkey and sxl.sku=SKU.sku)
where (sxl.allowreplenishfromcasepick=1 or sxl.allowreplenishfrombulk=1)
group by sxl.loc, loc.cubiccapacity
having max(sku.abc)<>'X'

print '6666666666666666666666666666666666666666666666666666666666666666666666666666'
print '...������������ � ��������� ������ ���������� ��� ���� ��������� �����'
DECLARE LOCATIONSLIST CURSOR STATIC FOR 
SELECT LOC FROM #selectedLocs

OPEN LOCATIONSLIST
FETCH NEXT FROM LOCATIONSLIST INTO @pLOC

WHILE @@FETCH_STATUS = 0
BEGIN
	exec WH1.novex_RecalcLoc @pLOC
	FETCH NEXT FROM LOCATIONSLIST INTO @pLOC
END

CLOSE LOCATIONSLIST
DEALLOCATE LOCATIONSLIST

