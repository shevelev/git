ALTER PROCEDURE [dbo].[proc_DA_FizOstatki]
	@wh varchar(30),
	@transmitlogkey varchar (10)

as

set nocount on
	    
	    
CREATE TABLE [#rt](
	[id] int identity(1,1),
	[filetype] [nvarchar](16) COLLATE Cyrillic_General_CI_AS NULL,	
	[sessionid] [nvarchar](32) COLLATE Cyrillic_General_CI_AS NULL,	
	[data] [nvarchar](30) COLLATE Cyrillic_General_CI_AS NULL,	
	[transdate] [nvarchar](20) COLLATE Cyrillic_General_CI_AS NULL,
	[type] [nvarchar](3) COLLATE Cyrillic_General_CI_AS NULL,		
	[sku] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[skudescr] [nvarchar](200) COLLATE Cyrillic_General_CI_AS NULL,
	[inventlocationid] [nvarchar](25) COLLATE Cyrillic_General_CI_AS NULL,	--склад	
	[inventbatchid] [nvarchar](40) COLLATE Cyrillic_General_CI_AS NULL,  --партия,атрибут06 --Увеличил поле до 40 с 25(падало в ошибки)
	[inventserialid] [nvarchar](40) COLLATE Cyrillic_General_CI_AS NULL,	-- серийный номер,атрибут02
	[expiredate] [nvarchar](30) COLLATE Cyrillic_General_CI_AS NULL,    --дата срока годности	
	[manufacturedate] [nvarchar](30) COLLATE Cyrillic_General_CI_AS NULL, -- дата производства
	[inventqtyonhandwms] [nvarchar](30) COLLATE Cyrillic_General_CI_AS NULL,
	[barcodestring] [nvarchar](40) COLLATE Cyrillic_General_CI_AS NULL
	)    
			    
--select  STORERKEY, SKU,  max(ALTSKU) altsku  into #altsku from WH1.ALTSKU group by STORERKEY, SKU
select  STORERKEY, SKU,  max(ALTSKU) altsku  into #altsku from WH1.[ALTSKU] group by STORERKEY, SKU

insert into #rt
select  'INVENTOSTATOK' as filetype,
		@transmitlogkey as sessionid,
		convert(varchar(12),getdate(),112) as data,
		convert(varchar(12),getdate(),112) as transdate,
		'0' as type,
		l.SKU,
		s.DESCR,
		w.sklad,
		l2.LOTTABLE06,
	case when l2.LOTTABLE02 = '' then 'бс' else      l2.LOTTABLE02      end AS ATTRIBUTE02, 
		convert(varchar(12),ISNULL(l2.lottable05,'19000101'),112) as lottable05,
		convert(varchar(12),ISNULL(l2.lottable04,'19000101'),112) as lottable04,
		sum(l.QTY) as qty,
		isnull(a.ALTSKU,'')
from    wh1.TRANSMITLOG t
		join wh1.[LOTxLOCxID] l
			on t.TABLENAME = 'inventostatok'
		join wh1.LOC loc
			on loc.LOC = l.LOC and l.QTY > 0 --добавил количество >0
		join wh1.[LOTATTRIBUTE] l2
			on l2.LOT = l.LOT
		join wh1.[SKU] s
			on s.STORERKEY = l.STORERKEY
			AND s.SKU = l.SKU
		left join #altsku a
			on a.STORERKEY = s.STORERKEY
			and a.SKU = s.SKU
		join dbo.WHTOZONE w
			on w.zone = loc.PUTAWAYZONE
where   t.TRANSMITLOGKEY = @transmitlogkey
group by l.SKU,
    s.DESCR,
    w.sklad,
    l2.LOTTABLE06,
    l2.LOTTABLE02,
    l2.LOTTABLE05, 
    l2.LOTTABLE04,
     a.ALTSKU

drop table #altsku
	     
  if exists (select 1 from #rt)
  BEGIN
  	
  	print 'Пытаемся вставить в обменные таблы DAX'
  		    
	declare @n bigint


	select  @n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
	from    [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventsumFromWMS


	insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventsumFromWMS
	(DataAReaID, sessionid, date, transdate, Type, itemid,itemname, Inventlocationid,
	 inventbatchID, inventserialid, expiredate, manufacturedate,inventqtyonhandwms, 
	 Status,RecID,barcodestring)


	select  'SZ',sessionid,data,transdate,type,SKU,skudescr,inventlocationid, ---Переименовал все колонки в соответствии с #rt
		inventbatchid,inventserialid,expiredate,manufacturedate,inventqtyonhandwms,'5' as status,		
		@n + id as recid,barcodestring
	from    #rt
	
	
	
	select	*
	from	#rt 	
  	
  END  	    
    
  
IF OBJECT_ID('tempdb..#rt') IS NOT NULL DROP TABLE #rt
