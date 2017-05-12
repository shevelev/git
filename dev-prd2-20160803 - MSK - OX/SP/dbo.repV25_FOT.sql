-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 03.03.2010 (НОВЭКС)
-- Описание: Расчет фонда оплаты труда
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV25_FOT] ( 
	@wh varchar(30),	
	@month varchar(2),
	@year varchar(4),
	@TminPH decimal(22,2),
	@TminRH decimal(22,2),
	@Proc int
)

as

create table #table_Storer (
		Storerkey varchar(15) not null, -- Владелец
		Company varchar(45) not null -- Название владельца
)

create table #table_in_out_tmp (
		O_R varchar(1) not null, -- Тип документа приход расход
		actDate datetime, -- Дата документа
		storer varchar(15) not null, -- Владелец
		docNum varchar(30) not null, -- № документа
		externDocNum varchar(30) not null, -- Внеш № документа
		RSumCube float null, -- Вход объем
		OSumCube float null -- Выход объем
)

create table #table_in_out (
		storer varchar(15) not null, -- Владелец
		InCube decimal(22,7) null, -- Вход
		OutCube decimal(22,7) null -- Выход
)

create table #table_r_o_tmp (
		O_R varchar(1) not null,
		Storer varchar(15) not null, -- Владелец
		ReceiptLinesCount int not null, -- Кол-во строк в документах по приходу
		OrderLineCount int not null -- Кол-во строк в документах по расходу
)

create table #table_r_o (
		storer varchar(15) not null, -- Владелец
		Ph_Count int null, -- Кол-во строк прихода
		Rh_Count int null -- Кол-во строк расхода
)

create table #table_trans (
		storer varchar(15) not null, -- Владелец
		CubeTrans decimal(22,7) null -- объем транзит
)

create table #table_str_cube (
		storer varchar(15) not null, -- Владелец
		SC_ph decimal(22,2) not null, -- стр/объем приход
		SC_rh decimal(22,2) not null -- стр/объем расход
)


create table #tab_Tarrif_Ph (
		strD varchar(15) not null, -- Строчка
		MinSO decimal(22,1) not null, -- Минимальное значение
		MaxSO decimal(22,1) not null, -- Максимальное значение
		TRub decimal(22,2) not null, -- Тарифф
		storer varchar(15) not null -- Владелец
)

create table #tab_Tarrif_Rh (
		strD varchar(15) not null, -- Строчка
		MinSO decimal(22,2) not null, -- Минимальное значение
		MaxSO decimal(22,2) not null, -- Максимальное значение
		TRub decimal(22,2) not null, -- Тарифф
		storer varchar(15) not null -- Владелец
)

create table #result_table (
		Number int, -- Порядковый номер строчки
		Operation varchar(30) not null, -- Описание
		Znach float not null, -- Значение объема
		Tariff decimal(22,2) not null, -- Тарифф
		Itog decimal(22,2) not null -- Итого
)

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(20),
		@edateStart varchar(10)

set @bdate=@year+@month+'01'
set @edate=convert(varchar(20),dateadd(s,-1,dateadd(month,1,cast((@bdate)as datetime))),13)
set @edateStart=convert(varchar(10),dateadd(month,1,cast((@bdate)as datetime))-1,112)

print('@bdate '+@bdate)
print('@edate '+@edate)
print('@edateStart '+@edateStart)

-- Формирование таблицы владельцы
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

-- Подсчет вход-объем
set @sql='
insert into #table_in_out_tmp
select 
		''R'' O_R,
		rec.editdate actDate,
		storer.storerkey storer,
		rec.receiptkey docNum, 
		po.EXTERNPOKEY externDocNum,
		sum(pd.qtyreceived*sk.stdcube) RSumCube,
		0 OSumCube  
from '+@wh+'.PO po
	join '+@wh+'.receipt rec on po.otherreference=rec.receiptkey
	join '+@wh+'.podetail pd on po.pokey=pd.pokey
	left join '+@wh+'.sku sk on pd.sku=sk.sku and po.storerkey=sk.storerkey
	left join #table_Storer storer on po.storerkey=storer.storerkey
where (rec.editdate between '''+@bdate+''' and '''+@edate+''')
		and (po.susr4 not like ''%ИНВЕНТАРИЗ%'' or po.susr4 is null)
		and pd.status=11
group by rec.editdate, storer.storerkey, rec.receiptkey, po.EXTERNPOKEY
order by rec.editdate
'
print (@sql)
exec (@sql)

--select *
--from #table_in_out_tmp

-- Подсчет выход-объем
set @sql='
insert into #table_in_out_tmp
select 
		''O'' O_R,
		MAX(ord.editdate) actDate,
		storer.storerkey storer,
		ord.orderkey docNum, 
		ord.EXTERNORDERKEY externDocNum,		 
		0 RSumCube,
		sum(od.shippedqty*sk.stdcube) OSumCube
from '+@wh+'.orders ord
	join '+@wh+'.orderdetail od on ord.orderkey=od.orderkey
	join '+@wh+'.sku sk on od.sku=sk.sku and ord.storerkey=sk.storerkey
	left join #table_Storer storer on ord.storerkey=storer.storerkey
where ord.status>=92
		and (ord.editdate between '''+@bdate+''' and '''+@edate+''') 
group by ord.orderkey, storer.storerkey, ord.EXTERNORDERKEY
order by actDate
'
print (@sql)
exec (@sql)

--select *
--from #table_in_out_tmp

-- Формирование таблицы объемы
set @sql='
insert into #table_in_out
select 	tio.storer,
		sum(tio.RSumCube) InCube, 
		sum(tio.OSumCube) OutCube
from #table_in_out_tmp tio
group by tio.storer
order by tio.storer
'
print (@sql)
exec (@sql)

-- очистка tmp таблицы по объемам
drop table #table_in_out_tmp 

--select *
--from #table_in_out

-- подсчитываем строчки прихода
set @sql='
insert into #table_r_o_tmp
select  
		''R'' O_R,
		storer.storerkey Storer, 
		count(rd.receiptkey) ReceiptLinesCount,
		0 OrderLineCount
from '+@wh+'.receiptdetail rd
left join '+@wh+'.receipt as puo on rd.receiptkey = puo.receiptkey
left join #table_Storer storer on rd.storerkey=storer.storerkey
where	(puo.editdate between '''+@bdate+''' and '''+@edate+''')
		and	rd.qtyexpected>0
		and puo.status=''11''
group by storer.storerkey
'
print (@sql)
exec (@sql)

--select *
--from #table_r_o_tmp

-- подсчитываем строчки расхода
set @sql='
insert into #table_r_o_tmp
select  
		''O'' O_R,
		storer.storerkey Storer,
		0 ReceiptLinesCount,
		count(od.orderlinenumber) OrderLineCount
from '+@wh+'.orderdetail od
left join '+@wh+'.orders o on od.orderkey=o.orderkey
left join #table_Storer storer on od.storerkey=storer.storerkey
where (o.editdate between '''+@bdate+''' and '''+@edate+''')
		and (o.status=''92'' or o.status=''95'')
group by storer.storerkey
order by storer.storerkey
'
print (@sql)
exec (@sql)

--select *
--from #table_r_o_tmp

-- Формирование таблицы строки
set @sql='
insert into #table_r_o
select 	tro.storer Storer,
		sum(tro.ReceiptLinesCount) Ph_Count, 
		sum(tro.OrderLineCount) Rh_Count
from #table_r_o_tmp tro
group by tro.storer
order by tro.storer
'
print (@sql)
exec (@sql)

-- очистка tmp таблицы по строкам
drop table #table_r_o_tmp

--select *
--from #table_r_o

-- Формирование таблицы транзит
set @sql='
insert into #table_trans
select 	storer.storerkey Storer,
		sum(tship.cube) CubeTrans
from '+@wh+'.TRANSASN tasn
	left join #table_Storer storer on tasn.customerkey=storer.storerkey
	left join '+@wh+'.TRANSSHIP tship on tasn.TRANSASNKEY=tship.documentkey and tasn.vendorkey=tship.vendorkey
where (tasn.adddate between '''+@bdate+''' and '''+@edate+''') 
group by storer.storerkey
order by storer.storerkey
'
print (@sql)
exec (@sql)

--select *
--from #table_trans

-- Формирование таблицы строки/объем
set @sql='
insert into #table_str_cube
select
		tab1.storer STORER,
		tab2.Ph_Count/tab1.InCube SC_ph,
		tab2.Rh_Count/tab1.OutCube SC_rh
from #table_in_out tab1
left join #table_r_o tab2 on tab1.storer=tab2.storer
where tab1.storer=''92'' or tab1.storer=''219''
order by tab1.storer
'
print (@sql)
exec (@sql)

--select *
--from #table_str_cube

-- Заполнение тариффов по ПРИХОДУ на НОВЭКС
INSERT into #tab_Tarrif_Ph
select strD,
		minZ,
		maxZ,
		Itog,
		'219'
from [dbo].[TShag](0,1,@TminPH,@Proc,15)

--select *
--from #tab_Tarrif_Ph

-- Заполнение тариффов по РАСХОДУ на НОВЭКС
INSERT into #tab_Tarrif_Rh
select strD,
		minZ,
		maxZ,
		Itog,
		'219'
from [dbo].[TShag](0,15,@TminRH,@Proc,15)

--select *
--from #tab_Tarrif_Rh

-- Заполнение результирующей таблицы
insert into #result_table
select 1 Number,
		'Вход НОВЭКС' Operation,
		tio.InCube Znach,
		tPH.TRub Tariff,
		tio.InCube*tPH.TRub Itog
from #table_in_out tio
left join #table_str_cube tSC on tio.storer=tSC.storer
left join #tab_Tarrif_Ph tPh on tio.storer=tPH.storer
where tio.storer='219'
		and (tSC.SC_ph between tPH.MinSO and tPH.MaxSO)

insert into #result_table
select 2 Number,
		'Выход НОВЭКС' Operation,
		tio.OutCube Znach,
		tRH.TRub Tariff,
		tio.OutCube*tRH.TRub Itog
from #table_in_out tio
left join #table_str_cube tSC on tio.storer=tSC.storer
left join #tab_Tarrif_Rh tRh on tio.storer=tRH.storer
where tio.storer='219'
		and (tSC.SC_rh between tRH.MinSO and tRH.MaxSO)

-- Обновление тариффов по ПРИХОДУ на Оптсервис
update #tab_Tarrif_Ph
set	Storer = '92'

-- Обновление тариффов по РАСХОДУ на Оптсервис
update #tab_Tarrif_Rh
set	Storer = '92'

insert into #result_table
select 3 Number,
		'Вход Оптсервис' Operation,
		tio.InCube Znach,
		tPH.TRub Tariff,
		tio.InCube*tPH.TRub Itog
from #table_in_out tio
left join #table_str_cube tSC on tio.storer=tSC.storer
left join #tab_Tarrif_Ph tPh on tio.storer=tPH.storer
where tio.storer='92'
		and (tSC.SC_ph between tPH.MinSO and tPH.MaxSO)

insert into #result_table
select 4 Number,
		'Выход Оптсервис' Operation,
		tio.OutCube Znach,
		tRH.TRub Tariff,
		tio.OutCube*tRH.TRub Itog
from #table_in_out tio
left join #table_str_cube tSC on tio.storer=tSC.storer
left join #tab_Tarrif_Rh tRh on tio.storer=tRH.storer
where tio.storer='92'
		and (tSC.SC_rh between tRH.MinSO and tRH.MaxSO)

insert into #result_table
select 5 Number,
		'Транзит' Operation,
		sum(trans.CubeTrans) Znach,
		84 Tariff,
		sum(trans.CubeTrans)*84 Itog
from #table_trans trans

insert into #result_table
select 6 Number,
		'М.Видео и Авис' Operation,
		sum(tio.OutCube)+sum(tio.InCube) Znach,
		20 Tariff,
		(sum(tio.OutCube)+sum(tio.InCube))*20 Itog
from #table_in_out tio
where tio.storer<>'219' and tio.storer<>'92' 

select *
from #result_table
order by number

drop table #table_Storer
drop table #table_in_out
drop table #table_r_o
drop table #table_trans
drop table #table_str_cube
drop table #tab_Tarrif_Ph
drop table #tab_Tarrif_Rh
drop table #result_table

