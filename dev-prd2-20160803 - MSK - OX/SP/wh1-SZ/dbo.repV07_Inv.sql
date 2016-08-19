-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 21.12.2009 (НОВЭКС)
-- Описание: Потвержденная инвентаризация
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV07_Inv] ( 
									
	@wh varchar(30),
	@storer varchar(20),
	@datebegin datetime,
	@dateend datetime,
	@sku varchar(50)

)

as


create table #table_invent_ter (
		Date varchar(10), -- Дата
		Who varchar(18) not null, -- Ревизор
		Storer varchar(15) not null, -- Владелец
		Sku varchar(50) not null, -- Код товара
		Lot varchar(10) not null, -- Партия
		Loc varchar(10) not null, -- Ячейка
		KeyPack varchar(50) null, -- Ключ упаковки
		Ed varchar(10) null, -- Единица измерения
		Qty decimal(22,2) not null -- Подсчитанное кол-во
)

create table #tp (
		Date varchar(10), -- Дата
		Who varchar(18) not null, -- Ревизор
		Storer varchar(15) not null, -- Владелец
		Company varchar(45) null,
		Sku varchar(50) not null, -- Код товара
		Descr varchar(60) null, -- Наименование товара
		Lot varchar(10) not null, -- Партия
		Loc varchar(10) not null, -- Ячейка
		KeyPack varchar(50) null, -- Ключ упаковки
		Ed varchar(10) null, -- Единица измерения
		Qty decimal(22,2) not null, -- Подсчитанное кол-во
		Raznica int null -- Списание
)

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(10)

set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(10),@dateend+1,112)

/*Данные по инвентаризации, которые заполняют ревизоры*/
set @sql='
insert into #table_invent_ter
select convert(varchar(10),ph.adddate,112) Date,
		ph.addwho Who,
		ph.storerkey Storer,
		ph.sku Sku,
		ph.lot Lot,
		ph.loc Loc,
		ph.packkey KeyPack,
		ph.uom Ed,
		ph.qty Qty

from '+@wh+'.PHYSICAL ph		
where 1=1 '+case when @storer ='Любой' then 'and (ph.storerkey=''000000001''
													or ph.storerkey=''219''
													or ph.storerkey=''5854''
													or ph.storerkey=''6845''
													or ph.storerkey=''92'')' 
												else 'and ph.storerkey='''+@storer+'''' end + '
			and (ph.adddate between '''+@bdate+''' and '''+@edate+''')
			and ph.status=''9''
			'+case when @sku is null then '' else 'and ph.sku = '''+@sku+'''' end + '
'

print (@sql)
exec (@sql)

--select *
--from #table_invent_ter ter
--order by ter.date, ter.who, ter.storer, ter.sku

set @sql='
insert into #table_invent_ter
select convert(varchar(10),ph.editdate,112) Date,
		ph.editwho Who,
		ph.storerkey Storer,
		ph.sku Sku,
		ph.lot Lot,
		ph.loc Loc,
		ph.packkey KeyPack,
		ph.uom Ed,
		ph.qty Qty

from '+@wh+'.PHYSICAL ph		
where 1=1 '+case when @storer ='Любой' then 'and (ph.storerkey=''000000001''
													or ph.storerkey=''219''
													or ph.storerkey=''5854''
													or ph.storerkey=''6845''
													or ph.storerkey=''92'')' 
												else 'and ph.storerkey='''+@storer+'''' end + '
			and (ph.editdate between '''+@bdate+''' and '''+@edate+''')
			and ph.status=''9''
			and convert(varchar(10),ph.adddate,112)<>convert(varchar(10),ph.editdate,112)
			'+case when @sku is null then '' else 'and ph.sku = '''+@sku+'''' end + '
'

print (@sql)
exec (@sql)

--select *
--from #table_invent_ter ter
--order by ter.date, ter.who, ter.storer, ter.sku

set @sql='
insert into #tp
select ter.Date Date,
		ter.Who Who,
		ter.Storer Storer,
		st.company Company,
		ter.Sku Sku,
		sk.descr Descr,
		ter.Lot Lot,
		ter.Loc Loc,
		ter.KeyPAck KeyPAck,
		ter.Ed Ed,
		ter.Qty Qty,
		i.qty Raznica
from #table_invent_ter ter
		left join '+@wh+'.itrn i on ter.Date = convert(varchar(10),i.adddate,112)
							and ter.Who = i.addwho
							and ter.Storer = i.storerkey
							and ter.Sku = i.sku
							and ter.Lot = i.lot
							and ter.Loc = i.toloc
							and ter.KeyPAck = i.packkey
							and ter.Ed = i.uom
		left join '+@wh+'.sku sk on ter.Storer = sk.storerkey
									and ter.Sku = sk.sku
		left join '+@wh+'.storer st on ter.Storer = st.storerkey
order by ter.date, ter.who, ter.storer, ter.sku
'

print (@sql)
exec (@sql)

delete from #tp
where Raznica is null


select *
from #tp
order by Date


drop table #table_invent_ter
drop table #tp

