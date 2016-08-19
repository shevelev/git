ALTER PROCEDURE [dbo].[rep17a_EmptyLoc] ( @wh varchar (20), @category varchar(10))
as

CREATE TABLE [#ResultTable](loc varchar(10))

declare @sql varchar(max)

set @sql = 
'insert into #ResultTable
select loc
from '+@wh+'.loc
where locationCategory = '''+@category+'''
and not loc in (
  select distinct loc
  from '+@wh+'.lotxlocxid
  where qty > 0
)
'

exec (@sql)

select * from #ResultTable

drop table #ResultTable

