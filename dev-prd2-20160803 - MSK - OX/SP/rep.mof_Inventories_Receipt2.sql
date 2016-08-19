-- =============================================
-- Author:		Dr.MoPo3ilo
-- Create date: 2008-11-10
-- Description:	Get LOTTABLEVALIDATION
-- =============================================
ALTER PROCEDURE [rep].[mof_Inventories_Receipt2]
	-- Add the parameters for the stored procedure here
	@wh varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	create table #LOTTABLEVALIDATION (SORTORD int, LOTTABLEVALIDATIONKEY varchar(10), DESCRIPTION varchar(250))
	declare @sql varchar(max)
	set @sql='insert into #LOTTABLEVALIDATION
SELECT     0 AS SORTORD, LOTTABLEVALIDATIONKEY, DESCRIPTION
FROM         wh2.LOTTABLEVALIDATION
UNION
SELECT     - 1 AS Expr1, '''' AS Expr2, ''<Пустой>'' AS Expr3
UNION
SELECT     - 1 AS Expr1, NULL AS Expr2, ''<Любой>'' AS Expr3
ORDER BY 1, 2
  '
  exec (@sql)
  select SORTORD,LOTTABLEVALIDATIONKEY,DESCRIPTION
  from #LOTTABLEVALIDATION
  drop table #LOTTABLEVALIDATION
END

