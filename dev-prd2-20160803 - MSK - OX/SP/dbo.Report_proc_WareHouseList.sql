ALTER PROCEDURE [dbo].[Report_proc_WareHouseList] 
as
select [db_name]+' ('+db_logid+')' [db_name], db_logid 
from ssaadmin.pl_db 
where db_enterprise != 1

