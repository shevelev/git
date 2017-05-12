ALTER PROCEDURE [dbo].[rep_List_of_not_Shipped_Orders] (
	@date1 smalldatetime=null,
	@date2 smalldatetime=null,
	@wh varchar(10),
	@status_Shipped varchar(10)
)
AS

/*-------проверка--------*/
--declare @date1 smalldatetime,
--	@date2 smalldatetime,
--	@wh varchar(10),
--	@status_Shipped varchar(10)
--set @date2 = getdate()
--set @date1 = dateadd(dy, -10, @date2)
--set @wh = 'wh40'
/*-----------------------*/

declare @sql varchar(max)

set @sql = ' select od.orderkey, od.sku,od.status stPoz, o.status stOrd, od.EDITDATE, od.originalqty, od.SHIPPEDQTY, s.descr, od.QTYPICKED, od.QTYALLOCATED, od.editwho, ssa.usr_name
into #t
from '+@wh+'.orderdetail od
join '+@wh+'.orders o on o.orderkey = od.orderkey
join '+@wh+'.sku s on s.sku = od.sku and s.storerkey = od.storerkey
join ssaadmin.pl_usr ssa on ssa.usr_login = od.editwho
where 1=1 '+
	case when @status_Shipped = '0' then '' else ' and od.status < 95 ' end+
	' and o.status > 02
	and od.sku in (select sku from wh1.skuxloc )'+
	case when @date1 is null  then '' else ' and od.EDITDATE >= '''+convert(varchar(10),@date1,112)+''' ' end +
	case when @date2 is null  then '' else ' and od.EDITDATE < '''+convert(varchar(10),@date2,112)+''' ' end +
' order by od.orderkey
select * from #t'
exec (@sql)

