ALTER PROCEDURE [dbo].[proc_SelectOrderForASN] (
@orderkey varchar(20) = '', -- íîìåğ äîêóìåíòà
@externorderkey varchar(20)='', -- âíåøíèé íîìåğ äîêóìåíòà
@fiocarriercode varchar (100) = '', -- ôèî ıêñïåäèòîğà
@datemin datetime = null, -- äàòà íà÷àëà ïåğèîäà
@datemax datetime = null-- äàòà êîíöà ïåğèîäà
)
as  
--############################################ ÑÎÇÄÀÍÈÅ ÇÀÊÀÇÀ ÍÀ ÏĞÈÅÌÊÓ ÍÀ ÎÑÍÎÂÀÍÈÈ ÇÀÊÀÇÀ ÍÀ ÎÒÃĞÓÇÊÓ

if @datemin is null set @datemin = '01/01/1900 00:00:00'--getdate () - 1000
if @datemax is null set @datemax = getdate ()

--select @datemin,@datemax
--select * from wh1.orders where o.
--



select l.loadid, lod.shipmentorderid, 
isnull(oc.externorderkey,o.externorderkey) externorderkey,
o.requestedshipdate, s.companyname
from wh1.loadhdr l join wh1.storer s on l.externalid = s.storerkey
join wh1.loadstop ls on ls.loadid = l.loadid
join wh1.loadorderdetail lod on lod.loadstopid = ls.loadstopid
join wh1.orders o on o.orderkey = lod.shipmentorderid
left join wh1.orders_c oc on o.orderkey = oc.orderkey
where s.companyname like '%'+@fiocarriercode+'%' and o.orderkey like '%'+@orderkey+'%' 
  and isnull(oc.externorderkey,o.externorderkey) like '%'+@externorderkey+'%'
and o.status >= '92'
and o.requestedshipdate >= @datemin
and o.requestedshipdate <= @datemax

--select top (1) externorderkey from wh1.orders where orderkey = @orderkey

