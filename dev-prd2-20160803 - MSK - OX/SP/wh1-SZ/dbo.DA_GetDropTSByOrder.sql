
ALTER PROCEDURE [dbo].[DA_GetDropTSByOrder] (
	@wh varchar(10), 
	@orderkey varchar(18) = '', 
	@saveData int = 0, -- ��������� ������ � PackLoadSend
	@returnData int = 1 -- ���������� �������������� �������
)
as


--declare
--	@wh varchar(10), 
--	@orderkey varchar(18), 
--	@saveData int, -- ��������� ������ � PackLoadSend
--	@returnData int -- ���������� �������������� �������
--select 	@wh ='WH1', @orderkey = '0000017345', 
--	@saveData  = 0, -- ��������� ������ � PackLoadSend
--	@returnData  = 1 -- ���������� �������������� �������

set nocount on

	declare @sql varchar(max)
	create table #cases (serialkey int, caseid varchar(50)  COLLATE Cyrillic_General_CI_AS ,
		 dropid varchar(50) COLLATE Cyrillic_General_CI_AS , tsid varchar(50) COLLATE Cyrillic_General_CI_AS )

	set @sql = 'insert into #cases (serialkey, caseid) 
		select pd.serialkey, pd.caseid  
	from '+@wh+'.pickdetail pd	'
	+ case when isnull(@orderkey,'') ='' then '' else ' where orderkey = '''+@orderkey+'''' end
	exec(@sql)


	print @sql
	--update #cases set dropid='', tsid=''

	select cast(0 as int)serialkey, dropid, childid, cast (0 as int)lev into #dd1 from wh1.dropiddetail where 1=2
	select cast(0 as int)serialkey, dropid, childid, cast (0 as int)lev into #dd2 from wh1.dropiddetail where 1=2

	--select caseid, caseid as dropid, caseid as tsid into #pls from wh40.pickdetail where 1=2
	set @sql = 'insert #dd1
	select dd.serialkey, dd.dropid, dd.childid, dropidtype 
	from '+@wh+'.dropiddetail dd
		join '+@wh+'.dropid d on d.dropid = dd.dropid
	where childid in (select distinct caseid from #cases)'
	exec(@sql)
	print @sql


	
	--select * from #dd1
		
	update cs set dropid=dd.dropid  
	from #cases cs 
		join #dd1 dd on dd.childid = cs.caseid

	/* ������ �� ������������ */
	declare @maxlevels int, --����������� ���������� ���-�� ������� �����������. 
							--�� ���������� �������� ���������� �������������� ����� �� �����
			@iLevel int -- ������� �������
	select @maxLevels = 10, @iLevel=1

	--select * from #cases
	while exists (select top 1 * from #dd1) and (@iLevel <= @maxLevels)
	begin
		-- �������� � #dd2 ���� ��������� ������/������ �� #dd1
		set @sql = 'insert #dd2 select dd.serialkey, dd.dropid, dd.childid, dropidtype 
			from '+@wh+'.dropiddetail dd
				join '+@wh+'.dropid d on d.dropid = dd.dropid 
			where childid in (select dropid from #dd1)'
		exec(@sql)
	print @sql			

		-- ������� #dd1 � �������� � ��� ������ �� #dd2, ������ #dd2 
		delete from #dd1
		insert #dd1 (serialkey, dropid, childid, lev) 
			select serialkey, dropid, childid, lev from #dd2
		delete from #dd2
		-- ���������� ��������� ��������� �������� ��� dropid 
		-- ��� ����� ����� � ������� ��������� ��� �������� ����/����
		update  cs set dropid=dd.dropid  
		from #cases cs 
			join #dd1 dd on dd.childid = cs.dropid
		where dd.lev=1
		-- ���������� ��������� ��������� �������� ��� tsid 
		update cs set cs.tsid=dd.dropid  
		from #cases cs 
			join #dd1 dd on dd.childid = cs.dropid
		where dd.lev=4
		--select * from #dd1
		
		set @iLevel = @iLevel+1

	end
	
--	if @saveData = 1
--	begin
--		set @sql = 'update pls set pls.caseid=cs.caseid , pls.dropid=cs.dropid , pls.tsid=cs.tsid 
--			from '+@wh+'.packloadsend pls 
--				join #cases cs on cs.serialkey = pls.serialkey'
--		exec(@sql)
--	end
--	if @returnData = 1
		--select distinct caseid, dropid, tsid from #cases
		select * from #cases



	--drop table #ttt
	drop table #dd1
	drop table #dd2
	drop table #cases
--	drop table #ex
--	drop table #notEx


