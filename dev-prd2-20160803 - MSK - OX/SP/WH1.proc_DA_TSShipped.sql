ALTER PROCEDURE [WH1].[proc_DA_TSShipped](
	@wh varchar(30),
	@transmitlogkey varchar (10))
as

declare @loadid varchar(20)

select @loadid = key1 from wh1.TRANSMITLOG where TRANSMITLOGKEY = @transmitlogkey

select 	'TSSHIPPED' filetype,
	l.route mashina,
	o.EXTERNORDERKEY,
	o.EDITDATE shipdate
from	wh1.ORDERS o 
	join wh1.loadorderdetail lod 
	    on lod.SHIPMENTORDERID = o.ORDERKEY 
	join wh1.LOADSTOP ls 
	    on ls.LOADSTOPID = lod.LOADSTOPID
	join wh1.LOADHDR l 
	    on ls.LOADID = l.LOADID
where	ls.LOADID = @loadid

