-- =============================================
-- Author:		Сандаков В.В.
-- Create date:   16.06.08
-- Description:	отчет для ревизоров
-- =============================================
ALTER PROCEDURE [dbo].[rep_FromInspector] 
	@wh varchar(10),
	@sku1 varchar(15),
	@sku2 varchar(15)

AS
--для проверки работы процедуры
--declare @wh varchar(10),
--	@sku1 varchar(15),
--	@sku2 varchar(15)
--set @wh = 'wh40'
--set @sku1 = '000100000'
--set @sku2 = '000100005'

declare @sql varchar(max)


set @sql = '
select row_number() over(order BY sl.SKU) AS id, sl.SKU sku, s.SKUGROUP skugroup, s.DESCR descr, sl.QTY qty, sl.LOC loc 
into #t
from '+@wh+'.SKUXLOC as sl 
	join '+@wh+'.SKU s on sl.SKU = s.SKU
	where (sl.SKU <> ''GRUZ'')
		and (sl.SKU not like ''KS%'')
		and (sl.QTY > 0)

select *
from #t
where #t.sku between '+@sku1+' and '+@sku2+''

exec (@sql)

