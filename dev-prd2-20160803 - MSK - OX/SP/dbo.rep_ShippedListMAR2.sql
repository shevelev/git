/****** Object:  StoredProcedure [dbo].[rep_ShippedListMAR]    Script Date: 03/24/2011 15:14:50 ******/
ALTER PROCEDURE [dbo].[rep_ShippedListMAR2] (
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



/* Вытаскиваем заказ+товар+партию+количество товара+упаковку */
select pd.orderkey, pd.caseid,pd.sku, pd.lot, sum(pd.qty) qty, lot.LOTTABLE01, p.casecnt
into #ya1
from wh1.loadhdr lh
join wh1.loadstop ls on lh.LOADID=ls.LOADID
join wh1.LOADORDERDETAIL lod on ls.LOADSTOPID=lod.LOADSTOPID
join wh1.pickdetail pd on pd.ORDERKEY=lod.SHIPMENTORDERID
join wh1.LOTATTRIBUTE lot on pd.LOT=lot.lot
join wh1.PACK p on lot.LOTTABLE01=p.packkey
where lh.ROUTE=@mar   and pd.status ='6' --and lh.STATUS!='9'
group by pd.orderkey, pd.caseid, pd.sku,pd.lot,lot.LOTTABLE01,casecnt

/* Сумируем количество коробок по заказам */
select orderkey,caseid,
sum(ceiling(case when casecnt=0 then qty/1 else qty/casecnt end)) as yashik
into #ya2
from #ya1
group by orderkey, caseid


/* Вытаскиваем данные по заказам для шапки */
select  lod.SHIPMENTORDERID,ord.EXTERNORDERKEY,lh.DEPARTURETIME,st.company,lh.door,lh.ROUTE,  st.ADDRESS1
into #spisokOT
from wh1.loadhdr lh
join wh1.loadstop ls on lh.LOADID=ls.LOADID
join wh1.LOADORDERDETAIL lod on ls.LOADSTOPID=lod.LOADSTOPID
left join wh1.pickdetail pd on pd.ORDERKEY=lod.SHIPMENTORDERID
left join wh1.DROPID dr on dr.DROPID=pd.dropid
join WH1.STORER AS st ON lod.CUSTOMER = st.STORERKEY
left join wh1.ORDERS ord on ord.ORDERKEY=lod.SHIPMENTORDERID
join wh1.ORDERSTATUSSETUP oss on ord.STATUS=oss.code
where lh.ROUTE=@mar  --and ord.status in ('68','92') --and lh.STATUS!='9' 
and  DEPARTURETIME between ''+ @date1+'' and ''+@date2+''

group by   lod.SHIPMENTORDERID,ord.EXTERNORDERKEY,lh.DEPARTURETIME,st.company,lh.door,lh.ROUTE,  st.ADDRESS1

/* считаем количество кэйсов в каждом заказе */
select distinct pd.CASEID, @ts ts,sot.*
into #spis1
from wh1.pickdetail pd
join #spisokOT sot on sot.SHIPMENTORDERID=pd.ORDERKEY
group by pd.caseid, sot.COMPANY, sot.DEPARTURETIME, sot.DOOR, sot.EXTERNORDERKEY,
 sot.ROUTE, sot.SHIPMENTORDERID,  sot.ADDRESS1
 
 /* добавляем ко всему количество коробок */
 select sp2.ADDRESS1,sp2.COMPANY,sp2.DEPARTURETIME,sp2.DOOR,sp2.EXTERNORDERKEY,sp2.ROUTE,sp2.SHIPMENTORDERID,sp2.caseid,sp2.ts,ya2.yashik 
 into #spis2
 from #spis1 sp2
 join #ya2 ya2 on sp2.SHIPMENTORDERID=ya2.ORDERKEY  and ya2.CASEID=sp2.CASEID
 
 
 /* выводим минимальный статус кэйсов */
 select min(pd.status) stC, pd.dropid, d.droploc, oss.DESCRIPTION,  sp.* 
 into #spis3
 from #spis2 sp
join wh1.pickdetail pd on pd.ORDERKEY=sp.SHIPMENTORDERID and pd.CASEID=sp.CASEID
join wh1.DROPID d on d.DROPID=pd.dropid
join wh1.ORDERS o on o.ORDERKEY=sp.SHIPMENTORDERID
join wh1.ORDERSTATUSSETUP oss on o.STATUS=oss.CODE
group by  pd.dropid, d.droploc,
sp.COMPANY, sp.DEPARTURETIME, sp.DOOR, sp.EXTERNORDERKEY,
 sp.ROUTE, sp.SHIPMENTORDERID,  sp.ADDRESS1, sp.yashik, sp.CASEID, oss.DESCRIPTION,sp.ts
 
 /* выводим всю инфу */
select ck.DESCRIPTION descC,sp3.*, dbo.getean128(sp3.ts)bcts 
 from #spis3 sp3
join wh1.CODELKUP ck on sp3.stC=ck.CODE and LISTNAME='ordrstatus'


drop table #ya1
drop table #ya2
drop table #spis1
drop table #spisokOT
drop table #spis2
drop table #spis3
 

