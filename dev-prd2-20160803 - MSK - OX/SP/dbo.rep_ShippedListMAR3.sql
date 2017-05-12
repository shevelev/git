/* Погрузочный лист */
ALTER PROCEDURE [dbo].[rep_ShippedListMAR3] (
	@dat1 datetime,
	@dat2 datetime,
	@mar varchar(12)
)
AS

/* Переменная для машины */
declare @ts varchar(15)
exec dbo.DA_GetNewKey 'wh1','TS',@ts output
set @ts='TS'+right(@ts,8)

declare @date1 varchar(10),
@date2 varchar(10)
	
	set @date1 = convert(varchar(10),@dat1,112)
	set @date2 = convert(varchar(10),dateadd(dy,1,@dat2),112)
	declare @tmp varchar(10)
	if @date2 < @date1 
	begin
		select @tmp = @date2, @date2 = @date1
		select @date1 = @tmp
	end


select lod.SHIPMENTORDERID, pd.status,lh.DEPARTURETIME
into #t1
from wh1.loadhdr lh
join wh1.loadstop ls on lh.LOADID=ls.LOADID
join wh1.LOADORDERDETAIL lod on ls.LOADSTOPID=lod.LOADSTOPID
join wh1.PICKDETAIL pd on pd.ORDERKEY=lod.SHIPMENTORDERID
where lh.ROUTE=@mar and  lh.DEPARTURETIME between ''+ @date1+'' and ''+@date2+''
group by lod.SHIPMENTORDERID, pd.status, lh.DEPARTURETIME
order by lod.SHIPMENTORDERID asc


select distinct SHIPMENTORDERID into #t2 from #t1
where STATUS!=6

delete from t1 from #t1 t1 join #t2 t2 on t1.SHIPMENTORDERID=t2.SHIPMENTORDERID


select pd.caseid, sum(ceiling(case when p.casecnt=0 then pd.qty/1 else pd.qty/p.casecnt end)) yashik, pc.BOXNUM
into #t3
from wh1.PICKDETAIL pd
join wh1.LOTATTRIBUTE lot on pd.LOT=lot.lot
join wh1.PACK p on lot.LOTTABLE01=p.packkey
left join wh1.PICKCONTROL pc on pc.CASEID=pd.caseid
join wh1.ORDERS o on pd.orderkey=o.orderkey
where pd.ROUTE=@mar and pd.status ='6' 
and  o.adddate between ''+ @date1+'' and ''+@date2+''
group by pd.caseid, pc.BOXNUM
order by pd.caseid




/* Вытаскиваем данные по заказам для шапки */
select @ts ts,dbo.getean128(@ts)bcts,pd.orderkey, oss.DESCRIPTION descOrder, o.EXTERNORDERKEY ,pd.caseid, ck.DESCRIPTION descCase, 
pd.dropid, d.droploc, pd.ROUTE, s.COMPANY, s.ADDRESS1, t1.DEPARTURETIME,
CASE when isnull(t3.BOXNUM,'')='' then t3.yashik else t3.BOXNUM end as tt
from #t1 t1
join wh1.pickdetail pd on t1.SHIPMENTORDERID=pd.ORDERKEY
join wh1.DROPID d on d.DROPID=pd.dropid
join wh1.CODELKUP ck on pd.STATUS=ck.CODE and LISTNAME='ordrstatus'
join wh1.ORDERS o on pd.orderkey=o.orderkey
join wh1.ORDERSTATUSSETUP oss on o.STATUS=oss.CODE
join wh1.storer s on o.B_COMPANY=s.storerkey
join #t3 t3 on t3.CASEID=pd.CASEID
where pd.ROUTE=@mar and pd.status ='6' 
and  o.adddate between ''+ @date1+'' and ''+@date2+''
group by pd.orderkey, oss.DESCRIPTION, o.EXTERNORDERKEY ,pd.caseid, ck.DESCRIPTION, 
pd.dropid, d.droploc, pd.ROUTE, s.COMPANY, s.ADDRESS1, t1.DEPARTURETIME, t3.yashik, t3.BOXNUM


drop table #t1
drop table #t2
drop table #t3


