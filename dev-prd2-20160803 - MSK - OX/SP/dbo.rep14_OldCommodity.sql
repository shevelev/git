ALTER PROCEDURE [dbo].[rep14_OldCommodity](
	@wh varchar (10),
	@sku varchar(10),
	@lim varchar(10) = '',
	@RequestDate smalldatetime,
	@INN varchar(18),
	@Lot varchar(15),
	@carrierName varchar(20),
    @PUTAWAYZONE varchar(10)
)as


--declare 	@wh varchar (10),
--	@sku varchar(10),
--	@lim varchar(10),
--	@RequestDate smalldatetime,
--	@INN varchar(18),
--	@Lot varchar(15),
--	@carrierName varchar(60)

--declare @RequestDate smalldatetime
--select @wh = 'wh40', @RequestDate = '20090101'--getdate()--
--	,@lim = null
	
	
--CREATE TABLE [#restab](
--	[qty] [decimal](38, 5) NULL,
--	[sku] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[lot] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[sk] [varchar](15) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[gr] [varchar](30) COLLATE Cyrillic_General_CI_AS NULL,
--	[opisanie] [varchar](60) COLLATE Cyrillic_General_CI_AS NULL,
--	STDORDERCOST varchar(50),
--	[srok] [datetime] NULL,
--	[company] [varchar](45) COLLATE Cyrillic_General_CI_AS NULL,
--	[ost] [int] NULL) 

declare @sql varchar (max)

set @RequestDate = dateadd(dy,1,@RequestDate)
--insert into #restab
--print ''''+isnull(@sku,1)+''''
--set @sql =
--select STDORDERCOST,* from wh40.sku where STDORDERCOST <>''

set @sql =
'
select sum(l.qty) as qty, l.sku as sku, l.lot as lot, l.storerkey as sk 
    ,'''' STDORDERCOST
		,t.skugroup2 as gr, t.descr as opisanie, 
		lotatr.lottable05/*dateadd(mm,cast(STDORDERCOST as int),lotatr.lottable04)*/ as srok
		,st.company, 
		-cast(lotatr.lottable05-cast('''+convert(varchar(10),@RequestDate,112)+''' as datetime) as int)/*-datediff(day,dateadd(mm,cast(STDORDERCOST as int),lotatr.lottable04),'''+convert(varchar(10),@RequestDate,112)+''')*/ as ost,
		''''/*cr.companyName*/ CarrierName, st.vat
from '+@wh+'.lotxlocxid as l 
        left join '+@wh+'.LOC as loc on loc.LOC=l.LOC
		left join '+@wh+'.sku as t on l.sku=t.sku and l.storerkey=t.storerkey
		left join '+@wh+'.lotattribute as lotatr on l.lot=lotatr.lot
		--left join '+@wh+'.receipt as r on r.receiptkey=lotatr.lottable06
		--left join '+@wh+'.storer as cr on cr.storerkey=r.carrierkey
		left join '+@wh+'.storer as st on st.storerkey=l.storerkey

where /*1=1 and not STDORDERCOST is null and*/ isnull(lotatr.lottable05,'''')<> ''''  '--and dateadd(mm,cast(STDORDERCOST as int),lotatr.lottable04) < '''+convert(varchar(10),@RequestDate,112)+''''+
+' and cast(lotatr.lottable05-cast('''+convert(varchar(10),@RequestDate,112)+''' as datetime) as int)<=0'
+case when isnull(@sku,'')=''  then '' else ' and l.sku like ''' + @sku + '''' end 
+case when isnull(@INN,'')=''  then '' else ' and cr.vat like ''' + @INN + '''' end 
+' and l.storerkey=''' + @carrierName + ''''
+case when isnull(@Lot,'')=''  then '' else ' and l.lot like ''' + @Lot + '''' end 
+case when @PUTAWAYZONE<>'SKLAD' then  ' and loc.PUTAWAYZONE='''+@PUTAWAYZONE+'''' else
       'and loc.PUTAWAYZONE not in 
                          (select z.PUTAWAYZONE from '+@wh+'.hostzones z) ' end
--+case when isnull(@lim ,'')='' then '' else 
--	' and -datediff(day,dateadd(mm,cast(STDORDERCOST as int),lotatr.lottable04),'''+convert(varchar(10),@RequestDate,112)+''') < ' + @lim end
 +' group by l.sku,l.lot,l.storerkey,t.skugroup2,
 --STDORDERCOST,
	t.descr,
	lotatr.lottable05/*dateadd(mm,cast(STDORDERCOST as int),lotatr.lottable04)*/
	,st.company,/*cr.companyName,*/ st.vat
having sum(l.qty)>0
order by ost desc, opisanie,srok '
print @sql

exec (@sql)

--select * from #restab
--
--drop table #restab

--select * from wh40.lotxlocxid lli 
--left join wh40.lotattribute as lotatr on lli.lot=lotatr.lot
--order by lottable05
-- where lot in ('0000001200',
--'0000001194',
--'0000001148',
--'0000001187',
--'0000001127',
--'0000001155',
--'0000000467',
--'0000000468',
--'0000000469',
--'0000001204')
---and datediff(day,lotatr.lottable05,@RequestDate)


--select * from wh40.lotattribute order by lottable05 desc

