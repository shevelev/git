-- =============================================
-- Author:		Dr.MoPo3ilo
-- Create date: 2008-11-10
-- Description:	Get ORDHNDTYPE
-- =============================================
ALTER PROCEDURE [dbo].[rep_GetORDHNDTYPE] 
	-- Add the parameters for the stored procedure here
	@wh varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	create table #ORDHNDTYPE (ID int, OHTYPE varchar(10), DESCRIPTION varchar(250))
	declare @sql varchar(max)
	set @sql='insert into #ORDHNDTYPE
select 0 ID, CODE OHTYPE, DESCRIPTION
from wh1.CODELKUP ck where ck.LISTNAME like ''ORDHNDTYPE''
union select -1, NULL, ''<Все>'' 
order by 1,2'
  exec (@sql)
  select ID,OHTYPE,DESCRIPTION from #ORDHNDTYPE
  drop table #ORDHNDTYPE
END

