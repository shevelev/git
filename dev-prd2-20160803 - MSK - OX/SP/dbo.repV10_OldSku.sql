-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 14.01.2009 (НОВЭКС)
-- Описание: Отчет по товарам с истекшим и истекающим срокам годности
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV10_OldSku] ( 
									
	@wh varchar(30),
	@storer varchar(15),
	@requestdate varchar(11),
	@sku varchar(15),
	@lot varchar(10),
	@putawayzone varchar(10),
	@check int
)

as

create table #table_result (
--		Storer varchar(15) not null, -- Владелец
		Sku varchar(50) not null, -- Код товара
		Descr varchar(60) null, -- Описание товара
		GroupSku varchar(30) null, -- Группа товара
		Lot varchar(10) not null, -- Партия
		Loc varchar(10) not null, -- Ячейка
		Atr varchar(20) not null, -- Атрибут срока годности
		Life int null, -- Срок годности в днях
		DatePr datetime null, -- Произведен
		DateGod datetime null, -- Годен до
		Kol decimal(22,0) not null, -- Кол-во товара на остатке
		Ost int null -- Осталось дней до конца
)

declare @sql varchar(max),
		@date varchar(11)

--set @RequestDate = dateadd(dy,1,convert(datetime,convert(varchar(11),@RequestDate,112)))
set @RequestDate = convert(datetime,convert(varchar(11),@RequestDate,112))
set @date = convert(varchar(11),@RequestDate,112)

--print (@RequestDate)

set @sql='
insert into #table_result
select --lotx.storerkey Storer,
		lotx.sku Sku,
		sk.descr Descr,
		sk.skugroup2 as GroupSku,
		lotx.lot Lot,
		lotx.loc Loc,
		''E'' Atr,
		null Life,
		null DatePr,
		lotatr.lottable05 DateGod,
		lotx.qty Kol,
		'+case when @check=1 then'-cast(lotatr.lottable05-cast('''+@date+''' as datetime) as int) Ost'
			else'cast(lotatr.lottable05-cast('''+@date+''' as datetime) as int) Ost' end
		+'
from '+@wh+'.lotxlocxid as lotx
	left join '+@wh+'.loc as loc on loc.loc=lotx.loc
	left join '+@wh+'.storer as st on lotx.storerkey=st.storerkey
	left join '+@wh+'.sku as sk on lotx.sku=sk.sku and lotx.storerkey=sk.storerkey
	left join '+@wh+'.lotattribute as lotatr on lotx.lot=lotatr.lot
where isnull(lotatr.lottable05,'''')<> ''''
		and lotx.storerkey='''+@storer+'''
		and sk.lottablevalidationkey=''EXPIRED''
		'+case when isnull(@sku,'')=''  then '' else 'and lotx.sku like '''+@sku+'''' end
			+case when isnull(@lot,'')=''  then '' else 'and lotx.lot like '''+@Lot+'''' end
			+case when @putawayzone<>'SKLAD' then  'and loc.putawayzone='''+@putawayzone+'''' 
				else 'and loc.PUTAWAYZONE not in (select z.PUTAWAYZONE from '+@wh+'.hostzones z) ' end
		+'
		and lotx.qty>0
		'+ case when @check=1 then 'and	cast(lotatr.lottable05-cast('''+@date+''' as datetime) as int)<=0'
				else 'and lotatr.lottable05 between cast('''+@date+''' as datetime)-1 and dateadd(dy,90,'''+@requestdate+''')'	end
		+'
'
print (@sql)
exec (@sql)

--select *
--from #table_result
--order by sku

set @sql='
insert into #table_result
select --lotx.storerkey Storer,
		lotx.sku Sku,
		sk.descr Descr,
		sk.skugroup2 as GroupSku,
		lotx.lot Lot,
		lotx.loc Loc,
		''M'' Atr,
		sk.shelflife Life,
		lotatr.lottable04 DatePr,
		dateadd(dy,sk.shelflife,lotatr.lottable04) DateGod,
		lotx.qty Kol,
		'+case when @check=1 then '-cast(dateadd(dy,sk.shelflife,lotatr.lottable04)-cast('''+@date+''' as datetime) as int) Ost'
			else 'cast(dateadd(dy,sk.shelflife,lotatr.lottable04)-cast('''+@date+''' as datetime) as int) Ost' end
		+'
from '+@wh+'.lotxlocxid as lotx
	left join '+@wh+'.loc as loc on loc.loc=lotx.loc
	left join '+@wh+'.storer as st on lotx.storerkey=st.storerkey
	left join '+@wh+'.sku as sk on lotx.sku=sk.sku and lotx.storerkey=sk.storerkey
	left join '+@wh+'.lotattribute as lotatr on lotx.lot=lotatr.lot
where isnull(lotatr.lottable04,'''')<> ''''
		and lotx.storerkey='''+@storer+'''
		and sk.lottablevalidationkey=''MANUFAC''
		'+case when isnull(@sku,'')=''  then '' else 'and lotx.sku like '''+@sku+'''' end
			+case when isnull(@lot,'')=''  then '' else 'and lotx.lot like '''+@Lot+'''' end
			+case when @putawayzone<>'SKLAD' then  'and loc.putawayzone='''+@putawayzone+'''' 
				else 'and loc.PUTAWAYZONE not in (select z.PUTAWAYZONE from '+@wh+'.hostzones z) ' end
		+'
		and lotx.qty>0
		'+ case when @check=1 then 'and	cast(dateadd(dy,sk.shelflife,lotatr.lottable04)-cast('''+convert(varchar(11),@requestdate,112)+''' as datetime) as int)<=0'
				else 'and dateadd(dy,sk.shelflife,lotatr.lottable04) between cast('''+@date+''' as datetime) and dateadd(dy,90,'''+@requestdate+''')'	end
		+'
'
print (@sql)
exec (@sql)

select *
from #table_result
order by sku

drop table #table_result

