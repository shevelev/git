-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 21.12.2009 (НОВЭКС)
-- Описание: Лист инвентаризации
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV08_Inv_Layout] ( 
									
	@wh varchar(30),
	@check int,
	@storer1 varchar(2),
	@storer2 varchar(2),
	@storer3 varchar(2),
	@storer4 varchar(2),
	@storer5 varchar(2),
	@loc varchar(10),
	@groupT varchar(30),
	@chet int,
	@TypeYa varchar(5)

)

as

create table #result_table (
		Loc varchar(10) not null, -- Ячейка
		Sku varchar(50) not null, -- Код товара
		Descr varchar(60) null, -- Описание товара
		Qty decimal(22,5) not null, -- Кол-во товара
		--Storer varchar(15) null, -- Код владельца
		Company varchar(45) null, -- Название владельца,
		Ch decimal(22,1) null,
		LocType varchar(10) not null
		
)

declare @sql varchar(max),
		@sto2 varchar(max),
		@str varchar(10),
		@i decimal(22,1)



/*Проверка по кол-ву выбранных клиентов*/
set @sto2='('
	if @storer1='1' set @sto2=@sto2+'lotx.storerkey=''000000001''!'
	if @storer2='1' set @sto2=@sto2+'lotx.storerkey=''219''!'
	if @storer3='1' set @sto2=@sto2+'lotx.storerkey=''5854''!'
	if @storer4='1' set @sto2=@sto2+'lotx.storerkey=''6845''!'
	if @storer5='1' set @sto2=@sto2+'lotx.storerkey=''92'''
set @sto2=@sto2+')'
set @sto2 = replace(''+@sto2+'','!l',' or l')
set @sto2 = replace(''+@sto2+'','!','')

--print (@sto2)

if @check=1
begin
	/*Остаток на складе по ячейкам, владельцу и кол-во товара в ячейках*/
	set @sql='
	insert into #result_table
	select 	lotx.loc Loc,
			lotx.sku Sku,
			sk.descr Descr,
			sum(lotx.qty) Qty,
			--lotx.storerkey Storer,
			st.company Company,
			'+case when left(@loc,1)='M' then '(convert(decimal,substring(lotx.loc,4,2))/2) Ch'
				   when (left(@loc,1)='1' or left(@loc,1)='2' or left(@loc,1)='P') then '(convert(decimal,substring(lotx.loc,3,2))/2) Ch'
				   when (left(@loc,1)='B' or left(@loc,1)='D' or left(@loc,1)='S') then 'null'
				end +',
			LocB.locationtype LocType
	from '+@wh+'.LOTXLOCXID lotx
		left join '+@wh+'.SKU sk on lotx.storerkey = sk.storerkey
								and lotx.sku = sk.sku
		left join '+@wh+'.STORER st on lotx.storerkey = st.storerkey
		left join '+@wh+'.LOC locB on lotx.loc=locB.loc
	where	1=1 and '+@sto2+'
				'+case when (@loc='BRAKPRIEM' or @loc='DAMAGE' or @loc='SEZON') then 'and lotx.loc like '''+@loc+'%''' 
						else 'and lotx.loc like '''+@loc+'%.%.%''' end + '
				
	group by lotx.loc, lotx.sku, sk.descr, lotx.storerkey, st.company, LocB.locationtype
	order by lotx.loc, lotx.sku, sk.descr, lotx.storerkey, st.company, LocB.locationtype
	'

	print (@sql)
	exec (@sql)
end
else
begin
	/*Остаток на складе по группе товара, владельцу и кол-во товара в ячейках*/
	set @sql='
	insert into #result_table
	select 	lotx.loc Loc,
			lotx.sku Sku,
			sk.descr Descr,
			sum(lotx.qty) Qty,
			--lotx.storerkey Storer,
			st.company Company,
			null,
			LocB.locationtype LocType
	from '+@wh+'.LOTXLOCXID lotx
		left join '+@wh+'.SKU sk on lotx.storerkey = sk.storerkey
								and lotx.sku = sk.sku
		left join '+@wh+'.STORER st on lotx.storerkey = st.storerkey
		left join '+@wh+'.tariffdetail td on sk.busr3=td.descrip 
											or sk.busr2=td.descrip 
											or sk.busr1=td.descrip
		left join '+@wh+'.LOC locB on lotx.loc=locB.loc
	where	1=1 and '+@sto2+'
				and td.descrip = '''+@groupT+'''
				and (lotx.loc like ''1A%'' or lotx.loc like ''1B%'' or lotx.loc like ''1C%''
								or lotx.loc like ''1D%'' or lotx.loc like ''1E%'' or lotx.loc like ''1F%''
								or lotx.loc like ''1G%'' or lotx.loc like ''1H%'' or lotx.loc like ''1I%''
								or lotx.loc like ''1J%'' or lotx.loc like ''1K%'' or lotx.loc like ''1L%''
								or lotx.loc like ''1M%'' or lotx.loc like ''1N%'' or lotx.loc like ''1O%''
								or lotx.loc like ''1P%'' or lotx.loc like ''1Q%'' or lotx.loc like ''1R%''
								or lotx.loc like ''1S%'' or lotx.loc like ''1T%'' 
								or lotx.loc like ''2S%'' or lotx.loc like ''2T%'' or lotx.loc like ''2U%''
								or lotx.loc like ''2V%'' or lotx.loc like ''2W%'' or lotx.loc like ''2X%''
								or lotx.loc like ''M1A%'' or lotx.loc like ''M1B%'' or lotx.loc like ''M2A%''
								or lotx.loc like ''M2B%'' or lotx.loc like ''M2C%'' or lotx.loc like ''M2D%''
								or lotx.loc like ''M2E%'' or lotx.loc like ''M2F%'' or lotx.loc like ''M2G%''
								or lotx.loc like ''M2H%'' or lotx.loc like ''PA%.%.%'' or lotx.loc like ''PB%''
								or lotx.loc like ''BRAKPRIEM%'' or lotx.loc like ''DAMAGE%'' or lotx.loc like ''SEZON%''
								)
				
	group by lotx.loc, lotx.sku, sk.descr, lotx.storerkey, st.company, LocB.locationtype
	order by lotx.loc, lotx.sku, sk.descr, lotx.storerkey, st.company, LocB.locationtype
	'

	print (@sql)
	exec (@sql)
end

if @check=1
begin
	if (@loc<>'BRAKPRIEM' or @loc<>'DAMAGE' or @loc<>'SEZON')
		begin
			if @chet=1
			begin
				delete from #result_table
				where right(convert(varchar,Ch),2)<>'.5'
			end
			if @chet=2
			begin
				delete from #result_table
				where right(convert(varchar,Ch),2)='.5'				
			end
		end
end

if (@loc<>'BRAKPRIEM' and @loc<>'DAMAGE')
begin
		if @TypeYa='PICK'  
		begin
			delete from #result_table
			where LocType<>'PICK'
		end
		if @TypeYa='CASE'
		begin
			delete from #result_table
			where LocType<>'CASE'
		end
end

select rt.Loc,
		rt.Sku,
		rt.Descr,
		rt.Qty,
		rt.Company,
		rt.Ch,
		rt.LocType
from #result_table rt
where rt.Qty>0
order by rt.Loc


drop table #result_table

