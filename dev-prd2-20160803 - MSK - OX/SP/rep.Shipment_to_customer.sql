
--DECLARE
ALTER PROCEDURE [rep].[Shipment_to_customer]
@start_time VARCHAR(5)=NULL,
@end_time VARCHAR(5)=NULL,
@start_date datetime,--='01.09.2013',
@end_date datetime,--='01.10.2014',
@consigne varchar(30),
@word nvarchar(100)
AS
set @start_date = dbo.udf_get_date_from_datetime(isnull(@start_date,getdate()))
set @end_date = dbo.udf_get_date_from_datetime(isnull(@end_date,getdate()))

if dbo.sub_udf_common_regex_is_match(@start_time,'^([01][0-9]|2[0-3]):[0-5][0-9]$') = 1
		set @start_date = convert(datetime, convert(varchar(10),@start_date,120) + ' ' + @start_time + ':00',120)
	
	if dbo.sub_udf_common_regex_is_match(@end_time,'^([01][0-9]|2[0-3]):[0-5][0-9]$') = 1
		set @end_date = convert(datetime, convert(varchar(10),@end_date,120) + ' ' + @end_time + ':59',120)
	else
		set @end_date = @end_date + convert(time,'23:59:59.997')
DECLARE
@sql NVARCHAR(max)='		
SELECT	CONVERT(VARCHAR,a.ADDDATE,104) date,
		a.ORDERKEY,
		a.EXTERNORDERKEY,
		a.CONSIGNEEKEY,
		b.CompanyName,
		(SELECT COUNT(ORDERKEY)
		FROM WH1.ORDERDETAIL inside
		WHERE a.ORDERKEY = inside.ORDERKEY) qtyStrings,
		
		ISNULL(
		(SELECT sum(BOXNUM)
		FROM(
		SELECT DISTINCT pcl.*
		FROM WH1.PICKCONTROL_LABEL pcl JOIN WH1.PICKDETAIL pd
		ON pcl.CASEID = pd.CASEID JOIN WH1.ORDERS o
		ON o.ORDERKEY = pd.ORDERKEY
		WHERE o.STATUS >=78  AND BOXNUM is not null AND a.ORDERKEY = o.ORDERKEY)ef ),0)
		+
		ISNULL(
		(SELECT sum(pd.UOMQTY)
		FROM WH1.PICKCONTROL_LABEL pcl JOIN WH1.PICKDETAIL pd
		ON pcl.CASEID = pd.CASEID JOIN WH1.ORDERS o
		ON o.ORDERKEY = pd.ORDERKEY
		WHERE  a.ORDERKEY = o.ORDERKEY AND o.STATUS >=78  AND BOXNUM is null),0)
		+
		ISNULL(
		(SELECT sum(ceiling(o.originalqty/CONVERT(int,CASE WHEN o.PACKKEY IN (''STD'',''*'') THEN ''1'' ELSE o.PACKKEY END))) 
		FROM WH1.ORDERDETAIL o
		WHERE o.STATUS<78 AND a.ORDERKEY = o.ORDERKEY),0)  qtyPlaces,a.route, b.address1+b.address2+b.address3+b.address4 address
		

FROM WH1.ORDERS a JOIN WH1.STORER b
ON a.CONSIGNEEKEY = b.STORERKEY
WHERE a.ADDDATE BETWEEN @start_date AND @end_date ' + CASE WHEN @word is null and @consigne is null then ''
else
CASE WHEN @word IS NULL THEN 'AND @consigne = a.CONSIGNEEKEY' else 'AND b.CompanyName like ''%''+@word+''%'''end
end;
exec sp_executesql @sql,N'@start_time VARCHAR(5),@end_time VARCHAR(5),@start_date datetime,@end_date datetime,@consigne varchar(30),@word nvarchar(100)',
@start_time = @start_time,@end_time = @end_time, @start_date= @start_date,@end_date=@end_date,@consigne=@consigne,@word=@word

