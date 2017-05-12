ALTER PROCEDURE [dbo].[Report_1TF01] (
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
	



set @sql =
'SELECT	CONVERT(datetime, CONVERT(varchar(10), ord.EDITDATE, 104), 104) AS EditDate,
		CONVERT(datetime, CONVERT(varchar(10), ord.ADDDATE, 103), 103) AS AddDate,
		case when ord.orderDATE=ord.ACTUALSHIPDATE then CONVERT(datetime, CONVERT(varchar(10), getdate(), 103), 103) else CONVERT(datetime, CONVERT(varchar(10), ord.ACTUALSHIPDATE, 103), 103) end AS RequestedShipDate,
		o.ORDERKEY,
		ord.susr4 as SMnum,
		ISNULL(cast(s.notes1 as varchar(2000)),'''') DESCR,
		s.SKU,
		sum(pd.qty) AS shippedqty,
		sum(pd.qty*s.stdgrosswgt/1000) as weight, 
		sum(ISNULL(o.UNITPRICE, 0)) AS price,
		round(sum(ISNULL(o.UNITPRICE, 0) * pd.qty),2) AS cost,
		(ISNULL(ConstST.COMPANY, '''') + '', ''+ isnull(ConstST.ZIP,'''') + '', '' + ISNULL(ConstST.CITY, '''') + '', '' + ISNULL(ConstST.ADDRESS1, '''') + '' '' + ISNULL(ConstST.ADDRESS2, '''') + '' '' + ISNULL(ConstST.ADDRESS3, '''')
			+ '', '' + ISNULL(ConstST.PHONE1, '''') + '', '' + ISNULL(ConstST.FAX1, '''')+ ISNULL(cast(BcompanyST.NOTES2 as varchar(max)),'''')) 
		AS CONSIGNEEKEY,
		(ISNULL(ord.C_City,'''')+'',''+ISNULL(ord.C_ADDRESS1, '''')) 
		as razgruzka,
		(ISNULL(BcompanyST.COMPANY, '''') + '', ''+ isnull(BcompanyST.ZIP,'''') + '', ''  + ISNULL(BcompanyST.CITY, '''') + '', '' + ISNULL(BcompanyST.ADDRESS1, '''') + '' '' + ISNULL(BcompanyST.ADDRESS2, '''') + '' '' + ISNULL(BcompanyST.ADDRESS3, '''')
			+ '', '' + ISNULL(BcompanyST.PHONE1, '''') + '', '' + ISNULL(BcompanyST.FAX1, '''') + ISNULL(cast(BcompanyST.NOTES2 as varchar(max)),'''')) 
		AS BCOMPANY,		
		(ISNULL(st.COMPANY, '''') + '', ''+ isnull(ST.ZIP,'''') + '', '' + ISNULL(st.CITY, '''') + '', '' + ISNULL(st.ADDRESS1, '''') 
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
						JOIN '+@WH+'.pickdetail AS pd ON (pd.orderkey=o.orderkey and pd.sku=o.sku and pd.storerkey=o.storerkey and pd.status>=5)
WHERE     (o.ORDERKEY = '''+@orderkey+''')

group by CONVERT(datetime, CONVERT(varchar(10), ord.EDITDATE, 104), 104), 
		CONVERT(datetime, CONVERT(varchar(10), ord.ADDDATE, 103), 103),
		case when ord.orderDATE=ord.ACTUALSHIPDATE then CONVERT(datetime, CONVERT(varchar(10), getdate(), 103), 103) else CONVERT(datetime, CONVERT(varchar(10), ord.ACTUALSHIPDATE, 103), 103) end ,
		o.ORDERKEY,
		ord.susr4,
		ISNULL(cast(s.notes1 as varchar(2000)),''''),
		s.SKU,
		(ISNULL(ConstST.COMPANY, '''') + '', ''+ isnull(ConstST.ZIP,'''') + '', '' + ISNULL(ConstST.CITY, '''') + '', '' + ISNULL(ConstST.ADDRESS1, '''') + '' '' + ISNULL(ConstST.ADDRESS2, '''') + '' '' + ISNULL(ConstST.ADDRESS3, '''')
			+ '', '' + ISNULL(ConstST.PHONE1, '''') + '', '' + ISNULL(ConstST.FAX1, '''')+ ISNULL(cast(BcompanyST.NOTES2 as varchar(max)),'''')) 
		,
		(ISNULL(ord.C_City,'''')+'',''+ISNULL(ord.C_ADDRESS1, '''')) 
		,
		(ISNULL(BcompanyST.COMPANY, '''') + '', ''+ isnull(BcompanyST.ZIP,'''') + '', '' + ISNULL(BcompanyST.CITY, '''') + '', '' + ISNULL(BcompanyST.ADDRESS1, '''') + '' '' + ISNULL(BcompanyST.ADDRESS2, '''') + '' '' + ISNULL(BcompanyST.ADDRESS3, '''')
			+ '', '' + ISNULL(BcompanyST.PHONE1, '''') + '', '' + ISNULL(BcompanyST.FAX1, '''') + ISNULL(cast(BcompanyST.NOTES2 as varchar(max)),'''')) 
		,		
		(ISNULL(st.COMPANY, '''') + '', ''+ isnull(ST.ZIP,'''') + '', '' + ISNULL(st.CITY, '''') + '', '' + ISNULL(st.ADDRESS1, '''') 
                      + '' '' + ISNULL(st.ADDRESS2, '''') + '' '' + ISNULL(st.ADDRESS3, '''') + '', '' + ISNULL(st.PHONE1, '''') + '', '' + ISNULL(st.FAX1, '''')+ ISNULL(cast(st.NOTES2 as varchar(max)),''''))
		 ,
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
		ISNULL(o.tax01,''''),
		ord.deliverydate2
ORDER BY ISNULL(cast(s.notes1 as varchar(2000)),'''') '
print (@sql)
exec (@sql)

