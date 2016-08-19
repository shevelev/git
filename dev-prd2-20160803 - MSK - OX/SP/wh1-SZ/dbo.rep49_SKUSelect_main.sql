
ALTER PROCEDURE [dbo].[rep49_SKUSelect_main] 
    @WH varchar(10),          -- объ€вление параметров
	@sku varchar(10) =null,
	@descr varchar(60) =null,
	@storerdescr varchar(45) =null,
	@storerkey varchar(10) =null
  , @carrierINN varchar(20)=null
  , @carrierKey varchar(20)=null
AS

SET NOCOUNT OFF

declare @sql varchar(max)
	set @sql = 'SELECT     s.sku, s.descr, s.storerkey
		FROM        '+@WH+'.SKU s '
			+case when isnull(@carrierKey,'')!= '' then
				'join '+@WH+'.receiptdetail rd on rd.sku=s.sku and rd.storerkey=s.storerkey
				join '+@WH+'.receipt r on r.receiptkey=rd.receiptkey
				join '+@WH+'.storer st on r.carrierkey=st.storerkey '
				else '' end
		+' WHERE	1=1 ' 
			+ case when isnull(rtrim(@descr),'')='' then '' else ' and s.DESCR LIKE ''%'+@descr+'%''' end
			+ case when isnull(rtrim(@storerkey),'')='' then '' else ' and s.STORERKEY = '''+@storerkey+'''' end
			+ case when isnull(rtrim(@sku),'')=''  then '' else ' and s.sku LIKE ''%'+@sku+'%''' end
			--+ case when isnull(rtrim(@carrierINN),'') ='' then '' else ' and st.vat like '''+@carrierINN+'''' end
			+ case when isnull(rtrim(@carrierKey),'') = '' then '' else ' and r.carrierKey like '''+@carrierKey+'''' end
print @sql
	exec (@sql)
			

