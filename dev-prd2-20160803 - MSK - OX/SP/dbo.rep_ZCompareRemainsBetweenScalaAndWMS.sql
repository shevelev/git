-- =============================================
-- Author:		Юрчук Жанна
-- Create date: 12.05.2008
-- Description:	Для отчета Сравнение остатков между Scalaой и WMS системой
-- =============================================
ALTER PROCEDURE [dbo].[rep_ZCompareRemainsBetweenScalaAndWMS] 
	@wh VarChar(50)
  , @sel VarChar(1)  
AS
BEGIN
    declare @tmp VarChar(10)
	set @wh = upper(@wh)
    set @tmp = replace (@wh,'WH','')
    while len(@tmp) < 3
       begin
          set @tmp = '0'+@tmp 
       end
	declare @sql varchar(max)
--    update wh40.remainsSKU
--      set RemainsBrak = 0
--      where RemainsBrak is NULL
    if (@sel = '1') 
    begin
	   set @sql = 'select DateCreat
                        , '''+@tmp+''' as Warehouse 
                        , '+@wh+'.remainsSKU.SKU as SKUWMS
                        , SKUFROMSC03 as SKUScala
                        , DESCR
                        , '+@wh+'.remainsSKU.QTYWMS
                        , '+@wh+'.remainsSKU.QTYScala
                        --, '+@wh+'.remainsSKU.RemainsBrak
                        , QTYWMS - QTYScala as [Difference] -- QTYWMS - (QTYScala + RemainsBrak) as [Difference]
                     from '+@wh+'.remainsSKU left join '+@wh+'.SKU
                       on '+@wh+'.remainsSKU.SKU = '+@wh+'.SKU.SKU
                     where '+@wh+'.remainsSKU.SKU is not NULL
                       and '+@wh+'.remainsSKU.QTYWMS is not NULL
                       and '+@wh+'.remainsSKU.QTYScala is not NULL
                       and SKUFROMSC03 is not NULL
                       and QTYWMS - QTYScala <> 0'
    end
    else
    begin
       set @sql = 'select DateCreat
                     , '''+@tmp+''' as Warehouse 
                     , CASE WHEN '+@wh+'.remainsSKU.SKU is NULL THEN ''Нет кода запаса'' ELSE '+@wh+'.remainsSKU.SKU END as SKUWMS
                     , CASE WHEN SKUFROMSC03 is NULL THEN ''Нет кода запаса'' ELSE SKUFROMSC03 END as SKUScala
                     , DESCR
                     , CASE WHEN '+@wh+'.remainsSKU.QTYWMS is NULL THEN 0 ELSE '+@wh+'.remainsSKU.QTYWMS END as QTYWMS
                     , CASE WHEN '+@wh+'.remainsSKU.QTYScala is NULL THEN 0 ELSE '+@wh+'.remainsSKU.QTYScala END as QTYScala
                     , 0 as [Difference]
                  from '+@wh+'.remainsSKU left join '+@wh+'.SKU
                    on '+@wh+'.remainsSKU.SKU = '+@wh+'.SKU.SKU
                  where '+@wh+'.remainsSKU.SKU is NULL
                     or '+@wh+'.remainsSKU.QTYWMS is NULL
                     or '+@wh+'.remainsSKU.QTYScala is NULL
                     or SKUFROMSC03 is NULL'
    end
    exec (@sql)
END

