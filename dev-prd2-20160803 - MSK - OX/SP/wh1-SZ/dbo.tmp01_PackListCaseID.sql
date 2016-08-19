ALTER PROCEDURE [dbo].[tmp01_PackListCaseID] (
/* 06 ”паковочный лист на €щик */
	@wh varchar(30),
	@order varchar(10)
)
--with encryption
as

--declare
--	@wh varchar(30),
--	@order varchar(10)
--select @wh = 'Wh40', @order='0000000901'


		declare
			@sql varchar (max)

	SELECT P.ORDERKEY, P.STORERKEY, P.SKU, P.LOC, P.CASEID, P.QTY, S.COMPANY, SK.DESCR, 
			O.REQUESTEDSHIPDATE, P.FROMLOC, P.LOC AS Expr1, o.externorderkey,
			o.DeliveryAdr, st1.vat clientINN,
			cast(case when (p.id <> '') then 'ѕаллета' else 'ящик' end as varchar(15)) CaseDescr,
			case when (p.id <> '') then 0 else 1 end CaseType,
			L.LOGICALLOCATION, P.STATUS, O.DOOR, P.ID, S.COMPANY AS Expr2, PK.CASECNT, 
			O.ORDERDATE, O.CONSIGNEEKEY, st1.COMPANY AS conscomp, 
			st1.ADDRESS1 AS consaddress, PK.SERIALKEY, 
			cast(ISNULL ( CARTONTYPE , 'PALLET') as varchar(20)) AS CARTONTYPE,
			cast(isnull(sk.susr4, 'шт.') as varchar(20)) baseMeasure, sk.susr6
	into #Sel
	FROM wh40.PICKDETAIL AS P 
		LEFT JOIN wh40.STORER AS S ON P.STORERKEY = S.STORERKEY 
		LEFT JOIN wh40.SKU AS SK ON SK.STORERKEY = P.STORERKEY AND SK.SKU = P.SKU 
		LEFT JOIN wh40.ORDERS AS O ON O.ORDERKEY = P.ORDERKEY 
		LEFT JOIN wh40.PACK AS PK ON PK.PACKKEY = P.PACKKEY 
		LEFT JOIN wh40.LOC AS L ON P.LOC = L.LOC 
		LEFT JOIN wh40.STORER AS st1 ON st1.STORERKEY = O.CONSIGNEEKEY
	WHERE 1=2
--select * from wh40.pickdetail where orderkey = '0000000935'
	set @sql = 'insert #sel (ORDERKEY, STORERKEY, SKU, LOC, CASEID, QTY, COMPANY, DESCR, REQUESTEDSHIPDATE, 
					FROMLOC, Expr1, externorderkey, DeliveryAdr, clientINN,	CaseDescr,	CaseType,
					LOGICALLOCATION, STATUS,DOOR, ID, Expr2, CASECNT, ORDERDATE,CONSIGNEEKEY, conscomp, 
					consaddress,SERIALKEY,CARTONTYPE,baseMeasure,susr6)
				SELECT P.ORDERKEY, P.STORERKEY, P.SKU, P.LOC, P.CASEID, P.QTY, S.COMPANY, SK.DESCR, 
					O.REQUESTEDSHIPDATE, P.FROMLOC, P.LOC AS Expr1, o.externorderkey,
					o.DeliveryAdr, st1.vat clientINN,
					case when (p.id <> '''') then ''ѕаллета'' else ''ящик'' end CaseDescr,
					case when (p.id <> '''') then 0 else 1 end CaseType,
					L.LOGICALLOCATION, P.STATUS, O.DOOR, P.ID, S.COMPANY AS Expr2, PK.CASECNT, O.ORDERDATE, O.CONSIGNEEKEY, st1.COMPANY AS conscomp, 
					st1.ADDRESS1 AS consaddress, PK.SERIALKEY,ISNULL ( CARTONTYPE , ''PALLET'') AS CARTONTYPE,
					isnull(sk.susr4, ''шт.'') baseMeasure, sk.susr6
				FROM  '+@wh+'.PICKDETAIL AS P 
					LEFT JOIN '+@wh+'.STORER AS S ON P.STORERKEY = S.STORERKEY 
					LEFT JOIN '+@wh+'.SKU AS SK ON SK.STORERKEY = P.STORERKEY AND SK.SKU = P.SKU 
					LEFT JOIN '+@wh+'.ORDERS AS O ON O.ORDERKEY = P.ORDERKEY 
					LEFT JOIN '+@wh+'.PACK AS PK ON PK.PACKKEY = P.PACKKEY 
					LEFT JOIN '+@wh+'.LOC AS L ON P.LOC = L.LOC 
					LEFT JOIN '+@wh+'.STORER AS st1 ON st1.STORERKEY = O.CONSIGNEEKEY
				WHERE        (P.ORDERKEY = '''+@order+''') AND (P.STATUS < 5)'
print @sql
	exec(@sql)
--select * from #sel order by caseid
	select orderkey, caseid, id, sum(qty) sumQTY, 
		sum(ceiling(qty/case when casecnt=0 then 1 else casecnt end))sumCaseQTY 
	into #summary from #sel group by orderkey, caseid, id
	
	
--select * from #summary

--	select bm.* from #sel sel
--		left join wh40.billofmaterial as bm on bm.sku = sel.sku and bm.storerkey = sel.storerkey
--		left join wh40.sku sk2 on sk2.sku=bm.componentsku and sk2.storerkey = bm.storerkey
	--select * from #sel

	set @sql = '
	SELECT DISTINCT  SEL.ORDERKEY, SEL.STORERKEY, SEL.SKU, dbo.GetEAN128(SEL.SKU) bcSKU,
			SEL.LOC, sel.externorderkey,  dbo.GetEAN128(SEL.CASEID) CASEID1, '
			--+' dbo.GetEAN128(case when CaseType=1 then SEL.CASEID else SEL.ID end) CASEID1, '
			+' SEL.CaseDescr,
			case when CaseType=1 then SEL.CASEID else SEL.ID end CASEID, 
			SEL.QTY, DeliveryAdr, clientINN,
			SEL.COMPANY, SEL.DESCR, SEL.REQUESTEDSHIPDATE, SEL.FROMLOC, SEL.Expr1, 
			SEL.LOGICALLOCATION, SEL.STATUS, SEL.DOOR,SEL.ID, SEL.Expr2, SEL.CASECNT, 
			SEL.ORDERDATE, SEL.CONSIGNEEKEY, SEL.conscomp, SEL.consaddress, SEL.SERIALKEY, 
			SEL.CARTONTYPE, cart.CARTONDESCRIPTION, sel.susr6 skuSUSR6,
			bm.componentsku, dbo.GetEAN128(bm.componentsku) bcComponentSKU, 
			sel.QTY*bm.qty compQTY, sk2.descr compname,
			sumQTY, sumCaseQTY, sel.baseMeasure, isnull(sk2.susr4, ''шт.'') componentBaseMeasure,
			sk2.susr6 compSKUsusr6
	FROM #sel SEL
		LEFT JOIN '+@wh+'.CARTONIZATION cart ON SEL.CARTONTYPE = cart.CARTONTYPE
		left join '+@wh+'.billofmaterial as bm on bm.sku = sel.sku and bm.storerkey = sel.storerkey
		left join '+@wh+'.sku sk2 on sk2.sku=bm.componentsku and sk2.storerkey = bm.storerkey
		left join #summary sm on sm.orderkey =  sel.orderkey and sm.caseid = sel.caseid and sm.id=sel.id'
--print @sql
	
	exec (@sql)

--select * from #resulttable
drop table #sel
drop table #summary

