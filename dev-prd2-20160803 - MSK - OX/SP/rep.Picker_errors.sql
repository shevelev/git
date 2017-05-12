/*
ќшибки комплектовщиков, вы€вленные при контроле
*/
ALTER PROCEDURE [rep].[Picker_errors]
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
	
	

	
	select c.ORDERKEY, c.SKU, sum(pc.QTY) as CONTROLLED_QTY
	into #problem
		from wh1.PICKCONTROL pc with (NOLOCK, NOWAIT)
			join (
				select distinct p.ORDERKEY, p.SKU, p.CASEID, p.LOT
				from wh1.PICKDETAIL p with (NOLOCK, NOWAIT)
					join wh1.ITRN i with (NOLOCK,NOWAIT) on i.SOURCEKEY = p.PICKDETAILKEY
				where i.ADDDATE >= @date_from
			) c on c.CASEID = pc.CASEID and c.LOT = pc.LOT
		group by c.ORDERKEY, c.SKU
		
		
		select
				p.ORDERKEY, p.SKU,
				sum(i.QTY) as PICKED_QTY
				into #otobrk
			from wh1.ITRN i with (NOLOCK,NOWAIT)
				join wh1.PICKDETAIL p with (NOLOCK,NOWAIT) on i.SOURCEKEY = p.PICKDETAILKEY
			where i.SOURCETYPE = 'PICKING'
				and p.[STATUS] >= '6'
				and i.TOLOC <> 'PL_KONTR'
				and ( @date_from is NULL or i.EDITDATE >= @date_from )
				and ( @date_to is NULL or i.EDITDATE < @date_to )
			group by p.ORDERKEY, p.SKU
		
	select
				p.ORDERKEY, p.SKU,
				sum(i.QTY) as FULL_QTY
				into #allotbor
			from wh1.ITRN i with (NOLOCK,NOWAIT)
				join wh1.PICKDETAIL p with (NOLOCK,NOWAIT) on i.SOURCEKEY = p.PICKDETAILKEY
			where i.SOURCETYPE = 'PICKING'
				and p.[STATUS] >= '6'
				--and i.TOLOC <> 'PL_KONTR'
				and ( @date_from is NULL or i.EDITDATE >= @date_from )
				and ( @date_to is NULL or i.EDITDATE < @date_to )
			group by p.ORDERKEY, p.SKU
	
	
	
	-- проблемные строки
	select c.ORDERKEY, c.SKU, p.PICKED_QTY, pp.FULL_QTY, c.CONTROLLED_QTY
	into #PROBLEM_ROWS
	from #problem c
		-- отобранное со склада комплектации
		join #otobrk p on p.ORDERKEY = c.ORDERKEY and p.SKU = c.SKU
		-- общее отобранное количество
		join #allotbor pp on pp.ORDERKEY = c.ORDERKEY and pp.SKU = c.SKU
	where c.CONTROLLED_QTY <> p.PICKED_QTY
		and c.CONTROLLED_QTY <> pp.FULL_QTY -- включа€ коробки (странно! таких не должно быть...)
	
--select * from #PROBLEM_ROWS order by 1,2
	
	-- -- 8< -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	
	select distinct
		dense_rank() over (order by o.ORDERKEY, od.ORDERLINENUMBER) as RN,
		o.ORDERKEY,
		o.EXTERNORDERKEY,
		od.ORDERLINENUMBER,
		s.SKU,
		s.DESCR,
		od.ORIGINALQTY,
		p.CASEID,
		p.PICKED_QTY,
		p.PICKER_NAME,
		c.CONTROLLED_QTY,
		c.CONTROLLER_NAME,
		p.TOLOC
	from #PROBLEM_ROWS x
		join wh1.ORDERS o on o.ORDERKEY = x.ORDERKEY
		join wh1.SKU s on s.SKU = x.SKU and s.STORERKEY = '001'
		join wh1.ORDERDETAIL od with (NOLOCK,NOWAIT) on od.ORDERKEY = x.ORDERKEY and od.SKU = x.SKU -- возможны повторы!
		join (
			select
				p.ORDERKEY,
				p.SKU,
				p.CASEID,
				p.TOLOC,
				pu.usr_name as PICKER_NAME,
				sum(i.QTY) as PICKED_QTY
			from wh1.PICKDETAIL p with (NOLOCK,NOWAIT)
				join wh1.ITRN i with (NOLOCK,NOWAIT)
					join ssaadmin.pl_usr pu with (NOLOCK,NOWAIT) on i.ADDWHO = pu.usr_login
				on i.SOURCEKEY = p.PICKDETAILKEY
			group by
				p.ORDERKEY,
				p.SKU,
				p.CASEID,
				p.TOLOC,
				pu.usr_name

			--select
			--	p.ORDERKEY,
			--	p.SKU,
			--  p.CASEID,
			--	p.QTY as PICKED_QTY,
			--	pu.usr_name as PICKER_NAME
			--from wh1.PICKDETAIL p with (NOLOCK,NOWAIT)
			--	join wh1.ITRN i with (NOLOCK,NOWAIT)
			--		join ssaadmin.pl_usr pu with (NOLOCK,NOWAIT) on i.ADDWHO = pu.usr_login
			--	on i.SOURCEKEY = p.PICKDETAILKEY

		) p on x.ORDERKEY = p.ORDERKEY and x.SKU = p.SKU
		left join (
			select
				pd.ORDERKEY,
				pd.SKU,
				pd.CASEID,
				isnull(cu.usr_name,pc.EDITWHO) as CONTROLLER_NAME,
				sum(pc.QTY) as CONTROLLED_QTY
			from wh1.PICKCONTROL pc with (NOLOCK, NOWAIT)
				left join ssaadmin.pl_usr cu with (NOLOCK,NOWAIT) on pc.EDITWHO = cu.usr_login
				join (
					select distinct pd.ORDERKEY, pd.SKU, pd.CASEID, pd.LOT
					from #PROBLEM_ROWS x
						join wh1.PICKDETAIL pd with (NOLOCK, NOWAIT) on pd.ORDERKEY = x.ORDERKEY and pd.SKU = x.SKU
				) pd on pd.CASEID = pc.CASEID and pd.LOT = pc.LOT
			group by
				pd.ORDERKEY,
				pd.SKU,
				pd.CASEID,
				isnull(cu.usr_name,pc.EDITWHO)
		) c
		on x.ORDERKEY = c.ORDERKEY and x.SKU = c.SKU and p.CASEID = c.CASEID
	--where isnull(c.CONTROLLED_QTY,0) <> isnull(p.PICKED_QTY,0)
	order by 1,4
	
end

