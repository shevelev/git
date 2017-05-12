-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 15.02.2010 (НОВЭКС)
-- Описание: Планирование волны по времени
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV15_WaveTime] 
	@wh varchar(10),
	@wave varchar(max)
AS
create table #table_tariff(
		DESCRIP varchar(30) not null,-- Описание тариффа
		RATE decimal(22,6) not null,-- Тарифф за штуку
		COSTRATE decimal(22,6) not null,-- Тарифф за строчку
		COSTUOMSHOW varchar(10) not null-- Тип тарифа (EA - штука)
)
create table #tbl_wave (
		WAVEKEY varchar(10) not null -- № волны
)
create table #tbl_wave_NotStart (
		WAVEKEY varchar(10) not null, -- № волны
		ORDERKEY varchar(10) not null -- № заказа
)
create table #tbl_wave_Start (
		WAVEKEY varchar(10) not null, -- № волны
		ORDERKEY varchar(10) not null -- № заказа
)
create table #table_orders(
		Wavekey varchar(10) not null, -- № волны,
		Orderkey varchar(10) not null, -- № заказа
		Cartongroup varchar(10) null, -- Зона картонизации
		Sku varchar(50) not null, -- Код товара
		Qty decimal(22,5) not null, -- Кол-во товара в шт.
		StdCube float not null, -- Вес 1шт.
		SCube decimal(22,6) not null, -- Объем
		Rate int null, -- Тариф по отбору объема
		ROrder decimal(22,10) not null -- Необходимое время на сбор в сек.
)

create table #table_result(
		Wavekey varchar(10) not null, -- № волны,
		Orderkey varchar(10) not null, -- № заказа
		SCube decimal(22,6) not null, -- Объем
		ItogSec decimal(22,10) not null, -- Необходимое время на сбор в сек.
		ItogMinute int not null -- Необходимое время на сбор в сек.
)

declare @sql varchar(max)
		

INSERT into #tbl_wave
select *
from [dbo].[MultiValue2Table](@wave)

--select*
--from #tbl_wave

/*Тариффы*/
set @sql='
insert into #table_tariff
select substring(TD.DESCRIP,3,30) DESCRIP,
		TD.RATE RATE,
		TD.COSTRATE COSTRATE,
		TD.COSTUOMSHOW COSTUOMSHOW
from '+@wh+'.TARIFFDETAIL TD
where TD.DESCRIP like ''K_%''
'

print (@sql)
exec (@sql)

--select *
--from #table_tariff

set @sql='
insert into #tbl_wave_NotStart
select  wd.wavekey,
		wd.orderkey
from #tbl_wave tw
left join '+@wh+'.wave w on tw.wavekey=w.wavekey
left join '+@wh+'.wavedetail wd on tw.wavekey=wd.wavekey
where w.status=''0''
'
print (@sql)
exec (@sql)

--select*
--from #tbl_wave_NotStart

set @sql='
insert into #tbl_wave_Start
select  wd.wavekey,
		wd.orderkey
from #tbl_wave tw
left join '+@wh+'.wave w on tw.wavekey=w.wavekey
left join '+@wh+'.wavedetail wd on tw.wavekey=wd.wavekey
where w.status=''5''
'
print (@sql)
exec (@sql)

--select*
--from #tbl_wave_Start

set @sql='
insert into #table_orders
select  twNS.wavekey Wavekey,
		twNS.orderkey Orderkey,
		od.cartongroup Cartongroup,
		od.sku Sku,
		od.originalqty Qty,
		sk.stdcube StdCube,
		(od.originalqty*sk.stdcube) SCube,
		isnull(tard.rate,0) Rate,
		((od.originalqty*sk.stdcube)*isnull(tard.rate,0)) ROrder
from #tbl_wave_NotStart twNS
left join '+@wh+'.orderdetail od on twNS.orderkey=od.orderkey
left join '+@wh+'.sku sk on od.sku=sk.sku and od.storerkey=sk.storerkey
--left join '+@wh+'.TARIFFDETAIL TARD on sk.cartongroup=TARD.descrip
left join #table_tariff TARD on sk.cartongroup=TARD.descrip
where TARD.costuomshow=''EA''
order by twNS.wavekey, twNS.orderkey, od.cartongroup, od.sku
'
print (@sql)
exec (@sql)

--select *
--from #table_orders

set @sql='
insert into #table_result
select  tabo.Wavekey Wavekey,
		tabo.Orderkey Orderkey,
		sum(tabo.SCube) SCube,
		sum(tabo.ROrder) ItogSec,
		(datediff(minute,''00:00:00'',dateadd(second,sum(tabo.ROrder),''00:00:00''))) ItogMinute
from #table_orders tabo
group by tabo.Wavekey,tabo.Orderkey
'
print (@sql)
exec (@sql)

--select *
--from #table_result

delete #table_orders

set @sql='
insert into #table_orders
select  twNS.wavekey Wavekey,
		twNS.orderkey Orderkey,
		PD.cartongroup Cartongroup,
		PD.sku Sku,
		PD.originalqty Qty,
--		PD.qty Qty,
		SK.stdcube StdCube,
		PD.originalqty*SK.stdcube SCube,
--		PD.qty*SK.stdcube SCube,
		isnull(TARD.rate,0) Rate,
		(PD.originalqty*SK.stdcube)*isnull(TARD.rate,0) ROrder
--		(PD.qty*SK.stdcube)*isnull(TARD.rate,0) ROrder
from #tbl_wave_Start twNS
left join '+@wh+'.orderdetail PD on twNS.orderkey=PD.orderkey
--left join '+@wh+'.PICKDETAIL PD on twNS.orderkey=PD.orderkey
left join '+@wh+'.SKU SK on PD.storerkey=SK.storerkey and PD.sku=SK.sku
--left join '+@wh+'.TARIFFDETAIL TARD on PD.cartongroup=TARD.descrip
left join #table_tariff TARD on sk.cartongroup=TARD.descrip
where 	PD.status<>''55''
		--(PD.status=''0'' or PD.status=''1'')
		and TARD.costuomshow=''EA''
order by twNS.wavekey, twNS.orderkey, PD.cartongroup, PD.sku
'
print (@sql)
exec (@sql)

--select *
--from #table_orders

set @sql='
insert into #table_result
select  tabo.Wavekey Wavekey,
		tabo.Orderkey Orderkey,
		sum(tabo.SCube) SCube,
		sum(tabo.ROrder) ItogSec,
		(datediff(minute,''00:00:00'',dateadd(second,sum(tabo.ROrder),''00:00:00''))) ItogMinute
from #table_orders tabo
group by tabo.Wavekey,tabo.Orderkey
'
print (@sql)
exec (@sql)

select *
from #table_result

drop table #table_tariff
drop table #tbl_wave
drop table #tbl_wave_NotStart
drop table #tbl_wave_Start
drop table #table_orders
drop table #table_result

