
ALTER PROCEDURE dbo.rep_marshrut_vesogabarit
	@date_from datetime = NULL,
	@time_from varchar(5) = NULL,
	@date_to datetime = NULL,
	@time_to varchar(5) = NULL,
	@routes varchar(4000) = ''
as
begin
	set NOCOUNT on
	
	set @date_from = dbo.udf_get_date_from_datetime(isnull(@date_from,getdate()))
	set @date_to = dbo.udf_get_date_from_datetime(isnull(@date_to,getdate()))
	
	if dbo.sub_udf_common_regex_is_match(@time_from,'^([01][0-9]|2[0-3]):[0-5][0-9]$') = 1
		set @date_from = convert(datetime, convert(varchar(10),@date_from,120) + ' ' + @time_from + ':00',120)
	
	if dbo.sub_udf_common_regex_is_match(@time_to,'^([01][0-9]|2[0-3]):[0-5][0-9]$') = 1
		set @date_to = convert(datetime, convert(varchar(10),@date_to,120) + ' ' + @time_to + ':59',120)
	else
		set @date_to = @date_to + convert(time,'23:59:59.997')
	
select lh.ROUTE ,lod.SHIPMENTORDERID, o.EXTERNORDERKEY, o.ADDDATE, oss.DESCRIPTION,  sum(od.ORIGINALQTY * s.STDGROSSWGT) v, sum(od.ORIGINALQTY * s.STDCUBE) o
from wh1.LOADHDR lh 
	join wh1.LOADSTOP ls on ls.LOADID=lh.LOADID
	join wh1.LOADORDERDETAIL lod on lod.LOADSTOPID=ls.LOADSTOPID
	join wh1.ORDERS o on o.orderkey=lod.SHIPMENTORDERID
	join wh1.ORDERSTATUSSETUP oss on oss.CODE=o.STATUS
	join wh1.orderdetail od on od.ORDERKEY=lod.SHIPMENTORDERID
	join wh1.sku s on s.SKU=od.SKU
	
where		--lh.route in (@routes) and 
			( @routes = '' or lh.ROUTE in (select SLICE from dbo.sub_udf_common_split_string(@routes,',')) ) and
			lh.DEPARTURETIME between @date_from and @date_to

group by lh.ROUTE ,lod.SHIPMENTORDERID, o.EXTERNORDERKEY, o.ADDDATE, oss.DESCRIPTION
	
	
	
	
	
end

