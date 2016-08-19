ALTER PROCEDURE [dbo].[proc_DA_Counting](
	@wh varchar(10),
	@transmitlogkey varchar (10)
	
)AS
--############################################################### »Õ¬≈Õ“¿–»«¿÷»ﬂ

set nocount on

declare @sql varchar(max)

print '	-- REASONCODE = Gen Adjast'
set @sql =
'select 
	''COUNTING'' filetype,
	dc.storerkey,
	dc.sku,
	sum (dc.qty) delta,
	(select sum (qty) from '+@wh+'.lotxlocxid lli where lli.sku = dc.sku and lli.storerkey = dc.storerkey) qty
from DA_Counting dc
where whseid = '''+@wh+'''
group by storerkey, sku'

exec (@sql)

delete from DA_Counting where whseid = @wh

