/* Список заказов на отгрузку */
ALTER PROCEDURE [dbo].[rep98_ListOrders](
 	@wh  varchar (10),
	@orderdatemin datetime = null,
	@orderdatemax datetime = null,
	@requestedshipdatemin datetime = null,
	@requestedshipdatemax datetime = null,
	@rfidflag varchar(10) = null
)
AS
set nocount on
	create table #result_table (
		id int identity (1,1) not null,
		orderkey varchar(10) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		exterorderkey varchar(32) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),	
		wavekey varchar(10) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		ordergroup varchar(20) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		buyepro varchar(20) COLLATE Cyrillic_General_CI_AS DEFAULT (''),	
		company varchar(60) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),	
		orderdate datetime NOT NULL DEFAULT ('2000-01-01 00:00:00.000'),
		requestedshipdate datetime NOT NULL DEFAULT ('2000-01-01 00:00:00.000'),
		priority varchar(10) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		orderCompleted varchar(10) default('%'),
		stand varchar(20) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		description varchar(60) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		quant_rec decimal(22, 5) NOT NULL DEFAULT (0),
		quant_a8 decimal(22, 5) DEFAULT (0))

declare @i int,
	@sql varchar(max)

set @orderdatemax = dateadd(dy,1,@orderdatemax)
set @requestedshipdatemax = dateadd(dy,1,@requestedshipdatemax)

set @sql = 
'insert into #result_table
select o.orderkey, 
		o.externorderkey,
		case (select count (*) from '+@wh+'.orders wo join '+@wh+'.wavedetail ww on ww.orderkey = wo.orderkey where wo.orderkey = o.orderkey)
		when 0 then '''' else (select ww.wavekey from '+@wh+'.orders wo join '+@wh+'.wavedetail ww on ww.orderkey = wo.orderkey where wo.orderkey = o.orderkey) end as wavekey,  
		o.ordergroup,
		o.buyerpo, 
		s.company, 
		o.orderdate, 
		o.requestedshipdate, 
		o.priority, 
		case o.rfidflag when ''1'' then ''+'' else ''-'' end as orderCompleted,
		case o.ohtype when ''2'' then ''другой'' else ''обычный'' end as stand, 
		oss.description, 
		count(od.orderkey) as quant_rec,
		0
from '+ @wh +'.orders o 
	join '+ @wh +'.orderdetail od on o.orderkey = od.orderkey
	join '+ @wh +'.storer s on s.storerkey = o.consigneekey
	join '+ @wh +'.orderstatussetup oss on oss.code = o.status
where 1=1'+ 
case when @orderdatemin is null  then '' else ' AND o.orderdate >= '''+convert(varchar(10),@orderdatemin,112)+''' ' end +
case when @orderdatemax is null  then '' else ' AND o.orderdate < '''+convert(varchar(10),@orderdatemax,112)+''' ' end +
case when @requestedshipdatemin is null  then '' else ' AND o.requestedshipdate >= '''+convert(varchar(10),@requestedshipdatemin,112)+''' ' end +
case when @requestedshipdatemax is null  then '' else ' AND o.requestedshipdate < '''+convert(varchar(10),@requestedshipdatemax,112)+''' ' end +
case when isnull(@rfidflag,'')=''   then '' else ' AND o.rfidflag = '''+@rfidflag+''' ' end +
'group by o.orderkey, 
		o.externorderkey,
		o.ordergroup,
		o.buyerpo, 
		s.company, 
		o.orderdate, 
		o.requestedshipdate, 
		o.priority, 
		o.ohtype, 
		o.rfidflag,
		oss.description'

exec (@sql)

set @i = 1
	while (@i <= (select count(*) from #result_table))
		begin
			set @sql =
			'update #result_table set quant_a8 = 
				(select count(*) from #result_table r join '+@wh+'.orderdetail od on r.orderkey = od.orderkey
							join '+@wh+'.sku s on od.sku = s.sku and od.storerkey = s.storerkey
							join '+@wh+'.putawaystrategy st on st.putawaystrategykey = s.putawaystrategykey
					where r.id = '+cast(@i as varchar)+' and
						rtrim(ltrim(substring(st.descr, charindex('':'',st.descr)+1, len(st.descr) - charindex('':'', st.descr))))  = ''АНГАР8'')
				where #result_table.id = ' + cast(@i as varchar)
			exec (@sql)
			set @i = @i + 1
		end

select * from #result_table order by orderkey
drop table #result_table

