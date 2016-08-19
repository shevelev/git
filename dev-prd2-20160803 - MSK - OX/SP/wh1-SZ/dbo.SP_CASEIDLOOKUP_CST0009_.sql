
ALTER PROCEDURE [dbo].[SP_CASEIDLOOKUP_CST0009_] 
@user varchar(10),
@area varchar(10)
AS

declare @queryid varchar(15)
--declare @user varchar(10) set @user = 'ssa'
--declare @area varchar(10) set @area = 'facility'


	-- новый номер queryid
	exec dbo.DA_GetNewKey 'wh1','queryid',@queryid output
-- выбор прав пользователя
--select * into #userright from wh1.TASKMANAGERUSERDETAIL where USERKEY = @user and AREAKEY = @area
declare @allowpiece varchar (10)
declare @ALLOWPALLET varchar (10)
declare @ALLOWCASE varchar (10)


select	@ALLOWCASE = case when ALLOWCASE = 1 then 'CASE' else '' end, 
		@ALLOWPALLET = case when ALLOWPALLET = 1 then 'OTHER' else '' end, 
		@allowpiece = case when allowpiece = 1 then 'PIck' else '' end 
			--into #userright 
			from wh1.TASKMANAGERUSERDETAIL 
	where PERMISSIONTYPE = 'pk' and AREAKEY = @area and USERKEY = @user and PERMISSION = 1

print @ALLOWCASE+ @ALLOWPALLET+ @allowpiece

--select ALLOWCASE, ALLOWPALLET, allowpiece into #userright from wh1.TASKMANAGERUSERDETAIL 
--  where PERMISSIONTYPE = 'pk' and AREAKEY = 'facility' and USERKEY = 'ssa' and PERMISSION = 1

select distinct pd.caseid, pd.STATUS, pd.LOC, orderkey, ad.areakey, l.LOCATIONTYPE
	into #tmpc
	from wh1.pickDETAIL pd join wh1.loc l on pd.LOC = l.loc
			join wh1.AREADETAIL ad on ad.putawayzone = l.PUTAWAYZONE
	where pd.[STATUS] = 1 and ad.areakey = @area 

insert into wh1.CASEIDLOOKUP_CST0009 (QUERYID, VALUE, descr)
select top(1)  @queryid, caseid,
	CASEID+' '+cast((select sum( p.QTY *s.STDCUBE) 
					from wh1.pickdetail p join wh1.SKU s on p.SKU = s.SKU and p.STORERKEY = s.STORERKEY  
					where p.CASEID = t.caseid) as varchar(20))
from #tmpc t 
	where LOCATIONTYPE = @allowpiece 
		or LOCATIONTYPE = @ALLOWPALLET 
		or LOCATIONTYPE = @ALLOWCASE
	
--select * from 	#tmpc
--	select * from 	#userright
	
	
	--and tm.USERKEY = @user and tm.PERMISSION = 1

--select * from wh1.loc
--select * from wh1.putawayzone

--select * from #userright ur join #tmpc tc on ur.


--delete from t 
--from #tmpc t join wh1.PICKDETAIL p on t.CASEID = p.CASEID where p.STATUS != '1' -- проверка на отгруженность заказов

--select SECTION from WH1.loc l join #tmpc t on l.LOC = t.LOC

--insert into wh1.CASEIDLOOKUP_CST0009 (QUERYID, VALUE, descr)
--select @queryid, CASEID, CASEID+cast((select sum( p.QTY *s.STDCUBE) from wh1.pickdetail p join wh1.SKU s on p.SKU = s.SKU and p.STORERKEY = s.STORERKEY  where p.CASEID = t.caseid) as varchar(20)) from #tmpc t

--select * from wh1.CASEIDLOOKUP_CST0009  


drop table #tmpc
--select @queryid
return @queryid

