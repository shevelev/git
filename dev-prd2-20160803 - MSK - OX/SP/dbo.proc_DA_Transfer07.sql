ALTER PROCEDURE [dbo].[proc_DA_Transfer07](
	@wh varchar(10),
	@transmitlogkey varchar (10)
	
)AS

--declare @transmitlogkey varchar (10)
CREATE TABLE #Result(
	[filetype] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[storerkey] [varchar](15) COLLATE Cyrillic_General_CI_AS NULL,
	[adjustmentkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[adjustmentlinenumber] [varchar](5) COLLATE Cyrillic_General_CI_AS NULL,
	[sku] [varchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[reasoncode] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[description] [varchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[qty] [int] NULL,
	[editdate] [varchar] (10) COLLATE Cyrillic_General_CI_AS NULL,
	[editwho] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
	[lottable08] [varchar](50) COLLATE Cyrillic_General_CI_AS NULL
)

insert into #Result
select 
	'MOVE'  filetype,
	td.fromstorerkey storerkey,
	td.transferkey transferkey,
	td.transferlinenumber transferlinenuber,
	td.fromsku sku,
	td.frompackkey packkey,
	-td.fromqty,
	convert(varchar(10),td.editdate,112) editdate,
	lt.LOTTABLE02,
	lt.LOTTABLE04,
	lt.LOTTABLE05,
	lt.lottable07,
	'' SOURCESKLAD,
	'' DESTSKLAD	,
	td.fromqty qty	
	from wh1.transmitlog tl

join wh1.transferdetail td on tl.key1 = td.transferkey
join wh1.lotattribute lt on lt.lot = td.fromlot
where tl.tablename = 'transferfinalized' and tl.transmitlogkey = @transmitlogkey


insert into #Result
select 
	'TRANSFER'  filetype,
	td.tostorerkey,
	td.transferkey,
	td.transferlinenumber,
	td.tosku,
	'TRANSFER' reasoncode,
	'“–¿Õ—‘≈–' description,
	td.toqty,
	convert(varchar(10),td.editdate,112) editdate,
	td.editwho,
	td.lottable08
	from wh1.transmitlog tl
join wh1.transferdetail td on tl.key1 = td.transferkey
where tl.tablename = 'transferfinalized' and tl.transmitlogkey = @transmitlogkey

--STORERKEY
--SKU
--PACKKEY
--ATTRIBUTE02
--ATTRIBUTE04
--ATTRIBUTE05
--SOURCESKLAD
--DESTSKLAD
--QTY

