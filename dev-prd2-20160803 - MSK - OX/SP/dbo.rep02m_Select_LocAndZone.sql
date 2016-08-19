ALTER PROCEDURE [dbo].[rep02m_Select_LocAndZone] 
	-- Add the parameters for the stored procedure here
	@wh varchar(10),
	@zone varchar(10),
	@loc varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
  declare @sql varchar(max)
  set @sql='select pwz.PUTAWAYZONE,isnull(l.LOC,'''') LOC '+
    'from '+@wh+'.PUTAWAYZONE pwz '+
    'left join '+@wh+'.LOC l on pwz.PUTAWAYZONE=l.PUTAWAYZONE '+
    'where pwz.PUTAWAYZONE like '''+@zone+'%'' and isnull(l.LOC,'''') like '''+@loc+'%'' '+
    'order by pwz.PUTAWAYZONE,isnull(l.LOC,'''') '
	exec (@sql)
END

