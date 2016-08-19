ALTER PROCEDURE dbo.rep_loading_duration
	@date_from datetime = NULL,
	@time_from varchar(5) = NULL,
	@date_to datetime = NULL,
	@time_to varchar(5) = NULL,
	@routes varchar(4000) = ''
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
	
	
	select
		l.[ROUTE],
		l.DEPARTURETIME,
		l.LOADID,
		l.[STATUS]
	into #LOADS
	from wh1.LOADHDR l
	where ( @routes = '' or l.[ROUTE] in (select SLICE from dbo.sub_udf_common_split_string(@routes,',')) )
		and ( @date_from is NULL or l.DEPARTURETIME >= @date_from )
		and ( @date_to is NULL or l.DEPARTURETIME < @date_to )
	
	--select * from #LOADS
	
	;with DROPS ( DROPID, CHILDID, ADDWHO, ADDDATE ) as (
		select distinct d.DROPID, d.CHILDID, d.ADDWHO, d.ADDDATE
		from wh1.DROPIDDETAIL d
		where d.DROPID like 'TS%'
			and ( @date_from is NULL or d.ADDDATE >= @date_from )
		union all
		select d.DROPID, d.CHILDID, d.ADDWHO, d.ADDDATE
		from wh1.DROPIDDETAIL d
			join DROPS x on x.CHILDID = d.DROPID
	)
	select --distinct
		d.DROPID,
		d.CHILDID,
		d.ADDWHO,
		l.[ROUTE],
--		l.DEPARTURETIME,
		max(l.[STATUS]) as [STATUS],
		min(d.ADDDATE) as DROP_START,
		max(d.ADDDATE) as DROP_END,
		min(os.LOAD_START) as LOAD_START,
		max(os.LOAD_END) as LOAD_END
	into #TS
	from ( select distinct * from DROPS where DROPID like 'TS%' ) d
		join wh1.PICKDETAIL p with (NOLOCK,NOWAIT)
			join wh1.ORDERS o with (NOLOCK,NOWAIT)
				join #LOADS l on l.LOADID = o.LOADID
				join (
					--select * from wh1.ORDERSTATUSSETUP o
					select
						ORDERKEY,
						min(ADDDATE) as LOAD_START,
						max(ADDDATE) as LOAD_END
					from wh1.ORDERSTATUSHISTORY with (NOLOCK,NOWAIT)
					where ORDERLINENUMBER = ''
						--and [STATUS] between '82' and '95' -- от "В состоянии загрузки" до "Отгрузка завершена"
						and [STATUS] between '82' and '88' -- ВРЕМЕННО: время загрузки последнего дропа в TS
					group by ORDERKEY
				) os on os.ORDERKEY = o.ORDERKEY
			on o.ORDERKEY = p.ORDERKEY
		on p.DROPID = d.CHILDID or p.DROPID = d.DROPID
	group by
		d.DROPID,
		d.CHILDID,
		d.ADDWHO,
		l.[ROUTE]
--		l.DEPARTURETIME,
--		l.[STATUS]
	
	--select * from #TS
	
	select
		d.DROPID,
		count(distinct d.CHILDID) as DROPS,
		t.TOTAL,
		d.ADDWHO,
		d.[ROUTE],
--		d.DEPARTURETIME,
		d.[STATUS],
		min(d.DROP_START) as DROP_START,
		max(d.DROP_END) as DROP_END,
		datediff(mi,min(d.DROP_START),max(d.DROP_END)) as DROP_DURATION,
		min(d.LOAD_START) as LOAD_START,
		max(d.LOAD_END) as LOAD_END,
		datediff(mi,min(d.LOAD_START),max(d.LOAD_END)) as LOAD_DURATION
	into #RESULT
	from #TS d
		join (
			select DROPID, count(*) as TOTAL
			from wh1.DROPIDDETAIL with (NOLOCK,NOWAIT)
			where DROPID like 'TS%'
			group by DROPID
		) t on t.DROPID = d.DROPID
	group by
		d.DROPID,
		t.TOTAL,
		d.ADDWHO,
		d.[ROUTE],
--		d.DEPARTURETIME,
		d.[STATUS]
	
	
	select
		r.DROPID,
		r.DROPS as LOAD_DROPS,
		r.TOTAL as TOTAL_DROPS,
		pu.usr_name as ADDWHO,
		r.[ROUTE],
		r.[STATUS],
		c.[DESCRIPTION],
		r.DROP_START,
		r.DROP_END,
		r.DROP_DURATION,
		dbo.udf_common_get_datepart_suffix('n',r.DROP_DURATION,r.DROP_END,4) as DROP_DURATION_DESCRIPTION,
		r.LOAD_START,
		r.LOAD_END,
		r.LOAD_DURATION,
		dbo.udf_common_get_datepart_suffix('n',r.LOAD_DURATION,r.LOAD_END,4) as LOAD_DURATION_DESCRIPTION
	from #RESULT r
		join ssaadmin.pl_usr pu with (NOLOCK,NOWAIT) on r.ADDWHO = pu.usr_login
		join wh1.CODELKUP c with (NOLOCK,NOWAIT) on r.[STATUS] = c.CODE and c.LISTNAME = 'LOADSTATUS'
	order by DROPID
	
	--select * from wh1.DROPIDDETAIL where DROPID = 'TS00005171'
end

