CREATE proc [dbo].[rep_OrdersStatusChange] (@changeStatus int,
	@newStatus varchar(2),
	@orderkey1 varchar(10),
	@orderkey2 varchar(10),
	@orderkey varchar(10)
)AS

--declare 
--	@changeStatus int,
--	@newStatus varchar(2),
--	@orderkey1 varchar(10),
--	@orderkey2 varchar(10),
--	@orderkey varchar(10)
--select @changeStatus = 0, @orderkey1='',@orderkey2='0000001000', @newStatus='95', @orderkey=null

 if @changeStatus = 1 
 begin
	update wh40.orders set status = @newStatus where orderkey =@orderkey
 end


select * into #orders from wh40.orders where status < 95 --and rfidflag=1 and ohtype=2
	and (isnull(@orderkey1,'')=''  or externorderkey >= @orderkey1)
	and (isnull(@orderkey2,'')=''  or externorderkey <= @orderkey2)
	
select * into #ordDetail from wh40.orderdetail where orderkey in (select orderkey from #orders)

select * into #pickdetail from wh40.pickdetail where orderkey in (select orderkey from #orders)

select orderkey, sku, storerkey, orderlinenumber, sum(qty)qty, status
into #pickSum
from #pickdetail 
group by orderkey, sku, storerkey, orderlinenumber, status
--
--drop table #pickSum

select od.orderkey,  o.externorderkey, od.sku, od.storerkey, od.orderlinenumber, od.openqty+od.shippedqty expqty, 
	qty, ps.status, rfidflag, ohtype, od.status posStatus, o.status ordStatus, o.split_orders
into #result
from #ordDetail od
left join #pickSum ps on ps.orderkey=od.orderkey and ps.orderlinenumber=od.orderlinenumber
join  #orders o on o.orderkey=od.orderkey


select r.*, oss.Description posStatusDescr, s.descr, oss2.description ordStatusDescr
from #result r
	join wh40.sku s on r.sku=s.sku and r.storerkey = s.storerkey
	join wh40.orderstatussetup oss on r.posstatus = oss.code
	join wh40.orderstatussetup oss2 on r.ordstatus = oss2.code
 order by externorderkey
 
 
 drop table #result
drop table #ordDetail
drop table #orders
drop table #pickSum
drop table #pickdetail

