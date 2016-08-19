ALTER PROCEDURE [dbo].[repF02_CubeBillig_M02a] ( /*** =20091221 freez= Учет объемов склада 
																		(orders, PO, receipt) ***/
	@wh varchar(30) ,
	@storer varchar(15),
	@datebegin datetime,
	@dateend datetime
)

as

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(10)


set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(10),@dateend+1,112)

set @sql='
select ft.Date_cn actDate,
		ft.storerkey storerkey,
		sum(ft.qty*sk.stdcube) FTC
from adminsPRD1.dbo.FT_ostatki FT
left join '+@wh+'.sku sk on ft.storerkey=sk.storerkey and ft.sku=sk.sku
where ft.storerkey='''+@storer+''' and (ft.date_cn between '''+@bdate+''' and '''+@edate+''')
group by ft.Date_cn, ft.storerkey
order by ft.Date_cn, ft.storerkey
'

print (@sql)
exec (@sql)

