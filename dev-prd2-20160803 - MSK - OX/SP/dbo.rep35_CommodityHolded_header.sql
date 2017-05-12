ALTER PROCEDURE [dbo].[rep35_CommodityHolded_header](
	/* 35 Проблемные товары (отчет о заблокированных товарах и товарах из проблемных ячеек) */
	@wh varchar(30)
)
AS	

declare @sql varchar(max)


select i.loc, s.descr, i.qty, l.status, s.sku 
into #restab
from wh40.skuxloc i join wh40.sku s on i.sku = s.sku and i.storerkey = s.storerkey
join wh40.loc l on i.loc = l.loc
where 1=2

set @sql =
'insert into #restab
select i.loc, s.descr, i.qty, l.status, s.sku 
from '+@wh+'.skuxloc i join '+@wh+'.sku s on i.sku = s.sku and i.storerkey = s.storerkey
join '+@wh+'.loc l on i.loc = l.loc
where
((i.loc = ''LOST'' 
or i.loc = ''BRAK''
or i.loc = ''BRAKPRIEM''
or i.loc = ''NETSTRATEG''
or i.loc = ''NEIZVESTNO'')
or l.status != ''OK'')
and i.qty > 0
order by i.loc'

exec (@sql)

select * from #restab

drop table #restab

