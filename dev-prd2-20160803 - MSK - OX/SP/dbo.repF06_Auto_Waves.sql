-- =============================================
-- Автор:		Тын Максим
-- Проект:		ЛЦ, г.Барнаул
-- Дата создания: 12.05.2010 (ЛЦ)
-- Описание: Отчет о перевозимых объемах товаров "Транс-Авто"
-- =============================================


ALTER PROCEDURE [dbo].[repF06_Auto_Waves] ( 
	@dateBegin varchar(25),
	@dateEnd varchar(25)
)
as

	declare @dtBegin as datetime
			,@dtEnd as datetime
			,@ds as varchar(25)

set @dtBegin=convert(datetime,@dateBegin,21)
set @dtEnd=dateadd(s,-1,(dateadd(d, 1, convert(datetime,@dateEnd,21))))
set @ds=convert(varchar(25),@dtEnd,21)

print @ds

----*****************
---- общий запрос за период объемы по документам
----*****************
--select datepart(yyyy,o.deliverydate2) yyyy,
--		datepart(mm,o.deliverydate2) mm,
--		datepart(dd,o.deliverydate2) dd,
--	o.ordergroup wavekey, o.storerkey, o.consigneekey,
--	o.carriercode, o.carriername, o.drivername, o.trailernumber,
--	sum(ord.shippedqty*sk.STDGROSSWGT) shippedQty, sum(ord.shippedqty*sk.stdcube) cubeQty 
--into #tmp 
--from wh1.orders o 
--	join wh1.orderdetail ord on ord.orderkey=o.orderkey
--	join wh1.sku sk on sk.sku=ord.sku and sk.storerkey=ord.storerkey
--where o.storerkey<>'000000001' and o.status >=92 
--	and (o.carriername not like '%амовывоз%' and o.carriername not like '%Юнилеве%')
--	and o.deliverydate2 between @dtBegin and @dtEnd
--group by o.ordergroup, o.storerkey, o.consigneekey,
--	o.carriercode, o.carriername, o.drivername, o.trailernumber,
--	datepart(yyyy,o.deliverydate2),
--		datepart(mm,o.deliverydate2),
--		datepart(dd,o.deliverydate2)
--
--order by 
--		datepart(yyyy,o.deliverydate2),
--		datepart(mm,o.deliverydate2),
--		datepart(dd,o.deliverydate2),
--		o.ordergroup, o.storerkey
--
----*******************
---- Общий запрос за период по транзиту
----*******************
--
--select datepart(yyyy,tr.deliverydate) yyyy,
--		datepart(mm,tr.deliverydate) mm,
--		datepart(dd,tr.deliverydate) dd,
--		sum(tr.qty), sum(tr.weight), sum(tr.cube), st.company
--into #Tranzit
--from WH1.TRANSSHIP tr
--	join wh1.transdetail trd on trd.transshipkey=tr.transshipkey and trd.sku='TRANZIT'
--	join wh1.storer st on st.storerkey=tr.customerkey
--where tr.status=9 
--	and tr.customerkey<>'SM3499' 
--	and and tr.deliverydate between @dtBegin and @dtEnd
--group by datepart(yyyy,tr.deliverydate),
--		datepart(mm,tr.deliverydate),
--		datepart(dd,tr.deliverydate),
--		st.company

--*******************
-- Общий запрос за период по транзиту
--*******************

select 0 as idkey,
		datepart(yyyy,tr.deliverydate) yyyy,
		datepart(wk,tr.deliverydate) wk,
--		datepart(ww,tr.deliverydate) ww,
--		datepart(mm,tr.deliverydate) mm,
--		datepart(dd,tr.deliverydate) dd,
		tr.customerkey, st.company,
		sum(tr.qty) qty, sum(tr.weight) weight, sum(tr.cube) qcube
into #Tranzit
from WH1.TRANSSHIP tr
	join wh1.transdetail trd on trd.transshipkey=tr.transshipkey and trd.sku='TRANZIT'
	join wh1.storer st on st.storerkey=tr.customerkey
where tr.status=9 
	and tr.customerkey<>'SM3499' 
	and tr.deliverydate between @dtBegin and @dtEnd
group by 
		
		datepart(yyyy,tr.deliverydate),
		datepart(wk,tr.deliverydate),
--		datepart(ww,tr.deliverydate),
--		datepart(mm,tr.deliverydate),
--		datepart(dd,tr.deliverydate),
		st.company, tr.customerkey
order by 
		datepart(yyyy,tr.deliverydate),
		datepart(wk,tr.deliverydate),
		st.company, tr.customerkey

--select * 
--from #tranzit
----group by yyyy, wk, customerkey having count(*)>1
--order by yyyy, wk

--*****************
-- общий запрос за период объемы по документам
--*****************

create table #tmp(
	idKey int
	, yyyy int
	, wk int
	, mm int
	, dd int
	, wavekey varchar(20)
	, storerkey varchar(15)
	, consigneekey varchar(15)
	, carriercode varchar(15)
	, carriername varchar(45)
	, drivername varchar(45)
	, trailernumber varchar(18)
	, shippedQty float
	, cubeQty float
	, trweight float
	, trqcube float
	, constraint PK_#tmp primary key (idKey)
	)

insert into #tmp 
	select row_number() over(order by
		datepart(yyyy,o.deliverydate2),
		datepart(mm,o.deliverydate2),
		datepart(dd,o.deliverydate2),
		o.ordergroup, o.storerkey
		) as idKey,
		datepart(yyyy,o.deliverydate2) yyyy,		
		datepart(wk,o.deliverydate2) wk,
		datepart(mm,o.deliverydate2) mm,
		datepart(dd,o.deliverydate2) dd,
	o.ordergroup wavekey, o.storerkey, o.consigneekey,
	o.carriercode, o.carriername, o.drivername, o.trailernumber,
	sum(ord.shippedqty*sk.STDGROSSWGT) shippedQty, sum(ord.shippedqty*sk.stdcube) cubeQty
	,cast(0 as float) trweight, cast(0 as float) trqcube 

from wh1.orders o 
	join wh1.orderdetail ord on ord.orderkey=o.orderkey
	join wh1.sku sk on sk.sku=ord.sku and sk.storerkey=ord.storerkey
--	
where o.storerkey<>'000000001' and o.status >=92 
	and (o.carriername not like '%амовывоз%' and o.carriername not like '%Юнилеве%')
	and o.deliverydate2 between @dtBegin and @dtEnd
group by o.ordergroup, o.storerkey, o.consigneekey,
	o.carriercode, o.carriername, o.drivername, o.trailernumber,
	datepart(yyyy,o.deliverydate2),
		datepart(wk,o.deliverydate2),
		datepart(mm,o.deliverydate2),
		datepart(dd,o.deliverydate2)

order by 
		datepart(yyyy,o.deliverydate2),
		datepart(mm,o.deliverydate2),
		datepart(dd,o.deliverydate2),
		o.ordergroup, o.storerkey

select min(idkey) idkey, yyyy , wk  , consigneekey
--	select min(idkey)
into #tmpKey
	from #tmp
	where storerkey='219'
	group by yyyy , wk, consigneekey having count(*)>1

insert into #tmpkey
select min(idkey), yyyy , wk  , consigneekey
from #tmp
	where storerkey='219'
	group by yyyy , wk, consigneekey having count(*)=1

--select *
--from #tmpkey

update #tranzit
	set idkey=tk.idkey
from #tranzit tmp
	join #tmpkey tk on tk.yyyy=tmp.yyyy and tk.wk=tmp.wk and 
			tk.consigneekey=tmp.customerkey 


--select *
--from #tranzit
--order by idkey

--select *
--from #tmp tmp
--	left join #tranzit tr on tr.idkey=tmp.idkey
--order by tmp.idkey

--create table #out(
--	yyyy int,
--	wk int,
--	storerkey varchar(15),
--	consigneekey varchar(15)
--	);

update #tmp 
	set trweight=isnull(tr.weight,cast(0 as float)), trqcube=isnull(tr.qcube ,cast(0 as float))
--	output 
--		INSERTED.yyyy,
--		INSERTED.wk,
--		INSERTED.storerkey,
--		INSERTED.consigneekey		
--	into #out
	from #tmp tmp
		left join #tranzit tr on tr.idkey=tmp.idkey

--select *
----wk, storerkey, consigneekey, count(consigneekey) cn
--from #tmp 
--group by wk, storerkey, consigneekey
--order by dd


drop table #tmpKey
drop table #tranzit

--*******************
-- сворачиваем волны и машины
--*******************

select --t.idkey, 
	t.yyyy, t.mm, t.dd, 
	t.wavekey, 
	t.carriercode, t.carriername, t.drivername, t.trailernumber,
	sum(t.shippedQty) shippedQty, sum(t.cubeQty) cubeQty, sum(t.trweight) trweight, sum(t.trqcube) trqcube
into #tmp1
from #tmp t
group by --t.idkey, 
	t.yyyy, t.mm, t.dd,
	t.wavekey, 
	t.carriercode, t.carriername, t.drivername, t.trailernumber

--***********
-- разделяем объемы Опта и Новэкса
--***********

select t1.yyyy, t1.mm, t1.dd,
	t1.wavekey, 
	t1.carriercode, t1.carriername, t1.drivername, t1.trailernumber,
	t1.shippedQty, t1.cubeQty, t1.trweight, t1.trqcube,
	(case when t.storerkey='92' then sum(100*(t.cubeQty+t.trqcube)/(t1.cubeQty+t1.trqcube)) else 0 end) p92,
	(case when t.storerkey='219' then sum(100*(t.cubeQty+t.trqcube)/(t1.cubeQty+t1.trqcube)) else 0 end) p219
--	(case when t.storerkey='92' then t.cubeQty else 0 end) p92,
--	(case when t.storerkey='219' then t.cubeQty else 0 end) p219
into #tmp2
from #tmp1 t1
	join #tmp t on t.wavekey=t1.wavekey and t.carriercode=t1.carriercode
			and t.yyyy=t1.yyyy and t.mm=t1.mm and t.dd=t1.dd
group by t1.yyyy, t1.mm, t1.dd,
	t1.wavekey, 
	t1.carriercode, t1.carriername, t1.drivername, t1.trailernumber,
	t1.shippedQty, t1.cubeQty, t.cubeQty,  t1.trweight, t1.trqcube, t.storerkey

--select *
--from #tmp2

--*************
-- вычисляем проценты от объема
--*************
select t2.yyyy, t2.mm, t2.dd,
	t2.wavekey, 
	t2.carriercode, t2.carriername, t2.drivername, t2.trailernumber,
	t2.shippedQty, t2.cubeQty, t2.trweight, t2.trqcube,
	sum(t2.p92) p92,
	sum(t2.p219) p219
from #tmp2 t2
group by t2.yyyy, t2.mm, t2.dd,
	t2.wavekey, 
	t2.carriercode, t2.carriername, t2.drivername, t2.trailernumber,
	t2.shippedQty, t2.cubeQty, t2.trweight, t2.trqcube
order by t2.yyyy, t2.mm, t2.dd,
	t2.wavekey


--************

drop table #tmp
drop table #tmp1
drop table #tmp2

