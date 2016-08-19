ALTER PROCEDURE [dbo].[Report_1T] (
@wh varchar (15), @orderkey varchar (15))
as
declare @sql varchar (max)
set @sql =
'SELECT	CONVERT(datetime, CONVERT(varchar(10), ord.EDITDATE, 104), 104) AS EditDate,
		CONVERT(datetime, CONVERT(varchar(10), ord.ADDDATE, 103), 103) AS AddDate,
		case when ord.orderDATE=ord.ACTUALSHIPDATE then CONVERT(datetime, CONVERT(varchar(10), getdate(), 103), 103) else CONVERT(datetime, CONVERT(varchar(10), ord.ACTUALSHIPDATE, 103), 103) end AS RequestedShipDate,
		o.ORDERKEY,
		ord.susr4 as SMnum,
		s.DESCR,
		s.SKU,
		sum(pd.qty) AS shippedqty,
		sum(pd.qty*s.stdgrosswgt/1000) as weight, 
		sum(ISNULL(o.UNITPRICE, 0)) AS price,
		round(sum(ISNULL(o.UNITPRICE, 0) * pd.qty),2) AS cost,
		(ISNULL(ConstST.COMPANY, '''') + '', ��� '' + ISNULL(ConstST.VAT, '''') + '', '' + ISNULL(ConstST.ADDRESS1, '''') + '' '' + ISNULL(ConstST.ADDRESS2, '''') + '' '' + ISNULL(ConstST.ADDRESS3, '''')
			+ '', '' + ISNULL(ConstST.PHONE1, '''') + '', '' + ISNULL(ConstST.FAX1, '''')+ ISNULL(cast(ConstST.NOTES2 as varchar(max)),'''')) 
		AS CONSIGNEEKEY,
		(ISNULL(ord.C_City,'''')+'',''+ISNULL(ord.C_ADDRESS1, '''')) 
		as razgruzka,
		(ISNULL(BcompanyST.COMPANY, '''') + '', ��� '' + ISNULL(BcompanyST.VAT, '''') + '', '' + ISNULL(BcompanyST.ADDRESS1, '''') + '' '' + ISNULL(BcompanyST.ADDRESS2, '''') + '' '' + ISNULL(BcompanyST.ADDRESS3, '''')
			+ '', '' + ISNULL(BcompanyST.PHONE1, '''') + '', '' + ISNULL(BcompanyST.FAX1, '''') + ISNULL(cast(BcompanyST.NOTES2 as varchar(max)),'''')) 
		AS BCOMPANY,		
		(ISNULL(st.COMPANY, '''') + '', ��� '' + ISNULL(st.VAT, '''') + '', '' + ISNULL(st.ADDRESS1, '''') 
                      + '' '' + ISNULL(st.ADDRESS2, '''') + '' '' + ISNULL(st.ADDRESS3, '''') + '', '' + ISNULL(st.PHONE1, '''') + '', '' + ISNULL(st.FAX1, '''')+ ISNULL(cast(st.NOTES2 as varchar(max)),''''))
		 AS CLIENT,
			vst.COMPANY as vname,
			vst.vat as vvat,
			tst.Company as tname,
			tst.vat as tvat,
			st.COMPANY as stCompany,
			ISNULL(st.susr3,'''') as okpo,
			ISNULL(st.susr5,'''') as ogrn,
		ISNULL(cast(st.notes2 as varchar(2000)),'''') as stnotes2,
		ISNULL(cast(st.notes1 as varchar(2000)),'''') as stnotes1, ISNULL(st.B_COMPANY,'''') as stBcompany, 
		ISNULL(st.B_address1,'''') as stBaddress1, ISNULL(st.B_address2,'''') as stBaddress2, 
		ISNULL(st.B_address3,'''') as stBaddress3, ISNULL(st.B_address4,'''') as stBaddress4,
		ISNULL(st.B_contact1,'''') as stBcontact1,
		ISNULL(o.tax01,'''') as odTax01

FROM         '+@WH+'.ORDERDETAIL AS o INNER JOIN
                      '+@WH+'.SKU AS s ON s.SKU = o.SKU AND s.STORERKEY = o.STORERKEY INNER JOIN
                      '+@WH+'.STORER AS st ON st.STORERKEY = o.STORERKEY INNER JOIN
                      '+@WH+'.ORDERS AS ord ON ord.ORDERKEY = o.ORDERKEY left JOIN
						'+@WH+'.STORER AS Vst ON Vst.STORERKEY=ord.intermodalvehicle left JOIN
						'+@WH+'.STORER AS Tst ON Tst.STORERKEY=ord.CarrierCode INNER JOIN
						'+@WH+'.STORER AS ConstST ON ConstST.STORERKEY=ord.CONSIGNEEKEY INNER JOIN
						'+@WH+'.STORER AS BcompanyST ON BcompanyST.STORERKEY=ord.B_COMPANY
						JOIN '+@WH+'.pickdetail AS pd ON (pd.orderkey=o.orderkey and pd.sku=o.sku and pd.storerkey=o.storerkey and pd.status>=5)
WHERE     (o.ORDERKEY = '''+@orderkey+''')

group by CONVERT(datetime, CONVERT(varchar(10), ord.EDITDATE, 104), 104), 
		CONVERT(datetime, CONVERT(varchar(10), ord.ADDDATE, 103), 103),
		case when ord.orderDATE=ord.ACTUALSHIPDATE then CONVERT(datetime, CONVERT(varchar(10), getdate(), 103), 103) else CONVERT(datetime, CONVERT(varchar(10), ord.ACTUALSHIPDATE, 103), 103) end ,
		o.ORDERKEY,
		ord.susr4,
		s.DESCR,
		s.SKU,
		(ISNULL(ConstST.COMPANY, '''') + '', ��� '' + ISNULL(ConstST.VAT, '''') + '', '' + ISNULL(ConstST.ADDRESS1, '''') + '' '' + ISNULL(ConstST.ADDRESS2, '''') + '' '' + ISNULL(ConstST.ADDRESS3, '''')
			+ '', '' + ISNULL(ConstST.PHONE1, '''') + '', '' + ISNULL(ConstST.FAX1, '''')+ ISNULL(cast(ConstST.NOTES2 as varchar(max)),'''')),
		(ISNULL(BcompanyST.COMPANY, '''') + '', ��� '' + ISNULL(BcompanyST.VAT, '''') + '', '' + ISNULL(BcompanyST.ADDRESS1, '''') + '' '' + ISNULL(BcompanyST.ADDRESS2, '''') + '' '' + ISNULL(BcompanyST.ADDRESS3, '''')
			+ '', '' + ISNULL(BcompanyST.PHONE1, '''') + '', '' + ISNULL(BcompanyST.FAX1, '''') + ISNULL(cast(BcompanyST.NOTES2 as varchar(max)),'''')),
		(ISNULL(st.COMPANY, '''') + '', ��� '' + ISNULL(st.VAT, '''') + '', '' + ISNULL(st.ADDRESS1, '''') 
                      + '' '' + ISNULL(st.ADDRESS2, '''') + '' '' + ISNULL(st.ADDRESS3, '''') + '', '' + ISNULL(st.PHONE1, '''') + '', '' + ISNULL(st.FAX1, '''')+ ISNULL(cast(st.NOTES2 as varchar(max)),'''')),
		vst.COMPANY,
			vst.vat,
			tst.Company,
			tst.vat,
			st.COMPANY,
			ISNULL(st.susr3,''''),
			ISNULL(st.susr5,''''),
		ISNULL(cast(st.notes2 as varchar(2000)),''''),
		ISNULL(cast(st.notes1 as varchar(2000)),''''), ISNULL(st.B_COMPANY,''''), 
		ISNULL(st.B_address1,''''), ISNULL(st.B_address2,''''), ISNULL(st.B_address3,''''), ISNULL(st.B_address4,''''),
		ISNULL(st.B_contact1,''''),
		(ISNULL(ord.C_City,'''')+'',''+ISNULL(ord.C_ADDRESS1, '''')),
		ISNULL(o.tax01,'''')
ORDER BY s.DESCR '
print (@sql)
exec (@sql)

