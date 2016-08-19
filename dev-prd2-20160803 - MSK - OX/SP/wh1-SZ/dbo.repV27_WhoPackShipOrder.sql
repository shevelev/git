ALTER PROCEDURE [dbo].[repV27_WhoPackShipOrder] (
	@wh varchar(10),
	@orderkey varchar(10)
)AS

create table #result_table (
		caseid varchar(20) not null,
		ID varchar(20) null,
		WhoPack varchar(18) null,
		WhoShip varchar(18) null
)

declare @sql varchar(max)
	
set @sql = ' 
insert into #result_table
select distinct(pd.caseid),
		isnull(did2.childid,did1.dropid) ID,
		did1.addwho WhoPack,
		did2.addwho WhoShip
from '+@wh+'.pickdetail pd
left join '+@wh+'.dropiddetail did1 on pd.caseid=did1.childid
left join '+@wh+'.dropiddetail did2 on did1.dropid=did2.childid
where	pd.orderkey='''+@orderkey+'''
order by pd.caseid
'
exec (@sql)

select distinct(rt.ID),
		plu1.usr_name WhoPack,
		plu2.usr_name WhoShip
from #result_table rt
left join ssaadmin.pl_usr plu1 on rt.WhoPack=plu1.usr_login
left join ssaadmin.pl_usr plu2 on rt.WhoShip=plu2.usr_login
where isnull(rt.ID,'')<>''
order by rt.ID
--select *
--from #result_table rt

drop table #result_table

