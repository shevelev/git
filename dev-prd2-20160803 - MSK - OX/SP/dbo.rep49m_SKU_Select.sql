ALTER PROCEDURE [dbo].[rep49m_SKU_Select]
	-- Add the parameters for the stored procedure here
	@wh varchar(10), 
	@storerkey varchar(10)='',
	@storerdescr varchar(45)='',
	@sku varchar(10)='',
	@descr varchar(60)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
  declare @sql varchar(max)
  set @sql='select SKU,COMPANY,PACKKEY,DESCR from '+@wh+'.SKU sku '+
    'inner join '+@wh+'.STORER st on sku.STORERKEY=st.STORERKEY '+
    'where sku.SKU like ''%'+@sku+''' and sku.DESCR like ''%'+@descr+''' '+
    'and st.STORERKEY like ''%'+@storerkey+''' and st.COMPANY like ''%'+@storerdescr+''' '
	exec (@sql)
END

