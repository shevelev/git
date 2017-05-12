ALTER PROCEDURE [dbo].[repF00_Ostatki_V] ( /*** =20091221 freez= Остатки
																		(orders, PO, receipt) ***/
	@wh varchar(30) ,
	@storer varchar(15),
	@date_cn datetime
)

as

declare @sql varchar(max),
		@date varchar(10)


set @date=convert(varchar(10),@date_cn,112)

set @sql='

select ost.date_cn dcn, 
		ost.sku sku, 
		sk.descr descr, 
		ost.qty qty, 
		(ost.qty*sk.stdcube) v 
from adminsPRD1.dbo.FT_ostatki ost 
join '+@wh+'.sku sk on ost.storerkey=sk.storerkey and ost.sku=sk.sku 
where ost.date_cn='''+@date+'''
		and ost.storerkey='''+@storer+'''
		and ost.qty>0
'

print (@sql)
exec (@sql)

