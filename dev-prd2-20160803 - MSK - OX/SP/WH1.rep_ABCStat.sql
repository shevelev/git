-- =============================================
-- �����:		������� �����
-- ������:		������, �.�������
-- ���� ��������: 20.11.2009 (������)
-- ��������: ���������� ��� ������ �������� ���������� ����� ������
--	��� �� ��������������� ������ � ����� �� ������ !!! ��� ��������������� ������ � ������ ������ !
--	������ � ��������, ��� � ��������� ������ ������ ����� ����������� � ������� �����������. ������ D - ��������.
--  ���� QTYLOCATIONMINIMUM ������ ��� ������ ������ ������ �� ������, �� ������ ��������������� ������ �������������.
--	���� QTYLOCATIONMINIMUM ������ ��� ������ ������ ������ �� ������, �� ������ ��������������� ������ �����������.
--  ������������� ������ ��������������� �������� ������ � �������� A->B->C->D � ������� ������ �� A<-B<-C<-D
--  ��������� ������ X �������������� ������ ������� ����� ��������� INFOR
-- =============================================
ALTER PROCEDURE [WH1].[rep_ABCStat] 
	@ABCfilter varchar(20)='', --�������� �����, ������� ����� ����������
	@street	as varchar(20)=''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--##############################################################################
print '>>> [WH1].[rep_ABCStat] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
declare @fx int, @fa int, @fb int, @fc int, @fd int, @totalNeedRPCount int

select	@fx=charindex('X',isnull(@ABCfilter,'')),
		@fa=charindex('A',isnull(@ABCfilter,'')),
		@fb=charindex('B',isnull(@ABCfilter,'')),
		@fc=charindex('C',isnull(@ABCfilter,'')),
		@fd=charindex('D',isnull(@ABCfilter,''))

print '--�������� ������ � �������� �� ������. ��������� ������ �� ������� � ������ �� ��������'
select s.storerkey, s.sku, min(cast(s.notes1 as varchar(255))) notes1, min(isnull(s.abc,'C')) abc,
		min(s.busr1) busr1, min(s.busr2) busr2, min(s.busr3) busr3, min(s.cartongroup) cartongroup
into #balance
from wh1.lotxlocxid lld
join wh1.sku s on (s.storerkey=lld.storerkey and s.sku=lld.sku)
where lld.qty>0
AND
( isnull(@ABCfilter,'')=''
  OR
  (	(@fx>0 and isnull(s.abc,'C')='X') or
	(@fa>0 and isnull(s.abc,'C')='A') or
	(@fb>0 and isnull(s.abc,'C')='B') or
	(@fc>0 and isnull(s.abc,'C')='C') or
	(@fd>0 and isnull(s.abc,'C')='D')
  )
)
AND
(isnull(@street,'')='' or isnull(@street,'')=s.cartongroup)
group by s.storerkey, s.sku
--drop table #balance


print '--������� ����� ������ �� ��������� ������ (���������� ���������� ������)'
print '--...�������� ������ ��� ���������'
select td.storerkey,td.sku,td.fromloc loc,td.qty
into #shipRecords
from wh1.taskdetail td
where td.status='9' and tasktype='PK' and (td.editdate between (getdate()-7) and getdate())

print '--...������� ����� �� ������. ��������� ������ �� ������� � ���������'
select	SR.storerkey,SR.sku,
		sum(case when l.locationtype='PICK' then SR.qty else 0 end) pickQTY,	--������ �� ���� ������
		sum(case when l.locationtype<>'PICK' then SR.qty else 0 end) otherQTY,	--������ �� ��������
		sum(SR.qty) totalQTY
into #ship
from #shipRecords SR
	join wh1.loc l on (SR.loc=l.loc)
	join #balance B on (SR.storerkey=B.storerkey and SR.sku=B.sku)
group by SR.storerkey,SR.sku

print '--���������� ��������� ����� ������'
select sxl.storerkey,sxl.sku,sxl.loc,max(sxl.qtylocationminimum) minQTY,max(sxl.qtylocationlimit) maxQTY
into #minmax
from wh1.skuxloc sxl join #balance B on (sxl.storerkey=B.storerkey and sxl.sku=B.sku)
where 
(sxl.qtylocationminimum>0 and sxl.qtylocationlimit>0 and sxl.allowreplenishfromcasepick=1)
group by sxl.storerkey,sxl.sku,sxl.loc

print '--������� ���������� ����� ������ �� �����'
select storerkey,sku,count(loc) locCount
into #locCount
from #minmax
group by storerkey,sku

print '--������� ���������� ������� � ������ ������'
select loc,count(sku) skuCount
into #skuCount
from #minmax
group by loc

print '--��������� ������ ��� ������'
select	st.company, B.sku, B.notes1, B.abc, B.busr1, B.busr2, B.busr3, B.cartongroup, 
		M.loc, M.minQTY, M.maxQTY, SC.skuCount, LC.locCount,
		isnull(S.pickQTY,0) pickQTY,
		isnull(S.otherQTY,0) otherQTY,
		isnull(S.totalQTY,0) shipQTY,
		case when isnull(S.pickQTY,0)=0 then 999 else floor(M.minQTY/S.pickQTY*6*LC.locCount) end minDay,
		case when isnull(S.pickQTY,0)=0 then 999 else floor(M.maxQTY/S.pickQTY*6*LC.locCount) end maxDay
into #result
from #balance B
join #minmax M on (M.storerkey=B.storerkey and M.sku=B.sku)
join #locCount LC on (LC.storerkey=B.storerkey and LC.sku=B.sku)
join #skuCount SC on (SC.loc=M.loc)
left join #ship S on (S.storerkey=B.storerkey and S.sku=B.sku)
join wh1.storer st on (st.storerkey=B.storerkey)
order by B.cartongroup, B.notes1, B.storerkey

print '--����������� ��������� ���������� ���������� � ����'
select maxDay, case when maxDay>1 then count(sku)/maxDay else count(sku) end RPperDay
into #result2
from #result
group by maxDay

print '--����������� ��������� ���������� ���������� � ����'
select @totalNeedRPCount=sum(RPperDay) from #result2

print '--���������� ������ ��� ������'
select R.*,R2.RPperDay, @totalNeedRPCount totalNeedRPCount
from #result R join #result2 R2 on (R.maxDay=R2.maxDay)

END

