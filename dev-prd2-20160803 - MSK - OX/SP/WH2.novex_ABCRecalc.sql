-- =============================================
-- �����:		������� �����
-- ������:		������, �.�������
-- ���� ��������: 20.11.2009 (������)
-- ��������: �������� ������ ��������������� ������
--	������ ��������� ������������ �������� ������ ��������������� ������ � �������� ������ ������ !
--	�.�. ��� �� ��������������� ������ � ����� �� ������ !!! ��� ��������������� ������ � ������ ������ !
--	������ � ��������, ��� � ��������� ������ ������ ����� ����������� � ������� �����������. ������ D - ��������.
--  ���� QTYLOCATIONMINIMUM ������ ��� ������ ������ ������ �� ������, �� ������ ��������������� ������ �������������.
--	���� QTYLOCATIONMINIMUM ������ ��� ������ ������ ������ �� ������, �� ������ ��������������� ������ �����������.
--  ������������� ������ ��������������� �������� ������ � �������� A->B->C->D � ������� A<-B<-C<-D
--  ��������� ������ X �������������� ������ ������� ����� ��������� INFOR
--  ������ ������ ��������������� X ����������� �� ���������. X- ��� ������, ��� ������� ��������� ����� ������ ������������ �������.
-- =============================================
ALTER PROCEDURE [WH2].[novex_ABCRecalc] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--##############################################################################
--�������� ������ � �������� �� ������. ��������� ������ X
select s.storerkey, s.sku, isnull(s.abc,'C') abc
into #balance
from WH2.lotxlocxid lld
join WH2.sku s on (s.storerkey=lld.storerkey and s.sku=lld.sku)
where isnull(s.abc,'C')<>'X' and lld.qty>0
group by s.storerkey, s.sku, isnull(s.abc,'C')
--drop table #balance

--������� ����� ������ �� ��������� ������ (���������� ���������� ������)
select pd.storerkey,pd.sku,sum(pd.qty) shipQTY
into #ship
from WH2.pickdetail pd join #balance B on (pd.storerkey=B.storerkey and pd.sku=B.sku)
where pd.status='9' and (pd.editdate between getdate()-7 and getdate())
group by pd.storerkey,pd.sku

--���������� ��������� ����� ������
select sxl.storerkey,sxl.sku,max(sxl.qtylocationminimum) minQTY,max(sxl.qtylocationlimit) maxQTY
into #minmax
from WH2.skuxloc sxl join #balance B on (sxl.storerkey=B.storerkey and sxl.sku=B.sku)
where 
(sxl.qtylocationminimum>0 and sxl.qtylocationlimit>0 and sxl.allowreplenishfromcasepick=1)
group by sxl.storerkey,sxl.sku

--�������� ������ �� ������� ����� ��������� ������ ���������������
select B.storerkey,B.sku,M.minQTY,S.shipQTY, B.ABC oldABC,
	--���� ��� ������ A,B ��� �, �� ������� ������
	case when B.abc<>'X' and B.abc<>'D' then char(ascii(left(B.abc,1))+1) else B.abc end newABC
into #SKUdown
from #balance B
join #minmax M on (M.storerkey=B.storerkey and M.sku=B.sku)
join #ship S on (S.storerkey=B.storerkey and S.sku=B.sku)
where
M.minQTY>S.shipQTY*1.5 --����������� ������� � ������ ������ ������ ��� ������� �� ������ � ������� 1.5

--�������� ������ �� ������� ����� ��������� ������ ���������������
select B.storerkey,B.sku,M.minQTY,S.shipQTY, B.ABC oldABC,
	--���� ��� ������ B, C ��� D, �� �������� ������
	case when B.abc<>'X' and B.abc<>'A' then char(ascii(left(B.abc,1))-1) else B.abc end newABC
into #SKUup
from #balance B
join #minmax M on (M.storerkey=B.storerkey and M.sku=B.sku)
join #ship S on (S.storerkey=B.storerkey and S.sku=B.sku)
where
M.minQTY*1.5<S.shipQTY --����������� ������� � ������ ������ ������ ��� ������� �� ������ � ������� 1.5

--��������. ���� ������������ ������ ������ ���� ������
--select S.*
--from #SKUdown S join #SKUup S1 on (S.storerkey=S1.storerkey and S.sku=S1.sku)

--��������� �������� �������
update sku
set sku.abc=UP.newABC
from WH2.sku sku join #SKUup UP on (Sku.storerkey=UP.storerkey and Sku.sku=UP.sku)

update sku
set sku.abc=DOWN.newABC
from WH2.sku sku join #SKUdown DOWN on (Sku.storerkey=DOWN.storerkey and Sku.sku=DOWN.sku)

END

