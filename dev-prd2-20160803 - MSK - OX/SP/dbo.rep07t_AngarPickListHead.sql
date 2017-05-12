ALTER PROCEDURE [dbo].[rep07t_AngarPickListHead] (
	@wh varchar(30),
	@orderkey varchar(15)
)

as
	declare @sql varchar (max)
	
--	declare @wh varchar(30), @orderkey varchar(15)
--	set @orderkey = '0000000735'
--	set @wh = 'wh40'

	set @sql =
	'select
		who.orderkey as orderkey, who.externorderkey,
		whs.companyName as company, who.door, who.ordergroup, 
		case when len(ordergroup) = 2 then (case when right(ordergroup,1) = ''5'' then 1 else 
		case when right(ordergroup,1) = ''1'' then 2 else 0 end end) else 0 end FilialFlag
	from
		'+@wh+'.orders as who left join '+@wh+'.storer as whs on who.consigneekey = whs.storerkey
	where
		who.orderkey = '''+@orderkey+''''
		exec (@sql)

