
ALTER PROCEDURE [dbo].[rep49_SKUSelect_storer] 
    @WH varchar(10)          -- объ€вление параметров
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @sql varchar(max)

set @sql= 'SELECT     STORERKEY, COMPANY
FROM         '+@WH+'.STORER
WHERE     (TYPE = 1)'
exec (@sql)

END
