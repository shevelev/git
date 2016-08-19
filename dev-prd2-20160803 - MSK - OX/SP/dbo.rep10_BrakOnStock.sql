ALTER PROCEDURE  [dbo].[rep10_BrakOnStock] (
	@wh varchar(10),
	@dat1 datetime,
	@dat2 datetime
)
AS

--declare @wh varchar(10),@dat1 datetime,
--		@dat2 datetime
--select @wh='wh40', @dat1 = '20080101', @dat2=getdate()
		
		set @dat2 = dateadd(dy,1,convert(varchar(10),@dat2,112))
		
		declare @sql varchar(max)
		
		set @sql = 'select lli.storerkey, lli.sku, s.descr skuDescr, st.company StorerName, lli.qty 
		from '+@wh+'.lotxlocxid lli
			join '+@wh+'.sku s on lli.sku=s.sku and lli.storerkey=s.storerkey
			join '+@wh+'.storer st on lli.storerkey = st.storerkey
		where loc = ''BRAKSKLAD'' and qty > 0
			and lli.adddate between '''+convert(varchar(10),@dat1,112)+''' and '''+convert(varchar(10),@dat2,112)+''''
		exec (@sql)

