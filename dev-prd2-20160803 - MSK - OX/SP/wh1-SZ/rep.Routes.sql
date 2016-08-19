ALTER PROCEDURE [rep].[rep_int_pop2]
	@is_include_all bit = 0
as
begin

/*
	select
		[ROUTE],
		'[' + convert(varchar(10),max(DEPARTURETIME),104) + ' ' + convert(varchar(5),max(DEPARTURETIME),108) + '] - ' + [ROUTE] as DESCR,
		max(DEPARTURETIME) as DEPARTURETIME
	from wh1.LOADHDR
	group by [ROUTE]
	having max(DEPARTURETIME) &amp;gt;= dateadd(hh,-6,getdate())
	order by 3
*/

	select distinct
		right('000' + h.[ROUTE],3) as ROW_NUM,
		h.[ROUTE],
		h.[ROUTE] as DESCR,
		h.[ROUTE] + isnull(' - ' + convert(varchar(255),g.ROUTENAME),'') as FULL_DESCR,
		'[' + convert(varchar(10),max(h.DEPARTURETIME),104) + ' ' + convert(varchar(5),max(h.DEPARTURETIME),108) + '] - ' + h.[ROUTE] as TIME_DESCR
	from wh1.LOADHDR h with (NOLOCK,NOWAIT)
		left join dbo.LoadGroup g with (NOLOCK,NOWAIT) on h.[ROUTE] = g.ROUTEID
	group by h.[ROUTE], convert(varchar(255),g.ROUTENAME)
	
	union select NULL, NULL, '<Все>', '<Все>', '<Все>' where @is_include_all = 1
	
	order by 1
	
end

