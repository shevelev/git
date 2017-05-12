


-- ÏÎÄÒÂÅĞÆÄÅÍÈÅ ÎÒÃĞÓÇÊÈ ÇÀÊÀÇÀ

ALTER PROCEDURE [dbo].[proc_DA_test](
	@wh varchar(10),
	@transmitlogkey varchar (10)
)AS


select 'ORDERSHIPPEDDA' filetype,
	'orderkey' as orderkey,
	'storerkey' as storerkey,--
	'externorderkey' as externorderkey,--
	'type' as type,--
	'susr1' as susr1,--
	'susr2' as susr2,
	'susr3' as susr3,--
	'susr4' as susr4,--
	'sku' as sku,--
	'packkey' as packkey,--
	'attribute02' as attribute02




