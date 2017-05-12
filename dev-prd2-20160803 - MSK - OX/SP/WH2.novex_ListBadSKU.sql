-- =============================================
-- �����:		������� �����
-- ������:		������, �.�������
-- ���� ��������: 12.11.2009 (������)
-- ��������: ������ ������� �� ������� ���������� ��������� ������ ������

-- =============================================
ALTER PROCEDURE [WH2].[novex_ListBadSKU] 
AS

--������ ����� ������, ��� � �� ���� ���������� �� ��������� ����
select * into #STORER from WH2.storer
select distinct lld.storerkey, lld.sku, s.cartongroup, cast(s.notes1 as varchar(255)) notes1 into #BALANCE
	from WH2.lotxlocxid lld join WH2.sku s on (lld.storerkey=s.storerkey and lld.sku=s.sku) where lld.qty>0

--�������� �� ��������� ��������, ��� ����� ������� ������. ������ � ������� ������ ����� ����������, ��� � �� ������ SQL ������
select st.company, s.storerkey, s.sku, s.cartongroup, s.notes1
from #BALANCE s join #STORER st on (s.storerkey=st.storerkey)
where WH2.novex_checkNeedSetPickLoc(s.storerkey,s.sku)>0
order by s.cartongroup, s.notes1

