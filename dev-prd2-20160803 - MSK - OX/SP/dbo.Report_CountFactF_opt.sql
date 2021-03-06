ALTER PROCEDURE [dbo].[Report_CountFactF_opt] (
	@wh varchar(15),
	@orderkey varchar (15),
	@externorderkey varchar (20),
	@DocDate varchar(23)
)
as
declare
	@where varchar (2000),
	@where2 varchar (2000),
	@whereex varchar (2000),
	@sql varchar (max),
	@DocDate2 varchar(23)

	set @where = ' and 1=2'
	set @where2 = ' and 1=2'
	set @DocDate2=''



--	if @orderkey is not null and @externorderkey is not null
--		begin
--			set @where = ' and o.orderkey = '''+@orderkey+''' and o.externorderkey = '''+@externorderkey+''''
--		end
	if @orderkey is not null --or ltrim(rtrim(@orderkey)) != ''
		begin
		set @where = ' and o.orderkey = '''+@orderkey+''''
		set @where2 = ' and orderkey = '''+@orderkey+''''
		end
	if @externorderkey is not null --or ltrim(rtrim(@externorderkey)) != ''
		begin
		set @where = ' and o.externorderkey = '''+@externorderkey+''''
		set @where2 = ' and externorderkey = '''+@externorderkey+''''
		end

	if (@DocDate is null or @DocDate='')
		begin
			select max(o.editdate) eddate into #tmpDocDate2 from wh1.orderdetail o where 1=2 group by o.orderkey
			set @sql='insert into #tmpDocDate2 select max(o.editdate) eddate from wh1.orderdetail o where 1=1' + @where + ' group by o.orderkey'
			print (@sql)
			exec (@sql)
			set @DocDate2=(select convert(varchar(23),eddate,121) from #tmpDocDate2)
			print (@DocDate2)
			drop table #tmpDocDate2
			
			set @sql= 'update wh1.orders
						set deliverydate2='''+@DocDate2+'''
						where 1=1 and deliverydate2=orderdate' + @where2
			print (@sql)
			exec (@sql) 
		end
	else
		begin
			set @sql= 'update wh1.orders
						set deliverydate2='''+@DocDate+'''
						where 1=1' + @where2
			print (@sql)
			exec (@sql) 
			
		end
	

set @sql =
'select 
	ISNULL(o.SUSR4,'''') as susr4, 
	o.orderkey, 
	convert(varchar(10),o.adddate,103) adddate,
	case 
		when o.orderDATE=o.ACTUALSHIPDATE 
		then CONVERT(datetime, CONVERT(varchar(10), getdate(), 103), 103) 
		else CONVERT(datetime, CONVERT(varchar(10), o.ACTUALSHIPDATE, 103), 103) 
	end AS RequestedShipDate,

	ISNULL(s.companyname,s.company) scompany, 
	ISNULL(s.DESCRIPTION,'''') sDescr, 
	ISNULL(s.ZIP,'''') sZIP,
	ISNULL(s.CITY,'''') sCity,
	(ISNULL(s.address1,'''')
	+ ISNULL(s.address2,'''') 
	+ ISNULL(s.address3,'''') 
	+ ISNULL(s.address4,'''')) saddress,
	(ISNULL(s.phone1,'''') + ISNULL(s.phone2,'''')) sphone, 
	ISNULL(s.vat,'''') svat, 
	ISNULL(cast(s.notes2 as varchar(2000)),'''') snotes2, 
		ISNULL(s.SUSR3,'''') sSusr3, 
		ISNULL(s.SUSR4,'''') sSusr4, 
		ISNULL(s.SUSR5,'''') sSusr5,
		ISNULL(cast(s.notes1 as varchar(2000)),'''') snotes1, 
		ISNULL(s.B_COMPANY,'''') sBcompany, 
		(ISNULL(s.B_address1,'''')  
		+ ISNULL(s.B_address2,'''')  
		+ ISNULL(s.B_address3,'''')  
		+ ISNULL(s.B_address4,'''')) sBaddress,
		ISNULL(s.B_contact1,'''') sBcontact1,
	ISNULL(cs.DESCRIPTION,'''') csDescription,
	ISNULL(cs.companyname,cs.company) as csCompany, 
	ISNULL(cs.ZIP,'''') csZIP,
	ISNULL(cs.CITY,'''') csCity,
--	(ISNULL(cs.address1,'''') 
--	+ ISNULL(cs.address2,'''') 
--	+ ISNULL(cs.address3,'''') 
--	+ ISNULL(cs.address4,'''')) csaddress,
	(ISNULL(o.C_address1,'''') 
	+ ISNULL(o.C_address2,'''') 
	+ ISNULL(o.C_address3,'''') 
	+ ISNULL(o.C_address4,'''')) csaddress,
	(ISNULL(cs.phone1,'''') + ISNULL(cs.phone2,'''')) csphone, 
	ISNULL(cs.vat,'''') csvat, 
	ISNULL(cs.SUSR3,'''') cssusr3, 
	ISNULL(cs.SUSR4,'''') cssusr4, 
	ISNULL(cs.SUSR5,'''') cssusr5,
	ISNULL(cast(cs.notes2 as varchar(2000)),'''') csnotes2, 
	ISNULL(cast(cs.notes1 as varchar(2000)),'''') csnotes1,
		ISNULL(Bs.DESCRIPTION,'''') BsDescription,
		ISNULL(bs.companyname,bs.company) as BsCompany,
		ISNULL(bs.ZIP,'''') bsZIP,
		ISNULL(bs.CITY,'''') bsCity, 
--		(ISNULL(Bs.address1,'''') 
--		+ ISNULL(Bs.address2,'''') 
--		+ ISNULL(Bs.address3,'''') 
--		+ ISNULL(Bs.address4,'''')) Bsaddress,
		(ISNULL(o.B_address1,'''') 
		+ ISNULL(o.B_address2,'''') 
		+ ISNULL(o.B_address3,'''') 
		+ ISNULL(o.B_address4,'''')) Bsaddress,
		(ISNULL(Bs.phone1,'''') + ISNULL(Bs.phone2,'''')) Bsphone, 
		ISNULL(Bs.vat,'''') Bsvat, 
		ISNULL(bs.SUSR3,'''') bssusr3, 
		ISNULL(bs.SUSR4,'''') bssusr4, 
		ISNULL(bs.SUSR5,'''') bssusr5,
		ISNULL(cast(Bs.notes2 as varchar(2000)),'''') Bsnotes2, 
		ISNULL(cast(Bs.notes1 as varchar(2000)),'''') Bsnotes1,
	isnull(cast(sk.notes1 as varchar(2000)),ISNULL(sk.descr,'''')) as skDescr,
	sk.sku as SKU, 
	od.orderlinenumber,
	ISNULL(sk.BUSR10,'''') Coutry, 
	sum(pd.qty) as qty, 
	max(od.unitprice) as unitprice, 
	ISNULL(od.tax01,'''') as odTax01, 
	ISNULL(od.susr1,'''') odsusr1,
	case	when isnull(sk.busr4,'''')<>'''' then sk.busr4
			when isnull(sk.busr3,'''')<>'''' then sk.busr3
			when isnull(sk.busr2,'''')<>'''' then sk.busr2
			when isnull(sk.busr1,'''')<>'''' then sk.busr1
	else ''��� ������''
	end BUSR,
	max(od.editdate) editdate,
	o.deliverydate2 as DocDate

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
	and pd.qty>0
where 1=1 ' + @where +'
  group by
	
	ISNULL(o.SUSR4,'''') , 
	o.orderkey, 
	convert(varchar(10),o.adddate,103) ,
	case 
		when o.orderDATE=o.ACTUALSHIPDATE 
		then CONVERT(datetime, CONVERT(varchar(10), getdate(), 103), 103) 
		else CONVERT(datetime, CONVERT(varchar(10), o.ACTUALSHIPDATE, 103), 103) 
	end ,

	ISNULL(s.companyname,s.company) , 
	ISNULL(s.DESCRIPTION,'''') , 
	ISNULL(s.ZIP,'''') ,
	ISNULL(s.CITY,'''') ,
	(ISNULL(s.address1,'''')+ ISNULL(s.address2,'''') + ISNULL(s.address3,'''') + ISNULL(s.address4,'''')) ,
	(ISNULL(s.phone1,'''') + ISNULL(s.phone2,'''')) , 
	ISNULL(s.vat,'''') , 
	ISNULL(cast(s.notes2 as varchar(2000)),'''') , 
		ISNULL(s.SUSR3,'''') , 
		ISNULL(s.SUSR4,'''') , 
		ISNULL(s.SUSR5,'''') ,
		ISNULL(cast(s.notes1 as varchar(2000)),'''') , 
		ISNULL(s.B_COMPANY,'''') , 
		(ISNULL(s.B_address1,'''')  
		+ ISNULL(s.B_address2,'''')  
		+ ISNULL(s.B_address3,'''')  
		+ ISNULL(s.B_address4,'''')) ,
		ISNULL(s.B_contact1,'''') ,
	ISNULL(cs.DESCRIPTION,'''') ,
	ISNULL(cs.companyname,cs.company) , 
	ISNULL(cs.ZIP,'''') ,
	ISNULL(cs.CITY,'''') ,
--	(ISNULL(cs.address1,'''') 
--	+ ISNULL(cs.address2,'''') 
--	+ ISNULL(cs.address3,'''') 
--	+ ISNULL(cs.address4,'''')) ,
	(ISNULL(o.C_address1,'''') 
	+ ISNULL(o.C_address2,'''') 
	+ ISNULL(o.C_address3,'''') 
	+ ISNULL(o.C_address4,'''')) ,
	(ISNULL(cs.phone1,'''') + ISNULL(cs.phone2,'''')) , 
	ISNULL(cs.vat,'''') , 
	ISNULL(cs.SUSR3,'''') , 
	ISNULL(cs.SUSR4,'''') , 
	ISNULL(cs.SUSR5,'''') ,
	ISNULL(cast(cs.notes2 as varchar(2000)),'''') , 
	ISNULL(cast(cs.notes1 as varchar(2000)),'''') ,
		ISNULL(Bs.DESCRIPTION,'''') ,
		ISNULL(bs.companyname,bs.company) ,
		ISNULL(bs.ZIP,'''') ,
		ISNULL(bs.CITY,'''') , 
--		(ISNULL(Bs.address1,'''') 
--		+ ISNULL(Bs.address2,'''') 
--		+ ISNULL(Bs.address3,'''') 
--		+ ISNULL(Bs.address4,'''')) ,
		(ISNULL(o.B_address1,'''') 
		+ ISNULL(o.B_address2,'''') 
		+ ISNULL(o.B_address3,'''') 
		+ ISNULL(o.B_address4,'''')) ,
		(ISNULL(Bs.phone1,'''') + ISNULL(Bs.phone2,'''')) , 
		ISNULL(Bs.vat,'''') , 
		ISNULL(bs.SUSR3,'''') , 
		ISNULL(bs.SUSR4,'''') , 
		ISNULL(bs.SUSR5,'''') ,
		ISNULL(cast(Bs.notes2 as varchar(2000)),'''') , 
		ISNULL(cast(Bs.notes1 as varchar(2000)),'''') ,
	isnull(cast(sk.notes1 as varchar(2000)),ISNULL(sk.descr,'''')) ,
	sk.sku , 
	od.orderlinenumber,
	ISNULL(sk.BUSR10,'''') , 
	ISNULL(od.tax01,'''') , 
	ISNULL(od.susr1,'''') ,
	sk.busr4,sk.busr3,sk.busr2,sk.busr1,
	o.deliverydate2 

order by sk.busr4,sk.busr3,sk.busr2,sk.busr1 
'
print @sql
exec (@sql)

