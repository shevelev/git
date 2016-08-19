ALTER PROCEDURE [dbo].[proc_WaveReplenishmentPriority] (
@wh varchar(10),
@ordergroup varchar(20))
-- ��������� �������� ��������� ����� ���������� ��� ������� ��������� ���������� �� �����
-- 25/10/2009 ������� �����, ������, �������
as

declare @sql varchar(max)

--���������� ������ ������
select storerkey,sku, (openqty-qtyallocated-qtypicked) qty
into #SKUList
from wh1.orderdetail
where 1=2

select sxl.loc, sxl.storerkey, sxl.sku, sxl.qtylocationminimum, sxl.qtylocationlimit, cast(s.notes1 as varchar(250)) descr
into #pickneed
from wh1.skuxloc sxl join #SKUList L on (sxl.storerkey = L.storerkey and sxl.sku=L.sku)
join wh1.sku s on (sxl.storerkey = s.storerkey and sxl.sku=s.sku)
where 1=2

-- ������������ ������ �� ��������� ����������������� ������� �� �����
set @sql=
'insert into #SKUList
select od.storerkey,od.sku, sum(od.openqty-od.qtyallocated-od.qtypicked) qty
from '+@wh+'.orderdetail od join '+@wh+'.orders o on (o.orderkey=od.orderkey)
where ('''+@ordergroup+'''<>'''' and '''+@ordergroup+''' is not null and o.ordergroup='''+@ordergroup+''')
 and ((od.openqty-od.qtyallocated-od.qtypicked)>0)
group by od.storerkey,od.sku'
exec (@sql)

-- ������������ ������ ����� ��������� ���������� �� �����
set @sql=
'insert into #pickneed
select sxl.loc, sxl.storerkey, sxl.sku, sxl.qtylocationminimum, sxl.qtylocationlimit, cast(s.notes1 as varchar(250)) descr
from '+@wh+'.skuxloc sxl join #SKUList L on (sxl.storerkey = L.storerkey and sxl.sku=L.sku)
join '+@wh+'.sku s on (sxl.storerkey = s.storerkey and sxl.sku=s.sku)
where (sxl.replenishmentpriority<''5'' and (sxl.qty-sxl.qtyallocated-sxl.qtypicked)<L.qty)'
exec (@sql)

-- �������� ����� �������� ������ �� ������ �����
set @sql=
'update wh1.skuxloc
set replenishmentpriority=''3''
where replenishmentpriority=''2'''
exec (@sql)

-- ��������� ��� ��������� ����� �������� ���������� �� ������ ����������
set @sql=
'update sxl
set sxl.replenishmentpriority=''2''
from '+@wh+'.skuxloc sxl join #pickneed P on (sxl.loc=P.loc and sxl.storerkey = P.storerkey and sxl.sku=P.sku)'
exec (@sql)

set @sql=
'insert into #SKUList
select od.storerkey,od.sku, sum(od.openqty-od.qtyallocated-od.qtypicked) qty
from '+@wh+'.orderdetail od join '+@wh+'.orders o on (o.orderkey=od.orderkey)
where ('''+@ordergroup+'''<>'''' and '''+@ordergroup+''' is not null and o.ordergroup='''+@ordergroup+''')
 and ((od.openqty-od.qtyallocated-od.qtypicked)>0)
group by od.storerkey,od.sku'
exec (@sql)

-- ���������� ������ ������ ��� �����-�������, �� ������� ���� ������ ����� ����� �� ����������
set @sql=
'select distinct P.*
from #pickneed P join '+@wh+'.skuxloc sxl on (P.storerkey=sxl.storerkey and P.sku=sxl.sku)
				 join '+@wh+'.sku s on (P.storerkey=s.storerkey and P.sku=s.sku)
				 join '+@wh+'.pack pack on (pack.packkey=s.packkey)
where
(P.loc<>sxl.loc)
AND
( (sxl.locationtype=''CASE'' or sxl.locationtype=''OTHER'') 
  and 
  (sxl.qty-sxl.QTYALLOCATED-sxl.QTYPICKED)/pack.casecnt>=1
)'
exec (@sql)

/*
-- ���������� ������ ����� �� ������� �������� ��������� ����� ����������
select *
from #pickneed
order by loc
*/

