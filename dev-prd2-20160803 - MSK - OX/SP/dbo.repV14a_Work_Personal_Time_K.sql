-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 08.02.2010 (НОВЭКС)
-- Описание: Отчет работа и оплата персонала, учет по времени
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV14a_Work_Personal_Time_K] ( 
	@wh varchar(30),								
	@datebegin datetime,
	@dateend datetime,
	@NrmYa varchar(10)
)
as

create table #table_tariff(
		DESCRIP varchar(30) not null,-- Описание тариффа
		RATE decimal(22,6) not null,-- Тарифф за штуку
		COSTRATE decimal(22,6) not null,-- Тарифф за строчку
		COSTUOMSHOW varchar(10) not null-- Тип тарифа (EA - штука)
)
create table #table_Ya(
		Who varchar(18) not null, -- Пользователь
		CGROUP varchar(10) null, -- Зона картонизации
		KolCASEID int not null, -- Кол-во ящиков
		RateYa int null, -- Тариф при отборе по ящикам
		ResYa int not null -- Результат по сбору в сек. по ящикам
)
create table #table_Str(
		Who varchar(18) not null, -- Пользователь
		CGROUP varchar(10) null, -- Зона картонизации
		KolStr int not null, -- Кол-во строчек
		RateStr int null, -- Тариф при отборе по строчкам
		ResStr int null -- Результат по сбору в сек. по строчкам
)
create table #table_Sht(
		Who varchar(18) not null, -- Пользователь
		CGROUP varchar(10) null, -- Зона картонизации
		CaseId varchar(20) not null, -- Ящик
		LNumber varchar(5) not null, -- Строчка в заказе
		Sku varchar(50) not null, -- Код товара
		QtySht decimal(22,5) not null, -- Кол-во товара при отборе в шт.
		stdcube float not null,
		CubeMSht decimal(22,6) not null, -- Объем при отборе в шт.
		RateSht int null, -- Тариф при отборе по шт.
		ResSht decimal(22,6) not null -- Результат по сбору в сек. по шт.
)
create table #table_Sht_Itog(
		Who varchar(18) not null, -- Пользователь
		CGROUP varchar(10) null, -- Зона картонизации
		CubeMSht decimal(22,6) not null, -- Объем при отборе в шт.
		KolQtySht decimal(22,5) not null, -- Итог кол-во товара при отборе в шт.
		ResSht decimal(22,6) not null -- Итог результат по сбору в сек. по шт.
)
create table #table_Korob(
		Who varchar(18) not null, -- Пользователь
		CGROUP varchar(10) null, -- Зона картонизации
		CaseId varchar(20) not null, -- Ящик
		LNumber varchar(5) not null, -- Строчка в заказе
		Sku varchar(50) not null, -- Код товара
		QtyKorob decimal(22,5) not null, -- Кол-во товара при отборе в коробках
		ShtVKorob int not null, -- Шт. в коробке
		stdcube float not null,
		CubeMKorob decimal(22,10) not null, -- Объем при отборе в коробках
		RateKorob int not null, -- Тариф при отборе в коробках
		ResKorob decimal(22,10) not null -- Результат по сбору в сек. по коробкам
)
create table #table_Korob_Itog(
		Who varchar(18) not null, -- Пользователь
		CGROUP varchar(10) null, -- Зона картонизации
		CubeMKorob decimal(22,10) not null, -- Объем при отборе в коробках
		KolQtyKorob decimal(22,5) not null, -- Итог кол-во товара при отборе в коробках
		ResKorob decimal(22,10) not null -- Итог результат по сбору в сек. по коробкам
)
create table #table_result(
		UserName varchar(40) null, -- Фамилия, Имя
		Who varchar(18) not null, -- Пользователь
		CGROUP varchar(10) null, -- Зона картонизации
		KolCASEID int null, -- Кол-во ящиков
		ResYa int null, -- Результат по сбору в сек. по ящикам
		KolStr int null, -- Кол-во строчек
		ResStr int null, -- Результат по сбору в сек. по строчкам
		KolQtyKorob int null, -- Итог кол-во товара при отборе в коробках.
		ResKorob decimal(22,10) null, -- Итог результат по сбору в сек. по коробкам
		KolQtySht int null, -- Итог кол-во товара при отборе в шт.
		ResSht decimal(22,10) null, -- Итог результат по сбору в сек. по шт.
		CubeMItog decimal(22,6) null, -- Итог объем ящика
		ItogSec decimal(22,10) null, -- Итог по сек.  в зоне картонизации
		ItogMinute int null -- Итог по минутам  в зоне картонизации
)

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(10)

set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(10),@dateend+1,112)

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

/*Кол-во ящиков в зоне картонизации по пользователям*/
set @sql='
insert into #table_Ya
select  TD.userkey Who,
		PD.cartongroup CGROUP,
		count(distinct(PD.caseid)) KolCASEID,
		'+@NrmYa+' RateYa,
		count(distinct(PD.caseid))*cast('+@NrmYa+' as int) ResYa
from '+@wh+'.PICKDETAIL PD
left join '+@wh+'.TASKDETAIL TD on PD.caseid=TD.caseid and PD.pickdetailkey=TD.pickdetailkey
left join '+@wh+'.itrn i on pd.sku=i.sku and pd.storerkey=i.storerkey and pd.pickdetailkey=i.sourcekey
left join '+@wh+'.SKU SK on PD.storerkey=SK.storerkey and PD.sku=SK.sku
where 	i.editdate between '''+@bdate+''' and '''+@edate+'''
		and (PD.status=''5'' or PD.status=''9'')
		and isnull(TD.userkey,'''')<>''''
		--and TD.userkey=''elfimovr''
group by TD.userkey, PD.cartongroup
order by TD.userkey, PD.cartongroup
'

print (@sql)
exec (@sql)

--select *
--from #table_Ya

/*Кол-во строк в ящике в зоне картонизации по пользователям*/
set @sql='
insert into #table_Str
select  TD.userkey Who,
		PD.cartongroup CGROUP,
		count(PD.orderlinenumber) KolStr,
		TARD.costrate RateStr,
		count(PD.orderlinenumber)*cast(TARD.costrate as int) ResStr
from '+@wh+'.PICKDETAIL PD
left join '+@wh+'.TASKDETAIL TD on PD.caseid=TD.caseid and PD.pickdetailkey=TD.pickdetailkey
left join #table_tariff TARD on PD.cartongroup=TARD.descrip
left join '+@wh+'.itrn i on pd.sku=i.sku and pd.storerkey=i.storerkey and pd.pickdetailkey=i.sourcekey
left join '+@wh+'.SKU SK on PD.storerkey=SK.storerkey and PD.sku=SK.sku
where 	i.editdate between '''+@bdate+''' and '''+@edate+'''
		and (PD.status=''5'' or PD.status=''9'')
		and isnull(TD.userkey,'''')<>''''
		--and TD.userkey=''elfimovr''
		and TARD.costuomshow=''EA''
group by TD.userkey, PD.cartongroup, TARD.costrate
order by TD.userkey, PD.cartongroup, TARD.costrate
'

print (@sql)
exec (@sql)

--select *
--from #table_Str

/*Кол-во товара в шт. в зоне картонизации по пользователям*/
set @sql='
insert into #table_Sht
select  TD.userkey Who,
		PD.cartongroup CGROUP,
		PD.caseid CASEID,
		PD.orderlinenumber LNumber,
		PD.sku Sku,
		cast(i.qty-cast((i.qty/PK.casecnt)as int)*PK.casecnt as int) QtySht,
		SK.stdcube stdcube,
		sum(cast(i.qty-cast((i.qty/PK.casecnt)as int)*PK.casecnt as int)*SK.stdcube) CubeMSht,
		isnull(TARD.rate,0) RateSht,
		sum(cast(i.qty-cast((i.qty/PK.casecnt)as int)*PK.casecnt as int)*SK.stdcube)*isnull(TARD.rate,0) ResSht
from '+@wh+'.PICKDETAIL PD
left join '+@wh+'.TASKDETAIL TD on PD.caseid=TD.caseid and PD.pickdetailkey=TD.pickdetailkey
left join '+@wh+'.SKU SK on PD.storerkey=SK.storerkey and PD.sku=SK.sku
left join #table_tariff TARD on PD.cartongroup=TARD.descrip
left join '+@wh+'.itrn i on pd.sku=i.sku and pd.storerkey=i.storerkey and pd.pickdetailkey=i.sourcekey
left join '+@wh+'.PACK PK on i.packkey=PK.packkey
where 	i.editdate between '''+@bdate+''' and '''+@edate+'''
		and (PD.status=''5'' or PD.status=''9'')
		and isnull(TD.userkey,'''')<>''''
		--and TD.userkey=''elfimovr''
		and TARD.costuomshow=''EA''
		and PK.casecnt<>1 
group by TD.userkey, PD.cartongroup, TARD.rate, PD.caseid, PD.orderlinenumber, PD.sku, i.qty, PK.casecnt, SK.stdcube
order by TD.userkey, PD.cartongroup, TARD.rate, PD.caseid, PD.orderlinenumber, PD.sku, i.qty, PK.casecnt, SK.stdcube
'

print (@sql)
exec (@sql)

--select *
--from #table_Sht

/*Кол-во товара в шт. в зоне картонизации по пользователям и ключ упаковки равен 1*/
set @sql='
insert into #table_Sht
select  TD.userkey Who,
		PD.cartongroup CGROUP,
		PD.caseid CASEID,
		PD.orderlinenumber LNumber,
		PD.sku Sku,
		i.qty QtySht,
		SK.stdcube stdcube,
		i.qty*SK.stdcube CubeMSht,
		isnull(TARD.rate,0) RateSht,
		(i.qty*SK.stdcube)*isnull(TARD.rate,0) ResSht
from '+@wh+'.PICKDETAIL PD
left join '+@wh+'.TASKDETAIL TD on PD.caseid=TD.caseid and PD.pickdetailkey=TD.pickdetailkey
left join '+@wh+'.SKU SK on PD.storerkey=SK.storerkey and PD.sku=SK.sku
left join #table_tariff TARD on PD.cartongroup=TARD.descrip
left join '+@wh+'.itrn i on pd.sku=i.sku and pd.storerkey=i.storerkey and pd.pickdetailkey=i.sourcekey
left join '+@wh+'.PACK PK on i.packkey=PK.packkey
where 	i.editdate between '''+@bdate+''' and '''+@edate+'''
		and (PD.status=''5'' or PD.status=''9'')
		and isnull(TD.userkey,'''')<>''''
		--and TD.userkey=''elfimovr''
		and TARD.costuomshow=''EA''
		and PK.casecnt=1 
group by TD.userkey, PD.cartongroup, TARD.rate, PD.caseid, PD.orderlinenumber, PD.sku, i.qty, PK.casecnt, SK.stdcube
order by TD.userkey, PD.cartongroup, TARD.rate, PD.caseid, PD.orderlinenumber, PD.sku, i.qty, PK.casecnt, SK.stdcube
'

print (@sql)
exec (@sql)

--select *
--from #table_Sht

/*Итог кол-во товара в шт. в зоне картонизации по пользователям*/
set @sql='
insert into #table_Sht_Itog
select  Who,
		CGROUP,
		sum(CubeMSht) CubeMSht,
		sum(QtySht) KolQtySht,
		sum(ResSht) ResSht
from #table_Sht
group by Who,CGROUP
order by Who,CGROUP
'

print (@sql)
exec (@sql)

--select *
--from #table_Sht_Itog

/*Кол-во товара в коробках в зоне картонизации по пользователям*/
set @sql='
insert into #table_Korob
select  TD.userkey Who,
		PD.cartongroup CGROUP,
		PD.caseid CASEID,
		PD.orderlinenumber LNumber,
		PD.sku Sku,
		cast(i.qty/PK.casecnt as int) QtyKorob,
		PK.casecnt ShtVKorob,
		SK.stdcube stdcube,
		sum((cast((i.qty/PK.casecnt)as int)*PK.casecnt)*SK.stdcube) CubeMKorob,
		(isnull(TARD.rate,0)/PK.casecnt) RateKorob,
		sum((cast((i.qty/PK.casecnt)as int)*PK.casecnt)*SK.stdcube)*(isnull(TARD.rate,0)/PK.casecnt) ResKorob
from '+@wh+'.PICKDETAIL PD
left join '+@wh+'.TASKDETAIL TD on PD.caseid=TD.caseid and PD.pickdetailkey=TD.pickdetailkey
left join '+@wh+'.SKU SK on PD.storerkey=SK.storerkey and PD.sku=SK.sku
left join #table_tariff TARD on PD.cartongroup=TARD.descrip
left join '+@wh+'.itrn i on pd.sku=i.sku and pd.storerkey=i.storerkey and pd.pickdetailkey=i.sourcekey
left join '+@wh+'.PACK PK on i.packkey=PK.packkey
where 	i.editdate between '''+@bdate+''' and '''+@edate+'''
		and (PD.status=''5'' or PD.status=''9'')
		and isnull(TD.userkey,'''')<>''''
		--and TD.userkey=''elfimovr''
		and TARD.costuomshow=''EA''
		and PK.casecnt<>1
group by TD.userkey, PD.cartongroup, TARD.rate, PD.caseid, PD.orderlinenumber, PD.sku, i.qty, PK.casecnt, SK.stdcube
order by TD.userkey, PD.cartongroup, TARD.rate, PD.caseid, PD.orderlinenumber, PD.sku, i.qty, PK.casecnt, SK.stdcube
'

print (@sql)
exec (@sql)

--select *
--from #table_Korob

/*Итог кол-во товара в коробках в зоне картонизации по пользователям*/
set @sql='
insert into #table_Korob_Itog
select  Who,
		CGROUP,
		sum(CubeMKorob) CubeMKorob,
		sum(QtyKorob) KolQtyKorob,
		sum(ResKorob) ResKorob
from #table_Korob
group by Who,CGROUP
order by Who,CGROUP
'

print (@sql)
exec (@sql)

--select *
--from #table_Korob_Itog

set @sql='
insert into #table_result
select  u.usr_name UserName,
		TY.Who Who,
		TY.CGROUP CGROUP,
		TY.KolCASEID KolCASEID,
		isnull(TY.ResYa,0) ResYa,
		TStr.KolStr KolStr,
		isnull(TStr.ResStr,0) ResStr,
		isnull(TKI.KolQtyKorob,0) KolQtyKorob,
		isnull(TKI.ResKorob,0) ResKorob,
		isnull(TShtI.KolQtySht,0) KolQtySht,
		isnull(TShtI.ResSht,0) ResSht,
		(isnull(TShtI.CubeMSht,0)+isnull(TKI.CubeMKorob,0)) CubeMItog,
		(isnull(TY.ResYa,0)+isnull(ResStr,0)+isnull(TShtI.ResSht,0)+isnull(TKI.ResKorob,0)) ItogSec,
		(datediff(minute,''00:00:00'',dateadd(second,(isnull(TY.ResYa,0)+isnull(ResStr,0)+isnull(TShtI.ResSht,0)+isnull(TKI.ResKorob,0)),''00:00:00''))) ItogMinute
from #table_Ya TY
left join #table_Str TStr on TY.Who=TStr.Who and TY.CGROUP=TStr.CGROUP
left join #table_Sht_Itog TShtI on TY.Who=TShtI.Who and TY.CGROUP=TShtI.CGROUP
left join #table_Korob_Itog TKI on TY.Who=TKI.Who and TY.CGROUP=TKI.CGROUP
left join ssaadmin.pl_usr u on TY.Who=u.usr_login
order by u.usr_name,TY.CGROUP
'

print (@sql)
exec (@sql)

select *
from #table_result

drop table #table_tariff
drop table #table_Ya
drop table #table_Str
drop table #table_Sht
drop table #table_Sht_Itog
drop table #table_Korob
drop table #table_Korob_Itog
drop table #table_result

