
ALTER PROCEDURE [dbo].[proc_DA_physicalposted_Logicon]
	@wh varchar(10), 
	@transmitlogkey varchar(10)
AS
--BEGIN
	--SET NOCOUNT ON
	
	declare @phkey int
	declare @bsanalit varchar(100)

	SELECT @phkey = KEY1 FROM wh1.TRANSMITLOG where transmitlogkey = @transmitlogkey
	select @bsanalit = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bsanalit'
	
	select  'INVENTORY' as filetype,  zz.STORERKEY,  
			case when zz.LOTTABLE03 != 'OK' then  '1'  else   --4
			case when zz.LOTTABLE07 != 'OK' then  '30'   else  
			case when zz.LOTTABLE08 != 'OK'then  '22'   else  

			zz.sklad end     end     end sklad,
			--case when zz.LOC = 'LOST' then  '35'   else  
			--case when zz.LOC = 'SD01' OR zz.LOC = 'SD02' then  '3'   else  '1'   end   end   end     end     end sklad,      
			zz.SKU,     -- zz.packkey,      
			case when zz.LOTTABLE02 = '' then  @bsanalit else      zz.LOTTABLE02      end AS ATTRIBUTE02,      
			zz.LOTTABLE04 AS ATTRIBUTE04, zz.LOTTABLE05 AS ATTRIBUTE05,zz.LOTTABLE06, zz.planqty, zz.factqty, zz.delta ,zz.skladDAX  
	into	#itog   
	from       
	  (select      z.STORERKEY,      ISNULL(z.LOTTABLE03, '') as LOTTABLE03,      ISNULL(z.LOTTABLE07, '') as LOTTABLE07,      
	  ISNULL(z.LOTTABLE08, '') as LOTTABLE08, 
	  --z.LOC, 
	  z.sklad,
	  z.SKU, --ISNULL(z.packkey, '') as packkey,      
	  ISNULL(z.LOTTABLE02, '') as LOTTABLE02,      
	  ISNULL(z.LOTTABLE04, CONVERT(datetime, '1900-01-01 00:00:00.000')) as LOTTABLE04,      
	  ISNULL(z.LOTTABLE05, CONVERT(datetime, '1900-01-01 00:00:00.000')) as LOTTABLE05,
	  ISNULL(z.LOTTABLE06, '') as LOTTABLE06,       
	  SUM(z.planqty) as planqty,     SUM(z.factqty) as factqty,     SUM(z.factqty - z.planqty) as delta,
	  z.skladDAX    
	  from     
		(select lli.STORERKEY as STORERKEY,la.LOTTABLE03 as LOTTABLE03, la.LOTTABLE07 as LOTTABLE07,la.LOTTABLE08 as LOTTABLE08,      
	     
		 --lli.LOC as LOC,      
		 case when lli.LOC = 'LOST' then  '35' else  
		 case when lli.LOC = 'SD01' OR lli.LOC = 'SD02' then  '3' else  '1'   end   end sklad,
	     
		 lli.SKU as SKU,     /* la.LOTTABLE01 packkey,*/      la.LOTTABLE02 as LOTTABLE02,      la.LOTTABLE04 as LOTTABLE04,      
		 la.LOTTABLE05 as LOTTABLE05, la.LOTTABLE06,lli.qty as planqty, 0 as factqty, w.sklad as skladDAX
		 from   wh1.lotxlocxid_CST0030 lli 
				left join wh1.lotattribute la on lli.LOT = la.lot
				join wh1.LOC l on l.LOC = lli.LOC
				left join dbo.WHTOZONE w on w.zone = l.PUTAWAYZONE
		 where  lli.LOC in (select loc from wh1.PHYSICAL_CST0030 where PHYSICAL_030 = @phkey)      and lli.qty > 0 and  
				lli.inventoryid_030 = @phkey     
		 union      
		 select lli.STORERKEY,      la.LOTTABLE03,      la.LOTTABLE07,      la.LOTTABLE08,      
				--lli.LOC,      
				case when lli.LOC = 'LOST' then  '35' else  
				case when lli.LOC = 'SD01' OR lli.LOC = 'SD02' then  '3' else  '1'   end   end sklad,
			
				lli.SKU, /*la.LOTTABLE01, */ la.LOTTABLE02,la.LOTTABLE04, la.LOTTABLE05,la.LOTTABLE06, 0, lli.QTY, w.sklad as skladDAX      
		 from   wh1.PHYSICAL_CST0030 lli 
				left join wh1.lotattribute la on lli.LOT = la.lot      
				join wh1.LOC l on l.LOC = lli.LOC
				left join dbo.WHTOZONE w on w.zone = l.PUTAWAYZONE
		 where  lli.LOC in (select loc from wh1.PHYSICAL_CST0030 where PHYSICAL_030 = @phkey)
		 ) as z      
		 group by z.STORERKEY, z.LOTTABLE03, z.LOTTABLE07, z.LOTTABLE08, 
			
			--z.LOC
			z.sklad,		

			z.SKU, /*z.packkey,*/ z.LOTTABLE02, z.LOTTABLE04, z.LOTTABLE05,ISNULL(z.LOTTABLE06, ''),z.skladDAX
			) as zz  
	where zz.SKU <>'EMPTY' 
	
	
	declare @n bigint


	select  @n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
	from    [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventsumFromWMS
	
	
	select	IDENTITY(int,1,1) as id,
			DataAReaID,sessionid,
			data,transdate,
			type,
			sku, DESCR,
			skladDAX,
			LOTTABLE06,ATTRIBUTE02,ATTRIBUTE04,ATTRIBUTE05,
			planqty,factqty,
			status
	into	#zz
	from	(
			select  'SZ' as DataAReaID,@transmitlogkey as sessionid,
					convert(varchar(12),getdate(),112) as data,
					convert(varchar(12),getdate(),112) as transdate,
					'1' as type,
					i.sku, s.DESCR,
					skladDAX,
					LOTTABLE06,ATTRIBUTE02,ATTRIBUTE04,ATTRIBUTE05,
					sum(planqty) as planqty, 
					sum(factqty) as factqty, 		
					'5' as status	
			from	#itog i
					join wh1.sku s
						on s.SKU = i.SKU
			group by --getdate(),
					i.sku, s.DESCR,
					skladDAX,
					LOTTABLE06,ATTRIBUTE02,ATTRIBUTE04,ATTRIBUTE05
			)g
	
	
	insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventsumFromWMS
	(DataAReaID, sessionid, date, transdate, Type, itemid,itemname, 
	Inventlocationid,
	 inventbatchID, inventserialid, expiredate, manufacturedate,inventqtyonhandwms,qtywms, 
	 Status,RecID,barcodestring)
	
			
			
	select	DataAReaID,sessionid,
			data,transdate,
			type,sku, DESCR,
			skladDAX,LOTTABLE06,ATTRIBUTE02,ATTRIBUTE05,ATTRIBUTE04,
			planqty,
			factqty,
			status,
			@n + id as recid,
			'' as altsku 
	from	#zz
	
	
	select * from #itog
					

--END

