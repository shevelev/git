ALTER PROCEDURE [dbo].[DA_GetCasesByDropTS](@wh varchar(10), @ts varchar(18))
as

--declare @wh varchar(10), @ts varchar(18)
--select @wh ='wh40', @ts = 'd2596'

	declare @sql varchar(max)
	select cast(0 as int) serialkey, dropid, childid into #dropdet1 from wh1.dropiddetail where 1=2
	select cast(0 as int) serialkey, dropid, childid into #dropdet2 from wh1.dropiddetail where 1=2
	select cast(0 as int) serialkey, dropid, childid into #res from wh1.dropiddetail where 1=2
	select cast(0 as int) serialkey, dropid, childid into #tmpres from wh1.dropiddetail where 1=2

	set @sql = 'insert into #dropdet1 
	select dd.serialkey, dd.dropid, dd.childid 
		from '+@wh+'.dropiddetail dd
			join '+@wh+'.dropid d on d.dropid = dd.dropid
	where 1=1
		--and d.dropidtype = 4 
		and d.dropid = '''+@ts+''''
	exec(@sql)
	--select * from  wh1.dropid where dropidtype = 4

	declare @maxlevels int, --максимально допустимое кол-во уровней вложенности. 
							--по достижении которого произойдет автоматический выход из цикла
			@iLevel int -- счетчик уровней
	select @maxLevels = 10, @iLevel=1


	while exists(select top 1 * from #dropdet1) or (@iLevel <= @maxLevels)
	begin
		-- сохранили листья дерева, если они есть
		set @sql = 'insert #tmpRes select serialkey, dropid, childid 
		from #dropdet1 where not childid in (select dropid from '+@wh+'.dropiddetail)'
		exec (@sql)
		
		if @iLevel = @maxLevels
			update #tmpRes set childid = 'LevelError'
		insert into #res select serialkey, dropid, childid from #tmpRes
		
		delete from #dropdet1 where serialkey in (select serialkey from #tmpRes)
		
		delete from #tmpres
		
		set @sql = 'insert #dropdet2 select serialkey, dropid, childid 
		from '+@wh+'.dropiddetail where dropid in (select childid from #dropdet1)'
		exec (@sql)
		
		delete from #dropdet1
		insert #dropdet1 select serialkey, dropid, childid from #dropdet2
		
		delete from #dropdet2
		
		set @iLevel = @iLevel+1
	end

	select * from #res
	 
	drop table #dropdet1
	drop table #dropdet2
	drop table #tmpres
	drop table #res


