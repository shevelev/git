ALTER PROCEDURE [rep].[Performance_and_errors_of_order_picker]
	@date_from datetime = NULL,
	@time_from varchar(5) = NULL,
	@date_to datetime = NULL,
	@time_to varchar(5) = NULL
as
begin
	set NOCOUNT on
	
	set @date_from = isnull(@date_from,getdate())
	set @date_to = isnull(@date_to,getdate())
	
	if dbo.sub_udf_common_regex_is_match(@time_from,'^([01][0-9]|2[0-3]):[0-5][0-9]$') = 1
		set @date_from = convert(datetime, convert(varchar(10),@date_from,120) + ' ' + @time_from + ':00',120)
	
	if dbo.sub_udf_common_regex_is_match(@time_to,'^([01][0-9]|2[0-3]):[0-5][0-9]$') = 1
		set @date_to = convert(datetime, convert(varchar(10),@date_to,120) + ' ' + @time_to + ':59',120)
	else
		set @date_to = @date_to + convert(time,'23:59:59.997')
	
	
	----------------------------------------------------------
		select 	c.ORDERKEY, c.SKU, sum(pc.QTY) as CONTROLLED_QTY
		into #proverennoi
		from wh1.PICKCONTROL pc with (NOLOCK,NOWAIT)
			join (select distinct pd.ORDERKEY, pd.SKU, pd.CASEID, pd.LOT from wh1.PICKDETAIL pd with (NOLOCK,NOWAIT) 
				join wh1.ITRN i on i.SOURCEKEY = pd.PICKDETAILKEY
				where  ( @date_from is NULL or i.EDITDATE >= @date_from )
				and ( @date_to is NULL or i.EDITDATE < @date_to )) c on c.CASEID = pc.CASEID and c.LOT = pc.LOT 
		group by c.ORDERKEY, c.SKU
----------------------------------------------------------


----------------------------------------------------------

			select p.ORDERKEY, p.SKU, sum(p.QTY) as PICKED_QTY
			into #otobranoe
			from wh1.ITRN i with (NOLOCK,NOWAIT)
				join wh1.PICKDETAIL p with (NOLOCK,NOWAIT) on i.SOURCEKEY = p.PICKDETAILKEY
			where i.SOURCETYPE = 'PICKING'
				and p.[STATUS] = '9'
				and i.TOLOC <> 'PL_KONTR'
				and ( @date_from is NULL or i.EDITDATE >= @date_from )
				and ( @date_to is NULL or i.EDITDATE < @date_to )
			group by
				p.ORDERKEY, p.SKU
----------------------------------------------------------		


----------------------------------------------------------
			select
				p.ORDERKEY, p.SKU,
				sum(p.QTY) as FULL_QTY
				into #otobranoeall
			from wh1.ITRN i with (NOLOCK,NOWAIT)
				join wh1.PICKDETAIL p with (NOLOCK,NOWAIT) on i.SOURCEKEY = p.PICKDETAILKEY
			where i.SOURCETYPE = 'PICKING'
				and p.[STATUS] = '9'
				--and i.TOLOC <> 'PL_KONTR'
				and ( @date_from is NULL or i.EDITDATE >= @date_from )
				and ( @date_to is NULL or i.EDITDATE < @date_to )
			group by
				p.ORDERKEY, p.SKU
----------------------------------------------------------		


	
	
	-- ���������� ������
	select c.ORDERKEY, c.SKU, p.PICKED_QTY, pp.FULL_QTY, c.CONTROLLED_QTY
	into #PROBLEM_ROWS
	from #proverennoi c
		-- ���������� �� ������ ������������
		join #otobranoe p on p.ORDERKEY = c.ORDERKEY and p.SKU = c.SKU
		-- ����� ���������� ����������
		join #otobranoeall pp on pp.ORDERKEY = c.ORDERKEY and pp.SKU = c.SKU
	where c.CONTROLLED_QTY <> p.PICKED_QTY
		and c.CONTROLLED_QTY <> pp.FULL_QTY -- ������� ������� (�������! ����� �� ������ ����...)
	
	
	-- -- 8< -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
		
	---- �������� ��� ������������� ��������
	--select @current_date as EDITDATE, 1 as COLUMN_ID, '������' as HDR1, '���������' as HDR2, NULL as ROWS_CNT
	--union all
	--select @current_date as EDITDATE, 2 as COLUMN_ID, '������' as HDR1, '�������' as HDR2, NULL as ROWS_CNT
	--union all
	--select @current_date as EDITDATE, 3 as COLUMN_ID, '������' as HDR1, '�������.' as HDR2, NULL as ROWS_CNT
	--union all
	--select @current_date as EDITDATE, 4 as COLUMN_ID, '������' as HDR1, '���' as HDR2, NULL as ROWS_CNT
	--union all
	--select @current_date as EDITDATE, 5 as COLUMN_ID, '������' as HDR1, '�������.' as HDR2, NULL as ROWS_CNT
	--union all
	--select @current_date as EDITDATE, 6 as COLUMN_ID, '���������� �����������' as HDR1, '����.����� - EA_IN' as HDR2, NULL as ROWS_CNT
	--union all
	--select @current_date as EDITDATE, 7 as COLUMN_ID, '���������� �����������' as HDR1, '����� - ����.�����' as HDR2, NULL as ROWS_CNT
	--union all
	--select @current_date as EDITDATE, 8 as COLUMN_ID, '������' as HDR1, '�����' as HDR2, NULL as ROWS_CNT
	--union all
	--select @current_date as EDITDATE, 9 as COLUMN_ID, '������' as HDR1, '������' as HDR2, NULL as ROWS_CNT
	
	create table #PICKERS (
		ROW_ID int NOT NULL,
		USR_NAME varchar(255) NULL,
		COLUMN_ID int NULL,
		HDR1 varchar(255) NOT NULL,
		HDR2 varchar(255) NULL,
		ROWS_CNT int NOT NULL
	)
	
	insert into #PICKERS
	select
		1 as ROW_ID,
		pu.usr_name,
		case dbo.sub_udf_get_locgroup_by_loc(i.FROMLOC)
			when 'P' then case when fl.LOCATIONTYPE = 'PICK' then 2 else 1 end -- ����������: ��������� "���������" ������ �������� ������ ������� ����
			when 'K' then 2
			when 'X' then 3
			when 'D' then 4
			when 'SD' then 5
			else NULL
		end as COLUMN_ID,
		'������ �� �������' as HDR1,
		case dbo.sub_udf_get_locgroup_by_loc(i.FROMLOC)
			when 'P' then case when fl.LOCATIONTYPE = 'PICK' then '�������' else '���������' end -- ����������: ��������� "���������" ������ �������� ������ ������� ����
			when 'K' then '�������'
			when 'X' then '�������.'
			when 'D' then '���'
			when 'SD' then '�������.'
			else NULL
		end as HDR2,
		count(*) as ROWS_CNT
	from wh1.ITRN i with (NOLOCK,NOWAIT)
		join wh1.LOC fl with (NOLOCK,NOWAIT) on i.FROMLOC = fl.LOC
		join wh1.LOC tl with (NOLOCK,NOWAIT) on i.TOLOC = tl.LOC
		join ssaadmin.pl_usr pu with (NOLOCK,NOWAIT) on i.EDITWHO = pu.usr_login
	where i.TRANTYPE = 'MV'
		--and i.TOLOC in ('BAD_PICKTO','HOL_PICKTO','PICKTO','PL_KONTR','SD_PICKTO')
		and tl.LOCATIONTYPE = 'PICKTO'
		and i.[STATUS] = 'OK'
		and ( @date_from is NULL or i.EDITDATE >= @date_from )
		and ( @date_to is NULL or i.EDITDATE < @date_to )
	group by dbo.sub_udf_get_locgroup_by_loc(i.FROMLOC), fl.LOCATIONTYPE, pu.usr_name -- �������� ��������� ���������� ����� � �������� ������������, �� ��� ������ ������
	
	union all
	
	select
		1 as ROW_ID,
		pu.usr_name,
		6 as COLUMN_ID,
		'���������� �����������' as HDR1,
		'��������� - EA_IN' as HDR2, 
		count(*) as ROWS_CNT
	from wh1.ITRN i with (NOLOCK,NOWAIT)
		join wh1.LOC l with (NOLOCK,NOWAIT) on i.TOLOC = l.LOC
		join ssaadmin.pl_usr pu with (NOLOCK,NOWAIT) on i.EDITWHO = pu.usr_login
	where i.TRANTYPE = 'MV'
		and dbo.sub_udf_get_locgroup_by_loc(i.FROMLOC) = 'P'
		--and i.TOLOC = 'EA_IN'
		and l.LOCATIONTYPE = 'PND'
		and i.[STATUS] = 'OK'
		and ( @date_from is NULL or i.EDITDATE >= @date_from )
		and ( @date_to is NULL or i.EDITDATE < @date_to )
	group by pu.usr_name
	
	union all
	
	select
		1 as ROW_ID,
		pu.usr_name,
		7 as COLUMN_ID,
		'���������� �����������' as HDR1,
		'����� - ���������' as HDR2,
		count(*) as ROWS_CNT
	from wh1.ITRN i with (NOLOCK,NOWAIT)
		join ssaadmin.pl_usr pu with (NOLOCK,NOWAIT) on i.EDITWHO = pu.usr_login
	where i.TRANTYPE = 'MV'
		and i.FROMLOC in ('PRIEM','PRIEM_PL')
		and dbo.sub_udf_get_locgroup_by_loc(i.TOLOC) = 'P'
		and i.[STATUS] = 'OK'
		and ( @date_from is NULL or i.EDITDATE >= @date_from )
		and ( @date_to is NULL or i.EDITDATE < @date_to )
	group by pu.usr_name
	
	-- ��������� ����� � ��������� ������
	insert into #PICKERS
	select
		1 as ROW_ID,
		p.USR_NAME,
		8 as COLUMN_ID,
		'������' as HDR1,
		'�����' as HDR2,
		sum(p.ROWS_CNT) as ROWS_CNT
	from #PICKERS p
	group by p.USR_NAME
	
	
	insert into #PICKERS
	select
		1 as ROW_ID,
		pu.usr_name,
		9 as COLUMN_ID,
		'������' as HDR1,
		'������' as HDR2,
		count(distinct w.ORDERKEY+w.SKU) as ROWS_CNT
	from (
		select
			x.ORDERKEY, x.SKU,
			count(distinct i.ADDWHO) as WORKERS,
			min(i.ADDWHO) as ADDWHO
		from wh1.ITRN i with (NOLOCK,NOWAIT)
			join wh1.PICKDETAIL p with (NOLOCK,NOWAIT) on i.SOURCEKEY = p.PICKDETAILKEY
			join #PROBLEM_ROWS x on x.ORDERKEY = p.ORDERKEY and x.SKU = p.SKU
		group by
			x.ORDERKEY, x.SKU
		having count(distinct i.ADDWHO) = 1
	) w
		join ssaadmin.pl_usr pu with (NOLOCK,NOWAIT) on w.ADDWHO = pu.usr_login
	group by pu.usr_name
	
	
	
	
	-- ������� ������� ������, ��� ������ ������� � ������� �������
	delete from #PICKERS where COLUMN_ID is NULL
	
	-- ���������� ������ �����
	update p set
		ROW_ID = RN
	from (
		select
			ROW_ID,
			dense_rank() over (order by USR_NAME) as RN
		from #PICKERS
	) p
	
	select * from #PICKERS order by ROW_ID, COLUMN_ID
end

