


ALTER PROCEDURE [WH2].[proc_DA_TSShipped](
	@wh varchar(30),
	@transmitlogkey varchar (10))
as

declare @loadid varchar(20)

select @loadid = key1 from WH2.TRANSMITLOG where TRANSMITLOGKEY = @transmitlogkey

select 	'TSSHIPPED' filetype,
	l.route mashina,
	o.EXTERNORDERKEY,
	o.EDITDATE shipdate
from	WH2.ORDERS o 
	join WH2.loadorderdetail lod 
	    on lod.SHIPMENTORDERID = o.ORDERKEY 
	join WH2.LOADSTOP ls 
	    on ls.LOADSTOPID = lod.LOADSTOPID
	join WH2.LOADHDR l 
	    on ls.LOADID = l.LOADID
where	ls.LOADID = @loadid


