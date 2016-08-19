ALTER PROCEDURE [dbo].[rep34_TimeOrderShiped] 
	@WH varchar(10), 
	@customer varchar(45), 
	@susr4 varchar(30), -- podrazdelenie
	@susr1 varchar(10),-- manager
	@vat varchar (18), -- inn
	@externorderkey varchar (32),
	@datemin datetime = null,
	@datemax datetime = null
AS
BEGIN
	SET NOCOUNT ON;
	declare @sql varchar(max)
--				cast(((DATEDIFF(minute, REQUESTEDSHIPDATE, ACTUALSHIPDATE))/60) as varchar(10))+ 
--				'':'' + cast(abs((DATEDIFF(minute, REQUESTEDSHIPDATE, ACTUALSHIPDATE) - 
--				(DATEDIFF(minute, REQUESTEDSHIPDATE, ACTUALSHIPDATE)/60)*60 )) as varchar(10)) as raz
--	cast(floor(DATEDIFF(mi, REQUESTEDSHIPDATE, ACTUALSHIPDATE)/60) as varch(5))+'':''
set @sql = 'select REQUESTEDSHIPDATE, ACTUALSHIPDATE, ORDERKEY, o.externorderkey, st.COMPANY, st.vat, o.susr1, o.susr4 ordergroup,
 convert(int,DATEDIFF(mi, REQUESTEDSHIPDATE, ACTUALSHIPDATE)) as raz
			FROM '+@WH+'.ORDERS o
				left join '+@WH+'.Storer st on st.storerkey = consigneekey
			WHERE 1=1 '+
			case when isnull(@externorderkey,'')='' then '' else 'and o.externorderkey LIKE '''+ltrim(rtrim(@externorderkey))+''' ' end +
			case when isnull(@customer ,'')='' then '' else 'and st.Company LIKE ''%'+ltrim(rtrim(@customer))+'%'' ' end +
			case when isnull(@susr4 ,'')='' then '' else 'and o.susr4 like '''+@susr4+''' ' end +
			case when isnull(@vat ,'')='' then '' else 'and st.vat like '''+@vat+''' ' end +
			case when isnull(@susr1,'')='' then '' else 'and o.susr1 like '''+@susr1+''' ' end +
			case when @datemin is null then '' else 'and REQUESTEDSHIPDATE >= '''+convert(varchar(10),@datemin,112)+''' ' end +
			case when @datemax is null then '' else 'and REQUESTEDSHIPDATE <= '''+convert(varchar(10),@datemax,112)+''' ' end
exec (@sql)

END

--o.status > 82 
--
--select * from wh40.orderstatussetup

