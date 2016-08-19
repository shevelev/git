-- =============================================
-- Author:		Сандаков В.В.
-- Create date: 25.06.08 09.07.2008
-- Description:	отчет о незавершенных отгрузках (изменен)
-- =============================================
ALTER PROCEDURE [dbo].[rep_ShipmentUnclosed]
	@wh varchar(10),
	@externorderkey varchar(32),
	@orderkey varchar(10),
	@datemin datetime = null,
	@datemax datetime = null,
	@business varchar(20)
AS

declare @sql varchar(max)

--declare @wh varchar(10)
--set @wh = 'WH40'
if not @datemax is null 
	set @datemax=dateadd(dy,1,@datemax)

set @sql = 'select distinct pd.ORDERKEY, pd.EDITDATE, pd.EDITWHO, ssa.usr_name, pd.status, datediff(mi, pd.EDITDATE, GETDATE()), o.externorderkey
from '+@wh+'.PICKDETAIL as pd
join ssaadmin.pl_usr as ssa on usr_login = pd.EDITWHO
join '+@wh+'.orders o on pd.orderkey = o.orderkey
where 1=1 
	and (datediff(mi, pd.EDITDATE, GETDATE()) >= 30)
	and pd.STORERKEY='''+@business+'''
	and (pd.status = ''8'')' +
			case when @datemin is null then '' else 'and pd.EDITDATE >= '''+convert(varchar(10),@datemin,112)+''' ' end +
			case when @datemax is null then '' else 'and pd.EDITDATE <= '''+convert(varchar(10),@datemax,112)+''' ' end +
			case when @externorderkey is null then '' else 'and o.externorderkey LIKE '''+ltrim(rtrim(@externorderkey))+''' ' end +
			case when @orderkey is null then '' else 'and o.orderkey LIKE '''+ltrim(rtrim(@orderkey))+''' ' end
--print (@sql)
exec (@sql)

