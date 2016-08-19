-- =============================================
-- Автор:		Смехнов Антон
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 27.10.2009 (НОВЭКС)
-- Описание: Пересчет параметров пополнения для выбранной ячейки

-- =============================================
ALTER PROCEDURE [WH2].[novex_RecalcLoc]
			@loc varchar(10)
AS

print 'Отбираем ячейки по которым требуется провести пересчет параметров пополнения'
print 'Ячейки в которых лежит товар группы X исключаются из рассмотрения'
select sxl.loc, loc.cubiccapacity, cast(0 as float) skucount
into #selectedLocs
from SKUxLOC sxl join LOC on (sxl.loc=LOC.loc)
				 join SKU on (sxl.storerkey=SKU.storerkey and sxl.sku=SKU.sku)
where (sxl.allowreplenishfromcasepick=1 or sxl.allowreplenishfrombulk=1)
		AND
	 (sxl.loc=@loc and isnull(@loc,'')<>'')
group by sxl.loc, loc.cubiccapacity
having max(sku.abc)<>'X'
--select * from #selectedLocs

print '...Подсчитываем и запоминаем количество товаров, которым данная ячейка назначена ячейкой отбора'
print '...Для группы А каждую позицию считаем как 2, для группы B и C как 1, для группы D 0.5'
update #selectedLocs
set	SKUCOUNT=isnull((select sum(case when s.abc='A' then 2 when s.abc='D' then 0.5 else 1 end) 
					from WH2.skuxloc sxl join WH2.sku s on (sxl.storerkey=s.storerkey and sxl.sku=s.sku)
					where  sxl.loc=#selectedLocs.loc and
					((sxl.allowreplenishfromcasepick=1 or sxl.allowreplenishfrombulk=1))
				  ),0)
--select * from #selectedLocs
--drop table #selectedLocs

print '3333333333333333333333333333333333333333333333333333333333333333333333333333'
	print '...Рассчитываем и обновляем пороги пополнения для всех выбранных ячеек'
	----- при расчете уменьшаем суммарный доступный объем ячейки на 2% для каждой ассортиментной позиции
	----- т.е. в ячейке с одним товаром доступный объем - 98%, с двумя - 96%, с тремя 94% и т.д. //см. (1-(sc.skucount+...)*0.02)

	update sxl
	set
		sxl.qtylocationminimum=	--  20% от максимума
					 1 + -- +1 нужно для гарантированного наличия нижнего порога пополнения, что б точно не "0"
						CEILING(CEILING( ( (sl.cubiccapacity*( 1 -  case when (sl.skucount)*0.02<0.8 then (sl.skucount)*0.02
																		 else 0.2
																	end
										   ))--выше посчитан объем ячейки уменьшенный с учетом количества товарных позиций
										   / --если в ячейку уже назначено более 7-ми товаров, то допустимый объем ячейки устанавливается фиксированно равным 20% от всего объема
										   (sl.skucount)
										 )
										 * --выше посчитан объем выделяемый на одну условную ассортиментную позицию товара в данной ячейке
										 (case isnull(s.abc,'C') when 'A' then 2 when 'D' then 0.5 else 1 end) 
										 / --выше посчитан объем выделяемый под данную ассортиментную позицию
										 (case when s.stdcube=0 then 0.0015 else s.stdcube end)
										 / --выше посчитано максимальное количество штук товара
										 p.casecnt)	--считаем коробки; округляем верх
								*p.casecnt*0.2), --целую часть от коробок пересчитываем в штуки и берем 20%; округляем вверх
		sxl.qtylocationlimit=
						CEILING(CEILING( ( (sl.cubiccapacity*( 1 -  case when (sl.skucount)*0.02<0.8 then (sl.skucount)*0.02
																		 else 0.2
																	end
										   ))--выше посчитан объем ячейки уменьшенный с учетом количества товарных позиций
										   / --если в ячейку уже назначено более 7-ми товаров, то допустимый объем ячейки устанавливается фиксированно равным 20% от всего объема
										   (sl.skucount)
										 )
										 * --выше посчитан объем выделяемый на одну условную ассортиментную позицию товара в данной ячейке
										 (case isnull(s.abc,'C') when 'A' then 2 when 'D' then 0.5 else 1 end) 
										 / --выше посчитан объем выделяемый под данную ассортиментную позицию
										 (case when s.stdcube=0 then 0.0015 else s.stdcube end)
										 / --выше посчитано максимальное количество штук товара
										 p.casecnt)	--считаем коробки; округляем верх
								*p.casecnt), --целую часть от коробок пересчитываем в штуки; округляем вверх
		sxl.replenishmentcasecnt=p.casecnt,
		sxl.editwho='novex_SetPickLoc',
		sxl.editdate=getdate()
	from
		WH2.skuxloc sxl join #selectedLocs sl on (	sxl.loc=sl.loc )
						join WH2.sku s on (sxl.storerkey=s.storerkey and sxl.sku=s.sku)
						join WH2.pack p on (s.packkey=p.packkey)
	where sxl.allowreplenishfromcasepick=1 or sxl.allowreplenishfrombulk=1

	print '...Рассчитываем и обновляем требуемое количество единиц пополнения и приоритет пополнения'
	update sxl
	set	sxl.replenishmentseverity=(sxl.qtylocationlimit-sxl.qty)/p.casecnt,
		sxl.REPLENISHMENTPRIORITY=case when sxl.qty<sxl.qtylocationminimum then '4' else '9' end
	from
		WH2.skuxloc sxl join #selectedLocs sl on (	sxl.loc=sl.loc )
						join WH2.sku s on (sxl.storerkey=s.storerkey and sxl.sku=s.sku)
						join WH2.pack p on (s.packkey=p.packkey)
	where (sxl.allowreplenishfromcasepick=1 or sxl.allowreplenishfrombulk=1) and (sxl.qty<sxl.qtylocationlimit)

