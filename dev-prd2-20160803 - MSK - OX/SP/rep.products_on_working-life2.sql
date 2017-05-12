-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 21.01.2010 (НОВЭКС)
-- Описание: Отчет товар по срокам годности ПУО
--	...
-- =============================================
ALTER PROCEDURE [rep].[products_on_working-life2] ( 
									
	@wh varchar(30),
	@storer varchar(15),
	@asn varchar(15),
	@day int
)

as

create table #table_result (
		Sku varchar(50) not null, -- Код товара
		Descr varchar(60) null, -- Описание товара
		Qty decimal(22,0) not null, -- Кол-во товара
		NumberPal varchar(18) null, -- № палетты
		Date datetime not null, -- Дата приемки
		Proizved datetime null, -- Произведен
		GodDo datetime null, -- Годен до
		KolDay int null, -- Кол-во дней годности
		SrokGod datetime null -- Срок годности
)

declare @sql varchar(max)

set @sql='
insert into #table_result
select 	rd.sku Sku,
		sk.descr Descr,
		rd.qtyreceived Qty,
		rd.toid NumberPal,
		convert(datetime,convert(varchar(11),r.receiptdate,112)) Date,
		rd.lottable04 Proizved,
		null GodDo,
		sk.shelflife KolDay,
		dateadd(dy,sk.shelflife,rd.lottable04) SrokGod
from '+@wh+'.RECEIPTDETAIL as rd
	left join '+@wh+'.sku as sk on rd.sku=sk.sku and rd.storerkey=sk.storerkey
	left join '+@wh+'.RECEIPT as r on rd.receiptkey=r.receiptkey
where rd.receiptkey='''+@asn+'''
		and rd.storerkey='''+@storer+'''
		and sk.lottablevalidationkey=''MANUFAC''
		and rd.qtyreceived<>0
'
print (@sql)
exec (@sql)

--select *
--from #table_result

set @sql='
insert into #table_result
select 	rd.sku Sku,
		sk.descr Descr,
		rd.qtyreceived Qty,
		rd.toid NumberPal,
		convert(datetime,convert(varchar(11),r.receiptdate,112)) Date,
		null Proizved,
		rd.lottable05 GodDo,
		null KolDay,
		rd.lottable05 SrokGod
from '+@wh+'.RECEIPTDETAIL as rd
	left join '+@wh+'.sku as sk on rd.sku=sk.sku and rd.storerkey=sk.storerkey
	left join '+@wh+'.RECEIPT as r on rd.receiptkey=r.receiptkey
where rd.receiptkey='''+@asn+'''
		and rd.storerkey='''+@storer+'''
		and sk.lottablevalidationkey=''EXPIRED''
		and rd.qtyreceived<>0
'
print (@sql)
exec (@sql)

select  *
from #table_result
where cast(SrokGod - Date as int)<=@day
order by sku

drop table #table_result

