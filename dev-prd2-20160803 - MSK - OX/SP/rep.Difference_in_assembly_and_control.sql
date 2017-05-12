ALTER PROCEDURE [rep].[Difference_in_assembly_and_control]
	@date_from datetime = NULL,
	@date_to datetime = NULL,
	@externorderkey varchar(32) = NULL
as
begin
	set NOCOUNT on
	
	if object_id('tempdb..#PROBLEM_LOTS') is NOT NULL drop table #PROBLEM_LOTS
	if object_id('tempdb..#ERRORS') is NOT NULL drop table #ERRORS
	if object_id('tempdb..#ORDERS') is NOT NULL drop table #ORDERS
	
	select
		@externorderkey = nullif(rtrim(@externorderkey),''),
		@date_from = cast(round(cast(@date_from as real), 0, 1) as smalldatetime),
		@date_to = cast(round(cast(@date_to as real), 0, 1) as smalldatetime) + 1
	
	select distinct o.ORDERKEY, o.EXTERNORDERKEY
	into #ORDERS
	from wh1.ORDERS o
	where o.[STATUS] >= 78 -- проконтролированы
		and ( @date_from is NULL or o.ORDERDATE >= @date_from )
		and ( @date_to is NULL or o.ORDERDATE < @date_to )
		and ( @externorderkey is NULL or o.EXTERNORDERKEY like '%' + @externorderkey + '%' )
	
	/* 
	select
		od.ORDERKEY,
		od.SKU,
		od.ORIGINALQTY,
		p1.QTY as ALL_PICKED_QTY,
		p2.QTY as PICKED_QTY,
		pc.QTY as CONTROLLED_QTY
	into #PROBLEM_LOTS
	from (
			select od.ORDERKEY, od.SKU, sum(od.ORIGINALQTY) as ORIGINALQTY
			from #ORDERS o
				join wh1.ORDERDETAIL od
				--	left join wh1.LOTATTRIBUTE la on la.SKU = od.SKU
				----		and ( la.LOTTABLE01 = od.LOTTABLE01 or la.LOTTABLE01 is NULL and od.LOTTABLE01 is NULL ) -- упаковка
				--		and ( la.LOTTABLE02 = od.LOTTABLE02 or la.LOTTABLE02 is NULL and od.LOTTABLE02 is NULL ) -- серия Аналит
				--		and ( la.LOTTABLE03 = od.LOTTABLE03 or la.LOTTABLE03 is NULL and od.LOTTABLE03 is NULL ) -- наличие сертификата
				--		and ( la.LOTTABLE04 = od.LOTTABLE04 or la.LOTTABLE04 is NULL and od.LOTTABLE04 is NULL ) -- дата производства
				--		and ( la.LOTTABLE05 = od.LOTTABLE05 or la.LOTTABLE05 is NULL and od.LOTTABLE05 is NULL ) -- срок годности
				----		and ( la.LOTTABLE06 = od.LOTTABLE06 or la.LOTTABLE06 is NULL and od.LOTTABLE06 is NULL ) -- <не используется>
				--		and ( la.LOTTABLE07 = od.LOTTABLE07 or la.LOTTABLE07 is NULL and od.LOTTABLE07 is NULL ) -- признак брака
				--		and ( la.LOTTABLE08 = od.LOTTABLE08 or la.LOTTABLE08 is NULL and od.LOTTABLE08 is NULL ) -- признак запрета ФСН
				on o.ORDERKEY = od.ORDERKEY
			group by od.ORDERKEY, od.SKU--la.LOT
		) od
		left join (
			select p.ORDERKEY, p.SKU, sum(p.QTY) as QTY
			from #ORDERS o
				join wh1.PICKDETAIL p on p.ORDERKEY = o.ORDERKEY --and p.ORDERLINENUMBER = o.ORDERLINENUMBER
			group by p.ORDERKEY, p.SKU
		) p1 on p1.ORDERKEY = od.ORDERKEY and p1.SKU = od.SKU
		left join (
			select p.ORDERKEY, p.SKU, sum(p.QTY) as QTY
			from wh1.PICKDETAIL p
				join #ORDERS o on p.ORDERKEY = o.ORDERKEY --and p.ORDERLINENUMBER = o.ORDERLINENUMBER
			where p.LOC not in ('PL_KONTR')
			group by p.ORDERKEY, p.SKU
		) p2 on p2.ORDERKEY = od.ORDERKEY and p2.SKU = od.SKU
		left join (
			select p.ORDERKEY, p.SKU, sum(c.QTY) as QTY
			from wh1.PICKCONTROL c
				join (
					select distinct p.CASEID, p.SKU, p.ORDERKEY
					from wh1.PICKDETAIL p
						join #ORDERS o on p.ORDERKEY = o.ORDERKEY --and p.ORDERLINENUMBER = o.ORDERLINENUMBER
				) p on p.CASEID = c.CASEID and p.SKU = c.SKU
			group by p.ORDERKEY, p.SKU
		) pc on pc.ORDERKEY = od.ORDERKEY and pc.SKU = od.SKU
	where p1.QTY <> od.ORIGINALQTY /* or p2.QTY <> od.ORIGINALQTY */ or pc.QTY <> p2.QTY --or p1.LOT is NULL
	 */
	
	--select * from #PROBLEM_LOTS pl join wh1.ORDERS o on o.ORDERKEY = pl.ORDERKEY
	--select * from wh1.ORDERSTATUSSETUP
	--select * from wh1.PICKDETAIL p join wh1.LOC l on l.LOC = p.LOC
	
	
	select
		o.ORDERKEY,o.EXTERNORDERKEY,
		cr.COMPANY,
		s.[DESCRIPTION] as [STATUS],
		od.ORDERLINENUMBER,
		od.SKU,
		n.DESCR,
		od.LOTTABLE02 as SER,
		od.LOTTABLE05 as EXP_DATE,
		od.ORIGINALQTY,
		p.PICKED_QTY,
		p.PICKED_USER,
		c.CONTROLLED_QTY,
		isnull(nullif(c.CONTROLLED_USER,''),p.TOLOC) as CONTROLLED_USER
		--,xp.TOTAL_PICKED_QTY,p.TOLOC,isnull(c.PICKED_QTY,0) as c_p,isnull(c.CONTROLLED_QTY,0) as c_c
		--,pl.*
		--,pc.*
		--,t.*
		--,xp.*
		--,c.*
		--,*
		--,od.ORIGINALQTY as s1, sum(isnull(t.QTY,0)) as s_t, sum(isnull(xp.PICKEDQTY,0)) as s_xp, /* sum(isnull(xc.PICKEDQTY,0)) as s_xc, */ sum(isnull(pc.QTY,0)) as s_pc
	into #ERRORS
	from #ORDERS xo
		join wh1.ORDERS o
			join wh1.STORER cr on o.CONSIGNEEKEY = cr.STORERKEY
		on o.ORDERKEY = xo.ORDERKEY
		join wh1.ORDERSTATUSSETUP s on s.CODE = o.[STATUS]
		left join wh1.ORDERDETAIL od on od.ORDERKEY = o.ORDERKEY
		join wh1.SKU n on n.SKU = od.SKU AND n.STORERKEY = od.STORERKEY
		-- все отборы (общее количество)
		left join (
			select
				p.ORDERKEY, p.ORDERLINENUMBER,
				sum(p.QTY) as TOTAL_PICKED_QTY
--?				sum(t.QTY) as TOTAL_PICKED_QTY
			from wh1.PICKDETAIL p
--?				join wh1.TASKDETAIL t on t.PICKDETAILKEY = p.PICKDETAILKEY
--?			where t.QTY <> 0 and t.[STATUS] > 0
--?				and ( /* t.TOLOC in ('PL_KONTR') or */ t.STATUSMSG not in ('Canceled/Rejected By User') ) -- к сожалению, STATUS всегда 9
			group by p.ORDERKEY, p.ORDERLINENUMBER
		) xp on xp.ORDERKEY = od.ORDERKEY and xp.ORDERLINENUMBER = od.ORDERLINENUMBER
		-- отборы пофамильно
		left join (
			select
				p.ORDERKEY, p.ORDERLINENUMBER,
				sum(t.QTY) as PICKED_QTY,
				t.EDITWHO as PICKED_USER,
				p.CASEID, p.LOT,
				case when t.TOLOC in ('PL_KONTR') then 'PL_KONTR' else '' end as TOLOC
			from wh1.PICKDETAIL p
				join wh1.TASKDETAIL t on t.PICKDETAILKEY = p.PICKDETAILKEY
			where t.QTY <> 0 and t.[STATUS] > 0 and t.STATUSMSG not in ('Canceled/Rejected By User') -- к сожалению, STATUS всегда 9
			group by
				p.ORDERKEY, p.ORDERLINENUMBER,
				t.EDITWHO, p.CASEID, p.LOT,
				case when t.TOLOC in ('PL_KONTR') then 'PL_KONTR' else '' end
		) p on p.ORDERKEY = od.ORDERKEY and p.ORDERLINENUMBER = od.ORDERLINENUMBER
		-- подлежащее контролю количество
		left join (
			select
				p.*,
				sum(pc.QTY) as CONTROLLED_QTY,
				pc.EDITWHO as CONTROLLED_USER
			from (
				select
					p.ORDERKEY, p.ORDERLINENUMBER,
					p.CASEID, p.LOT,
					sum(p.QTY) as PICKED_QTY
				from wh1.PICKDETAIL p
				where p.LOC not in ('PL_KONTR')
				group by p.ORDERKEY, p.ORDERLINENUMBER, p.CASEID, p.LOT
			) p
				join wh1.PICKCONTROL pc on pc.CASEID = p.CASEID and pc.LOT = p.LOT
			group by p.ORDERKEY, p.ORDERLINENUMBER, p.CASEID, p.LOT, p.PICKED_QTY, pc.EDITWHO
		) c on c.ORDERKEY = p.ORDERKEY and c.ORDERLINENUMBER = p.ORDERLINENUMBER and c.CASEID = p.CASEID and c.LOT = p.LOT
	--group by
	--	o.ORDERKEY,o.EXTERNORDERKEY,s.[DESCRIPTION],
	--	od.ORDERLINENUMBER,
	--	od.SKU,
	--	n.DESCR,
	--	od.LOTTABLE02,
	--	od.LOTTABLE05,
	--	od.ORIGINALQTY,
	--	xp.PICKED_QTY,
	--	t.EDITWHO
	--	--xc.ORDERKEY,
	--	--xc.CONTROLLED_QTY,
	--	--xc.EDITWHO
	where od.ORIGINALQTY <> isnull(xp.TOTAL_PICKED_QTY,0) -- общий сбор <> заказу
		or ( isnull(p.TOLOC,'') <> 'PL_KONTR' and isnull(c.PICKED_QTY,0) <> isnull(c.CONTROLLED_QTY,0) ) -- 
	order by o.ORDERKEY, od.ORDERLINENUMBER
	
	
	-- дополнительная зачистка
	delete x
	from #ERRORS x join (
		select ORDERKEY, ORDERLINENUMBER, ORIGINALQTY
		from #ERRORS
		group by ORDERKEY, ORDERLINENUMBER, ORIGINALQTY
		having ORIGINALQTY = sum(PICKED_QTY) and ORIGINALQTY = sum(CONTROLLED_QTY)
	) e on x.ORDERKEY = e.ORDERKEY and x.ORDERLINENUMBER = e.ORDERLINENUMBER

	
	select * from #ERRORS order by EXTERNORDERKEY, ORDERLINENUMBER
	
end

