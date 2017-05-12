ALTER PROCEDURE [dbo].[rep44_CarShippingTime] (
	@wh varchar(10),
	@dt smalldatetime,
	@ts varchar(20)
	)
as

declare @dt2 smalldatetime, @sql varchar(max)--, @dt smalldatetime, @ts varchar(20)
--set @dt = getdate()
set @dt2=dateadd(dy,1,@dt)
/*
select pls.tsid, max(ti.editdate) enter,  max(pd.editdate) ship,  
	datediff(mi, max(ti.editdate), max(pd.editdate)) dt,
	s.companyName, ti.avtomark, ti.avtonum, ti.DriverFIO, max(u.usr_name)editwho,
	0 hh, 0 mm
into #tmp
from wh40.pickdetail pd
	join WH40.PackLoadSend pls on pls.serialkey = pd.serialkey
	join ttninfo ti on pls.tsid = ti.tsid
	join wh40.orders o on pd.orderkey = o.orderkey
	join wh40.storer s on s.storerkey = o.consigneeKey
	join ssaadmin.pl_usr u on u.usr_login=pd.editwho
where 1 = 2
group by pls.tsid, s.companyName, ti.avtomark, ti.avtonum, ti.DriverFIO
*/
set @sql = ' select pls.tsid, max(ti.editdate) enter,  max(pd.editdate) ship,  
	datediff(mi, max(ti.editdate), max(pd.editdate)) dt,
	s.companyName, ti.avtomark, ti.avtonum, ti.DriverFIO, max(u.usr_name)editwho,
	0 hh, 0 mm
into #tmp
from '+@wh+'.pickdetail pd
	join '+@wh+'.PackLoadSend pls on pls.serialkey = pd.serialkey
	join ttninfo ti on pls.tsid = ti.tsid
	join '+@wh+'.orders o on pd.orderkey = o.orderkey
	join '+@wh+'.storer s on s.storerkey = o.consigneeKey
	join ssaadmin.pl_usr u on u.usr_login=pd.editwho
where ti.editdate between '''+convert(varchar(10),@dt,112)+''' and '''+convert(varchar(10),@dt2,112)+'''
and  ti.editdate < pd.editdate'+
case when  isnull(@ts,'')='' then '' else ' and pls.tsid = '''+@ts+''' ' end+
' group by pls.tsid, s.companyName, ti.avtomark, ti.avtonum, ti.DriverFIO'+



' update #tmp set hh=floor(dt/60)
update #tmp set mm=dt-hh*60

select tsid, enter, ship, companyname, avtomark, avtonum, driverfio,editwho,'+
' cast(hh as varchar(10)) + '':'' +  case when mm<10 then ''0'' else '''' end  +  cast(mm as varchar(2)) tm
from #tmp'
print @sql
exec (@sql)

drop table #tmp

