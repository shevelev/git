ALTER PROCEDURE [rep].[mof_Controller_performance]
	@date_from datetime = NULL,
	@time_from varchar(5) = NULL,
	@date_to datetime = NULL,
	@time_to varchar(5) = NULL
as
begin
	set NOCOUNT on
	
	set @date_from = dbo.udf_get_date_from_datetime(isnull(@date_from,getdate()))
	set @date_to = dbo.udf_get_date_from_datetime(isnull(@date_to,getdate()))
	
	if dbo.sub_udf_common_regex_is_match(@time_from,'^([01][0-9]|2[0-3]):[0-5][0-9]$') = 1
		set @date_from = convert(datetime, convert(varchar(10),@date_from,120) + ' ' + @time_from + ':00',120)
	
	if dbo.sub_udf_common_regex_is_match(@time_to,'^([01][0-9]|2[0-3]):[0-5][0-9]$') = 1
		set @date_to = convert(datetime, convert(varchar(10),@date_to,120) + ' ' + @time_to + ':59',120)
	else
		set @date_to = @date_to + convert(time,'23:59:59.997')
	
	
		
---------------------------------------------------------
		-- проверенное количество по строкам
		select
			c.ORDERKEY, c.ORDERLINENUMBER, sum(pc.QTY) as CONTROLLED_QTY
		into #proverenoe
		from wh2.PICKCONTROL pc with (NOLOCK,NOWAIT)
			join (select distinct ORDERKEY, ORDERLINENUMBER, CASEID, LOT from wh2.PICKDETAIL with (NOLOCK,NOWAIT)) c on c.CASEID = pc.CASEID and c.LOT = pc.LOT
		where pc.[STATUS] = '1'
			and ( @date_from is NULL or pc.EDITDATE >= @date_from )
			and ( @date_to is NULL or pc.EDITDATE < @date_to )
		group by c.ORDERKEY, c.ORDERLINENUMBER
---------------------------------------------------------	
	
---------------------------------------------------------	
	
			select
				p.ORDERKEY, p.ORDERLINENUMBER,
				sum(p.QTY) as PICKED_QTY
			into #otobrannoe
			from wh2.ITRN i with (NOLOCK,NOWAIT)
				join wh2.PICKDETAIL p with (NOLOCK,NOWAIT) on i.SOURCEKEY = p.PICKDETAILKEY
			where i.SOURCETYPE = 'PICKING'
				and p.[STATUS] = '9'
				and i.TOLOC <> 'PL_KONTR'
				and ( @date_from is NULL or i.EDITDATE >= @date_from - 3 ) -- фиг сейчас прикрутишь дату контроля, поэтому 3 дня запаса
				and ( @date_to is NULL or i.EDITDATE < @date_to )
			group by
				p.ORDERKEY, p.ORDERLINENUMBER
---------------------------------------------------------	
	
	
	
	
---------------------------------------------------------	
			select
				p.ORDERKEY, p.ORDERLINENUMBER,
				sum(p.QTY) as FULL_QTY
			into #otobrannoeall
			from wh2.ITRN i with (NOLOCK,NOWAIT)
				join wh2.PICKDETAIL p with (NOLOCK,NOWAIT) on i.SOURCEKEY = p.PICKDETAILKEY
			where i.SOURCETYPE = 'PICKING'
				and p.[STATUS] = '9'
				--and i.TOLOC <> 'PL_KONTR'
				and ( @date_from is NULL or i.EDITDATE >= @date_from - 3 ) -- фиг сейчас прикрутишь дату контроля, поэтому 3 дня запаса
				and ( @date_to is NULL or i.EDITDATE < @date_to )
			group by
				p.ORDERKEY, p.ORDERLINENUMBER
---------------------------------------------------------	
	
	
	
	
	
	-- проблемные строки
	select c.ORDERKEY, c.ORDERLINENUMBER, p.PICKED_QTY, pp.FULL_QTY, c.CONTROLLED_QTY
	into #PROBLEM_ROWS
	from #proverenoe c
		-- отобранное со склада комплектации
		join #otobrannoe p on p.ORDERKEY = c.ORDERKEY and p.ORDERLINENUMBER = c.ORDERLINENUMBER
		-- общее отобранное количество
		join #otobrannoeall pp on pp.ORDERKEY = c.ORDERKEY and pp.ORDERLINENUMBER = c.ORDERLINENUMBER
	where c.CONTROLLED_QTY <> p.PICKED_QTY
		and c.CONTROLLED_QTY <> pp.FULL_QTY -- включая коробки (странно! таких не должно быть...)
	
	
	-- -- 8< -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	
	create table #CONTROLLERS (
		ROW_ID int NOT NULL,
		USR_NAME varchar(255) NOT NULL,
		ROWS_CNT int NOT NULL,
		ERRORS_QTY int NULL
	)
	
	set ANSI_WARNINGS off -- NULLs в игнор
	
	insert into #CONTROLLERS
	select
		1 as ROW_ID,
		pu.usr_name,
		count(distinct pc.CASEID + pc.LOT) as ROWS_CNT,
		nullif(count(distinct pr.ORDERKEY + pr.ORDERLINENUMBER),0) as ERRORS_QTY
	from wh2.PICKCONTROL pc with (NOLOCK,NOWAIT)
		join ssaadmin.pl_usr pu with (NOLOCK,NOWAIT) on pc.EDITWHO = pu.usr_login
		join (select distinct ORDERKEY, ORDERLINENUMBER, CASEID, LOT from wh2.PICKDETAIL with (NOLOCK,NOWAIT)) c on c.CASEID = pc.CASEID and c.LOT = pc.LOT
		left join #PROBLEM_ROWS pr on pr.ORDERKEY = c.ORDERKEY and pr.ORDERLINENUMBER = c.ORDERLINENUMBER
	where pc.[STATUS] = '1'
		and ( @date_from is NULL or pc.EDITDATE >= @date_from )
		and ( @date_to is NULL or pc.EDITDATE < @date_to )
	group by pu.usr_name
	
	set ANSI_WARNINGS on
	
	
	-- правильные номера строк
	update p set
		ROW_ID = RN
	from (
		select
			ROW_ID,
			dense_rank() over (order by USR_NAME) as RN
		from #CONTROLLERS
	) p
	
	select * from #CONTROLLERS order by ROW_ID
end


