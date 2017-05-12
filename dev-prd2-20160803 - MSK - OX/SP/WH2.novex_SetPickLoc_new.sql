-- =============================================
-- Автор:		Смехнов Антон
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 19.08.2009 (НОВЭКС)
-- Описание: Назначение ячеек отбора
--	Данная процедура осуществляет назначение ячеек штучного отбора для
--	указанного товара.
--	...
-- =============================================
ALTER PROCEDURE [WH2].[novex_SetPickLoc_new] 
	@Storer as varchar(15),
	@SkuName as varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--##############################################################################

declare	@zone		varchar(10),
		@SkuPrefix	varchar(50),
		@needLoc	int,
		@abc		varchar(5),
		@newLot		varchar(10),
		@pLOC		varchar(10)

--declare @Storer varchar(15), @SkuName varchar(60)
--select @Storer='219',@SkuName='10223'

print '>>>novex_SetPickLoc  Настройка ячейки пополнения для товара Storer='+isnull(@Storer,'<NULL>')+' Sku='+isnull(@SkuName,'<NULL>')

print 'Создаем пустые таблицы возвращающие набор данных'
	select 			l.LOC,
					l.LOGICALLOCATION,
					l.CUBICCAPACITY,
					cast(0 as float)		SKUCOUNT,
					cast('C' as varchar(5)) ABC,
					l.loclevel,
					cast(0 as int)		SKUSTDCOUNT,
					cast('' as varchar(10)) LOCindex
	into #processingLocs
	from WH2.loc l
	where 1=0

	select * into #selectedLocs from #processingLocs where 1=0
	select * into #PREselectedLocs from #processingLocs where 1=0


print '1.0 Проверяем нужна ли настройка ячейки пополнения'
select @needLoc=WH2.novex_checkNeedSetPickLoc(@Storer,@SkuName)

if (@needLoc>0)
begin 
	print '...Для товара требуется настроить '+cast(@needLoc as varchar)+' ячейку отбора'
	print '...Запоминаем параметры товара'	
	select	@zone=left(s.putawayzone,len(s.putawayzone)-2)+'EA',
			@abc=isnull(s.abc,'C'),
--Здесь устанавливается маска определения "похожих" товаров. Выбирается 1/3 от названия товара.
--В дальнейшем, товары с подобным началом в названии не назначаются в одну ячейку.
			@SkuPrefix=left(s.descr,round(len(s.descr)/3,0))
	from WH2.sku s 
	where (s.storerkey=@Storer and s.sku=@SkuName)

	-------------------------------------------------------------------------------
	print '2.0 Поиск наиболее свободных ячеек в указанной зоне по порядку маршрута'
	print '...Отбираем список ячеек соответствующей зоны'
	print '...Ячейки в которых лежит товар группы X исключаются из рассмотрения'
	insert into #processingLocs
	select 			l.LOC,
					l.LOGICALLOCATION,
					l.CUBICCAPACITY,
					cast(0 as float)		SKUCOUNT,
					cast('C' as varchar(5)) ABC,
					case 
					 when isnull(l.loclevel,0)>0 then l.loclevel
												 else 1
					end	loclevel,
					isnull(Z.PZLEVEL,0)	SKUSTDCOUNT,
					''					LOCindex
	from WH2.loc l
		join WH2.PUTAWAYZONE Z on (l.PUTAWAYZONE=Z.PUTAWAYZONE)
		left join WH2.SKUXLOC sxl on (l.loc=sxl.loc)
		left join WH2.SKU s on (sxl.storerkey=s.storerkey and sxl.sku=s.sku)
	where 
	l.putawayzone = @zone						-- поиск в указанной зоне
	and
	(l.locationtype='PICK')						-- только ячейки штучного отбора
	and
	(l.locationflag='NONE' and l.status='OK')	-- только ячейки с рабочими статусами
	and
	(l.loc like '[1-9]___.[1-9].[1-9]')			-- только стеллажные ячейки
	group by		l.LOC,
					l.LOGICALLOCATION,
					l.CUBICCAPACITY,
					case 
					 when isnull(l.loclevel,0)>0 then l.loclevel
												 else 1
					end,
					isnull(Z.PZLEVEL,0)
	having max(isnull(s.abc,'C'))<>'X'			-- исключаем ячейки с товаром группы X

	print '...Подсчитываем и запоминаем количество товаров, которым данная ячейка назначена ячейкой отбора'
	print '...Для группы А каждую позицию считаем как 2, для группы B и C как 1, для группы D - 1'
	update #processingLocs
	set	SKUCOUNT=isnull((select sum(case when s.abc='A' then 2 when s.abc='D' then 1 else 1 end) 
					from WH2.skuxloc sxl join WH2.sku s on (sxl.storerkey=s.storerkey and sxl.sku=s.sku)
					where  sxl.loc=#processingLocs.loc and
					((sxl.allowreplenishfromcasepick=1 or sxl.allowreplenishfrombulk=1))
				  ),0)
	print '...Запоминаем, самую высокую группу оборачиваемости среди товаров данной ячейке'
	update #processingLocs
	set	ABC=isnull((select min(isnull(s.abc,'C')) from WH2.skuxloc sxl 
											join WH2.sku s on (sxl.storerkey=s.storerkey and sxl.sku=s.sku)
					where  sxl.loc=#processingLocs.loc and
					(sxl.allowreplenishfromcasepick=1 or sxl.allowreplenishfrombulk=1)
			),@abc)
--select * from #processingLocs

	print '...Формируем индекс для сортировки ячеек отбора'
	insert into #PREselectedLocs
		select pl.LOC,pl.LOGICALLOCATION,pl.CUBICCAPACITY,pl.SKUCOUNT,pl.ABC,pl.loclevel,pl.SKUSTDCOUNT,
			--расчет индекса для сортировки ячеек
			case pl.SKUSTDCOUNT
			-----------------------------------------------------------------------------------------
			--нормальное количество товаров в ячейке равно 1 ячека=1 товар
			when 1 then
				case	
						--группа товара D (желательно в одной ячейке 2 товара, максимум 2)
						--сортировка:  желательно ярус 3 [1-D/C/B/A, 0]
						--сортировка:  ярус 1-2 [1-D/C/B/A, 0]
						when isnull(@abc,'C')='D' then 
								case 
									when pl.loclevel>=3 and pl.skucount=1 then '000'
									when pl.loclevel>=3 and pl.skucount=0 then '010'
									when pl.loclevel<=2 and pl.skucount=1 then '020'
									when pl.loclevel<=2 and pl.skucount=0 then '030'
									else 'ZZZ' --ячейка не назначается
									--else replicate('0',3-len(cast((pl.skucount+2)*10 as varchar(3)))) + cast((pl.skucount+2)*10 as varchar(3))
								end	
								+ (char(ascii('Z')-ascii(left(pl.abc,1))+ascii('A')))
						--товара группы A (желательно: 1 ячека=1 товар, максимум 1)
						--сортировка:  [0-D/C/B/A]
						when isnull(@abc,'C')='A' then 
								--replicate('0',3-len(cast(pl.skucount*10 as varchar(3)))) + cast(pl.skucount*10 as varchar(3))
								case 
									when pl.loclevel<=2 and pl.skucount=0 then '000'
									else 'ZZZ' --ячейка не назначается
								end	
								+ (char(ascii('Z')-ascii(left(pl.abc,1))+ascii('A')))
						--основная масса товара, группы B и С (желательно: 1 ячека=1 товар, максимум 2)
						--сортировка:  [0-D/C/B/A, 1-D/C/B/A]
						else
								case 
									when pl.loclevel<=2 and pl.skucount=0 then '000'
									when pl.loclevel<=2 and pl.skucount=1 then '010'
									when pl.loclevel>=3 and pl.skucount=0 then '020'
									when pl.loclevel>=3 and pl.skucount=1 then '030'
									else 'ZZZ' --ячейка не назначается
									--else replicate('0',3-len(cast((pl.skucount+2)*10 as varchar(3)))) + cast((pl.skucount+2)*10 as varchar(3))
								end	
								+ (char(ascii('Z')-ascii(left(pl.abc,1))+ascii('A')))
				end			
			-----------------------------------------------------------------------------------------
			--нормальное количество товаров в ячейке равно 1 ячека=2 товара
			when 2 then  
				case	
						--группа товара A или B (желательно: 1 ячека=1 товар, максимум 1 товар)
						--сортировка:  ярус 1-2 [0-D/C/B/A]
						--сортировка:  ярус 3 и выше запрет размещения
						when isnull(@abc,'C')='A' or isnull(@abc,'C')='B' then 
							case 
							 when pl.loclevel<=2 and pl.skucount=0 then '000'
							 else 'ZZZ' --ячейка не назначается
							end
							+ 
							(char(ascii('Z')-ascii(left(pl.abc,1))+ascii('A')))
						--группа товара D (желательно: 1 ячейка 2 товара, максимум 3 товара)
						--сортировка:  желательно ярус 3 [1-D/C/B/A, 0, 2-D/C/B/A]
						--сортировка:  ярус 1-2 [1-D/C/B/A, 0, 2-D/C/B/A]
						when isnull(@abc,'C')='D' then 
								case 
									when pl.loclevel>=3 and pl.skucount=1 then '000'
									when pl.loclevel>=3 and pl.skucount=0 then '010'
									when pl.loclevel>=3 and pl.skucount=2 then '020'
									when pl.loclevel<=2 and pl.skucount=1 then '030'
									when pl.loclevel<=2 and pl.skucount=0 then '040'
									when pl.loclevel<=2 and pl.skucount=2 then '050'
									else 'ZZZ' --ячейка не назначается
								end	
								+ (char(ascii('Z')-ascii(left(pl.abc,1))+ascii('A')))
						--основная масса товара, группа С (желательно: 1 ячека=2 товара, максимум 3)
						--сортировка:  ярус 1-2 [1-C/D/B/A, 0, 2-C/D/B/A]
						--сортировка:  ярус 3	[0, 1-C/D/B/A]
						else
								case 
									when pl.loclevel<=2 and pl.skucount=1 then '000'
									when pl.loclevel<=2 and pl.skucount=0 then '010'
									when pl.loclevel<=2 and pl.skucount=2 then '020'
									when pl.loclevel>=3 and pl.skucount=0 then '030'
									when pl.loclevel>=3 and pl.skucount=1 then '040'
									else 'ZZZ' --ячейка не назначается
								end	
								+
								case pl.abc
									when 'B' then 'Y'
									when 'A' then 'Z'
									else pl.abc
								end	
				end			
			-----------------------------------------------------------------------------------------
			--нормальное количество товаров в ячейке считаем равным 1 ячека=3 товара
			else --
				case isnull(@abc,'C')
						when 'A' then --группа товара A (желательно: 1 ячека=1 товар, максимум 2)
								--сортировка:  ярус 1-2 [0-D/C/B/A, 1-D/C/B/A, 2-D/C/B/A]
								--сортировка:  ярус 3 и выше запрет размещения
								case 
									when pl.loclevel<=2 and pl.skucount=0 then '000'
									when pl.loclevel<=2 and pl.skucount=1 then '010'
									when pl.loclevel<=2 and pl.skucount=2 then '020'
									else 'ZZZ' --ячейка не назначается
								end	
								+ 
								(char(ascii('Z')-ascii(left(pl.abc,1))+ascii('A')))

						when 'B' then --группа товара B (желательно: 1 ячека=2 товара, максимум 3)
								--сортировка:  ярус 1-2 [1-B/C/D/A, 0, 2]
								--сортировка:  ярус 3   [1-B/C/D/A, 0]
								case 
									when pl.loclevel<=2 and pl.skucount=1 then '000'
									when pl.loclevel<=2 and pl.skucount=0 then '010'
									when pl.loclevel<=2 and pl.skucount=2 then '020'
									when pl.loclevel>=3 and pl.skucount=1 then '030'
									when pl.loclevel>=3 and pl.skucount=0 then '040'
									else 'ZZZ' --ячейка не назначается
								end	
								+
								case pl.abc
									when 'A' then 'Z'
									else pl.abc
								end

						when 'D' then --группа товара D (желательно: 1 ячейка 4 товара, максимум 4)
								--сортировка:  желательно ярус 3 [1-D/C/B/A, 2, 0]
								--сортировка:  ярус 1-2 [2-D/C/B/A, 1, 3, 0]
								case 
									when pl.loclevel>=3 and pl.skucount=1 then '000'
									when pl.loclevel>=3 and pl.skucount=2 then '010'
									when pl.loclevel>=3 and pl.skucount=0 then '020'
									when pl.loclevel<=2 and pl.skucount=2 then '030'
									when pl.loclevel<=2 and pl.skucount=1 then '040'
									when pl.loclevel<=2 and pl.skucount=3 then '050'
									when pl.loclevel<=2 and pl.skucount=0 then '060'
									else 'ZZZ' --ячейка не назначается
								end	
								+ (char(ascii('Z')-ascii(left(pl.abc,1))+ascii('A')))

						else	
								--сортировка:  желательно ярус 1-2 [2-C/D/B/A, 1, 0]
								--сортировка:  ярус 3 [1-D/C/B/A, 0]
								case 
									when pl.loclevel<=2 and pl.skucount=2 then '000'
									when pl.loclevel<=2 and pl.skucount=1 then '010'
									when pl.loclevel<=2 and pl.skucount=0 then '020'
									when pl.loclevel>=3 and pl.skucount=1 then '030'
									when pl.loclevel>=3 and pl.skucount=0 then '040'
									else 'ZZZ' --ячейка не назначается
								end	
								+
								case pl.abc
									when 'B' then 'Y'
									when 'A' then 'Z'
									else pl.abc
								end	
				end
			end	LOCindex
		from #processingLocs pl
		where pl.loc not in	(
					select pl2.loc
					from #processingLocs pl2
						join WH2.skuxloc sxl on (pl2.loc=sxl.loc)
						join WH2.sku s on (sxl.storerkey=s.storerkey and sxl.sku=s.sku)
					where
						s.descr like @SkuPrefix+'%'
						and ((sxl.allowreplenishfromcasepick=1 or sxl.allowreplenishfrombulk=1) 
								and (sxl.qtylocationminimum>0 and sxl.qtylocationlimit>0))
					group by pl2.loc
					)

--	select * from #PREselectedLocs
--	order by LOCindex, pl.logicallocation

	delete from #PREselectedLocs where LOCindex like 'ZZZ%'

	if (@needLoc=1)
	begin
		print '...Отбираем ОДНУ наиболее подходящую ячейку'
		if isnull(@abc,'C')='D'
		begin
			insert into #selectedLocs
			select top 1 *
			from #PREselectedLocs
			order by LOCindex, CUBICCAPACITY, LOGICALLOCATION desc
		end
		else begin
			insert into #selectedLocs
			select top 1 *
			from #PREselectedLocs
			order by LOCindex, CUBICCAPACITY desc, LOGICALLOCATION
		end
	end
	else
	begin
		print '...Отбираем ДВЕ наиболее подходящие ячейки'
		if isnull(@abc,'C')='D'
		begin
			insert into #selectedLocs
			select top 2 *
			from #PREselectedLocs
			order by LOCindex, CUBICCAPACITY, LOGICALLOCATION desc
		end
		else begin
			insert into #selectedLocs
			select top 2 *
			from #PREselectedLocs
			order by LOCindex, CUBICCAPACITY desc, LOGICALLOCATION
		end
	end

--	select * from #processingLocs
--	select * from #selectedLocs 
--	truncate table #selectedLocs

	print '...Добавляем, если необходимо, записи привязки товара ячейке в skuxloc (без установки параметров пополнения)'
	insert into WH2.skuxloc
		 (WHSEID,STORERKEY,		SKU,   LOC,LOCATIONTYPE,qtylocationminimum,qtylocationlimit,replenishmentuom,allowreplenishfromcasepick,allowreplenishfrombulk,REPLENISHMENTPRIORITY, ADDWHO)
	select 'WH2',  @Storer,@SkuName,sl.LOC,		 'PICK',				 0,				  0,			 '2',						  1,				     1,					 '4','novex_SetPickLoc'
	from #selectedLocs sl
		left join WH2.skuxloc sxl on (sl.loc=sxl.loc and sxl.storerkey=@Storer and sxl.sku=@SkuName)
	where sxl.loc is null
	print '...Если запись в SKUXLOC по товару уже была, но не было параметров пополнения, то прописываем флажки пополнения из коробочного и паллетного хранения'
	update sxl
	set	replenishmentuom='2',
		allowreplenishfromcasepick=1,
		allowreplenishfrombulk=1
	from WH2.skuxloc sxl join #selectedLocs sl   on (sl.loc=sxl.loc)
	where (sxl.storerkey=@Storer and sxl.sku=@SkuName)

	print '...Рассчитываем и обновляем пороги пополнения для всех выбранных ячеек'
	----- при расчете уменьшаем суммарный доступный объем ячейки на 10% для каждой ассортиментной позиции
	----- т.е. в ячейке с одним товаром доступный объем - 90%, с двумя - 80%, с тремя 70% и т.д. //см. (1-(sc.skucount+...)/10)
	DECLARE LOCATIONSLIST CURSOR STATIC FOR 
	SELECT LOC FROM #selectedLocs

	OPEN LOCATIONSLIST
	FETCH NEXT FROM LOCATIONSLIST INTO @pLOC

	WHILE @@FETCH_STATUS = 0
	BEGIN
		exec WH2.novex_RecalcLoc @pLOC
		FETCH NEXT FROM LOCATIONSLIST INTO @pLOC
	END

	CLOSE LOCATIONSLIST
	DEALLOCATE LOCATIONSLIST


	print '...Если необходимо добавляем в LOTxLOCxID записи соответствующие назначенным ячейкам'
	--отбираем партию, которую пропишем в LOTxLOCxID
	select storerkey, sku, min(lot) lot
	into #LLD2
	from WH2.lot lot
	where
	(lot.storerkey=@Storer and lot.sku=@SkuName)
	group by storerkey, sku 

	--если товар новый, то создаем пустую партию
	if (select count(*) from #LLD2)=0
	begin
	print '......товар новый, создаем пустую партию'
		exec dbo.DA_GetNewKey 'WH2', 'LOT', @newLot OUTPUT --получаем номер новой партии
		insert into WH2.lotattribute
			(	whseid,	lot,	storerkey,	sku,		addwho,				editwho)
		select	'WH2',	@newLot,@Storer,	@SkuName,	'novex_SetPickLoc',	'novex_SetPickLoc'
		insert into WH2.lot
			(	whseid,	lot,	storerkey,	sku,		addwho,				editwho)
		select	'WH2',	@newLot,@Storer,	@SkuName,	'novex_SetPickLoc',	'novex_SetPickLoc'

		insert into #LLD2
			(	storerkey,	sku,		lot)
		select @Storer,		@SkuName,	@newLot
	end

	print '...Готовим записи для добавления в LOTxLOCxID'
	--select * from #selectedLocs
	select 'WH2' whseid, lld2.lot, sxl.loc, @Storer storerkey, @SkuName sku
	into #newLLD
	from #selectedLocs sxl
		left join WH2.lotxlocxid lld on (sxl.loc=lld.loc and lld.storerkey=@Storer and lld.sku=@SkuName)
		join #LLD2 lld2 on (lld2.storerkey=@Storer and lld2.sku=@SkuName)
	where
		(lld.loc is null)	--запрос возвращает записи только в тех случаях, когда в LOTxLOCxID нет соответствующих записей 

	--добавляем записи в LOTxLOCxID
	insert into WH2.lotxlocxid
		(whseid,lot,loc,storerkey,sku)
	select whseid,lot,loc,storerkey ,sku
	from #newLLD

--drop table #processingLocs
--drop table #selectedLocs
end
else
begin
	if @needLoc=0	print 'Для данного товара уже имеются назначенные ячейки отбора'
			else	print 'Товар привязан к зоне хранения, не требующей назначения ячеек отбора'
end

select * from #selectedLocs


END

