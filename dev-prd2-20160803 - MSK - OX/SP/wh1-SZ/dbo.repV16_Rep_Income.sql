-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 03.03.2010 (НОВЭКС)
-- Описание: Сводный отчет по доходам
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV16_Rep_Income] ( 
	@wh varchar(30),								
	@datebegin datetime,
	@dateend datetime,
	@B219 float,
	@B92 float
)

as

create table #table_Storer (
		Storerkey varchar(15) not null, -- Владелец
		Company varchar(45) not null -- Название владельца
)

create table #table_DocLinesCount (
		Storer varchar(15) not null, -- Владелец
		Company varchar(45) not null, -- Название владельца
		CountOrder int not null, -- Кол-во документов
		CountOrderLine int not null, -- Кол-во строк в документах
		ReceiptLinesCount int not null, -- Кол-во строк в документах по приходу
		OQTY decimal(22,5) not null, -- Общее кол-во заказанного товара
		SQTY decimal(22,5) not null, -- Общее кол-во отгруженного товара
		SumOQTY decimal(22,5) not null, -- Цена за общее кол-во заказанного товара
		SumSQTY decimal(22,5) not null, -- Цена за общее кол-во отгруженного товара
		PercentSum decimal(22,5) not null, -- Процентное соотношение по цене
		PercentQty decimal(22,5) not null -- Процентное соотношение по кол-ву
)

create table #table_Trans (
		Storer varchar(15) not null, -- Владелец
		Company varchar(45) not null, -- Название владельца
		SummaTrans decimal(22,2) not null -- Сумма транзита		
)

create table #table_Pallete (
		Storer varchar(15) not null, -- Владелец
		Company varchar(45) not null, -- Название владельца
		SummaPal decimal(22,2) not null -- Сумма паллетирования		
)

create table #table_volume_ro (
		O_R varchar(1) not null,
		actDate datetime,
		storer varchar(15) not null,
		docNum varchar(30) not null, 
		externDocNum varchar(30) not null,
		RSumCube float null,
		OSumCube float null
)

create table #table_volume_ft (
		actDate datetime,
		storer varchar(15) not null,
		FTC float null
)

create table #table_volume_tmp (
		actDate datetime,
		RSumCube float null,
		OSumCube float null,
		storer varchar(15) not null,
)

create table #table_volume_res (
		actDate varchar(15),
		storer varchar(15) not null,
		na_0 float not null, 
		RSumCube float null,
		OSumCube float null,
		na_24 float not null
)

create table #table_volume (
		actDate varchar(15),
		storer varchar(15) not null,
		na_0 float not null, 
		RSumCube float null,
		OSumCube float null,
		na_24 float not null,
		P400 float not null
)

create table #result_table (
		Storer varchar(15) not null, -- Владелец
		Company varchar(45) not null, -- Название владельца
		Operation varchar(45) not null, -- Вид операции
		Ed varchar(45) not null, -- Единица измерения
		Expense float null, -- Расход
		Arrival float null, -- Приход
		Total float null, -- Итого
		Tariff varchar(10) not null, -- Тариф
		TotalRub decimal(22,2) null -- Итого в руб.
)

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(10),
		@edateStart varchar(10),
		@kolday decimal(22,2)

set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(10),@dateend+1,112)
set @edateStart=convert(varchar(10),@dateend,112)
set @kolday=(datediff(day,cast(@bdate as datetime),cast(@edate as datetime)))

--print(@kolday)

set @sql='
insert into #table_Storer
select 	storer.storerkey Storerkey,
		storer.company Company
from '+@wh+'.STORER storer
where storer.type=''1''
'
print (@sql)
exec (@sql)

--select *
--from #table_Storer

/*Заполнение полей для НОВЭКС и ОПТСЕРВИС*/
-- 
set @sql='
insert into #table_DocLinesCount
exec dbo.repV13_DocLinesCount '''+@wh+''','''+@bdate+''','''+@edateStart+'''
'
print (@sql)
exec (@sql)

--select *
--from #table_DocLinesCount

--
set @sql='
insert into #table_Trans
select 	storer.storerkey Storer,
		storer.company Company,
		sum(cast(isnull(tasn.udf2,0)as decimal(22,2))) SummaTrans
from '+@wh+'.TRANSASN tasn
left join #table_Storer storer on tasn.customerkey=storer.storerkey
where tasn.adddate between '''+@bdate+''' and '''+@edate+'''
group by storer.storerkey, storer.company
'
print (@sql)
exec (@sql)

--select *
--from #table_Trans

--
set @sql='
insert into #table_Pallete
select  storer.storerkey Storer,
		storer.company Company,
		sum(cast(isnull(ord.CONTAINERQTY,0)as decimal(22,2))) SummaPal
from '+@wh+'.orders ord
left join #table_Storer storer on ord.storerkey=storer.storerkey
where ord.DELIVERYDATE2 between '''+@bdate+''' and  '''+@edate+'''
		and (ord.status=''92'' or ord.status=''95'')
group by  storer.storerkey, storer.company
'
print (@sql)
exec (@sql)

--select *
--from #table_Pallete

----
insert into #result_table
select  tDLC.Storer Storer,
		tDLC.Company Company,
		'Строки' Operation,
		'шт.' Ed,
		tDLC.CountOrder Expense,
		tDLC.ReceiptLinesCount Arrival,
		(tDLC.CountOrder+tDLC.ReceiptLinesCount) Total,
		'10 руб.' Tariff,
		(tDLC.CountOrder+tDLC.ReceiptLinesCount)*10 TotalRub
from #table_DocLinesCount tDLC
		where tDLC.Storer='219' or tDLC.Storer='92'

--select *
--from #result_table

insert into #result_table
select  tT.Storer Storer,
		tT.Company Company,
		'Транзит' Operation,
		'руб.' Ed,
		null Expense,
		tT.SummaTrans Arrival,
		tT.SummaTrans Total,
		'1%' Tariff,
		(tT.SummaTrans*1)/100 TotalRub
from #table_Trans tT
		where tT.Storer='219' or tT.Storer='92'

--select *
--from #result_table

insert into #result_table
select  tP.Storer Storer,
		tP.Company Company,
		'Паллетирование' Operation,
		'пл.' Ed,
		null Expense,
		tP.SummaPal Arrival,
		tP.SummaPal Total,
		'40 руб.' Tariff,
		tP.SummaPal*40 TotalRub
from #table_Pallete tP
		where tP.Storer='219' or tP.Storer='92'

--select *
--from #result_table

insert into #result_table
select  tS.Storerkey Storer,
		tS.Company Company,
		'Хранение рекламы' Operation,
		'пл.' Ed,
		null Expense,
		null Arrival,
		sum(fto.Qty) Total,
		'300 руб.' Tariff,
		(300*sum(fto.Qty))/@kolday TotalRub
from #table_Storer tS
left join dbo.FT_ostatki fto on tS.storerkey=fto.storerkey
		where tS.Storerkey='219' 
				and fto.sku like 'REKLAM%'
				and (fto.date_CN between ''+@bdate+'' and  ''+@edateStart+'' ) 
group by tS.Storerkey, tS.Company

--select *
--from #result_table

insert into #result_table
select  tS.Storerkey Storer,
		tS.Company Company,
		'Хранение рекламы' Operation,
		'пл.' Ed,
		null Expense,
		null Arrival,
		sum(fto.Qty) Total,
		'300 руб.' Tariff,
		(300*sum(fto.Qty))/@kolday TotalRub
from #table_Storer tS
left join dbo.FT_ostatki fto on tS.storerkey=fto.storerkey
		where tS.Storerkey='92'
				and fto.sku like 'REKLAM%'
				and (fto.date_CN between ''+@bdate+'' and  ''+@edateStart+'' ) 
group by tS.Storerkey, tS.Company

--select *
--from #result_table


insert into #result_table
select  tS.Storerkey Storer,
		tS.Company Company,
		'Брак, ротации, оборудование' Operation,
		'шт.' Ed,
		null Expense,
		null Arrival,
		null Total,
		'' Tariff,
		@B219 TotalRub
from #table_Storer tS
		where tS.Storerkey='219'

--select *
--from #result_table

insert into #result_table
select  tS.Storerkey Storer,
		tS.Company Company,
		'Брак, ротации, оборудование' Operation,
		'шт.' Ed,
		null Expense,
		null Arrival,
		null Total,
		'' Tariff,
		@B92 TotalRub
from #table_Storer tS
		where tS.Storerkey='92'

--select *
--from #result_table

insert into #result_table
select  tS.Storerkey Storer,
		tS.Company Company,
		'Штрихкод распечатка' Operation,
		'шт.' Ed,
		null Expense,
		null Arrival,
		null Total,
		'0,26 руб.' Tariff,
		null TotalRub
from #table_Storer tS
		where tS.Storerkey='219' or tS.Storerkey='92'

--select *
--from #result_table

insert into #result_table
select  tS.Storerkey Storer,
		tS.Company Company,
		'Штрихкод наклейка' Operation,
		'шт.' Ed,
		null Expense,
		null Arrival,
		null Total,
		'0,4 руб.' Tariff,
		null TotalRub
from #table_Storer tS
		where tS.Storerkey='219' or tS.Storerkey='92'

--select *
--from #result_table

/*Заполнение полей для М.Видео и Авис */
-- 
set @sql='
insert into #table_volume_ro
select 
		''R'' O_R,
		rec.editdate actDate,
		po.storerkey storer,
		rec.receiptkey docNum, 
		po.EXTERNPOKEY externDocNum,
		sum(pd.qtyreceived*sk.stdcube) RSumCube,
		0 OSumCube  
from '+@wh+'.PO po
	join '+@wh+'.receipt rec on po.otherreference=rec.receiptkey
	join '+@wh+'.podetail pd on po.pokey=pd.pokey
	left join '+@wh+'.sku sk on pd.sku=sk.sku and po.storerkey=sk.storerkey
where (po.storerkey=''000000001'' or po.storerkey=''6845'')
		and (rec.editdate between '''+@bdate+''' and '''+@edate+''')
		and (po.susr4 not like ''%ИНВЕНТАРИЗ%'' or po.susr4 is null)
		and pd.status=11
group by 
		rec.editdate,
		po.storerkey,
		rec.receiptkey, 
		po.EXTERNPOKEY
order by rec.editdate
'

print (@sql)
exec (@sql)

--select *
--from #table_volume_ro

set @sql='
insert into #table_volume_ro
select 
		''O'' O_R,
		MAX(ord.editdate) actDate,
		ord.storerkey storer,
		ord.orderkey docNum, 
		ord.EXTERNORDERKEY externDocNum,		 
		0 RSumCube,
		sum(od.shippedqty*sk.stdcube) OSumCube
from '+@wh+'.orders ord
	join '+@wh+'.orderdetail od on ord.orderkey=od.orderkey
	join '+@wh+'.sku sk on od.sku=sk.sku and ord.storerkey=sk.storerkey
where (ord.storerkey=''000000001'' or ord.storerkey=''6845'')
		and ord.status>=92
		and (ord.editdate between '''+@bdate+''' and '''+@edate+''') 
group by 
		ord.orderkey, 
		ord.storerkey,
		ord.EXTERNORDERKEY
		
order by actDate
'

print (@sql)
exec (@sql)

--select *
--from #table_volume_ro

set @sql='
insert into #table_volume_ft
select ft.Date_cn actDate,
		ft.storerkey storer,
		sum(ft.qty*sk.stdcube) FTC
from dbo.FT_ostatki FT
left join '+@wh+'.sku sk on ft.storerkey=sk.storerkey and ft.sku=sk.sku
where (ft.storerkey=''000000001'' or ft.storerkey=''6845'') 
		and (ft.date_cn between dateadd("d",-1,'''+@bdate+''') and '''+@edate+''')
group by ft.Date_cn,
		ft.storerkey
order by ft.Date_cn, ft.storerkey
'

print (@sql)
exec (@sql)

--select *
--from #table_volume_ft

set @sql='
insert into #table_volume_tmp
select convert(varchar(10),rt.actDate,112) actDate, 
		sum(rt.RSumCube) RSumCube, 
		sum(rt.OSumCube) OSumCube,
		rt.storer
from #table_volume_ro rt
group by convert(varchar(10),rt.actDate,112), rt.storer
'

print (@sql)
exec (@sql)

--select *
--from #table_volume_tmp

set @sql='
insert into #table_volume_res
select convert(varchar(10),ft.actDate,104) actDate, 
		ft.storer storer, 
		fto.ftc na_0, 
		isnull(tmp.RSumCube,0) RSumCube, 
		isnull(tmp.OSumCube,0) OSumCube, 
		ft.ftc na_24
from #table_volume_ft ft
	left join #table_volume_tmp tmp on ft.actDate=tmp.actDate and ft.storer=tmp.storer
	left join #table_volume_ft fto on ft.actDate=dateadd("d", 1,fto.actDate) and ft.storer=fto.storer
where (ft.actDate between '''+@bdate+''' and dateadd("d",-1,'''+@edate+'''))
order by ft.actDate
'

print (@sql)
exec (@sql)

--select *
--from #table_volume_res


insert into #result_table
select  tS.Storerkey Storer,
		tS.Company Company,
		'Хранение резервируемого объема' Operation,
		'м3' Ed,
		null Expense,
		null Arrival,
		400 Total,
		'300 руб.' Tariff,
		400*300 TotalRub
from #table_Storer tS
		where tS.Storerkey='000000001'

--select *
--from #result_table

-- 
insert into #table_volume
select 	tv_res.actDate actDate,
		tv_res.storer storer,
		tv_res.na_0 na_0,
		tv_res.RSumCube RSumCube,
		tv_res.OSumCube OSumCube,
		tv_res.na_24 na_24,
		(tv_res.na_24-400) P400
from #table_volume_res tv_res

--select *
--from #table_volume

-- 
update rt set rt.P400 = 0
	from #table_volume rt
		where rt.P400<0

--select *
--from #table_volume

-- 
insert into #result_table
select  tV.Storer Storer,
		storer.Company Company,
		'Превышение суточного объема хранения' Operation,
		'м3' Ed,
		null Expense,
		null Arrival,
		sum(tV.P400) Total,
		cast(cast(340/@kolday as decimal(22,2)) as varchar(10))+' руб.' Tariff,
		sum(tV.P400)*cast(340/@kolday as decimal(22,2)) TotalRub
from #table_volume tV
left join #table_Storer storer on tV.storer=storer.storerkey
where tV.storer='000000001'
group by tV.Storer, storer.Company

--select *
--from #result_table

-- 
insert into #result_table
select  tV.Storer Storer,
		storer.Company Company,
		'Вход-выход' Operation,
		'м3' Ed,
		sum(tV.OSumCube) Expense,
		sum(tV.RSumCube) Arrival,
		(sum(tV.OSumCube)+sum(tV.RSumCube)) Total,
		'120 руб.' Tariff,
		(sum(tV.OSumCube)+sum(tV.RSumCube))*120 TotalRub
from #table_volume tV
left join #table_Storer storer on tV.storer=storer.storerkey
where tV.storer='000000001'
group by tV.Storer, storer.Company

--select *
--from #result_table

-- 
insert into #result_table
select  tV.Storer Storer,
		storer.Company Company,
		'Хранение объема' Operation,
		'м3' Ed,
		null Expense,
		null Arrival,
		sum(tV.na_24) Total,
		cast(cast(360/@kolday as decimal(22,2)) as varchar(10))+' руб.' Tariff,
		sum(tV.na_24)*cast(360/@kolday as decimal(22,2)) TotalRub
from #table_volume_res tV
left join #table_Storer storer on tV.storer=storer.storerkey
where tV.storer='6845'
group by tV.Storer, storer.Company

--select *
--from #result_table

-- 
insert into #result_table
select  tV.Storer Storer,
		storer.Company Company,
		'Вход-выход' Operation,
		'м3' Ed,
		sum(tV.OSumCube) Expense,
		sum(tV.RSumCube) Arrival,
		(sum(tV.OSumCube)+sum(tV.RSumCube)) Total,
		'120 руб.' Tariff,
		(sum(tV.OSumCube)+sum(tV.RSumCube))*120 TotalRub
from #table_volume_res tV
left join #table_Storer storer on tV.storer=storer.storerkey
where tV.storer='6845'
group by tV.Storer, storer.Company

--select *
--from #result_table

--'Ренесанскосметик'
insert into #table_Storer 
Values('0','Ренесанскосметик')

insert into #result_table
select  tS.Storerkey Storer,
		tS.Company Company,
		'Хранение' Operation,
		'пл' Ed,
		null Expense,
		null Arrival,
		null Total,
		'' Tariff,
		null TotalRub
from #table_Storer tS
		where tS.Storerkey='0'

select *
from #result_table
--order by company


drop table #table_Storer
drop table #table_DocLinesCount
drop table #table_Trans
drop table #table_Pallete
drop table #table_volume_ro
drop table #table_volume_ft
drop table #table_volume_tmp
drop table #table_volume_res
drop table #table_volume
drop table #result_table

