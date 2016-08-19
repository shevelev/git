CREATE proc [dbo].[rep94_InventorySheet](
	@wh varchar(10),
	@loc1 varchar(10),
	@loc2 varchar(10),
	@sku1 varchar(10),
	@sku2 varchar(10),
	@stkey varchar(18)
)
AS
--declare
--	@wh varchar(10),
--	@loc1 varchar(10),
--	@loc2 varchar(10),
--	@sku1 varchar(10),
--	@sku2 varchar(10),
--	@stkey varchar(18)
--select @wh ='wh40', @loc1 ='08.00',	@loc2 ='08.01',
--	@sku1 ='000000000',	@sku2 ='999999999',	@stkey = 'ST6661018350'
----
	declare @sql varchar(max)
	set @sql = '
		SELECT L.LOC, L.ID, L.SKU, S.DESCR, L.LOT, T.LOTTABLE05, 
				P.CASECNT, L.QTY /case when P.CASECNT=0 then 1 else P.CASECNT end AS NCASE, 
				L.QTY, S.STORERKEY, st.company
		FROM  '+@wh+'.LOTXLOCXID AS L 
				INNER JOIN '+@wh+'.SKU AS S ON S.SKU = L.SKU 
				INNER JOIN '+@wh+'.LOTATTRIBUTE AS T ON L.LOT = T.LOT 
				INNER JOIN '+@wh+'.PACK AS P ON S.PACKKEY = P.PACKKEY '
				+' left join '+@wh+'.STORER st on st.storerkey = s.storerkey '
		+' WHERE     (L.QTY > 0) 
			AND (L.LOC >= '''+@loc1+''') AND (L.LOC <= '''+@loc2+''') 
			AND (L.SKU >= '''+@sku1+''') AND (L.SKU <= '''+@sku2+''') 
			AND (S.STORERKEY = '''+@stkey+''')
		ORDER BY L.LOC'
--print @sql
	exec(@sql)

