ALTER PROCEDURE [dbo].[rep40_Replenishment_old] (
@wh varchar(10),
@externorderkey varchar (32),
@orderkey varchar(10),
@typereplenishment varchar (1))
as

declare @sql varchar(max)
declare @orderjoin varchar(max)
declare @orderwhere varchar(max)

--set @typereplenishment = '1' -- пополнение ячеек штучного отбора из ячеек коробочного отбора
--set @typereplenishment = '2' -- пополнение ячеек коробочного отбора из ячеек паллетного хранения
--set @typereplenishment = '3' -- пополнение ячеек штучного отбора из ячеек коробочного отбора и паллетного хранения

create table #result (
		descr varchar(60) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		sku varchar(50) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		storerkey varchar(15) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),	
--		descr varchar(60) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),	
		loc_in varchar(15) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),		-- пополняемая ячейка
		loc_out varchar(15) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),		-- пополняющая ячейка
		id_out varchar(15) COLLATE Cyrillic_General_CI_AS DEFAULT (''),					-- пополняющая паллета
		qtypick decimal(22, 5) NOT NULL DEFAULT (0),									-- количество штук
		qtycase decimal(22, 5) NOT NULL DEFAULT (0))									-- количество коробок

-- формирование списка товаров по заказу
if (@orderkey  is not null) or (@externorderkey is not null)
	begin
		set @orderjoin =
			' join '+@wh+'.orderdetail od on od.sku = sl.sku and od.storerkey = sl.storerkey'
		set @orderwhere = 
			' and od.openqty > 0 and od.status <= 14' +
			case when @orderkey is null then '' else ' and od.orderkey = '''+@orderkey+'''' end +
			case when @externorderkey is null then '' else ' and od.externorderkey = '''+@externorderkey+''' ' end
	end
else
	begin
		set @orderjoin = ''
		set @orderwhere = ''
	end

-- ячейки штучного отбора требующие пополнения 
select sl.serialkey, s.descr, sl.sku, sl.storerkey, sl.loc, sl.qty, sl.qtylocationlimit, l.comminglesku, p.casecnt
into #pickneed
from wh1.skuxloc sl join WH1.loc l on sl.loc = l.loc
join wh1.sku s on s.sku = sl.sku and s.storerkey = sl.storerkey
left join wh1.pack p on p.packkey = s.packkey 
where 1=2

set @sql = 
'insert into #pickneed
select sl.serialkey, s.descr, sl.sku, sl.storerkey, sl.loc, sl.qty, sl.qtylocationlimit, l.comminglesku, p.casecnt
from '+@wh+'.skuxloc sl join '+@wh+'.loc l on sl.loc = l.loc
join '+@wh+'.sku s on s.sku = sl.sku and s.storerkey = sl.storerkey ' +
@orderjoin+
' left join '+@wh+'.pack p on p.packkey = s.packkey 
where sl.replenishmentpriority <= 4
and ' +
case @typereplenishment when '1' then '(l.locationtype = ''PICK'') ' 
						when '2' then '(l.locationtype = ''CASE'') '
						when '3' then '(l.locationtype = ''PICK'') '
end +
'and p.packkey != ''STD'' --and p.packkey != ''CABEL''
and (sl.loc != ''BRAK'' and sl.loc != ''BRAKPRIEM'' and sl.loc != ''NEIZVESTNO'' and 
		sl.loc != ''QC'' and sl.loc != ''LOST'' and sl.loc != ''NETSTRATEG'' and sl.loc != ''STAGE'' and sl.loc != ''BRAKPROG'')
and sl.qtylocationlimit > 0 -- отбрасываем ячейки у которых максимальное количество НОЛЬ
and sl.qty < sl.qtylocationlimit -- отбрасываем ячейки у ктоторых текущее количество меньше максимального (навсякий случай)
and not (l.comminglesku = ''0'' and sl.qty != 0) -- отбрасываем не пустые ячеки в котрых нельзя смешивать партии
'+@orderwhere +
' order by sl.qtylocationlimit'
print @sql
exec (@sql)


--select 'ячейки для пополнения'
--select * from #pickneed order by sku

-- ячейки паллетного хранения из которых пополнять
select lli.serialkey ,lli.sku, lli.storerkey, sl.loc, lli.id,
 (lli.qty - lli.qtyallocated) qtyaccess, p.casecnt,
 p.packkey, l.comminglesku
into #palletaccess
from WH1.skuxloc sl join WH1.lotxlocxid lli on sl.loc = lli.loc and sl.sku = lli.sku and sl.storerkey = lli.storerkey
join WH1.sku s on s.sku = sl.sku and s.storerkey = sl.storerkey
join WH1.loc l on l.loc = sl.loc 
left join WH1.pack p on p.packkey = s.packkey
where 1=2

set @sql =
'insert into #palletaccess 
select lli.serialkey, lli.sku, lli.storerkey, sl.loc, lli.id,
 (lli.qty - lli.qtyallocated) qtyaccess, p.casecnt,
 p.packkey, l.comminglesku
from '+@wh+'.skuxloc sl join '+@wh+'.lotxlocxid lli on sl.loc = lli.loc and sl.sku = lli.sku and sl.storerkey = lli.storerkey
join '+@wh+'.sku s on s.sku = sl.sku and s.storerkey = sl.storerkey
join '+@wh+'.loc l on l.loc = sl.loc 
left join '+@wh+'.pack p on p.packkey = s.packkey
where 1=1 
--and sl.replenishmentpriority >= 8 -- приоритет пополнения ниже либо равен 8
and ' +
case @typereplenishment when '1' then '(l.locationtype = ''CASE'') '  -- выбираем ячейки коробочного хранения
						when '2' then '(l.locationtype = ''OTHER'' and ltrim(rtrim(lli.id)) != '''' ) ' -- выбираем ячейки паллетного хранения
						when '3' then '(l.locationtype = ''CASE'' or (l.locationtype = ''OTHER'' and ltrim(rtrim(lli.id)) != '''' )) ' -- выбираем ячейки коробочного и паллетного хранения
end + 
'and (l.loc != ''BRAK'' and l.loc != ''BRAKPRIEM'' and l.loc != ''NEIZVESTNO'' and 
		l.loc != ''QC'' and l.loc != ''LOST'' and l.loc != ''NETSTRATEG'' and l.loc != ''BRAKPROG'') -- отбрасываем всякие неправильные ячейки
and p.packkey != ''STD'' --and p.packkey != ''CABEL''
and lli.qty > 0 -- отбрасываем ячейки с нулевым количеством
and lli.qty - lli.qtyallocated > 0 -- отбрасываем ячейки в которых все количество зарезервировано
order by qtyaccess'

exec (@sql)

--select 'пополняющие ячейки'
--select * from #palletaccess order by sku

declare @ski int, -- ключ таблицы
		@loc_in varchar(15), -- пополняемая ячейка
		@sku varchar(50), -- товар
		@storerkey varchar(15), -- владелец
		@qty decimal(22, 5), -- необходимое количество
		@qtylocationlimit decimal(22, 5), -- максимальновозможное количество
		@comminglesku varchar(1), -- смешивать/несмешивать партии 1/0
		@descr varchar (60), -- описание
		@casecnt decimal(22, 5), -- количество на коробоке

		@sko int, -- ключ таблицы
		@loc_out varchar(15), -- пополняющая ячейка
		@id_out varchar(15), -- пополняющая палета
		@qtyacc decimal(22, 5) -- количество на пополняющей единице


while ( (select count(serialkey) from #pickneed) > 0  )
	begin
		select top (1) @ski = serialkey, @descr = descr, @loc_in = loc, @sku = sku, @storerkey = storerkey, @qty = (qtylocationlimit - qty), @comminglesku = comminglesku, @casecnt = casecnt, @qtylocationlimit = qtylocationlimit from #pickneed
		delete from #pickneed where serialkey = @ski
		if @comminglesku = '1' -- смешивать партии
			begin
				while ((select count(serialkey) from #palletaccess where sku = @sku and storerkey = @storerkey) > 0 and @qty > 0) -- перебирать пополняющие ячейки паллеты пока не закончатся или количество 
					begin
						select top(1) @sko = serialkey, @loc_out = loc, @id_out = id, @qtyacc = qtyaccess  
							from #palletaccess 
							where sku = @sku and storerkey = @storerkey 
							order by qtyaccess
						if @qty = @qtyacc -- количество для пополнения равно количеству на пополняющей паллете
							begin
								set @qty = 0
								delete from #palletaccess where serialkey = @sko
								insert into #result (descr, sku, storerkey, loc_in, loc_out, id_out, qtypick, qtycase) 
											values (@descr, @sku, @storerkey, @loc_in, @loc_out, @id_out, @qtyacc, floor(@qtyacc/@casecnt))
							end
						else
							begin
								if @qty > @qtyacc
									begin
										set @qty = @qty - @qtyacc
										delete from #palletaccess where serialkey = @sko
										insert into #result (descr, sku, storerkey, loc_in, loc_out, id_out, qtypick, qtycase) 
													values (@descr, @sku, @storerkey, @loc_in, @loc_out, @id_out, @qtyacc, floor(@qtyacc/@casecnt))
									end
								else
									begin
										set @qtyacc = @qtyacc - @qty
										update #palletaccess set qtyaccess = @qtyacc where serialkey = @sko
										insert into #result (descr, sku, storerkey, loc_in, loc_out, id_out, qtypick, qtycase) 
													values (@descr, @sku, @storerkey, @loc_in, @loc_out, @id_out, @qty, floor(@qty/@casecnt))
										set @qty = 0
									end
							end
					end
			end
		if @comminglesku = '0' -- не смешивать партии
			begin
				if (select count(serialkey) from #palletaccess where sku = @sku and storerkey = @storerkey) > 0
					begin
						select top(1) @sko = serialkey, @loc_out = loc, @id_out = id, @qtyacc = qtyaccess  from #palletaccess where sku = @sku and storerkey = @storerkey order by qtyaccess -- сортируем паллету/ячейку с наименьшим количеством
						if @qtylocationlimit < @qtyacc
							begin
								update #palletaccess set qtyaccess = (@qtyacc - @qty) where serialkey = @sko
								insert into #result (descr, sku, storerkey, loc_in, loc_out, id_out, qtypick, qtycase) 
											values (@descr, @sku, @storerkey, @loc_in, @loc_out, @id_out, @qty, floor(@qty/@casecnt))
							end
						else
							begin
								delete from #palletaccess where serialkey = @sko
								insert into #result (descr, sku, storerkey, loc_in, loc_out, id_out, qtypick, qtycase) 
											values (@descr, @sku, @storerkey, @loc_in, @loc_out, @id_out, @qtyacc, floor(@qtyacc/@casecnt))
							end
					end
				set @qty = 0
			end
	end

--select * from #result order by id_out
--select * from #palletaccess

select * from #result

drop table #palletaccess
drop table #pickneed
drop table #result

