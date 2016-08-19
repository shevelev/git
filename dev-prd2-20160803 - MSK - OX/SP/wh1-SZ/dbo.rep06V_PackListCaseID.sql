/*¬ отчет rep06_PackListCaseID добавлена зона*/
ALTER PROCEDURE [dbo].[rep06V_PackListCaseID] (
/* 06 ”паковочный лист на €щик */
	@wh varchar(30),
	@begindate datetime,
	@enddate datetime,
	@wave varchar(10)=null,
	@order varchar(10)=null,
	@caseid varchar(20)=null,
	@viewall integer
)
--with encryption
as

--declare
--	@wh varchar(30),
--	@order varchar(10), @caseid varchar(20)
--select @wh = 'wh1', @order='0000006898'--, @caseid='0000068802'

declare @bdate varchar(10), @edate varchar(10)
set @bdate=convert(varchar(10),@begindate,104)
set @edate=convert(varchar(10),@enddate,104)

declare	@sql varchar (max)
 
-- EV <

set dateformat dmy
set @sql = '
declare @Ord_id varchar(10)
DECLARE Ord_cursor CURSOR STATIC
FOR 
select distinct P.ORDERKEY 
from '+@wh+'.PICKDETAIL AS P 
	left join '+@wh+'.TASKDETAIL TD on P.CASEID=TD.CASEID and P.PICKDETAILKEY=TD.PICKDETAILKEY
	left JOIN '+@wh+'.SKU AS S ON S.STORERKEY = P.STORERKEY AND S.SKU = P.SKU 
	left join '+@wh+'.LOC l on p.LOC=l.LOC
	left join '+@wh+'.LOTATTRIBUTE la on la.lot = p.lot
	where P.ORDERKEY in (select ORDERKEY from '+@wh+'.ORDERS where ORDERDATE between '''+@bdate+''' and '''+@edate+''') '+
	case when isnull(@wave,'')='' then '' else ' AND P.ORDERKEY in (select ORDERKEY from '+@wh+'.WAVEDETAIL where WAVEKEY='''+@wave+''') ' end+
	case when isnull(@order,'')='' then '' else ' AND P.ORDERKEY = '''+@order+''' ' end+
	case when @viewall=0 then ' AND (P.STATUS < 5)' else '' end+
	'
OPEN Ord_cursor
FETCH NEXT FROM Ord_cursor INTO @Ord_id
WHILE @@FETCH_STATUS= 0
BEGIN
  exec dbo.Up_pick1 @Ord_id, '''+@wh+'''  
  FETCH NEXT FROM Ord_cursor INTO  @Ord_id
END 
CLOSE Ord_cursor
DEALLOCATE Ord_cursor

'

exec(@sql)
-- EV >

select max(serialkey) serialkey,storerkey,sku,min(altsku) altsku
into #altsku
from WH1.altSKU
group by storerkey,sku

update a1
set a1.altsku=a2.altsku
from #altsku a1 join wh1.altsku a2 on a1.serialkey=a2.serialkey

	SELECT P.ORDERKEY, P.STORERKEY, P.SKU, P.LOC,O.TRANSPORTATIONSERVICE, dbo.GetEAN128(O.TRANSPORTATIONSERVICE) TRANSPORTATIONSERVICE1, P.CASEID, P.QTY, S.COMPANY, SK.DESCR,aSK.ALTSKU, 
			O.REQUESTEDSHIPDATE, P.FROMLOC, P.LOC AS Expr1, o.externorderkey,
			(o.C_Address1+o.C_Address2+o.C_Address3+o.C_Address4) DeliveryAdr, st1.vat clientINN,
			cast(case when (p.id <> '') then 'ѕаллета' else 'ящик' end as varchar(15)) CaseDescr,
			case when (p.id <> '') then 0 else 1 end CaseType,
			L.LOGICALLOCATION, P.STATUS, O.DOOR, P.ID, S.COMPANY AS Expr2, PK.CASECNT, 
			O.ORDERDATE, O.CONSIGNEEKEY, st1.COMPANY AS conscomp, 
			st1.ADDRESS1 AS consaddress, PK.SERIALKEY, 
			cast(ISNULL ( P.CARTONGROUP , 'PALLET') as varchar(20)) AS SEL_CARTONGROUP,
			cast(isnull(sk.susr4, 'шт.') as varchar(20)) baseMeasure, sk.susr6,p.lot, la.LOTTABLE03 as LOTTABLE03, la.LOTTABLE05 as LOTTABLE05
			,car.COMPANY CarrierName
	into #Sel
	FROM wh1.PICKDETAIL AS P 
		LEFT JOIN wh1.STORER AS S ON P.STORERKEY = S.STORERKEY 
		LEFT JOIN wh1.SKU AS SK ON SK.STORERKEY = P.STORERKEY AND SK.SKU = P.SKU 
		LEFT JOIN #altsku as aSK on SK.SKU=aSK.sku and SK.Storerkey=aSK.Storerkey
		LEFT JOIN wh1.ORDERS AS O ON O.ORDERKEY = P.ORDERKEY 
		LEFT JOIN wh1.PACK AS PK ON PK.PACKKEY = P.PACKKEY 
		LEFT JOIN wh1.LOC AS L ON P.LOC = L.LOC 
		left join wh1.STORER as car on O.CarrierCode=car.STORERKEY
		LEFT JOIN wh1.STORER AS st1 ON st1.STORERKEY = O.CONSIGNEEKEY
		left join wh1.LOTATTRIBUTE la on la.sku = p.sku and la.STORERKEY = p.STORERKEY
	WHERE 1=2
--select * from wh1.pickdetail where orderkey = '0000000935'

	select P.ORDERKEY, P.STORERKEY, P.SKU, P.LOC, P.CASEID, sum(P.QTY)QTY, 
						 P.FROMLOC, P.LOC AS Expr1,
						case when (p.id <> '') then 'ѕаллета' else 'ящик' end CaseDescr,
						case when (p.id <> '') then 1 else 1 end CaseType,
						P.STATUS, P.ID,	p.lot, p.packkey, P.CARTONGROUP, la.LOTTABLE03, la.LOTTABLE05
	into #picks
	from wh1.PICKDETAIL AS P 
	left join wh1.LOTATTRIBUTE la on la.sku = p.sku and la.STORERKEY = p.STORERKEY
	where 1=2
	group by P.ORDERKEY, P.STORERKEY, P.SKU, P.CASEID, P.FROMLOC , P.LOC, p.id, P.STATUS, p.lot, p.packkey, CARTONGROUP, la.LOTTABLE03, la.LOTTABLE05

--	set @sql = '
--	  set dateformat dmy
--	  insert into #picks select P.ORDERKEY, P.STORERKEY, P.SKU, P.LOC, P.CASEID, sum(P.QTY)QTY, 
--					 P.FROMLOC, isnull(TD.FROMLOC,'''') AS Expr1, --P.LOC AS Expr1,
--					case when (p.id <> '''') then ''ѕаллета'' else ''ящик'' end CaseDescr,
--					case when (p.id <> '''') then 1 else 1 end CaseType,
--					P.STATUS, P.ID,	p.lot, p.packkey, p.CARTONGROUP, max(la.LOTTABLE03), max(la.LOTTABLE05)
--				from '+@wh+'.PICKDETAIL AS P 
--				left join '+@wh+'.TASKDETAIL TD on P.CASEID=TD.CASEID and P.PICKDETAILKEY=TD.PICKDETAILKEY
--				left JOIN '+@wh+'.SKU AS S ON S.STORERKEY = P.STORERKEY AND S.SKU = P.SKU 
--				left join '+@wh+'.LOC l on p.LOC=l.LOC
--				left join '+@wh+'.LOTATTRIBUTE la on la.lot = p.lot
--				where P.ORDERKEY in (select ORDERKEY from '+@wh+'.ORDERS where ORDERDATE between '''+@bdate+''' and '''+@edate+''') '+
--				case when isnull(@wave,'')='' then '' else ' AND P.ORDERKEY in (select ORDERKEY from '+@wh+'.WAVEDETAIL where WAVEKEY='''+@wave+''') ' end+
--				case when isnull(@order,'')='' then '' else ' AND P.ORDERKEY = '''+@order+''' ' end+
--				case when @viewall=0 then ' AND (P.STATUS < 5)' else '' end+
--				' /*(s.LOTTABLEVALIDATIONKEY != ''02'' and l.PUTAWAYZONE not in (''OCTATKI7'',''OTMOTKA7'', ''BARABAN7'',''ELKA7''))*/
--				group by P.ORDERKEY, p.STORERKEY, p.SKU, P.CASEID, P.FROMLOC , 
--					p.LOC, isnull(TD.FROMLOC,''''), p.id, P.STATUS, p.lot, p.packkey, P.CARTONGROUP'
	set @sql = '
	  set dateformat dmy
	  insert into #picks select P.ORDERKEY, P.STORERKEY, P.SKU, P.LOC, P.CASEID, sum(P.QTY)QTY, 
					 P.FROMLOC, isnull(TD.FROMLOC,'''') AS Expr1, 
					''ящик'' CaseDescr,
					1 CaseType,
					P.STATUS, P.ID,	p.lot, p.packkey, p.CARTONGROUP, max(la.LOTTABLE03), max(la.LOTTABLE05)
				from '+@wh+'.PICKDETAIL AS P 
				left join '+@wh+'.TASKDETAIL TD on P.CASEID=TD.CASEID and P.PICKDETAILKEY=TD.PICKDETAILKEY
				left JOIN '+@wh+'.SKU AS S ON S.STORERKEY = P.STORERKEY AND S.SKU = P.SKU 
				left join '+@wh+'.LOC l on p.LOC=l.LOC
				left join '+@wh+'.LOTATTRIBUTE la on la.lot = p.lot
				where P.ORDERKEY in (select ORDERKEY from '+@wh+'.ORDERS where ORDERDATE between '''+@bdate+''' and '''+@edate+''') '+
				case when isnull(@wave,'')='' then '' else ' AND P.ORDERKEY in (select ORDERKEY from '+@wh+'.WAVEDETAIL where WAVEKEY='''+@wave+''') ' end+
				case when isnull(@order,'')='' then '' else ' AND P.ORDERKEY = '''+@order+''' ' end+
				case when @viewall=0 then ' AND (P.STATUS < 5)' else '' end+
				' group by P.ORDERKEY, p.STORERKEY, p.SKU, P.CASEID, P.FROMLOC , 
					p.LOC, isnull(TD.FROMLOC,''''), p.id, P.STATUS, p.lot, p.packkey, P.CARTONGROUP'
print (@sql)
	exec (@sql)
--select * from #picks
--	set @sql = 'insert #sel (ORDERKEY, STORERKEY, SKU, LOC, TRANSPORTATIONSERVICE, TRANSPORTATIONSERVICE1, CASEID, QTY, COMPANY, DESCR, ALTSKU, REQUESTEDSHIPDATE, 
--					FROMLOC, Expr1, externorderkey, DeliveryAdr, clientINN,	CaseDescr,	CaseType,
--					LOGICALLOCATION, STATUS,DOOR, ID, Expr2, CASECNT, ORDERDATE,CONSIGNEEKEY, conscomp, 
--					consaddress,SERIALKEY,sel_CARTONGROUP,baseMeasure,susr6,lot, LOTTABLE03, LOTTABLE05,CarrierName)
--				SELECT P.ORDERKEY, P.STORERKEY, P.SKU, P.LOC, O.TRANSPORTATIONSERVICE, dbo.GetEAN128(O.TRANSPORTATIONSERVICE) TRANSPORTATIONSERVICE1, P.CASEID, P.QTY, S.COMPANY, SK.DESCR, aSK.ALTSKU,
--					O.REQUESTEDSHIPDATE, P.FROMLOC, P.Expr1, o.externorderkey,
--					(o.C_Address1+o.C_Address2+o.C_Address3+o.C_Address4) DeliveryAdr, st1.vat clientINN,
--					case when (p.id <> '''') then ''ѕаллета'' else ''ящик'' end CaseDescr,
--					case when (p.id <> '''') then 1 else 1 end CaseType,
--					L.LOGICALLOCATION, P.STATUS, O.DOOR, P.ID, S.COMPANY AS Expr2, PK.CASECNT, O.ORDERDATE, O.CONSIGNEEKEY, st1.COMPANY AS conscomp, 
--					st1.ADDRESS1 AS consaddress, PK.SERIALKEY,ISNULL ( P.CARTONGROUP , ''PALLET'') AS sel_CARTONGROUP,
--					isnull(sk.susr4, ''шт.'') baseMeasure, sk.susr6,p.lot, p.LOTTABLE03, p.LOTTABLE05,car.COMPANY CarrierName
--				FROM  #picks AS P 
--					LEFT JOIN '+@wh+'.STORER AS S ON P.STORERKEY = S.STORERKEY 
--					LEFT JOIN '+@wh+'.SKU AS SK ON SK.STORERKEY = P.STORERKEY AND SK.SKU = P.SKU 
--					LEFT JOIN #altsku as aSK ON SK.SKU=aSK.SKU and SK.Storerkey=aSK.Storerkey
--					LEFT JOIN '+@wh+'.ORDERS AS O ON O.ORDERKEY = P.ORDERKEY 
--					LEFT JOIN '+@wh+'.PACK AS PK ON PK.PACKKEY = P.PACKKEY 
--					LEFT JOIN '+@wh+'.LOC AS L ON P.LOC = L.LOC 
--					left join '+@wh+'.STORER as car on O.CarrierCode=car.STORERKEY
--					LEFT JOIN '+@wh+'.STORER AS st1 ON st1.STORERKEY = O.CONSIGNEEKEY '
				--WHERE        (P.ORDERKEY = '''+@order+''') AND (P.STATUS < 9)'
	set @sql = 'insert #sel (ORDERKEY, STORERKEY, SKU, LOC, TRANSPORTATIONSERVICE, TRANSPORTATIONSERVICE1, CASEID, QTY, COMPANY, DESCR, ALTSKU, REQUESTEDSHIPDATE, 
					FROMLOC, Expr1, externorderkey, DeliveryAdr, clientINN,	CaseDescr,	CaseType,
					LOGICALLOCATION, STATUS,DOOR, ID, Expr2, CASECNT, ORDERDATE,CONSIGNEEKEY, conscomp, 
					consaddress,SERIALKEY,sel_CARTONGROUP,baseMeasure,susr6,lot, LOTTABLE03, LOTTABLE05,CarrierName)
				SELECT P.ORDERKEY, P.STORERKEY, P.SKU, P.LOC, O.TRANSPORTATIONSERVICE, dbo.GetEAN128(O.TRANSPORTATIONSERVICE) TRANSPORTATIONSERVICE1, P.CASEID, P.QTY, S.COMPANY, SK.DESCR, aSK.ALTSKU,
					O.REQUESTEDSHIPDATE, P.FROMLOC, P.Expr1, o.externorderkey,
					(o.C_Address1+o.C_Address2+o.C_Address3+o.C_Address4) DeliveryAdr, st1.vat clientINN,
					''ящик'' CaseDescr,
					1 CaseType,
					L.LOGICALLOCATION, P.STATUS, O.DOOR, P.ID, S.COMPANY AS Expr2, PK.CASECNT, O.ORDERDATE, O.CONSIGNEEKEY, st1.COMPANY AS conscomp, 
					st1.ADDRESS1 AS consaddress, PK.SERIALKEY,ISNULL ( P.CARTONGROUP , ''PALLET'') AS sel_CARTONGROUP,
					isnull(sk.susr4, ''шт.'') baseMeasure, sk.susr6,p.lot, p.LOTTABLE03, p.LOTTABLE05,car.COMPANY CarrierName
				FROM  #picks AS P 
					LEFT JOIN '+@wh+'.STORER AS S ON P.STORERKEY = S.STORERKEY 
					LEFT JOIN '+@wh+'.SKU AS SK ON SK.STORERKEY = P.STORERKEY AND SK.SKU = P.SKU 
					LEFT JOIN #altsku as aSK ON SK.SKU=aSK.SKU and SK.Storerkey=aSK.Storerkey
					LEFT JOIN '+@wh+'.ORDERS AS O ON O.ORDERKEY = P.ORDERKEY 
					LEFT JOIN '+@wh+'.PACK AS PK ON PK.PACKKEY = P.PACKKEY 
					LEFT JOIN '+@wh+'.LOC AS L ON P.LOC = L.LOC 
					left join '+@wh+'.STORER as car on O.CarrierCode=car.STORERKEY
					LEFT JOIN '+@wh+'.STORER AS st1 ON st1.STORERKEY = O.CONSIGNEEKEY '
print @sql
	exec(@sql)
	
	
	drop table #picks
	
--select * from #sel order by caseid
-- Dr.MoPo3ilo - Ќе забыть сказать, что из-за этого ID считалась сумма не корректно.
	select orderkey, caseid, /*id,*/ sum(qty) sumQTY, 
		sum(round(qty/case when casecnt=0 then 1 else casecnt end,2))sumCaseQTY 
	into #summary from #sel group by orderkey, caseid/*, id*/
	
	
--select * from #summary

--	select bm.* from #sel sel
--		left join wh1.billofmaterial as bm on bm.sku = sel.sku and bm.storerkey = sel.storerkey
--		left join wh1.sku sk2 on sk2.sku=bm.componentsku and sk2.storerkey = bm.storerkey
	--select * from #sel

	set @sql = '
	SELECT DISTINCT  SEL.ORDERKEY, SEL.STORERKEY, SEL.SKU, dbo.GetEAN128(SEL.SKU) bcSKU,
			SEL.LOC, l.locationtype, sel.externorderkey, '
			+' dbo.GetEAN128(case when CaseType=1 then SEL.CASEID else SEL.ID end) CASEID1, '
			+' SEL.CaseDescr,
			case when CaseType=1 then SEL.CASEID else SEL.ID end CASEID, 
			SEL.QTY, DeliveryAdr, clientINN,
			SEL.COMPANY, SEL.DESCR,SEL.ALTSKU, SEL.TRANSPORTATIONSERVICE, SEL.TRANSPORTATIONSERVICE1, SEL.REQUESTEDSHIPDATE, SEL.FROMLOC, SEL.Expr1, 
			SEL.LOGICALLOCATION, SEL.STATUS, SEL.DOOR,SEL.ID, SEL.Expr2, SEL.CASECNT, 
			SEL.ORDERDATE, SEL.CONSIGNEEKEY, SEL.conscomp, SEL.consaddress, SEL.SERIALKEY, 
			SEL.sel_CARTONGROUP, min(cart.CARTONDESCRIPTION) CARTONDESCRIPTION, sel.susr6 skuSUSR6, sel.lot,
			bm.componentsku, dbo.GetEAN128(bm.componentsku) bcComponentSKU, 
			sel.QTY*bm.qty compQTY, sk2.descr compname,
			sumQTY, sumCaseQTY, sel.baseMeasure, isnull(sk2.susr4, ''шт.'') componentBaseMeasure,
			sk2.susr6 compSKUsusr6, sel.LOTTABLE03, sel.LOTTABLE05,
			min(wav.WAVEKEY) WAVEKEY,(SEL.QTY*sk.STDCUBE) STDCUBE,SEL.CarrierName, l.logicallocation
	FROM #sel SEL
		LEFT JOIN '+@wh+'.CARTONIZATION cart ON SEL.sel_CARTONGROUP = cart.CARTONIZATIONGROUP
		left join '+@wh+'.billofmaterial as bm on bm.sku = sel.sku and bm.storerkey = sel.storerkey
		left join '+@wh+'.SKU sk on SEL.SKU=sk.SKU and sel.Storerkey=sk.storerkey
		left join '+@wh+'.sku sk2 on sk2.sku=bm.componentsku and sk2.storerkey = bm.storerkey
		left join '+@wh+'.WAVEDETAIL wav on SEL.ORDERKEY=wav.ORDERKEY
		left join #summary sm on sm.orderkey =  sel.orderkey and sm.caseid = sel.caseid 
        left join '+@wh+'.Loc l on l.loc=SEL.Expr1 '
	+' where 1=1 '
	+ case when isnull(@caseid,'')='' then '' else ' and sel.caseid = '''+@caseid+'''' end
    +' group by SEL.ORDERKEY, SEL.STORERKEY, SEL.SKU,SEL.LOC, l.locationtype, sel.externorderkey,SEL.CaseDescr, '
    +' SEL.QTY, DeliveryAdr, clientINN,'
    +'			SEL.COMPANY, SEL.DESCR, SEL.ALTSKU, SEL.TRANSPORTATIONSERVICE, SEL.TRANSPORTATIONSERVICE1, SEL.REQUESTEDSHIPDATE, SEL.FROMLOC, SEL.Expr1, 
			SEL.LOGICALLOCATION, SEL.STATUS, SEL.DOOR,SEL.ID, SEL.Expr2, SEL.CASECNT, 
			SEL.ORDERDATE, SEL.CONSIGNEEKEY, SEL.conscomp, SEL.consaddress, SEL.SERIALKEY, 
			SEL.SEL_CARTONGROUP, sel.susr6, sel.lot,
			bm.componentsku, dbo.GetEAN128(bm.componentsku), 
			bm.qty, sk2.descr,
			sumQTY, sumCaseQTY, sel.baseMeasure, sk2.susr4,sk2.susr6, sel.LOTTABLE03, sel.LOTTABLE05,
			sk.STDCUBE,SEL.CarrierName, l.logicallocation,dbo.GetEAN128(case when CaseType=1 then SEL.CASEID else SEL.ID end),
            case when CaseType=1 then SEL.CASEID else SEL.ID end'
--    +' Order by l.logicallocation  '
print @sql
	--select * from wh1.pickdetail where caseid = '0000010248'
	exec (@sql)
--select * from wh1.pickdetail where caseid = '0000003693'
--select * from #resulttable

drop table #altsku
drop table #sel
drop table #summary

