ALTER PROCEDURE [dbo].[proc_DA_TransferMove](
	@wh varchar(10),
	@transmitlogkey varchar (10)
)AS

--declare @transmitlogkey varchar (10) set @transmitlogkey = '0005247082'

declare @bs varchar(3) select @bs = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'
declare @bsanalit varchar(3) select @bsanalit = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bsanalit'

select 
	'MOVE'  filetype,
	td.transferkey transferkey,
	td.transferlinenumber transferlinenuber,
	td.fromstorerkey storerkey,
	td.fromsku sku,
	lt.LOTTABLE01 packkey,
	case when lt.LOTTABLE02 = @bs then @bsanalit else lt.lottable02 end attribute02,
	convert(varchar(20),lt.LOTTABLE04,120) attribute04,
	convert(varchar(20),lt.LOTTABLE05,120) attribute05,
	tl.key3 SOURCESKLAD,
	tl.key4 DESTSKLAD,
	td.fromqty qty
	--convert(varchar(10),td.editdate,112) editdate
	from wh1.transmitlog tl
join wh1.transferdetail td on tl.key1 = td.transferkey
join wh1.lotattribute lt on lt.lot = td.fromlot
where tl.tablename = 'TransferMove' and tl.transmitlogkey = @transmitlogkey

