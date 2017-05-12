
-- РАБОТА С БРАКОМ --

ALTER PROCEDURE [dbo].[proc_DA_Move](
	@wh varchar(10),
	@transmitlogkey varchar (10)
)AS

--SET NOCOUNT ON

declare @osn varchar(50) set @osn = '1'
declare @lost varchar(50) set @lost = '35'
declare @tamg varchar(50) set @tamg = '4'

declare @bs varchar(3) select @bs = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'
declare @bsanalit varchar(3) select @bsanalit = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bsanalit'

--3    __Сильнодействующие
--1    1 Склад
--22    Забраковка
--30    Некондиция
--35    Потери
--4    Сертификация


--declare  @transmitlogkey varchar (10) set @transmitlogkey ='0005247014'


--if @wh <> 'wh1'
--begin
--	raiserror('Недопустимая схема %s',16,1,@wh)
--	return
--end

CREATE TABLE #result(
	[sku] varchar(50) NULL,
	[storerkey] varchar(15) NULL,
	[packkey] varchar(50) NULL,
	[attribute02] varchar(50) NULL,
	--[attribute04] varchar(50) NULL,
	[attribute04] datetime null,
	--[attribute05] varchar(50) NULL,
	[attribute05] datetime null,	
	[SOURCESKLAD] varchar(50) NULL,
	[DESTSKLAD] varchar(50) NULL,
	[qty] decimal(19,10) NULL,
)

--<STORERKEY>
--<SKU>
--<PACKKEY>
--<ATTRIBUTE02>
--<ATTRIBUTE04>
--<ATTRIBUTE05>
--<SOURCESKLAD>
--<DESTSKLAD>
--<QTY>


-- перемещение в/из ячейки LOST
insert into #result
select 
	i.SKU sku,
	i.STORERKEY storerkey,
	s.PACKKEY packkey,
	case when la.LOTTABLE02 = @bs then @bsanalit else la.LOTTABLE02 end  ATTRIBUTE02, -- замена кода бессерийного товара инфор на код аналит
	convert(varchar(20),la.LOTTABLE04,120) ATTRIBUTE04,
	convert(varchar(20),la.LOTTABLE05,120) ATTRIBUTE05,
	case when i.fromloc = 'LOST' then @lost else @osn end SOURCESKLAD,
	case when i.toloc = 'LOST' then @lost else @osn end DESTSKLAD,
	QTY
 from wh1.transmitlog tl 
		join wh1.itrn i on tl.key1 = i.itrnkey
		join wh1.SKU s on s.SKU = i.SKU and s.storerkey = i.STORERKEY
		join wh1.LOTATTRIBUTE la on la.LOT = i.LOT
where (i.toloc = 'LOST' or i.fromloc = 'LOST') and tl.TRANSMITLOGKEY = @transmitlogkey


-- перемещение в/из ячейки TAMOGNIA
insert into #result
select 
	i.SKU sku,
	i.STORERKEY storerkey,
	s.PACKKEY packkey,
	case when la.LOTTABLE02 = @bs then @bsanalit else la.LOTTABLE02 end  ATTRIBUTE02, -- замена кода бессерийного товара инфор на код аналит
	convert(varchar(20),la.LOTTABLE04,120) ATTRIBUTE04,
	convert(varchar(20),la.LOTTABLE05,120) ATTRIBUTE05,
	case when i.fromloc = 'TAMOGNIA' then @tamg else @osn end SOURCESKLAD,
	case when i.toloc = 'TAMOGNIA' then @tamg else @osn end DESTSKLAD,
	QTY
 from wh1.transmitlog tl 
		join wh1.itrn i on tl.key1 = i.itrnkey
		join wh1.SKU s on s.SKU = i.SKU and s.storerkey = i.STORERKEY
		join wh1.LOTATTRIBUTE la on la.LOT = i.LOT
where (i.toloc = 'TAMOGNIA' or i.fromloc = 'TAMOGNIA') and tl.TRANSMITLOGKEY = @transmitlogkey


--print	'1. перемещение норм. -> брак, брак -> норм.'
--	--insert into #result
--	select i.itrnkey,
--		convert(varchar(8),i.adddate,112), i.storerkey, i.sku, i.qty,
--		--isnull(hz2.hostzone,'unknown') whfrom,
--		--isnull(hz.hostzone,'unknown') whto,
--		case
--			when (i.fromloc like 'LOST%' and i.fromloc <> 'LOST') or i.fromloc like 'H0%' 
--				then 'B'
--			else 
--				NULL
--		end as fromsup,
--		case
--			when (i.toloc like 'LOST%' and i.toloc <> 'LOST') or i.toloc like 'H0%'
--				then 'B'
--			else 
--				NULL
--		end as tosup
--	from wh1.transmitlog tl 
--		inner join wh1.itrn i on tl.key1 = i.itrnkey
--		inner join wh1.loc l on l.loc = i.toloc --  в ячейку
--		inner join wh1.loc l2 on l2.loc = i.fromloc -- из ячейки
--		left join da_hostzones hz on hz.putawayzone = l.putawayzone --and hz.storerkey = i.storerkey -- в зону
--		left join da_hostzones hz2 on hz2.putawayzone = l2.putawayzone --and hz2.storerkey = i.storerkey -- из зоны
--	where tl.transmitlogkey = @transmitlogkey
----					and ((l.putawayzone like 'BRAK%' and l2.putawayzone not like 'BRAK%')	--Commented by Slanchevskiy 24/09/2010
----				     or (l2.putawayzone like 'BRAK%' and l.putawayzone not like 'BRAK%'))	--Commented by Slanchevskiy 24/09/2010
--					and (i.toloc != 'PICKTO' and i.fromloc != 'PICKTO')
--					and (i.toloc != 'LOST' and i.fromloc != 'LOST')							--Added by Slanchevskiy 24/09/2010
----					and (i.toloc != 'LOST2' and i.fromloc != 'LOST2')						--Added by Slanchevskiy 30/10/2010
--					and (
--						isnull(hz.hostzone,'UNKNOWN') != isnull(hz2.hostzone, 'UNKNOWN')
--						or (i.fromloc <> i.toloc and (i.fromloc like 'LOST%' or i.toloc like 'LOST%'))
--					)			


															
print '2. передача результата'
select 	'MOVE' as filetype, r.* from #Result r

drop table #Result


