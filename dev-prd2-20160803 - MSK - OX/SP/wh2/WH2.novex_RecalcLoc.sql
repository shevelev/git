-- =============================================
-- �����:		������� �����
-- ������:		������, �.�������
-- ���� ��������: 27.10.2009 (������)
-- ��������: �������� ���������� ���������� ��� ��������� ������

-- =============================================
ALTER PROCEDURE [WH2].[novex_RecalcLoc]
			@loc varchar(10)
AS

print '�������� ������ �� ������� ��������� �������� �������� ���������� ����������'
print '������ � ������� ����� ����� ������ X ����������� �� ������������'
select sxl.loc, loc.cubiccapacity, cast(0 as float) skucount
into #selectedLocs
from SKUxLOC sxl join LOC on (sxl.loc=LOC.loc)
				 join SKU on (sxl.storerkey=SKU.storerkey and sxl.sku=SKU.sku)
where (sxl.allowreplenishfromcasepick=1 or sxl.allowreplenishfrombulk=1)
		AND
	 (sxl.loc=@loc and isnull(@loc,'')<>'')
group by sxl.loc, loc.cubiccapacity
having max(sku.abc)<>'X'
--select * from #selectedLocs

print '...������������ � ���������� ���������� �������, ������� ������ ������ ��������� ������� ������'
print '...��� ������ � ������ ������� ������� ��� 2, ��� ������ B � C ��� 1, ��� ������ D 0.5'
update #selectedLocs
set	SKUCOUNT=isnull((select sum(case when s.abc='A' then 2 when s.abc='D' then 0.5 else 1 end) 
					from WH2.skuxloc sxl join WH2.sku s on (sxl.storerkey=s.storerkey and sxl.sku=s.sku)
					where  sxl.loc=#selectedLocs.loc and
					((sxl.allowreplenishfromcasepick=1 or sxl.allowreplenishfrombulk=1))
				  ),0)
--select * from #selectedLocs
--drop table #selectedLocs

print '3333333333333333333333333333333333333333333333333333333333333333333333333333'
	print '...������������ � ��������� ������ ���������� ��� ���� ��������� �����'
	----- ��� ������� ��������� ��������� ��������� ����� ������ �� 2% ��� ������ �������������� �������
	----- �.�. � ������ � ����� ������� ��������� ����� - 98%, � ����� - 96%, � ����� 94% � �.�. //��. (1-(sc.skucount+...)*0.02)

	update sxl
	set
		sxl.qtylocationminimum=	--  20% �� ���������
					 1 + -- +1 ����� ��� ���������������� ������� ������� ������ ����������, ��� � ����� �� "0"
						CEILING(CEILING( ( (sl.cubiccapacity*( 1 -  case when (sl.skucount)*0.02<0.8 then (sl.skucount)*0.02
																		 else 0.2
																	end
										   ))--���� �������� ����� ������ ����������� � ������ ���������� �������� �������
										   / --���� � ������ ��� ��������� ����� 7-�� �������, �� ���������� ����� ������ ��������������� ������������ ������ 20% �� ����� ������
										   (sl.skucount)
										 )
										 * --���� �������� ����� ���������� �� ���� �������� �������������� ������� ������ � ������ ������
										 (case isnull(s.abc,'C') when 'A' then 2 when 'D' then 0.5 else 1 end) 
										 / --���� �������� ����� ���������� ��� ������ �������������� �������
										 (case when s.stdcube=0 then 0.0015 else s.stdcube end)
										 / --���� ��������� ������������ ���������� ���� ������
										 p.casecnt)	--������� �������; ��������� ����
								*p.casecnt*0.2), --����� ����� �� ������� ������������� � ����� � ����� 20%; ��������� �����
		sxl.qtylocationlimit=
						CEILING(CEILING( ( (sl.cubiccapacity*( 1 -  case when (sl.skucount)*0.02<0.8 then (sl.skucount)*0.02
																		 else 0.2
																	end
										   ))--���� �������� ����� ������ ����������� � ������ ���������� �������� �������
										   / --���� � ������ ��� ��������� ����� 7-�� �������, �� ���������� ����� ������ ��������������� ������������ ������ 20% �� ����� ������
										   (sl.skucount)
										 )
										 * --���� �������� ����� ���������� �� ���� �������� �������������� ������� ������ � ������ ������
										 (case isnull(s.abc,'C') when 'A' then 2 when 'D' then 0.5 else 1 end) 
										 / --���� �������� ����� ���������� ��� ������ �������������� �������
										 (case when s.stdcube=0 then 0.0015 else s.stdcube end)
										 / --���� ��������� ������������ ���������� ���� ������
										 p.casecnt)	--������� �������; ��������� ����
								*p.casecnt), --����� ����� �� ������� ������������� � �����; ��������� �����
		sxl.replenishmentcasecnt=p.casecnt,
		sxl.editwho='novex_SetPickLoc',
		sxl.editdate=getdate()
	from
		WH2.skuxloc sxl join #selectedLocs sl on (	sxl.loc=sl.loc )
						join WH2.sku s on (sxl.storerkey=s.storerkey and sxl.sku=s.sku)
						join WH2.pack p on (s.packkey=p.packkey)
	where sxl.allowreplenishfromcasepick=1 or sxl.allowreplenishfrombulk=1

	print '...������������ � ��������� ��������� ���������� ������ ���������� � ��������� ����������'
	update sxl
	set	sxl.replenishmentseverity=(sxl.qtylocationlimit-sxl.qty)/p.casecnt,
		sxl.REPLENISHMENTPRIORITY=case when sxl.qty<sxl.qtylocationminimum then '4' else '9' end
	from
		WH2.skuxloc sxl join #selectedLocs sl on (	sxl.loc=sl.loc )
						join WH2.sku s on (sxl.storerkey=s.storerkey and sxl.sku=s.sku)
						join WH2.pack p on (s.packkey=p.packkey)
	where (sxl.allowreplenishfromcasepick=1 or sxl.allowreplenishfrombulk=1) and (sxl.qty<sxl.qtylocationlimit)

