ALTER PROCEDURE [rep].[mof_Reviews_selection] (
    @ds datetime, -- начальная дата
    @de datetime -- конечная дата
)
as
begin

set @ds = dbo.udf_get_date_from_datetime(isnull(@ds,getdate()))
set @de = dbo.udf_get_date_from_datetime(isnull(@de,getdate()))
set @de = @de + convert(time,'23:59:59.997')
		
select cc.caseid, usr.usr_lname+' '+usr.usr_fname username, cc.dateadd data, cc.area 
from wh2.caselog cc
	join ssaadmin.pl_usr usr on cc.userkey=usr.usr_login
where cc.caseid in (	select caseid from wh2.caselog
						where dateadd between @ds and @de and caseid !='' 
						group by caseid
						having COUNT(caseid)>1
					)
end

/*
exec dbo.rep_check_obman_otbor '20120701','20120731'
*/

 

