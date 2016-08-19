
ALTER PROCEDURE [dbo].[Report_proc_WarehouseStorer] (@wh varchar(15))
as
declare @sql varchar(max)
set @sql ='
select -1 sort, ''Все'' company, ''%'' storerkey
union
select 0 sort, s.company, ws.storerkey 
from dbo.warehousestorer ws join '+@wh+'.storer s on ws.storerkey = s.storerkey
where ws.whseid = '''+@wh+''' 
order by 1,2 '
exec (@sql)

