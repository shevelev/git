ALTER PROCEDURE [dbo].[proc_InventoryResult] (
		@wh varchar (10),
		@skugroup varchar (10),
		@hostzone varchar (20),
		@storerkey varchar (15)
)

AS

--##################################### СОЗДАНИЕ КОРРЕКТИРОВКИ

create table #InventoryDetail(
	[whseid] [varchar] (10) NULL, -- схема
	[skugroup] [varchar](10) NULL, -- вид товара
	[storerkey] [varchar](15) NULL, -- владелец/бизнесс
	[sku] [varchar](10) NULL, -- код товара
	[factqty] [decimal](22, 5) NULL, -- фактическое количество
	[deltaqty] [decimal](22, 5) NULL, -- отклонение в количестве
	[loc] [varchar](10) NULL, -- ячейка
	[sklad] [varchar](10) NULL ) -- host зона

declare @sql varchar (max),
		@adddate datetime,    -- дата/время формирования утвержденной инвентаризации
		@invkey varchar (10), -- номер инвентаризации
		@Currdate datetime    -- текущая дата/время (время запуска формирования инвентаризации)

print 'получаем дату/время последней утвержденной инвентаризации'
select @adddate = max(adddate) from DA_InventoryHead where [status] = 1 and whseid = @wh
if @adddate is null set @adddate = '19010101 00:00:00'
set @currdate = getdate()

print 'выбираем циклические инвентаризации с терминала'
	set @sql =
	'insert into #InventoryDetail (whseid, skugroup, sku, storerkey, factqty, deltaqty, loc, sklad)
		select '''+@wh+''', s.skugroup, i.sku, i.storerkey, 0, i.qty, i.toloc, null
		from '+@wh+'.transmitlog t join '+@wh+'.itrn i on t.key3 = i.itrnkey
			join '+@wh+'.loc l on l.loc = i.toloc
			join '+@wh+'.sku s on i.sku = s.sku and i.storerkey = s.storerkey
--			join '+@wh+'.hostzones h on h.putawayzone = l.putawayzone
		where t.adddate > '''+convert(varchar(19),@adddate,112)+' '+convert(varchar(19),@adddate,114)+''' 
			and t.adddate < '''+convert(varchar(19),@currdate,112)+' '+convert(varchar(19),@currdate,114)+'''
			and t.tablename = ''adjustment'' and t.eventcategory = ''E''
			and i.sourcetype = ''ntrCCDetailAdd'' -- RF циклическая инвентаризация с терминала!''
	--		and s.skugroup =''@skugroup''
			and i.storerkey ='''+ @storerkey+''''

print (@sql)
	exec (@sql)

print'ИНВЕНТАРИЗАЦИЯ С РАБОЧЕЙ СТАНЦИИ'
	set @sql =
	'insert into #InventoryDetail (whseid, skugroup, sku, storerkey, factqty, deltaqty, loc, sklad)
		select '''+@wh+''', s.skugroup, ad.sku, ad.storerkey, 0, ad.qty, ad.loc, null
		from '+@wh+'.transmitlog t 
			join '+@wh+'.itrn i on t.key3 = i.itrnkey
			join '+@wh+'.adjustmentdetail ad on ad.adjustmentkey = t.key1 and ad.adjustmentlinenumber = t.key2
			join '+@wh+'.sku s on ad.sku = s.sku and ad.storerkey = s.storerkey
		where t.adddate > '''+convert(varchar(19),@adddate,112)+' '+convert(varchar(19),@adddate,114)+''' 
			and t.adddate < '''+convert(varchar(19),@currdate,112)+' '+convert(varchar(19),@currdate,114)+'''
			and t.tablename = ''adjustment'' and t.eventcategory = ''E''
			and (i.sourcetype = ''ntrAdjustmentDetailAdd'' and ad.reasoncode = ''Gen Adjust'') -- ИНВЕНТАРИЗАЦИЯ С РАБОЧЕЙ СТАНЦИИ
		--	and s.skugroup = ''@skugroup''
			and ad.storerkey = '''+@storerkey+''''

print (@sql)
	exec (@sql)

print'определение ХОСТ-склада'
	set @sql =
		'update ir set ir.sklad = hz.hostzone			
			from #InventoryDetail ir join '+@wh+'.loc l on ir.loc = l.loc
			join '+@wh+'.hostzones hz on l.putawayzone = hz.putawayzone and hz.storerkey = ir.storerkey

		update ir set ir.sklad = hz.hostzone
		from #InventoryDetail ir join '+@wh+'.hostzones hz on ''SKLAD'' = hz.putawayzone and hz.storerkey = ir.storerkey
		where ir.sklad is null'
	exec (@sql)

print 'удаление из выборки данных, не относяхися к складу'
		delete from #inventorydetail where sklad != @hostzone

	-- создание таблицы
		select identity (int, 1,1) id, i.skugroup, i.storerkey, i.sku, 
				sum(factqty) factqty, 
				sum (deltaqty) deltaqty, i.sklad, s.descr 
		into #result 
		from #InventoryDetail i 
			join wh1.sku  s on s.sku = i.sku and s.storerkey = i.storerkey and 2=1	
		group by i.skugroup, i.storerkey, i.sku, i.loc, i.sklad, s.descr

print 'подсчет дельты количества товара'
		set @sql =
		'insert into #result
			select i.skugroup, i.storerkey, i.sku, sum(factqty) factqty, sum (deltaqty) deltaqty, i.sklad, s.descr
			from #InventoryDetail i 
				join '+@wh+'.sku  s on s.sku = i.sku and s.storerkey = i.storerkey
			group by i.skugroup, i.storerkey, i.sku, i.loc, i.sklad, s.descr'
		exec (@sql)
/*
print'определение зон инвентаризации'

	if @hostzone != 'ЦС+КОНС'
		begin
			set @sql = 
			'insert into #result (skugroup, storerkey, sku, factqty, deltaqty, sklad, descr)
				select s.skugroup, sl.storerkey, sl.sku, sum (sl.qty-sl.qtyallocated-sl.qtypicked+sl.qtyexpected) factqty, 0 deltaqty, '''+@hostzone+''' skald, s.descr
				from '+@wh+'.skuxloc sl join '+@wh+'.loc l on sl.loc = l.loc
					join '+@wh+'.hostzones hz on hz.putawayzone = l.putawayzone
					join '+@wh+'.sku s on s.sku = sl.sku and s.storerkey = sl.storerkey
				where hz.hostzone = '''+@hostzone+'''
					and sl.storerkey = '''+@storerkey+'''
			--		and s.skugroup = ''@skugroup''
					and sl.qty !=0
				group by s.skugroup, sl.storerkey, sl.sku, s.descr'
			exec (@sql)
		end
	else 
		begin
-- sklad
set @sql = 
'insert into #result (skugroup, storerkey, sku, factqty, deltaqty, sklad, descr)
		select s.skugroup, sl.storerkey, sl.sku, sum (sl.qty-sl.qtyallocated-sl.qtypicked+sl.qtyexpected) factqty, 0 deltaqty, '''+@hostzone+''' sklad, s.descr
from '+@wh+'.skuxloc sl join '+@wh+'.loc l on sl.loc = l.loc
			join '+@wh+'.sku s on s.sku = sl.sku and s.storerkey = sl.storerkey
		where not l.putawayzone in (select putawayzone from '+@wh+'.hostzones where putawayzone != ''ЦС+КОНС'')
			and sl.storerkey = '''+@storerkey+'''
		--	and s.skugroup = ''@skugroup''
			and sl.qty !=0
		group by s.skugroup, sl.storerkey, sl.sku, s.descr'
exec (@sql)
	end
*/
print'проверка наличия данных для вставки в таблицы инвентаризации'
if (select count (sku) from #result) > 0
	begin
		exec dbo.DA_GetNewKey 'wh1','INVKEY',@invkey output	
		set @sql =
		'insert into da_inventoryhead (whseid, inventorykey, skugroup, storerkey, hostzone, createdate)
			select '''+@wh+''', '''+@invkey+''', null, '''+@storerkey+''', '''+@hostzone+''', '''+convert(varchar(19),@currdate,112)+' '+convert(varchar(19),@currdate,114)+''''

		exec (@sql)

		set @sql =
		'insert into da_inventorydetail (whseid, inventorykey, inventorydetailkey, skugroup, sklad, storerkey, sku, factqty, deltaqty, descr)
			select '''+@wh+''', '''+@invkey+''', right(''000000000''+convert(varchar(10),id ),10), skugroup, sklad, storerkey, sku, factqty, deltaqty, descr
			from #result'
		exec (@sql)
	end
--else
--	print 'для М-Видео приходиться НАСИЛЬНО создавать инвентаризацию т.к. расхождений практически не бывает'
--
--	if @storerkey='000000001'
--		begin
--			print '1'
--			set @sql =
--			'insert into #result
--				select ''MVideo'' skugroup, i.storerkey, i.sku sku, sum(i.qty) factqty, sum(0) deltaqty, ''1'' sklad, s.descr
--				from '+@wh+'.lotxlocxid i 
--					join '+@wh+'.sku  s on s.sku = i.sku and s.storerkey = i.storerkey
--				where i.storerkey='''+@storerkey+''' and i.qty>0
--				group by i.storerkey, i.sku, s.descr'
--			exec (@sql)
--			
--			
--			exec dbo.DA_GetNewKey 'wh1','INVKEY',@invkey output	
--			print '2'
--			set @sql =
--			'insert into da_inventoryhead (whseid, inventorykey, skugroup, storerkey, hostzone, createdate)
--				select '''+@wh+''', '''+@invkey+''', null, '''+@storerkey+''', '''+@hostzone+''', '''+convert(varchar(19),@currdate,112)+' '+convert(varchar(19),@currdate,114)+''''
--
--			exec (@sql)
--			print '3'
--			set @sql =
--			'insert into da_inventorydetail (whseid, inventorykey, inventorydetailkey, skugroup, sklad, storerkey, sku, factqty, deltaqty, descr)
--				select '''+@wh+''', '''+@invkey+''', right(''000000000''+convert(varchar(10),id ),10), skugroup, sklad, storerkey, sku, factqty, deltaqty, descr
--				from #result'
--			exec (@sql)
--		end




print 'вывод результатов'
set @sql =
'select distinct '''+@wh+''' whseid, hz.hostzone, '''+convert(varchar(19),@currdate,103)+' '+convert(varchar(19),@currdate,114)+''' currdate, s.company, id.inventorykey, id.skugroup, id.sku, id.storerkey, sum (id.factqty) factqty, sum(id.deltaqty) deltaqty, id.sklad, id.descr
from da_inventorydetail id join '+@wh+'.storer s on s.storerkey = id.storerkey
join '+@wh+'.hostzones hz on id.sklad = hz.hostzone
where inventorykey = '+@invkey + '
group by hz.hostzone, s.company, id.inventorykey, id.skugroup, id.sku, id.storerkey, id.sklad, id.descr'
exec (@sql)

drop table #result
drop table #InventoryDetail

