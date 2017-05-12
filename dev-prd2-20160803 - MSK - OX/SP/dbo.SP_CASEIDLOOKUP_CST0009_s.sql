
ALTER PROCEDURE [dbo].[SP_CASEIDLOOKUP_CST0009_s] 
@user varchar(10),
@area varchar(10)
AS

declare @queryid varchar(15)
--declare @user varchar(10) set @user = 'ssa'
--declare @area varchar(10) set @area = 'facility'


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


--select distinct pd.caseid, pd.STATUS, pd.LOC, orderkey, ad.areakey, l.LOCATIONTYPE
--	into #tmpc
--	from wh1.pickDETAIL pd join wh1.loc l on pd.LOC = l.loc
--			join wh1.AREADETAIL ad on ad.putawayzone = l.PUTAWAYZONE
--	where pd.[STATUS] = 1 and ad.areakey = @area and isnull(pd.PDUDF3,'') = ''

select distinct pd.caseid, pd.STATUS, pd.LOC, pd.orderkey, ad.areakey, l.LOCATIONTYPE, st.company,lh.DEPARTURETIME
	into #tmpc
	from wh1.pickDETAIL pd join wh1.loc l on pd.LOC = l.loc
			join wh1.AREADETAIL ad on ad.putawayzone = l.PUTAWAYZONE
			join wh1.ORDERS o on o.ORDERKEY=pd.orderkey
			join wh1.storer st on o.B_COMPANY=st.storerkey
			left join wh1.LOADHDR lh on o.LOADID = lh.loadid
	where pd.[STATUS] = 1 and ad.areakey =@area and isnull(pd.PDUDF3,'') = ''
	
	
	

select * from #tmpc

drop table #tmpc
--select @queryid


