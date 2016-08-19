ALTER PROCEDURE [dbo].[rep_check_obman_otbor_c] (
    @ds datetime, -- начальная дата
    @de datetime -- конечная дата
)
as
begin

set @ds = dbo.udf_get_date_from_datetime(isnull(@ds,getdate()))
set @de = dbo.udf_get_date_from_datetime(isnull(@de,getdate()))
set @de = @de + convert(time,'23:59:59.997')
		
select ROW_NUMBER() over (PARTITION BY cc.caseid order by cc.caseid, cc.dateadd desc) as NN,
		cc.caseid, usr.usr_lname+' '+usr.usr_fname username, cc.dateadd data, cc.area 
into #temp
from wh1.caselog cc
	join ssaadmin.pl_usr usr on cc.userkey=usr.usr_login
where cc.caseid in (	select caseid from wh1.caselog
						where dateadd between @ds and @de and caseid !='' 
						group by caseid
						having COUNT(caseid)>1
					)

delete from #temp where NN=1

select username, COUNT(NN) n from #temp
group by username

drop table #temp

end

/*
exec dbo.rep_check_obman_otbor_c '20120701','20120731'
*/

 

