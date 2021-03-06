ALTER PROCEDURE [dbo].[Report_CountFact] (
	@wh varchar(15),
	@orderkey varchar (15),
	@externorderkey varchar (20)
)
as
declare
	@where varchar (2000),
	@whereex varchar (2000),
	@sql varchar (max)

	set @where = ' and 1=2'


--	if @orderkey is not null and @externorderkey is not null
--		begin
--			set @where = ' and o.orderkey = '''+@orderkey+''' and o.externorderkey = '''+@externorderkey+''''
--		end
	if @orderkey is not null --or ltrim(rtrim(@orderkey)) != ''
		set @where = ' and o.orderkey = '''+@orderkey+''''
	if @externorderkey is not null --or ltrim(rtrim(@externorderkey)) != ''
		set @where = ' and o.externorderkey = '''+@externorderkey+''''

set @sql =
'select ISNULL(o.SUSR4,'''') as susr4, o.orderkey, convert(varchar(10),o.adddate,103) adddate,
	case when o.orderDATE=o.ACTUALSHIPDATE then CONVERT(datetime, CONVERT(varchar(10), getdate(), 103), 103) else CONVERT(datetime, CONVERT(varchar(10), o.ACTUALSHIPDATE, 103), 103) end AS RequestedShipDate,
	s.company scompany, ISNULL(s.DESCRIPTION,'''') sDescr, 
	ISNULL(s.address1,'''') saddress1,
	ISNULL(s.address2,'''') saddress2,
	ISNULL(s.address3,'''') saddress3,
	ISNULL(s.address4,'''') saddress4,
	ISNULL(s.phone1,'''') sphone, 
	ISNULL(s.vat,'''') svat, 
	ISNULL(cast(s.notes2 as varchar(2000)),'''') snotes2, 
		ISNULL(s.SUSR3,'''') sSusr3, 
		ISNULL(s.SUSR4,'''') sSusr4, 
		ISNULL(s.SUSR5,'''') sSusr5,
		ISNULL(cast(s.notes1 as varchar(2000)),'''') snotes1, 
		ISNULL(s.B_COMPANY,'''') sBcompany, 
		ISNULL(s.B_address1,'''') sBaddress1, 
		ISNULL(s.B_address2,'''') sBaddress2, 
		ISNULL(s.B_address3,'''') sBaddress3, 
		ISNULL(s.B_address4,'''') sBaddress4,
		ISNULL(s.B_contact1,'''') sBcontact1,
	ISNULL(cs.DESCRIPTION,'''') csDescription,
	cs.company as csCompany, 
	ISNULL(cs.address1,'''') csaddress1,
	ISNULL(cs.address2,'''') csaddress2,
	ISNULL(cs.address3,'''') csaddress3, 
	ISNULL(cs.address4,'''') csaddress4,
	ISNULL(cs.phone1,'''') csphone, 
	ISNULL(cs.vat,'''') csvat, 
	ISNULL(cast(cs.notes2 as varchar(2000)),'''') csnotes2, 
	ISNULL(cast(cs.notes1 as varchar(2000)),'''') csnotes1,
		ISNULL(Bs.DESCRIPTION,'''') BsDescription,
		Bs.company as BsCompany, 
		ISNULL(Bs.address1,'''') Bsaddress1,
		ISNULL(Bs.address2,'''') Bsaddress2,
		ISNULL(Bs.address3,'''') Bsaddress3, 
		ISNULL(Bs.address4,'''') Bsaddress4,
		ISNULL(Bs.phone1,'''') Bsphone, 
		ISNULL(Bs.vat,'''') Bsvat, 
		ISNULL(bs.SUSR3,'''') bssusr3, 
		ISNULL(bs.SUSR4,'''') bssusr4, 
		ISNULL(bs.SUSR5,'''') bssusr5,
		ISNULL(cast(Bs.notes2 as varchar(2000)),'''') Bsnotes2, 
		ISNULL(cast(Bs.notes1 as varchar(2000)),'''') Bsnotes1,
	ISNULL(sk.descr,'''') as skDescr,
	sk.sku as SKU, 
	od.orderlinenumber,
	ISNULL(sk.BUSR10,'''') Coutry, 
	sum(pd.qty) as qty, 
	max(od.unitprice) as unitprice, 
	ISNULL(od.tax01,'''') as odTax01, 
	ISNULL(od.susr1,'''') odsusr1,
	case	when isnull(sk.busr4,'''')<>'''' then busr4
			when isnull(sk.busr3,'''')<>'''' then busr3
			when isnull(sk.busr2,'''')<>'''' then busr2
			when isnull(sk.busr1,'''')<>'''' then busr1
	else ''��� ������''
	end BUSR

from '+@wh+'.orders o 
join '+@wh+'.orderdetail od on o.orderkey = od.orderkey
join '+@wh+'.storer s on o.storerkey = s.storerkey
join '+@wh+'.storer cs on o.consigneekey = cs.storerkey
join '+@wh+'.storer Bs on o.B_COMPANY = Bs.storerkey
join '+@wh+'.sku sk on od.sku = sk.sku and o.storerkey = sk.storerkey
join '+@wh+'.pickdetail pd on o.orderkey = pd.orderkey 
	and o.storerkey = pd.storerkey 
	and od.sku = pd.sku
	and pd.status>=5
where 1=1 ' + @where +'
  group by
	
	ISNULL(o.SUSR4,''''), o.orderkey, convert(varchar(10),o.adddate,103),
	case when o.orderDATE=o.ACTUALSHIPDATE then CONVERT(datetime, CONVERT(varchar(10), getdate(), 103), 103) else CONVERT(datetime, CONVERT(varchar(10), o.ACTUALSHIPDATE, 103), 103) end ,
	s.company, ISNULL(s.DESCRIPTION,''''), 
	ISNULL(s.address1,''''),
	ISNULL(s.address2,''''),
	ISNULL(s.address3,''''),
	ISNULL(s.address4,''''),
	ISNULL(s.phone1,''''), 
	ISNULL(s.vat,''''), 
	ISNULL(cast(s.notes2 as varchar(2000)),''''), 
		ISNULL(s.SUSR3,''''), 
		ISNULL(s.SUSR4,''''), 
		ISNULL(s.SUSR5,''''),
		ISNULL(cast(s.notes1 as varchar(2000)),''''), 
		ISNULL(s.B_COMPANY,''''), 
		ISNULL(s.B_address1,''''), 
		ISNULL(s.B_address2,''''), 
		ISNULL(s.B_address3,''''), 
		ISNULL(s.B_address4,''''),
		ISNULL(s.B_contact1,''''),
	ISNULL(cs.DESCRIPTION,''''),
	cs.company, 
	ISNULL(cs.address1,''''),
	ISNULL(cs.address2,''''),
	ISNULL(cs.address3,''''), 
	ISNULL(cs.address4,''''),
	ISNULL(cs.phone1,''''), 
	ISNULL(cs.vat,''''), 
	ISNULL(cast(cs.notes2 as varchar(2000)),''''), 
	ISNULL(cast(cs.notes1 as varchar(2000)),''''),
		ISNULL(Bs.DESCRIPTION,''''),
		Bs.company, 
		ISNULL(Bs.address1,''''),
		ISNULL(Bs.address2,''''),
		ISNULL(Bs.address3,''''), 
		ISNULL(Bs.address4,''''),
		ISNULL(Bs.phone1,''''), 
		ISNULL(Bs.vat,''''), 
		ISNULL(bs.SUSR3,''''), 
		ISNULL(bs.SUSR4,''''), 
		ISNULL(bs.SUSR5,''''),
		ISNULL(cast(Bs.notes2 as varchar(2000)),''''), 
		ISNULL(cast(Bs.notes1 as varchar(2000)),''''),
	ISNULL(sk.descr,''''), 
	sk.sku,
	ISNULL(sk.BUSR10,''''),  
	ISNULL(od.tax01,''''), 
	ISNULL(od.susr1,''''),
	od.orderlinenumber,
	sk.busr4,sk.busr3,sk.busr2,sk.busr1 

order by sk.busr4,sk.busr3,sk.busr2,sk.busr1 
'
print @sql
exec (@sql)

