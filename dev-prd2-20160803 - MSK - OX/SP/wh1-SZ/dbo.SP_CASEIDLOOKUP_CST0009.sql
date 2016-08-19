
ALTER PROCEDURE [dbo].[SP_CASEIDLOOKUP_CST0009] 
@user varchar(20),
@area varchar(20)
AS

declare @queryid varchar(15)
--declare @user varchar(10) set @user = 'timofeev'
--declare @area varchar(10) set @area = '2323'


	-- новый номер queryid
	exec dbo.DA_GetNewKey 'wh1','queryid',@queryid output
-- выбор прав пользователя
--select * into #userright from wh1.TASKMANAGERUSERDETAIL where USERKEY = @user and AREAKEY = @area
declare @allowpiece varchar (10)
declare @ALLOWPALLET varchar (10)
declare @ALLOWCASE varchar (10)
declare @caseid varchar (20)

select * into #userright 
			from wh1.TASKMANAGERUSERDETAIL 
	where PERMISSIONTYPE = 'pk' and USERKEY = @user and PERMISSION = 1


--select * from #userright

--select ALLOWCASE, ALLOWPALLET, allowpiece into #userright from wh1.TASKMANAGERUSERDETAIL 
--  where PERMISSIONTYPE = 'pk' and AREAKEY = 'facility' and USERKEY = 'ssa' and PERMISSION = 1


print 'выбираем свободные кейсы'
select distinct pd.caseid, pd.STATUS, pd.LOC, pd.orderkey, ad.areakey, l.LOCATIONTYPE, o.PRIORITY
	into #tmpc
	from wh1.pickDETAIL pd join wh1.loc l on pd.LOC = l.loc
			join wh1.AREADETAIL ad on ad.putawayzone = l.PUTAWAYZONE
			join wh1.ORDERS o on o.ORDERKEY = pd.ORDERKEY
	where pd.[STATUS] = 1 --and ad.areakey = case when isnull(@area,'') = '' then ad.areakey else @area end 
		and isnull(pd.PDUDF3,'') = ''
		and dateadd(mi,3,pd.GIVEDATE) < GETDATE() 
		and o.STATUS < '92'	-- '1900-01-01 00:00:00.000' -- кейс не выдан в работу


----select * from #tmpc

--print 'выбираем свободные кейсы'
--select distinct pd.caseid, pd.STATUS, pd.LOC, pd.orderkey, ad.areakey, l.LOCATIONTYPE, o.PRIORITY
--	into #tmpc
--	from wh1.pickDETAIL pd join wh1.loc l on pd.LOC = l.loc
--			join wh1.AREADETAIL ad on ad.putawayzone = l.PUTAWAYZONE
--			join wh1.ORDERS o on o.ORDERKEY = pd.ORDERKEY
--	where pd.[STATUS] = 1 and ad.areakey = case when isnull(@area,'') = '' then ad.areakey else @area end and isnull(pd.PDUDF3,'') = ''
--		and dateadd(mi,3,pd.GIVEDATE) < GETDATE() and o.STATUS < '92'	-- '1900-01-01 00:00:00.000' -- кейс не выдан в работу

print 'выбираем кейсы в работе'
--по таскдетейл
select td.caseid into #tmpcw
	from wh1.taskdetail td join #tmpc t on td.CASEID = t.CASEID where td.STATUS != '0'

print 'выбираем кейсы, у которых нет задач'
select t.caseid into #tmpnt
	from wh1.taskdetail td right join #tmpc t on isnull(td.CASEID,t.CASEID) = t.CASEID
	where isnull(td.CASEID,'') = ''

--по пикдетайл
--select distinct pd.caseid into #tmpcw
--	from wh1.PICKDETAIL pd join #tmpc t on pd.CASEID = t.CASEID where pd.STATUS != '1'
	
print 'удаляем кейсы в работе'
delete from t
	from #tmpc t join #tmpcw tw on t.CASEID = tw.CASEID
	
print 'удаляем кейсы без задач'
delete from t
	from #tmpc t join #tmpnt tw on t.CASEID = tw.CASEID
	
	
--delete from #tmpc where CASEID = (select caseid from #tmpc where [STATUS] != 1)

--select * from #tmpc


if (select COUNT(caseid) from #tmpc) != 0  --нет кейсов для работы
	begin
		
		select top(1)  @caseid = caseid, @area = t.areakey
		from #tmpc t join #userright ur on t.AREAKEY = ur.areakey and 
				(t.LOCATIONTYPE = case when ur.ALLOWCASE = 1 then t.LOCATIONTYPE else ur.ALLOWCASE end
				 or t.LOCATIONTYPE = case when ur.ALLOWPALLET = 1 then t.LOCATIONTYPE else ur.ALLOWPALLET end  
				 or t.LOCATIONTYPE = case when ur.ALLOWPIECE = 1 then t.LOCATIONTYPE else ur.ALLOWPIECE end)
				order by t.PRIORITY asc

		--select *
		--from #tmpc t join #userright ur on t.AREAKEY = ur.areakey and 
		--		(t.LOCATIONTYPE = case when ur.ALLOWCASE = 1 then t.LOCATIONTYPE else ur.ALLOWCASE end
		--		 or t.LOCATIONTYPE = case when ur.ALLOWPALLET = 1 then t.LOCATIONTYPE else ur.ALLOWPALLET end  
		--		 or t.LOCATIONTYPE = case when ur.ALLOWPIECE = 1 then t.LOCATIONTYPE else ur.ALLOWPIECE end)
		--		order by t.PRIORITY asc

--print @area
		update wh1.pickdetail set givedate = GETDATE() where CASEID = @caseid -- отметка о выдаче кейса в работу
		
		insert into wh1.caselog (caseid, userkey, [dateadd], area) select @caseid, @user,  getdate(), @area
		
		delete from wh1.CASEIDLOOKUP_CST0009 --очистка таблицы еперд вставкой нового кейса
				
		insert into wh1.CASEIDLOOKUP_CST0009 (QUERYID, VALUE, descr)
		select top(1)  @queryid, caseid,CASEID
		--+' '+cast((select cast(sum( p.QTY*s.STDCUBE) as decimal(20,7))
		--					from wh1.pickdetail p join wh1.SKU s on p.SKU = s.SKU and p.STORERKEY = s.STORERKEY  
		--					where p.CASEID = t.caseid) as varchar(20))
		from #tmpc t 
			where CASEID = @caseid
		
		
		--update wh1.PICKDETAIL set PDUDF3 = GETDATE() where CASEID = @caseid
	end
else
	begin
		print''
	end	


drop table #tmpc
drop table #tmpcw
drop table #tmpnt
drop table #userright


return @queryid

