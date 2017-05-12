ALTER PROCEDURE [dbo].[rep05_StorageOptimization](
	@wh varchar(10),
	@psku varchar(10)=null,
	@pstorerkey varchar(10)=null,
	@upFromLevel int = 0
)as


--5. если кол-во+ миним. кол-во влезают в ячейку, то создать в результате запись откуда и куда переместить
--	удалить ячейку-донора из общего списка
--6. если не влезают - дополнить столько сколько можно, уменьшить ячеку-донора на перемещенное кол-во
--7. перейти к пункту 3, если есть еще ячейки с таким товаром
--8.  если обработаны не все товары - перейти к пункту 2
--
--!! при перемещении проверять разрешение на смешение партий и товаров !!
	set nocount on
	-- 1. выбрать ячейки которые содержат неполные паллеты (критерий полности?)
	create table #result (id int identity(1,1), sku varchar(10) collate Cyrillic_General_CI_AS, 
		storerkey varchar(20) collate Cyrillic_General_CI_AS, fromqty decimal(15,3), 
	fromloc varchar(10)  collate Cyrillic_General_CI_AS, toloc varchar(10) collate Cyrillic_General_CI_AS, 
	fromID varchar(10) collate Cyrillic_General_CI_AS, toID varchar(10) collate Cyrillic_General_CI_AS)

	
	select identity(int,1,1)gid, lli.sku, lli.storerkey, lli.loc, max(lli.id)id, max(lli.lot)lot, sum(lli.qty)qty, 
		l.cubiccapacity loccube, l.weightcapacity, 
		l.status locStatus, lli.status skuStatus, l.comminglesku, l.comminglelot, 
		l.loclevel, s.stdcube, sum(lli.qty)*s.stdcube V
	into #global
	from wh40.lotxlocxid lli
		join wh40.loc l on l.loc = lli.loc
		join wh40.sku s on s.sku=lli.sku and s.storerkey=lli.storerkey
	where qtyallocated+qtypicked=0 and l.cubiccapacity>(lli.qty+1)*s.stdcube
		and not logicallocation in ('PROBLEM')
		and not l.loc in ('PICKTO', 'STAGE')
		and l.loc like '08.%' 
		and (isnull(@psku,'')='' or lli.sku = @psku)
		and (isnull(@pstorerkey,'')='' or lli.storerkey = @pstorerkey)
		and loclevel >= @upFromLevel
		--000100300,000100125,000400017
	group by lli.sku, lli.storerkey,l.cubiccapacity,l.weightcapacity, l.status, lli.loc,lli.status,
		l.comminglesku, l.comminglelot,l.loclevel, s.stdcube --, lli.lot
	order by lli.sku
--select * from wh40.lotxlocxid where loc = '08.03J32' ' order by sku, qty

--select * from #global

	--2. выбрать ячейки с одним товаром, отсортировать по товару, кол-ву 
	select distinct identity(int,1,1) id, sku, storerkey into #sku from #global
	print 1
	declare @tolot varchar(10), @sku varchar(10), @storerkey varchar(20), @lotmix INT, @toqty decimal(15,3), 
			@toloc varchar(10), @toID varchar(10),
			@toLocCube decimal(15,3), @toV decimal(15,3), @toSkuCube decimal(15,3)
	declare @fromlot varchar(10), @fromqty decimal(15,3), @fromloc varchar(10), @fromID varchar(10),
			@fromLocCube decimal(15,3), @fromV decimal(15,3), @fromSkuCube decimal(15,3)

	declare @breakW2 int, @kmax int, @kmin int, @w1id int, @w2id int, @w2idmax int,
		@fromQtyV decimal(15,3), @fromQtyW decimal(15,3)

	select @breakW2=0
	print 2	
	declare @i int
	select @i=1
	while exists(select * from #sku where id=@i)
	begin
		print 3	

		select identity(int,1,1)w1id, g.* into #work1 from #global g
			join #sku s on s.sku=g.sku and s.storerkey=g.storerkey
		where s.id=@i
		order by qty
		set @breakW2 = 0
--select count(*) from #work1 group by sku
		
		-- 3. выбрать ячейку с макс. кол-вом, убрать ее из общего списка
		select @kmax = max(w1id), @kmin=min(w1id) from #work1
		while @breakW2=0 and @kmax<>@kmin
		begin
			print 4
			select  @kmax = max(w1id), @kmin=min(w1id) from #work1
			select top 1 * into #recLoc from #work1 where w1id = @kmax and qty > 0--
--select '#recloc',* from #recLoc
			delete from #work1 where w1id = @kmax
			set @kMax = @kMax-1
			if not exists(select * from #recLoc) set @breakW2 = 1
			-- 4. искать в общем списке такой же товар, начиная с минимального
			-- выбираем данные получателя в переменные

			select @sku=sku, @storerkey=storerkey,
				@tolot = lot, @lotmix = comminglelot, @toqty=qty, @toloc=loc, @toID=ID,
				@toLocCube = locCube, @toV=V,
				--l.weightcapacity, locStatus, skuStatus, l.comminglesku, 
				@toSkuCube = stdcube
			from #recLoc rl
print @sku
--select '#recLoc',* from #recLoc
			
			CREATE TABLE #work2(
				[w2id] [int] IDENTITY(1,1) NOT NULL,
				[w1id] [int] NOT NULL,
				[gid] [int] NOT NULL,
				[sku] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
				[storerkey] [varchar](15) COLLATE Cyrillic_General_CI_AS NOT NULL,
				[loc] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
				[id] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
				[lot] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
				[qty] [decimal](22, 5) NOT NULL,
				[loccube] [float] NOT NULL,
				[weightcapacity] [float] NOT NULL,
				[locStatus] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
				[skuStatus] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
				[comminglesku] [varchar](1) COLLATE Cyrillic_General_CI_AS NOT NULL,
				[comminglelot] [varchar](1) COLLATE Cyrillic_General_CI_AS NOT NULL,
				[loclevel] [int] NOT NULL,
				[stdcube] [float] NOT NULL,
				[V] [float] NULL
			) ON [PRIMARY]

		
			-- копируем данные по критерию смешиваемости партий в ячейке-получателе
			
			if @lotmix = 0 --identity(int,1,1) w2id,
				insert into #work2 (w1id,[gid],[sku],[storerkey],[loc],[id],[lot],[qty],
				[loccube],[weightcapacity],[locStatus],[skuStatus],[comminglesku],[comminglelot],
				[loclevel],[stdcube],[V])
				select w1id,[gid],[sku],[storerkey],[loc],[id],[lot],[qty],
				[loccube],[weightcapacity],[locStatus],[skuStatus],[comminglesku],[comminglelot],
				[loclevel],[stdcube],[V] from #work1 where lot = @toLot and qty > 0 order by qty
			else 
				insert into #work2 (w1id,[gid],[sku],[storerkey],[loc],[id],[lot],[qty],
				[loccube],[weightcapacity],[locStatus],[skuStatus],[comminglesku],[comminglelot],
				[loclevel],[stdcube],[V])
				select w1id,[gid],[sku],[storerkey],[loc],[id],[lot],[qty],
				[loccube],[weightcapacity],[locStatus],[skuStatus],[comminglesku],[comminglelot],
				[loclevel],[stdcube],[V] from #work1 where qty > 0 order by qty
			
--select count(*) from #work2
			
			select @w2id = 1, @w2idmax=count(*) from #work2
			while @w2id<=@w2idmax and @breakW2 = 0 
			begin
			print 5
				-- выбираем данные донора в переменные
--select * from 
				if exists (select * from #work2 where w2id = @w2id)
				begin
					select @w1id = w1id, @fromQTY=qty, @fromLoc=loc, @fromID=ID, 
						@fromLocCube = locCube, @fromV=V, @fromSkuCube = stdcube
					from #work2 where w2id = @w2id -- and qty > 0
	--select * from wh40.lotxlocxid where loc = '08.03G41' and qty > 0				
					
	--select 'work2',* from #work2				
					-- проверяем проходимость по объему и весу
					if (@toLocCube > @fromSKUcube*@fromQTY+@toV) and (1=1 /* заменить на проверку веса*/)
					begin
						print 6
						-- если проходит все кол-во  - ничего не делаем
						set @fromQty = @fromQty
					end
					else
					begin
						print 7
						-- иначе - вычисляем сколько штук можно переместить исходя из объема и из веса
						set @fromQtyV = floor((@toLocCube-@toV)/@fromSKUcube)
						--set @fromQtyV =  floor((@toLocCube - (@fromSKUcube*@fromQTY+@toV)) / @fromSKUcube)
						set @fromQtyW = 9999999.9 -- прописать проверку на вес floor((@toLocCube - (@fromSKUcube*@fromQTY+@toV))/@fromSKUcube)
	--select @toLocCube,@fromSKUcube,@fromQTY,@toV,@fromQtyV

						-- выбираем меньшее число
						if @fromQtyV <= @fromQtyW
							set @fromQty = @fromQtyV
						else 
							set @fromQty = @fromQtyW
					end
					-- создаем результат
					insert #result (sku, storerkey, fromqty, fromloc, toloc, fromID, toID)
					values (@sku, @storerkey, @fromQTY, @fromLoc, @toLoc, @fromID, @toID)
--select * from #result				
					-- обновляем запасы в таблицах
					update #work2 set qty = qty-@fromQTY where w2id = @w2id
					update #work1 set qty = qty-@fromQTY where w1id = @w1id
					update #recLoc set qty = qty+@fromQTY, V=V+(@fromQTY*@toSkuCube), @toV=V+(@fromQTY*@toSkuCube)
	--select @fromQTY
					-- проверяем, если в эту ячейку больше ничего не войдет, то выходим из цикла
					if  @toLocCube < @toV + (@toQTY+@fromQTY+1)*@toSkuCube
						set @breakW2=1
				end
				
				print 8	
				set @w2id=@w2id+1
			end
			IF exists (select * FROM #recLoc)
				set @breakW2=0

			drop table #recLoc
			drop table #work2
		end
		-- если ни одна из ячеек не освободилась (qty>0)то смысла делать перемещения нет. 
		-- удаляем результаты для этого товара
		if not exists(select * from #work1 where qty=0)
		begin
			print 'del'
			delete from #result 
			where sku in(select sku 
					from #work1 where sku = @sku and storerkey = @storerkey group by sku having min(qty)>0)
				and storerkey = @storerkey
		end
		if not exists (select * from #work1)
			set @breakW2 = 1
		drop table #Work1
		set @i=@i+1
	end

	select loc, r.sku, r.storerkey into #t1 from #result r
		join #global g on loc = fromloc and g.sku=r.sku and g.storerkey=r.storerkey
	group by fromloc, r.sku, loc, r.storerkey
	having sum(fromqty)<> max(qty)
	
	select r.id into #t2 from #result r
		join  #t1 t on t.sku=r.sku and t.storerkey=r.storerkey and t.loc=r.fromloc
	
	delete from #result where id in (select id from #t2)

	select r.*, s.Descr from #result r
		join wh40.sku s on s.sku = r.sku and s.storerkey=r.storerkey
		
drop table #t1
drop table #t2
drop table #result
drop table #global
drop table #sku
/*
drop table #work1
drop table #work2
drop table #recLoc
*/

