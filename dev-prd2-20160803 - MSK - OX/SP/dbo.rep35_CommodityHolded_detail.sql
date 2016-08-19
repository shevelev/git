ALTER PROCEDURE [dbo].[rep35_CommodityHolded_detail](
	/* 35 Проблемные товары (отчет о заблокированных товарах и товарах из проблемных ячеек) */
	@wh varchar(30),
	@sku varchar (10),
	@loc varchar (10) = null
)
AS	

declare @sql varchar(max)

select distinct i.sku, s.descr, pu.usr_name, i.fromloc,i.fromid, i.toloc, i.toid, i.qty, i.editdate, l.status 
into #restab
from wh40.itrn i join wh40.sku s on i.sku = s.sku and i.storerkey = s.storerkey
join ssaadmin.pl_Usr pu on i.addwho = pu.usr_login
join wh40.loc l on i.fromloc = l.loc or i.toloc = l.loc
where 1=2

set @sql =
'insert into #restab
select distinct i.sku, s.descr, pu.usr_name, i.fromloc,i.fromid, i.toloc, i.toid, i.qty, i.editdate, l.status 
from '+@wh+'.itrn i join '+@wh+'.sku s on i.sku = s.sku and i.storerkey = s.storerkey
join ssaadmin.pl_Usr pu on i.addwho = pu.usr_login
join '+@wh+'.loc l on i.fromloc = l.loc or i.toloc = l.loc
where ' +
case when @sku is null then '' else ' i.sku = '''+@sku+''' and ' end + ' 1=1 ' +
case when @loc is null then 
' and (i.toloc = ''LOST'' or i.fromloc = ''LOST''
or i.toloc = ''BRAK'' or fromloc = ''BRAK''
or i.toloc = ''BRAKPRIEM'' or i.fromloc = ''BRAKPRIEM''
or i.toloc = ''NETSTRATEG'' or i.fromloc = ''NETSTRATEG''
or i.toloc = ''NEIZVESTNO'' or i.fromloc = ''NEIZVESTNO'') '

else ' and ( i.toloc = '''+@loc+''' or i.fromloc = '''+@loc+''' ) ' end +
' and 
(
((i.toloc = ''LOST'' or i.fromloc = ''LOST''
or i.toloc = ''BRAK'' or fromloc = ''BRAK''
or i.toloc = ''BRAKPRIEM'' or i.fromloc = ''BRAKPRIEM''
or i.toloc = ''NETSTRATEG'' or i.fromloc = ''NETSTRATEG''
or i.toloc = ''NEIZVESTNO'' or i.fromloc = ''NEIZVESTNO'')
and i.qty > 0  or l.status != ''OK'')
and
((i.toloc != ''LOST'' or i.fromloc != ''LOST''
or i.toloc != ''BRAK'' or fromloc != ''BRAK''
or i.toloc != ''BRAKPRIEM'' or i.fromloc != ''BRAKPRIEM''
or i.toloc != ''NETSTRATEG'' or i.fromloc != ''NETSTRATEG''
or i.toloc != ''NEIZVESTNO'' or i.fromloc != ''NEIZVESTNO'')
and i.qty > 0  or l.status = ''HOLD''))'

exec (@sql)
print (@sql)
select distinct * from #restab

drop table #restab

