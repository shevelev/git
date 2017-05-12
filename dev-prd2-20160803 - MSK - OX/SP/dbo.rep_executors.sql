CREATE proc dbo.rep_executors
	@orderkey varchar(20) = NULL,
	@externorderkey varchar(20) = NULL,
	@orderdate datetime = NULL
as
begin
	set NOCOUNT on
	
	select
		@orderkey = nullif(rtrim(@orderkey),''),
		@externorderkey = nullif(rtrim(@externorderkey),''),
		@orderdate = cast(round(cast(@orderdate as real), 0, 1) as smalldatetime)
	
	create table #EXECUTORS (
		ORDERKEY varchar(10),
		EXTERNORDERKEY varchar(32),
		DROPID varchar(20) NULL,
		CASEID varchar(20) NULL,
		PICKER varchar(18) NULL,
		CONTROLLER varchar(18) NULL,
		LOADER varchar(18) NULL
	)
	
	if (@orderkey is NOT NULL or @externorderkey is NOT NULL or @orderdate is NOT NULL)
	begin
		insert into #EXECUTORS
		select distinct
			o.ORDERKEY,
			o.EXTERNORDERKEY,
			p.CASEID as DROPID,
			p.CASEID,
			t.EDITWHO as PICKER,
			pc.EDITWHO as CONTROLLER,
			NULL as LOADER
		from wh1.ORDERS o
			join wh1.ORDERDETAIL od on od.ORDERKEY = o.ORDERKEY
			/*left*/ join wh1.PICKDETAIL p
				left join wh1.TASKDETAIL t on t.PICKDETAILKEY = p.PICKDETAILKEY
				left join wh1.PICKCONTROL pc on pc.CASEID = p.CASEID and pc.LOT = p.LOT
			on p.ORDERKEY = od.ORDERKEY and p.ORDERLINENUMBER = od.ORDERLINENUMBER
		where ( @orderkey is NULL or o.ORDERKEY = @orderkey )
			and ( @externorderkey is NULL or o.EXTERNORDERKEY = @externorderkey )
			and ( @orderdate is NULL or o.ORDERDATE between @orderdate and @orderdate + 1 )
		
		;with tree (DROPID, CHILDID, THREAD, LEVEL) as (
			select distinct convert(varchar(20),d.DROPID), convert(varchar(20),d.CASEID), convert(varchar(20),d.CASEID), 1
			from #EXECUTORS d
			union all
			select convert(varchar(20),d.DROPID), convert(varchar(20),d.CHILDID), t.THREAD, t.LEVEL + 1
			from wh1.DROPIDDETAIL d
				join tree t on d.CHILDID = t.DROPID
		)
		update e set
			DROPID = x.DROPID,
			LOADER = case when x.DROPID = e.DROPID then NULL else d.EDITWHO end
		from (select THREAD as CASEID, DROPID, CHILDID, row_number() over (partition by THREAD order by LEVEL desc) as RN from tree) x
			join wh1.DROPIDDETAIL d on x.CHILDID = d.CHILDID
			join #EXECUTORS e on x.CASEID = e.CASEID
		where x.RN = 1
		
	end
	
	select * from #EXECUTORS order by ORDERKEY, CASEID
end

