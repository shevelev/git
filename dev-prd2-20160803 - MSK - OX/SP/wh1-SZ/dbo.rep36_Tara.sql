ALTER PROCEDURE [dbo].[rep36_Tara](
	@wh varchar(10)  -- склад
)AS

CREATE TABLE [#restab](
	[loc] [varchar] (18) COLLATE Cyrillic_General_CI_AS NULL,
	[id] [varchar](40) COLLATE Cyrillic_General_CI_AS NULL)

declare @sql varchar (max)
set @sql = 
'select loc, id 
from '+@wh+'.lotxlocxid
where id like ''C%''
group by id, loc having max (qty) <= 0'
exec (@sql)

select * from #restab

drop table #restab

