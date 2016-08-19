ALTER PROCEDURE [dbo].[proc_NotAllocatedSKU] (
@wh varchar(10),
@ordergroup varchar(20))
-- Процедура выводит список товаров, которые не зарезервировались по Волне и на которые нет задач пополнения
-- 12/11/2009 Смехнов Антон, НОВЭКС, Барнаул
as

declare @sql varchar(max)

--подготовка пустых таблиц
select storerkey,sku, (openqty-qtyallocated-qtypicked) qty
into #SKUList
from wh1.orderdetail
where 1=2

select sxl.loc, sxl.storerkey, sxl.sku, sxl.qtylocationminimum, sxl.qtylocationlimit, sxl.qty, (sxl.qty-sxl.qtyallocated-sxl.qtypicked) freeQTY,s.notes1 descr
into #pickneed
from wh1.skuxloc sxl join #SKUList L on (sxl.storerkey = L.storerkey and sxl.sku=L.sku)
join wh1.sku s on (sxl.storerkey = s.storerkey and sxl.sku=s.sku)
where 1=2

-- формирование списка не полностью зарезервированных товаров по Волне
set @sql=
'insert into #SKUList
select distinct od.storerkey,od.sku, sum(od.openqty-od.qtyallocated-od.qtypicked) qty
from '+@wh+'.orderdetail od join '+@wh+'.orders o on (o.orderkey=od.orderkey)
where ('''+@ordergroup+'''<>'''' and '''+@ordergroup+''' is not null and o.ordergroup='''+@ordergroup+''')
 and ((od.openqty-od.qtyallocated-od.qtypicked)>0)
group by od.storerkey,od.sku'
exec (@sql)

-- формирование списка ячеек по которым не назначилось пополнение, хотя товар не зарезервировался
set @sql=
'insert into #pickneed
select sxl.loc, sxl.storerkey, sxl.sku, sxl.qtylocationminimum, sxl.qtylocationlimit, sxl.qty, (sxl.qty-sxl.qtyallocated-sxl.qtypicked) freeQTY,s.notes1 descr
from '+@wh+'.skuxloc sxl join #SKUList L on (sxl.storerkey = L.storerkey and sxl.sku=L.sku)
join '+@wh+'.sku s on (sxl.storerkey = s.storerkey and sxl.sku=s.sku)
where
(sxl.qtylocationminimum>0 and sxl.qtylocationlimit>0 and sxl.ALLOWREPLENISHFROMCASEPICK=1) 
AND
(sxl.replenishmentpriority>''4'' and (sxl.qty-sxl.qtyallocated-sxl.qtypicked)<L.qty)'
exec (@sql)

-- возвращаем список ячеек по котором поменяли приоритет задач пополнения
select *
from #pickneed
order by loc

