ALTER PROCEDURE [dbo].[repF05_TORG13] (
@wh varchar (15), @orderkey varchar (15), @DocDate varchar(23))
as
declare @sql varchar (max),
		@DocDate2 varchar(23),
		@where varchar (2000),
		@where2 varchar (2000)

	set @where = ' and 1=2'
	set @where2 = ' and 1=2'
	set @DocDate2=''

if @orderkey is not null --or ltrim(rtrim(@orderkey)) != ''
		begin
		set @where = ' and o.orderkey = '''+@orderkey+''''
		set @where2 = ' and orderkey = '''+@orderkey+''''
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
	
-- *******************************

SELECT	CONVERT(datetime, CONVERT(varchar(10), ord.EDITDATE, 104), 104) AS EditDate,
		CONVERT(datetime, CONVERT(varchar(10), ord.ADDDATE, 103), 103) AS AddDate,
		case when ord.orderDATE=ord.ACTUALSHIPDATE 
			then CONVERT(datetime, CONVERT(varchar(10), getdate(), 103), 103) 
			else CONVERT(datetime, CONVERT(varchar(10), ord.ACTUALSHIPDATE, 103), 103) 
		end AS RequestedShipDate,

		o.ORDERKEY,
		ord.susr4 as SMnum,
		s.DESCR,
		s.SKU,

		sum(pd.qty) AS shippedqty,
		sum(pd.qty*s.stdgrosswgt/1000) as weight, 
		sum(ISNULL(o.UNITPRICE, 0)) AS price,
		round(sum(ISNULL(o.UNITPRICE, 0) * pd.qty),2) AS cost,
		

		ISNULL(ConstST.COMPANY, '') ConstSTCOMPANY,
		isnull(ConstST.ZIP,'') ConstSTZIP,
		ISNULL(ConstST.City,'') ConstSTCity,
		(ISNULL(ConstST.ADDRESS1, '') 
		+ ISNULL(ConstST.ADDRESS2, '') 
		+ ISNULL(ConstST.ADDRESS3, '')
		+ ISNULL(ConstST.address4,'')) ConstSTADDRESS,
		ISNULL(ConstST.PHONE1, '') +' ' 
		+ ISNULL(ConstST.PHONE2, '') ConstSTPHONE,
		ISNULL(cast(ConstST.NOTES2 as varchar(max)),'') BcompanyConstSTNOTES2, 
		ISNULL(ConstST.SUSR3,'') ConstOKPO, 
		ISNULL(ConstST.SUSR4,'') ConstKPP, 
		ISNULL(ConstST.SUSR5,'') ConstOGRN,
		
		(ISNULL(ord.C_City,'')+','+ISNULL(ord.C_ADDRESS1, '')) 
		as razgruzka,
		
		ISNULL(BcompanyST.COMPANY, '') BcompanySTCOMPANY,
		isnull(BcompanyST.ZIP,'') BcompanySTZIP,
		ISNULL(BcompanyST.City,'') BcompanySTCity,
		(ISNULL(BcompanyST.ADDRESS1, '') 
		+ ISNULL(BcompanyST.ADDRESS2, '') 
		+ ISNULL(BcompanyST.ADDRESS3, '')
		+ ISNULL(BcompanyST.ADDRESS4, '')) BcompanySTADDRESS,
		(ISNULL(BcompanyST.PHONE1, '') +' ' 
		+ ISNULL(BcompanyST.PHONE2, '')) BcompanySTPHONE,
		ISNULL(cast(BcompanyST.NOTES2 as varchar(max)),'') BcompanySTNOTES2,
		ISNULL(BcompanyST.SUSR3,'') BcompanyOKPO, 
		ISNULL(BcompanyST.SUSR4,'') BcompanyKPP, 
		ISNULL(BcompanyST.SUSR5,'') BcompanyOGRN,
		
		ISNULL(st.COMPANY, '') stCOMPANY,
		isnull(st.ZIP,'') stZIP,
		ISNULL(st.City,'') stCity,
		(ISNULL(st.ADDRESS1, '') 
		+ ISNULL(st.ADDRESS2, '') 
		+ ISNULL(st.ADDRESS3, '')
		+ ISNULL(st.ADDRESS4, ''))  stADDRESS,
		(ISNULL(st.PHONE1, '') +' ' 
		+ ISNULL(st.PHONE2, '')) stPHONE,
		

			vst.COMPANY as vname,
			vst.vat as vvat,
			tst.Company as tname,
			tst.vat as tvat,
			st.COMPANY as stCompany1,
			ISNULL(st.susr3,'') as okpo,
			ISNULL(st.susr5,'') as ogrn,
		ISNULL(cast(st.notes2 as varchar(2000)),'') as stnotes2,
		ISNULL(cast(st.notes1 as varchar(2000)),'') as stnotes1, 
		ISNULL(st.B_COMPANY,'') as stBcompany, 
		(ISNULL(st.B_address1,'') 
		+ ISNULL(st.B_address2,'') 
		+ ISNULL(st.B_address3,'') 
		+ ISNULL(st.B_address4,'')) as stBaddress4,
		ISNULL(st.B_contact1,'') as stBcontact1,
		ISNULL(o.tax01,'') as odTax01,
		ord.deliverydate2 as DocDate

INTO #tmpRTable

FROM         WH1.ORDERDETAIL AS o INNER JOIN
                      WH1.SKU AS s ON s.SKU = o.SKU AND s.STORERKEY = o.STORERKEY INNER JOIN
                      WH1.STORER AS st ON st.STORERKEY = o.STORERKEY INNER JOIN
                      WH1.ORDERS AS ord ON ord.ORDERKEY = o.ORDERKEY left JOIN
						WH1.STORER AS Vst ON Vst.STORERKEY=ord.intermodalvehicle left JOIN
						WH1.STORER AS Tst ON Tst.STORERKEY=ord.CarrierCode INNER JOIN
						WH1.STORER AS ConstST ON ConstST.STORERKEY=ord.CONSIGNEEKEY INNER JOIN
						WH1.STORER AS BcompanyST ON BcompanyST.STORERKEY=ord.B_COMPANY
						JOIN WH1.pickdetail AS pd ON (pd.orderkey=o.orderkey and pd.sku=o.sku and pd.storerkey=o.storerkey and pd.status>=5 and pd.qty>0)
WHERE     1=2 and (o.ORDERKEY = @orderkey)

group by CONVERT(datetime, CONVERT(varchar(10), ord.EDITDATE, 104), 104) ,
		CONVERT(datetime, CONVERT(varchar(10), ord.ADDDATE, 103), 103) ,
		case when ord.orderDATE=ord.ACTUALSHIPDATE 
			then CONVERT(datetime, CONVERT(varchar(10), getdate(), 103), 103) 
			else CONVERT(datetime, CONVERT(varchar(10), ord.ACTUALSHIPDATE, 103), 103) 
		end ,

		o.ORDERKEY,
		ord.susr4 ,
		s.DESCR,
		s.SKU,
		
		ISNULL(ConstST.COMPANY, '') ,
		isnull(ConstST.ZIP,'') ,
		ISNULL(ConstST.City,'') ,
		(ISNULL(ConstST.ADDRESS1, '') 
		+ ISNULL(ConstST.ADDRESS2, '') 
		+ ISNULL(ConstST.ADDRESS3, '')
		+ ISNULL(ConstST.address4,'')) ,
		ISNULL(ConstST.PHONE1, '') +' ' 
		+ ISNULL(ConstST.PHONE2, '') ,
		ISNULL(cast(ConstST.NOTES2 as varchar(max)),'') , 
		ISNULL(ConstST.SUSR3,'') , 
		ISNULL(ConstST.SUSR4,'') , 
		ISNULL(ConstST.SUSR5,'') ,
		
		(ISNULL(ord.C_City,'')+','+ISNULL(ord.C_ADDRESS1, '')),
		
		ISNULL(BcompanyST.COMPANY, '') ,
		isnull(BcompanyST.ZIP,'') ,
		ISNULL(BcompanyST.City,'') ,
		(ISNULL(BcompanyST.ADDRESS1, '') 
		+ ISNULL(BcompanyST.ADDRESS2, '') 
		+ ISNULL(BcompanyST.ADDRESS3, '')
		+ ISNULL(BcompanyST.ADDRESS4, '')) ,
		(ISNULL(BcompanyST.PHONE1, '') +' ' 
		+ ISNULL(BcompanyST.PHONE2, '')) ,
		ISNULL(cast(BcompanyST.NOTES2 as varchar(max)),'') ,
		ISNULL(BcompanyST.SUSR3,'') , 
		ISNULL(BcompanyST.SUSR4,'') , 
		ISNULL(BcompanyST.SUSR5,'') ,
		
		ISNULL(st.COMPANY, '') ,
		isnull(st.ZIP,'') ,
		ISNULL(st.City,'') ,
		(ISNULL(st.ADDRESS1, '') 
		+ ISNULL(st.ADDRESS2, '') 
		+ ISNULL(st.ADDRESS3, '')
		+ ISNULL(st.ADDRESS4, ''))  ,
		(ISNULL(st.PHONE1, '')+' ' 
		+ ISNULL(st.PHONE2, '')) ,
		

			vst.COMPANY ,
			vst.vat ,
			tst.Company ,
			tst.vat ,
			st.COMPANY ,
			ISNULL(st.susr3,'') ,
			ISNULL(st.susr5,'') ,
		ISNULL(cast(st.notes2 as varchar(2000)),'') ,
		ISNULL(cast(st.notes1 as varchar(2000)),'') , 
		ISNULL(st.B_COMPANY,'') , 
		(ISNULL(st.B_address1,'') 
		+ ISNULL(st.B_address2,'') 
		+ ISNULL(st.B_address3,'') 
		+ ISNULL(st.B_address4,'')) ,
		ISNULL(st.B_contact1,'') ,
		ISNULL(o.tax01,'') ,
		ord.deliverydate2
ORDER BY s.DESCR



--********************************

set @sql =' INSERT INTO #tmpRTable
		SELECT	CONVERT(datetime, CONVERT(varchar(10), ord.EDITDATE, 104), 104) AS EditDate,
		CONVERT(datetime, CONVERT(varchar(10), ord.ADDDATE, 103), 103) AS AddDate,
		case when ord.orderDATE=ord.ACTUALSHIPDATE 
			then CONVERT(datetime, CONVERT(varchar(10), getdate(), 103), 103) 
			else CONVERT(datetime, CONVERT(varchar(10), ord.ACTUALSHIPDATE, 103), 103) 
		end AS RequestedShipDate,

		o.ORDERKEY,
		ord.susr4 as SMnum,
		s.DESCR,
		s.SKU,

		sum(pd.qty) AS shippedqty,
		sum(pd.qty*s.stdgrosswgt/1000) as weight, 
		sum(ISNULL(o.UNITPRICE, 0)) AS price,
		round(sum(ISNULL(o.UNITPRICE, 0) * pd.qty),2) AS cost,
		

		ISNULL(ConstST.COMPANY, '''') ConstSTCOMPANY,
		isnull(ConstST.ZIP,'''') ConstSTZIP,
		ISNULL(ConstST.City,'''') ConstSTCity,
		(ISNULL(ConstST.ADDRESS1, '''') 
		+ ISNULL(ConstST.ADDRESS2, '''') 
		+ ISNULL(ConstST.ADDRESS3, '''')
		+ ISNULL(ConstST.address4,'''')) ConstSTADDRESS,
		ISNULL(ConstST.PHONE1, '''') +'' '' 
		+ ISNULL(ConstST.PHONE2, '''') ConstSTPHONE,
		ISNULL(cast(ConstST.NOTES2 as varchar(max)),'''') BcompanyConstSTNOTES2, 
		ISNULL(ConstST.SUSR3,'''') ConstOKPO, 
		ISNULL(ConstST.SUSR4,'''') ConstKPP, 
		ISNULL(ConstST.SUSR5,'''') ConstOGRN,
		
		(ISNULL(ord.C_City,'''')+'',''+ISNULL(ord.C_ADDRESS1, '''')) 
		as razgruzka,
		
		ISNULL(BcompanyST.COMPANY, '''') BcompanySTCOMPANY,
		isnull(BcompanyST.ZIP,'''') BcompanySTZIP,
		ISNULL(BcompanyST.City,'''') BcompanySTCity,
		(ISNULL(BcompanyST.ADDRESS1, '''') 
		+ ISNULL(BcompanyST.ADDRESS2, '''') 
		+ ISNULL(BcompanyST.ADDRESS3, '''')
		+ ISNULL(BcompanyST.ADDRESS4, '''')) BcompanySTADDRESS,
		(ISNULL(BcompanyST.PHONE1, '''') +'' '' 
		+ ISNULL(BcompanyST.PHONE2, '''')) BcompanySTPHONE,
		ISNULL(cast(BcompanyST.NOTES2 as varchar(max)),'''') BcompanySTNOTES2,
		ISNULL(BcompanyST.SUSR3,'''') BcompanyOKPO, 
		ISNULL(BcompanyST.SUSR4,'''') BcompanyKPP, 
		ISNULL(BcompanyST.SUSR5,'''') BcompanyOGRN,
		
		ISNULL(st.COMPANY, '''') stCOMPANY,
		isnull(st.ZIP,'''') stZIP,
		ISNULL(st.City,'''') stCity,
		(ISNULL(st.ADDRESS1, '''') 
		+ ISNULL(st.ADDRESS2, '''') 
		+ ISNULL(st.ADDRESS3, '''')
		+ ISNULL(st.ADDRESS4, ''''))  stADDRESS,
		(ISNULL(st.PHONE1, '''') +'' '' 
		+ ISNULL(st.PHONE2, '''')) stPHONE,
		

			vst.COMPANY as vname,
			vst.vat as vvat,
			tst.Company as tname,
			tst.vat as tvat,
			st.COMPANY as stCompany1,
			ISNULL(st.susr3,'''') as okpo,
			ISNULL(st.susr5,'''') as ogrn,
		ISNULL(cast(st.notes2 as varchar(2000)),'''') as stnotes2,
		ISNULL(cast(st.notes1 as varchar(2000)),'''') as stnotes1, 
		ISNULL(st.B_COMPANY,'''') as stBcompany, 
		(ISNULL(st.B_address1,'''') 
		+ ISNULL(st.B_address2,'''') 
		+ ISNULL(st.B_address3,'''') 
		+ ISNULL(st.B_address4,'''')) as stBaddress4,
		ISNULL(st.B_contact1,'''') as stBcontact1,
		ISNULL(o.tax01,'''') as odTax01,
		ord.deliverydate2 as DocDate



FROM         '+@WH+'.ORDERDETAIL AS o INNER JOIN
                      '+@WH+'.SKU AS s ON s.SKU = o.SKU AND s.STORERKEY = o.STORERKEY INNER JOIN
                      '+@WH+'.STORER AS st ON st.STORERKEY = o.STORERKEY INNER JOIN
                      '+@WH+'.ORDERS AS ord ON ord.ORDERKEY = o.ORDERKEY left JOIN
						'+@WH+'.STORER AS Vst ON Vst.STORERKEY=ord.intermodalvehicle left JOIN
						'+@WH+'.STORER AS Tst ON Tst.STORERKEY=ord.CarrierCode INNER JOIN
						'+@WH+'.STORER AS ConstST ON ConstST.STORERKEY=ord.CONSIGNEEKEY INNER JOIN
						'+@WH+'.STORER AS BcompanyST ON BcompanyST.STORERKEY=ord.B_COMPANY
						JOIN '+@WH+'.pickdetail AS pd ON (pd.orderkey=o.orderkey and pd.sku=o.sku and pd.storerkey=o.storerkey and pd.status>=5 and pd.qty>0)
WHERE     (o.ORDERKEY = '''+@orderkey+''')

group by CONVERT(datetime, CONVERT(varchar(10), ord.EDITDATE, 104), 104) ,
		CONVERT(datetime, CONVERT(varchar(10), ord.ADDDATE, 103), 103) ,
		case when ord.orderDATE=ord.ACTUALSHIPDATE 
			then CONVERT(datetime, CONVERT(varchar(10), getdate(), 103), 103) 
			else CONVERT(datetime, CONVERT(varchar(10), ord.ACTUALSHIPDATE, 103), 103) 
		end ,

		o.ORDERKEY,
		ord.susr4 ,
		s.DESCR,
		s.SKU,
		
		ISNULL(ConstST.COMPANY, '''') ,
		isnull(ConstST.ZIP,'''') ,
		ISNULL(ConstST.City,'''') ,
		(ISNULL(ConstST.ADDRESS1, '''') 
		+ ISNULL(ConstST.ADDRESS2, '''') 
		+ ISNULL(ConstST.ADDRESS3, '''')
		+ ISNULL(ConstST.address4,'''')) ,
		ISNULL(ConstST.PHONE1, '''') +'' '' 
		+ ISNULL(ConstST.PHONE2, '''') ,
		ISNULL(cast(ConstST.NOTES2 as varchar(max)),'''') , 
		ISNULL(ConstST.SUSR3,'''') , 
		ISNULL(ConstST.SUSR4,'''') , 
		ISNULL(ConstST.SUSR5,'''') ,
		
		(ISNULL(ord.C_City,'''')+'',''+ISNULL(ord.C_ADDRESS1, '''')),
		
		ISNULL(BcompanyST.COMPANY, '''') ,
		isnull(BcompanyST.ZIP,'''') ,
		ISNULL(BcompanyST.City,'''') ,
		(ISNULL(BcompanyST.ADDRESS1, '''') 
		+ ISNULL(BcompanyST.ADDRESS2, '''') 
		+ ISNULL(BcompanyST.ADDRESS3, '''')
		+ ISNULL(BcompanyST.ADDRESS4, '''')) ,
		(ISNULL(BcompanyST.PHONE1, '''') +'' '' 
		+ ISNULL(BcompanyST.PHONE2, '''')) ,
		ISNULL(cast(BcompanyST.NOTES2 as varchar(max)),'''') ,
		ISNULL(BcompanyST.SUSR3,'''') , 
		ISNULL(BcompanyST.SUSR4,'''') , 
		ISNULL(BcompanyST.SUSR5,'''') ,
		
		ISNULL(st.COMPANY, '''') ,
		isnull(st.ZIP,'''') ,
		ISNULL(st.City,'''') ,
		(ISNULL(st.ADDRESS1, '''') 
		+ ISNULL(st.ADDRESS2, '''') 
		+ ISNULL(st.ADDRESS3, '''')
		+ ISNULL(st.ADDRESS4, ''''))  ,
		(ISNULL(st.PHONE1, '''')+'' '' 
		+ ISNULL(st.PHONE2, '''')) ,
		

			vst.COMPANY ,
			vst.vat ,
			tst.Company ,
			tst.vat ,
			st.COMPANY ,
			ISNULL(st.susr3,'''') ,
			ISNULL(st.susr5,'''') ,
		ISNULL(cast(st.notes2 as varchar(2000)),'''') ,
		ISNULL(cast(st.notes1 as varchar(2000)),'''') , 
		ISNULL(st.B_COMPANY,'''') , 
		(ISNULL(st.B_address1,'''') 
		+ ISNULL(st.B_address2,'''') 
		+ ISNULL(st.B_address3,'''') 
		+ ISNULL(st.B_address4,'''')) ,
		ISNULL(st.B_contact1,'''') ,
		ISNULL(o.tax01,'''') ,
		ord.deliverydate2
ORDER BY s.DESCR '

print (@sql)
exec (@sql)

--=round(sum(Fields!cost.Value-(Fields!cost.Value*Fields!odTax01.Value/(100+Fields!odTax01.Value))),2)

select dbo.RubPhrase(round(sum(trt.cost-(trt.cost*trt.odTax01/(100+trt.odTax01))),2)) sumcost
from #tmpRTable trt

drop table #tmpRTable

