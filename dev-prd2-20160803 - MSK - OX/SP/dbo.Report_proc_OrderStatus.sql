

ALTER PROCEDURE [dbo].[Report_proc_OrderStatus](@wh varchar(10)) 

as
	declare @sql varchar(max)
	set @sql = 'select 0 so, code, description, showseq from '+@wh+'.orderstatussetup
	union select -1, null, ''<Все>'', 0
	order by 1, showseq'
	exec (@sql)


