ALTER PROCEDURE [rep].[Build_errors]
	--@orderkey varchar(18) = NULL,
	@date_from datetime = NULL,
	@date_to datetime = NULL
as
begin
	set NOCOUNT on
	
	if object_id('tempdb..#PROBLEM_LINES') is NOT NULL drop table #PROBLEM_LINES
	if object_id('tempdb..#ERRORS') is NOT NULL drop table #ERRORS
	if object_id('tempdb..#STATISTIC') is NOT NULL drop table #STATISTIC
	
	create table #PROBLEM_LINES (
		ORDERKEY varchar(10),
		ORDERLINENUMBER varchar(5)
	)

	insert into #PROBLEM_LINES
	select
		od.ORDERKEY, od.ORDERLINENUMBER
		--, count(distinct p1.CASEID), count(distinct pc.CASEID), sum(p1.QTY), sum(p2.QTY), sum(pc.QTY)
	from wh1.ORDERDETAIL od
		join wh1.ORDERS o on o.ORDERKEY = od.ORDERKEY
		left join (
			select ORDERKEY, ORDERLINENUMBER, CASEID, LOT, sum(QTY) as QTY
			from wh1.PICKDETAIL
			group by ORDERKEY, ORDERLINENUMBER, CASEID, LOT
		) p1 on p1.ORDERKEY = od.ORDERKEY and p1.ORDERLINENUMBER = od.ORDERLINENUMBER
		left join (
			select ORDERKEY, ORDERLINENUMBER, CASEID, LOT, sum(QTY) as QTY
			from wh1.PICKDETAIL
			where LOC not in ('PL_KONTR')
			group by ORDERKEY, ORDERLINENUMBER, CASEID, LOT
		) p2 on p1.CASEID = p2.CASEID and p1.LOT = p2.LOT
		left join wh1.PICKCONTROL pc on pc.CASEID = p2.CASEID and pc.LOT = p2.LOT
	where o.[STATUS] >= 78 -- проконтролированы
		and ( @date_from is NULL or od.EDITDATE >= @date_from )
		and ( @date_to is NULL or od.EDITDATE <= @date_to )
	group by od.ORDERKEY, od.ORDERLINENUMBER, od.ORIGINALQTY
	having /* -- Склад отказался от ошибок отбора
			od.ORIGINALQTY <> sum(isnull(p1.QTY,0))
		or*/ ( sum(isnull(p1.QTY,0)) <> sum(isnull(pc.QTY,0)) and sum(isnull(p2.QTY,0)) <> sum(isnull(pc.QTY,0)) )
	--order by od.ORDERKEY, od.ORDERLINENUMBER
	
	
	--select * from #PROBLEM_LINES
	--select * from wh1.ORDERSTATUSSETUP
	--select * from wh1.PICKDETAIL p join wh1.LOC l on l.LOC = p.LOC

	select distinct
		isnull(nullif(od.EXTERNORDERKEY,''),'б/н') as EXTERNORDERKEY,
		od.ORDERKEY,
		od.ORDERLINENUMBER,
		p.SKU,
		n.DESCR,
		od.LOTTABLE02 as SER,
		od.LOTTABLE05 as EXP_DATE,
		od.ORIGINALQTY,
		
		p.CASEID as DROPID,
		p.CASEID,
		t.FROMLOC,
		p.QTY as PICKED_QTY,
		t.EDITDATE as PICKED_DATE,
		t.EDITWHO as PICKED_USER,
		
		pc.QTY as CONTRLLED_QTY,
		pc.EDITDATE as CONTRLLED_DATE,
		pc.EDITWHO as CONTRLLED_USER
		
		--,
		--p.LOT,
		--od.QTYPICKED,
		--p.QTY as QTY_IN_CASE,
		--s.[DESCRIPTION] as [STATUS],
		--p.DROPID, p.LOC, p.TOLOC
		--, od.LOTTABLE01, od.LOTTABLE02, od.LOTTABLE03, od.LOTTABLE04, od.LOTTABLE05, od.LOTTABLE06, od.LOTTABLE07, od.LOTTABLE08
		--,t.*
	into #ERRORS
	from #PROBLEM_LINES pl
		join wh1.ORDERDETAIL od
			join wh1.ORDERS o on o.ORDERKEY = od.ORDERKEY
			join wh1.SKU n on n.SKU = od.SKU and n.STORERKEY = od.STORERKEY
		on od.ORDERKEY = pl.ORDERKEY and od.ORDERLINENUMBER = pl.ORDERLINENUMBER
		left join WH1.PICKDETAIL p on p.ORDERKEY = pl.ORDERKEY and p.ORDERLINENUMBER = pl.ORDERLINENUMBER and p.QTY <> 0
		left join wh1.TASKDETAIL t on t.PICKDETAILKEY = p.PICKDETAILKEY
		join wh1.CODELKUP s on p.[STATUS] = s.CODE and s.LISTNAME = 'ORDRSTATUS'
		left join wh1.PICKCONTROL pc on pc.CASEID = p.CASEID and pc.LOT = p.LOT
	where -- Склад отказался от ошибок отбора -- ( p.QTY <> od.ORIGINALQTY or isnull(pc.QTY,0) <> p.QTY )
		isnull(pc.QTY,0) <> p.QTY
	--	and ( isnull(@orderkey,'') = '' or p.ORDERKEY = @orderkey )
	--	and ( @date_from is NULL or p.EDITDATE >= @date_from or pc.EDITDATE >= @date_from )
	--	and ( @date_to is NULL or p.EDITDATE <= @date_to or pc.EDITDATE <= @date_to )
	--	and p.QTY <> isnull(pc.QTY,0)
	order by
	
		od.ORDERKEY,
		od.ORDERLINENUMBER
	
	;with tree (DROPID, CHILDID, THREAD, LEVEL) as (
		select distinct convert(varchar(20),d.DROPID), convert(varchar(20),d.CASEID), convert(varchar(20),d.CASEID), 1
		from #ERRORS d
		union all
		select convert(varchar(20),d.DROPID), convert(varchar(20),d.CHILDID), t.THREAD, t.LEVEL + 1
		from wh1.DROPIDDETAIL d
			join tree t on d.CHILDID = t.DROPID
	)
	update e set
		DROPID = x.DROPID
	from (select THREAD as CASEID, DROPID, row_number() over (partition by THREAD order by LEVEL desc) as RN from tree) x
		join #ERRORS e on x.CASEID = e.CASEID
	where x.RN = 1
	
	create table #STATISTIC (
		ROW_CNT int,
		ERRORS_PROPORTION float
	)
	
	declare @errors_cnt int
	
	select @errors_cnt = count(*) from #ERRORS
	
	insert into #STATISTIC
	select
		@errors_cnt as ERRORS_CNT,
		--case when @errors_cnt = 0 then 0 else convert(float,@errors_cnt) / count(distinct isnull(pc.SERIALKEY,-p.SERIALKEY)) end as ERRORS_PROPORTION
		case when @errors_cnt = 0 then 0 else convert(float,@errors_cnt) / count(distinct od.SERIALKEY) end as ERRORS_PROPORTION
	from wh1.ORDERDETAIL od
		join wh1.ORDERS o on o.ORDERKEY = od.ORDERKEY
		join wh1.PICKDETAIL p on p.ORDERKEY = od.ORDERKEY and p.ORDERLINENUMBER = od.ORDERLINENUMBER
		join wh1.PICKCONTROL pc on pc.CASEID = p.CASEID and pc.LOT = p.LOT
	where o.[STATUS] >= 78 -- проконтролированы
		and ( @date_from is NULL or od.EDITDATE >= @date_from )
		and ( @date_to is NULL or od.EDITDATE <= @date_to )
	
	
	select * from #ERRORS
	select * from #STATISTIC
	
end

