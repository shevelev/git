ALTER PROCEDURE [dbo].[rep17_FreeLoc] ( @wh varchar (20), @sku varchar(10))
as

CREATE TABLE [#ResultTable](
	[zone] [varchar](60) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[ya4] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[opisanie] [varchar](250) COLLATE Cyrillic_General_CI_AS NULL,
	[qty] [decimal](38, 5) NULL)

declare @sql varchar(max)

set @sql = 
'insert into #ResultTable
select PAZ.descr as zone,
l.loc as ya4,
CC.description as opisanie,
sum(isnull(lli.qty, 0)) as qty 
from '+@wh+'.codelkup as CC, 
'+@wh+'.putawayzone as PAZ,
'+@wh+'.loc as l 
left join 
'+@wh+'.lotxlocxid as lli 
on lli.loc = l.loc
where l.locationtype in (''CASE'',''PICK'')
and (paz.putawayzone=l.putawayzone)
and (cc.code=l.locationtype)
and (cc.listname=''LOCTYPE'')'
+case when isnull(@sku,'')='' then '' else ' and sku = '''+@sku+'''' end+
'
group by PAZ.descr,l.loc,CC.description
having sum(isnull(lli.qty, 0)) <= 0
order by zone,l.loc'

exec (@sql)

select * from #ResultTable

drop table #ResultTable

