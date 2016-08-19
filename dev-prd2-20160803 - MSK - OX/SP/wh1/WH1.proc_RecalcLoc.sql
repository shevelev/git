-- =============================================
-- �����:		������� �����
-- ������:		������, �.�������
-- ���� ��������: 27.10.2009 (������)
-- ��������: ��������/�������� ���������� ���������� ��� ��������� ������
-- =============================================
ALTER PROCEDURE [WH1].[proc_RecalcLoc]
			@loc			varchar(10),
			@flag			int=0, --0- ��������, 1- ��������, -1 - ������� � �����������
			@storerkey		as varchar(15)='',
			@sku			as varchar(60)=''

AS

if (isnull(@loc,'')<>'' and @flag=-1 and isnull(@storerkey,'')<>'' and isnull(@sku,'')<>'')
begin
	--�������� ���������� ������ �� ������ ������
	exec WH1.novex_ClearSKUPickLoc @loc,@storerkey,@sku
end

if (isnull(@loc,'')<>'' and (@flag=1 or @flag=-1))
begin
	--�������� ���������� ���������� 
	exec WH1.novex_RecalcLoc @loc
end

print '���������� ������ ������� ����������� ��� ������ ������'
select	sxl.loc,
		sxl.storerkey,
		st.company,
		sxl.sku,
		cast(s.notes1 as varchar(255)) notes1,
		s.abc,
		sxl.qtylocationminimum,
		sxl.qtylocationlimit,
		(sxl.qtylocationminimum*s.stdcube) minSKUcube,
		(sxl.qtylocationlimit*s.stdcube) maxSKUcube,
		l.cubiccapacity,
		sxl.qty,
		(sxl.qty-sxl.QTYALLOCATED-sxl.QTYPICKED) freeQTY
from wh1.skuxloc sxl
join wh1.storer st on (sxl.storerkey=st.storerkey)
join wh1.sku s on (sxl.storerkey=s.storerkey and sxl.sku=s.sku)
join wh1.loc l on (sxl.loc=l.loc)
where
(sxl.allowreplenishfromcasepick=1 or sxl.allowreplenishfrombulk=1)
		AND
	 (sxl.loc=@loc and isnull(@loc,'')<>'')

