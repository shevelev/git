ALTER PROCEDURE [dbo].[rep29_SkuByLots_skutyps](
	@wh varchar(10)
)

AS

CREATE TABLE [#resulttablet](
	[sortord] [int] NOT NULL,
	[lottablevalidationkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[description] [varchar](60) COLLATE Cyrillic_General_CI_AS NOT NULL)

declare @sql varchar (max)

set @sql =
'insert into #resulttablet
select 0  sortord, lottablevalidationkey, description 
from '+@wh+'.lottableValidation
union 
select -1, '''', ''<Пустой>''
union 
select -1, null, ''<Любой>''
order by 1,2'

exec (@sql)
select * from #resulttablet
drop table #resulttablet

