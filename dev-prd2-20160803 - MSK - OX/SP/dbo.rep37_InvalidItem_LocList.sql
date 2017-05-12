-- =============================================
-- Author:		EV
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [dbo].[rep37_InvalidItem_LocList]
	@wh varchar(10),
	@PUTAWAYZONE varchar(10)
AS
BEGIN
	
SET NOCOUNT ON;

declare @sql varchar(max)
if @PUTAWAYZONE='Ыўсрџ'
  set @sql='
    select
     LOC as loc
    from '
     +@wh+'.LOC
    where '
     +@wh+'.loc.LOCATIONTYPE=''STAGED''
    order by loc.loc '
else
 set @sql='
  select
     LOC as loc
  from '
     +@wh+'.LOC
  where 
     PUTAWAYZONE='''+@PUTAWAYZONE+'''
      union select '''''

exec (@sql)
END

