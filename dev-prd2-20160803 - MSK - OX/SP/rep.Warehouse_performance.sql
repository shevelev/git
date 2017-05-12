/*
Отчет "Производительность склада"
*/
ALTER PROCEDURE [rep].[Warehouse_performance]
	@date_from datetime = NULL,
	@date_to datetime = NULL
as
begin
	set NOCOUNT on
	
	if object_id('tempdb..#ROWS') is NOT NULL drop table #ROWS
	
	declare @current_date datetime
	
	if @date_to is NOT NULL
	begin
		set @current_date = dbo.udf_get_date_from_datetime(@date_to)
		if @date_to = @current_date set @date_to = @date_to + 1
	end
	else
		set @current_date = dbo.udf_get_date_from_datetime(getdate())
	
	create table #ROWS (
		EDITDATE datetime NOT NULL,
		COLUMN_ID tinyint NOT NULL,
		HDR1 varchar(20) NOT NULL,
		HDR2 varchar(20) NOT NULL,
		ID varchar(20) NULL,
		STDCUBE float NOT NULL
	)
	
	insert into #ROWS
	-- болванка для отсутствующих значений
	select @current_date as EDITDATE, 1 as COLUMN_ID, 'Приемка' as HDR1, 'Строки' as HDR2, NULL as ID, 0 as STDCUBE
	union all
	select @current_date as EDITDATE, 2 as COLUMN_ID, 'Приемка' as HDR1, 'Объем, м3' as HDR2, NULL as ID, 0 as STDCUBE
	union all
	select @current_date as EDITDATE, 3 as COLUMN_ID, 'Пополнение' as HDR1, 'Строки' as HDR2, NULL as ID, 0 as STDCUBE
	union all
	select @current_date as EDITDATE, 4 as COLUMN_ID, 'Комплектация' as HDR1, 'Заказы' as HDR2, NULL as ID, 0 as STDCUBE
	union all
	select @current_date as EDITDATE, 5 as COLUMN_ID, 'Комплектация' as HDR1, 'Строки' as HDR2, NULL as ID, 0 as STDCUBE
	union all
	select @current_date as EDITDATE, 6 as COLUMN_ID, 'Контроль' as HDR1, 'Заказы' as HDR2, NULL as ID, 0 as STDCUBE
	union all
	select @current_date as EDITDATE, 7 as COLUMN_ID, 'Контроль' as HDR1, 'Строки' as HDR2, NULL as ID, 0 as STDCUBE
	union all
	select @current_date as EDITDATE, 8 as COLUMN_ID, 'Отгрузка' as HDR1, 'Заказы' as HDR2, NULL as ID, 0 as STDCUBE
	union all
	select @current_date as EDITDATE, 9 as COLUMN_ID, 'Отгрузка' as HDR1, 'Объем, м3' as HDR2, NULL as ID, 0 as STDCUBE
	
	--union all
	insert into #ROWS
	
	select dbo.udf_get_date_from_datetime(p.EDITDATE) as EDITDATE, 1 as COLUMN_ID, 'Приемка' as HDR1, 'Строки' as HDR2, p.POKEY + p.POLINENUMBER as ID, 0 as STDCUBE
	from wh1.PODETAIL p with (NOLOCK,NOWAIT)
	where EXTERNPOKEY='' and EXTERNLINENO='' 
	--p.WHSEID = 'dbo'
		and ( @date_from is NULL or p.EDITDATE >= @date_from )
		and ( @date_to is NULL or p.EDITDATE < @date_to )

	--union all
	insert into #ROWS
	
	select dbo.udf_get_date_from_datetime(p.EDITDATE), 2 as COLUMN_ID, 'Приемка' as HDR1, 'Объем, м3' as HDR2, NULL as ID, s.STDCUBE * p.QTYRECEIVED
	from wh1.PODETAIL p with (NOLOCK,NOWAIT)
		join wh1.SKU s on s.STORERKEY = p.STORERKEY and s.SKU = p.SKU
	where EXTERNPOKEY='' and EXTERNLINENO='' 
	--p.WHSEID = 'dbo'
		and ( @date_from is NULL or p.EDITDATE >= @date_from )
		and ( @date_to is NULL or p.EDITDATE < @date_to )

	--union all
	insert into #ROWS

	select dbo.udf_get_date_from_datetime(i.EDITDATE), 3 as COLUMN_ID, 'Пополнение' as HDR1, 'Строки' as HDR2, i.ITRNKEY as ID, 0 as STDCUBE
	from wh1.ITRN i with (NOLOCK,NOWAIT)
		join wh1.LOC l on i.FROMLOC = l.LOC
	where l.LOCATIONTYPE = 'CASE'
		and i.TOLOC = 'EA_IN'
		and ( @date_from is NULL or i.EDITDATE >= @date_from )
		and ( @date_to is NULL or i.EDITDATE < @date_to )

	--union all
	insert into #ROWS

	--select distinct dbo.udf_get_date_from_datetime(i.EDITDATE), 4 as COLUMN_ID, 'Комплектация' as HDR1, 'Заказы' as HDR2, p.ORDERKEY as ID, 0 as STDCUBE
	--from wh1.PICKDETAIL p with (NOLOCK,NOWAIT)
	--	join wh1.ITRN i on i.SOURCEKEY = p.PICKDETAILKEY and i.TRANTYPE = 'MV'
	--where p.[STATUS] >= '5' -- Picked
	--	and ( @date_from is NULL or i.EDITDATE >= @date_from )
	--	and ( @date_to is NULL or i.EDITDATE < @date_to )
		
		select distinct dbo.udf_get_date_from_datetime(i.EDITDATE), 4 as COLUMN_ID, 'Комплектация' as HDR1, 'Заказы' as HDR2, p.ORDERKEY as ID, 0 as STDCUBE
	from wh1.ITRN i with (NOLOCK,NOWAIT)
		join wh1.PICKDETAIL p on i.SOURCEKEY = p.PICKDETAILKEY and i.TRANTYPE = 'MV'
	where p.[STATUS] >= '5' -- Picked
		and ( @date_from is NULL or i.EDITDATE >= @date_from )
		and ( @date_to is NULL or i.EDITDATE < @date_to )

	--union all
	insert into #ROWS

	--select distinct dbo.udf_get_date_from_datetime(i.EDITDATE), 5 as COLUMN_ID, 'Комплектация' as HDR1, 'Строки' as HDR2, p.ORDERKEY + p.ORDERLINENUMBER as ID, 0 as STDCUBE
	--from wh1.PICKDETAIL p with (NOLOCK,NOWAIT)
	--	join wh1.ITRN i on i.SOURCEKEY = p.PICKDETAILKEY and i.TRANTYPE = 'MV'
	--where p.[STATUS] >= '5' -- Picked
	--	and ( @date_from is NULL or i.EDITDATE >= @date_from )
	--	and ( @date_to is NULL or i.EDITDATE < @date_to )
		
		
			select distinct dbo.udf_get_date_from_datetime(i.EDITDATE), 5 as COLUMN_ID, 'Комплектация' as HDR1, 'Строки' as HDR2, p.ORDERKEY + p.ORDERLINENUMBER as ID, 0 as STDCUBE
	from wh1.ITRN i with (NOLOCK,NOWAIT)
		join wh1.PICKDETAIL p on i.SOURCEKEY = p.PICKDETAILKEY and i.TRANTYPE = 'MV'
	where p.[STATUS] >= '5' -- Picked
		and ( @date_from is NULL or i.EDITDATE >= @date_from )
		and ( @date_to is NULL or i.EDITDATE < @date_to )
		

	--union all
	insert into #ROWS

	select distinct dbo.udf_get_date_from_datetime(pc.EDITDATE), 6 as COLUMN_ID, 'Контроль' as HDR1, 'Заказы' as HDR2, pd.ORDERKEY as ID, 0 as STDCUBE
	from wh1.PICKCONTROL pc  with (NOLOCK,NOWAIT)
		join wh1.PICKDETAIL pd on pd.CASEID = pc.CASEID and pd.LOT = pc.LOT
	where pc.[STATUS] = 1
		and ( @date_from is NULL or pc.EDITDATE >= @date_from )
		and ( @date_to is NULL or pc.EDITDATE < @date_to )

	--union all
	insert into #ROWS

	select distinct dbo.udf_get_date_from_datetime(pc.EDITDATE), 7 as COLUMN_ID, 'Контроль' as HDR1, 'Строки' as HDR2, pd.ORDERKEY + pd.ORDERLINENUMBER as ID, 0 as STDCUBE
	from wh1.PICKCONTROL pc with (NOLOCK,NOWAIT)
		join wh1.PICKDETAIL pd on pd.CASEID = pc.CASEID and pd.LOT = pc.LOT
	where pc.[STATUS] = 1
		and ( @date_from is NULL or pc.EDITDATE >= @date_from )
		and ( @date_to is NULL or pc.EDITDATE < @date_to )

	--union all
	insert into #ROWS

	select distinct dbo.udf_get_date_from_datetime(o.EDITDATE), 8 as COLUMN_ID, 'Отгрузка' as HDR1, 'Заказы' as HDR2, o.ORDERKEY as ID, 0 as STDCUBE
	from wh1.ORDERDETAIL o with (NOLOCK,NOWAIT)
	where o.[STATUS] >= '78' -- Контроль пройден\Не требуется
		and ( @date_from is NULL or o.EDITDATE >= @date_from )
		and ( @date_to is NULL or o.EDITDATE < @date_to )

	--select * from wh1.ORDERSTATUSSETUP

	--union all
	insert into #ROWS

	select dbo.udf_get_date_from_datetime(o.EDITDATE), 9 as COLUMN_ID, 'Отгрузка' as HDR1, 'Объем, м3' as HDR2, NULL as ID, s.STDCUBE * o.SHIPPEDQTY
	from wh1.ORDERDETAIL o with (NOLOCK,NOWAIT)
		join wh1.SKU s on s.SKU = o.SKU and s.STORERKEY = o.STORERKEY
	where o.[STATUS] >= '95' -- Отгрузка завершена
		and ( @date_from is NULL or o.EDITDATE >= @date_from )
		and ( @date_to is NULL or o.EDITDATE < @date_to )

	
	select EDITDATE, COLUMN_ID, HDR1, HDR2, count(ID) as CNT_ID, sum(STDCUBE) as SUM_STDCUBE
	from #ROWS
	group by EDITDATE, COLUMN_ID, HDR1, HDR2
	order by COLUMN_ID

end


