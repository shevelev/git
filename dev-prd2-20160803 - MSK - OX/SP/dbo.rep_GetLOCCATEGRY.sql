-- =============================================
-- Author:		Dr.MoPo3ilo
-- Create date: 2008-11-10
-- Description:	Get LOCCATEGRY
-- =============================================
ALTER PROCEDURE [dbo].[rep_GetLOCCATEGRY]
	-- Add the parameters for the stored procedure here
	@wh varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    create table #LOCCATEGRY (CODE varchar(10) , LONG_VALUE varchar(250))
    declare @sql varchar(max)
    set @sql='insert into #LOCCATEGRY select CODE,LONG_VALUE from '+@wh+'.CODELKUP where LISTNAME = ''LOCCATEGRY'''
    exec (@sql)
    select CODE,LONG_VALUE from #LOCCATEGRY order by CODE
    drop table #LOCCATEGRY
END

