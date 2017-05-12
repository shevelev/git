ALTER PROCEDURE [dbo].[rep55_Shiplist] (
	@key varchar(12)
)AS

declare @sql varchar(max)

print 1
select st1.company s1c, st2.company s2c, sum(s.STDGROSSWGT*od.SHIPPEDQTY) ves, sum(s.STDCUBE*od.SHIPPEDQTY) obem, o.orderkey, o.EXTERNORDERKEY, lh.route, lh.DEPARTURETIME, lh.loadid, lh.door
into #ordersList 
from wh1.orders o
left join wh1.LOADHDR lh on o.LOADID=lh.LOADID 
join wh1.LOADstop ls on ls.LOADID = lh.LOADID
join wh1.LOADORDERDETAIL lod on lod.LOADSTOPID=ls.LOADSTOPID
join wh1.orderdetail od on o.orderkey=od.orderkey 
join wh1.sku s on s.SKU = od.sku
join wh1.storer st1 on st1.STORERKEY=left(LOD.CUSTOMER,case when charindex('_',LOD.CUSTOMER) = 0 then len(LOD.CUSTOMER) else charindex('_',LOD.CUSTOMER)-1 end)
join wh1.storer st2 on st2.STORERKEY=lod.storer
where o.LOADID = @key
group by o.orderkey, o.EXTERNORDERKEY, lh.route, lh.DEPARTURETIME, lh.loadid, lh.door, st1.COMPANY, st2.COMPANY

print 2
select ORDERKEY, DROPID, LOC into #plist from WH1.PICKDETAIL where 1=2
insert into #plist select  ORDERKEY, DROPID, LOC from wh1.PICKDETAIL where ORDERKEY in (select orderkey from #ordersList) group by ORDERKEY, DROPID, LOC


select pl.DROPID, pl.LOC, pl.ORDERKEY, ol.DEPARTURETIME, ol.EXTERNORDERKEY, ol.ROUTE, ol.door, ves, obem, s1c, s2c from #plist pl
join #ordersList ol on ol.ORDERKEY=pl.orderkey

drop table #ordersList
drop table #plist


