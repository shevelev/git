
/**************************************************************************************/

ALTER PROCEDURE [WH2].[proc_DA_SKU_Update]
	@wh varchar(10),
	@transmitlogkey varchar (10)
AS

--declare @transmitlogkey varchar (10)
declare @sku varchar(50)
declare @storerkey varchar(50)
declare @altsku varchar (50)


    
CREATE TABLE [#rt](
	[filetype] [nvarchar](16) COLLATE Cyrillic_General_CI_AS NULL,	
	[sku] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[stdgrosswgt] [nvarchar](5) COLLATE Cyrillic_General_CI_AS NULL,		
	[stdcube] [nvarchar](5) COLLATE Cyrillic_General_CI_AS NULL,
	[grossdepth] [nvarchar](5) COLLATE Cyrillic_General_CI_AS NULL,
	[grosswidth] [nvarchar](5) COLLATE Cyrillic_General_CI_AS NULL,	
	[grossheight] [nvarchar](5) COLLATE Cyrillic_General_CI_AS NULL,
	[altsku] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[skugroup] [nvarchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[freightclass] [nvarchar](10) COLLATE Cyrillic_General_CI_AS NULL
	)

select	@sku = tl.key1,
	@storerkey = tl.KEY2
from	WH2.transmitlog tl
where	tl.transmitlogkey = @transmitlogkey
	and tl.TABLENAME = 'commodityupdated'
	
	
select	IDENTITY(int,1,1) as id,
	'COMMODITYUPDATE' as filetype,
	s.SKU,	
	s.STDGROSSWGT,
	s.STDCUBE,
	0 as grossdepth,
	0 as grosswidth,
	0 as grossheight,
	a.ALTSKU,
	s.SKUGROUP,
	s.FREIGHTCLASS
into	#e	
from	WH2.SKU s
	left join WH2.ALTSKU a
	    on a.STORERKEY = s.STORERKEY
	    and a.SKU = s.SKU
where	s.SKU = @sku
	and s.STORERKEY = @storerkey
	
declare @n bigint

select	@n = isnull(max(cast(cast(recid as numeric) as bigint)),0) -- проверка на null, иначе не вставлялось.
from	[spb-sql1202].[DAX2009_1].[dbo].SZ_ImpItemgrossparameters

    	
insert into [spb-sql1202].[DAX2009_1].[dbo].SZ_ImpItemgrossparameters
(itemid, netweight, unitvolume, grossdepth, grosswidth, grossheight, barcodestring, vital, freightclass, status, error,recid, dataareaid)

select	SKU,STDGROSSWGT,STDCUBE,0,0,0,isnull(ALTSKU,''),'',FREIGHTCLASS,'5' as status,'',@n+id, 'vir'

from	#e	
	
	
select * from #e


IF OBJECT_ID('tempdb..#e') IS NOT NULL DROP TABLE #e	



