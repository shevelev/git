ALTER PROCEDURE [rep].[mof_Act_receipt_ASN1] (
/* 01 ��� ������� (���) */
	@wh varchar(30),
	@asn varchar(15),
	@nav varchar(15),
	@receipttype varchar(10)=null
)
--with encryption
as


--declare @wh varchar(30),
--	@asn varchar(15)
--	select @wh='wh2', @asn='0000011341'

--	set @wh = upper(@wh)
--	set @asn= replace(upper(@asn),';','')  -- ������� ; �� ����� ��� ���������� ������������.
--select * from wh2.receipt where type = 20 detail
	declare @sql varchar(max)
    declare @str_proc varchar(1)

IF @asn<>'(�����)' or @nav<>'(�����)'
BEGIN

	if @asn='(�����)' set @asn='%'
	if @nav='(�����)' set @nav='%'

	-- KSV 
    set @str_proc = '%'
    set @asn = @str_proc + @asn
    -- KSV END

	SELECT identity(int,1,1) id, s.SUSR10 SUSR10, min(R.STATUS) STATUS, R.RECEIPTKEY, dbo.getean128(R.RECEIPTKEY) bcRECEIPKEY, RD.STORERKEY,
		r.externreceiptkey, dbo.getean128(r.externreceiptkey)bcexternreceiptkey,
		dbo.getean128(RD.STORERKEY) bcSTORERKEY, ST.COMPANY, max(R.RECEIPTDATE)RECEIPTDATE, 
		RD.SKU, S.DESCR, mf.COMPANY as MANUFACTURER, RD.PACKKEY, PK.CASECNT, PK.PALLET, 
		SUM(RD.QTYEXPECTED) AS QTYEXPECTED, SUM(RD.QTYRECEIVED) AS QTYRECEIVED, (SUM(RD.QTYEXPECTED)*S.STDCUBE) AS SCUBE,
		0 AS Expr1, R.CARRIERNAME, R.CARRIERKEY, 
		R.SUSR1, cast(case when rd.lottable07='STD' then '' else rd.lottable07 end as varchar(20)) lottable07,		
		R.WAREHOUSEREFERENCE,
		rtrim(ltrim(substring(whpas.descr, charindex(':', whpas.descr)+1, len(whpas.descr) - charindex(':', whpas.descr)))) as angar,
		cast(isnull(s.susr4,'') as varchar(10)) baseMeasure, r.type, 
		case when rd.lottable08='STD' then '' else rd.lottable08 end lottable08,
		dbo.getean128(case when rd.lottable08='STD' then '' else rd.lottable08 end) bclottable08,
		R.POKEY, '                                                                                                    ' ER2
	into #asn
	from wh2.RECEIPTDETAIL as RD 
		join wh2.PACK as PK on PK.PACKKEY = RD.PACKKEY 
		join wh2.RECEIPT as R on R.RECEIPTKEY = RD.RECEIPTKEY 
		join wh2.SKU as S
			left join wh2.STORER mf on s.BUSR1 = mf.STORERKEY -- manufacturer
		on RD.SKU = S.SKU and RD.STORERKEY = S.STORERKEY 
		join wh2.STORER as ST on ST.STORERKEY = RD.STORERKEY 
		left join wh2.PUTAWAYSTRATEGY as whpas on whpas.PUTAWAYSTRATEGYKEY = s.PUTAWAYSTRATEGYKEY
	where 1 = 2
	group by s.SUSR10, RD.SKU, RD.PACKKEY, RD.STORERKEY, 
		R.RECEIPTKEY, S.DESCR, mf.COMPANY, PK.CASECNT, PK.PALLET, ST.COMPANY,  
		R.CARRIERNAME, R.CARRIERKEY, R.SUSR1, R.WAREHOUSEREFERENCE, 
		case when rd.lottable07='STD' then '' else rd.lottable07 end, 
		r.externreceiptkey,s.susr4, r.type, case when rd.lottable08='STD' then '' else rd.lottable08 end,R.POKEY,
		rtrim(ltrim(substring(whpas.descr, charindex(':', whpas.descr)+1, len(whpas.descr) - charindex(':', whpas.descr)))),S.STDCUBE


	set @sql = 'insert into #ASN (
			SUSR10 ,STATUS, RECEIPTKEY, bcRECEIPKEY, STORERKEY,	externreceiptkey, bcexternreceiptkey,
			bcSTORERKEY, COMPANY, RECEIPTDATE, 	SKU, DESCR, MANUFACTURER, PACKKEY, CASECNT, PALLET, 
			QTYEXPECTED, QTYRECEIVED, SCUBE, Expr1, CARRIERNAME, CARRIERKEY, SUSR1, lottable07,		
			WAREHOUSEREFERENCE,	angar, baseMeasure, type, lottable08,bclottable08,POKEY, ER2)
		SELECT s.SUSR10, min(R.STATUS) STATUS, R.RECEIPTKEY, dbo.getean128(R.RECEIPTKEY) bcRECEIPKEY, RD.STORERKEY,
			r.externreceiptkey, dbo.getean128(r.externreceiptkey)bcexternreceiptkey,
			dbo.getean128(RD.STORERKEY) bcSTORERKEY, ST.COMPANY, max(R.RECEIPTDATE)RECEIPTDATE,
			RD.SKU, S.DESCR, mf.COMPANY as MANUFACTURER, pk.PACKKEY, PK.CASECNT, PK.PALLET, 
			SUM(RD.QTYEXPECTED) AS QTYEXPECTED, SUM(RD.QTYRECEIVED) AS QTYRECEIVED, (SUM(RD.QTYEXPECTED)*S.STDCUBE) AS SCUBE, 
			0 AS Expr1, R.CARRIERNAME, R.CARRIERKEY, 
			R.SUSR1, case when rd.lottable07=''STD'' then '''' else rd.lottable07 end lottable07,		
			R.WAREHOUSEREFERENCE,
			rtrim(ltrim(substring(whpas.descr, charindex('':'', whpas.descr)+1, len(whpas.descr) - charindex('':'', whpas.descr)))) as angar,
			isnull(s.susr4,''��.'') baseMeasure, r.type, 
			case when rd.lottable08=''STD'' then '''' else rd.lottable08 end,
			dbo.getean128(case when rd.lottable08=''STD'' then '''' else rd.lottable08 end),R.POKEY, '''' ER2
		FROM wh2.RECEIPTDETAIL AS RD 
			JOIN wh2.RECEIPT AS R ON R.RECEIPTKEY = RD.RECEIPTKEY 
			JOIN wh2.SKU AS S
				left join wh2.STORER mf on s.BUSR1 = mf.STORERKEY
			ON RD.SKU = S.SKU AND RD.STORERKEY = S.STORERKEY 
			JOIN wh2.PACK AS PK ON PK.PACKKEY = s.PACKKEY 
			JOIN wh2.STORER AS ST ON ST.STORERKEY = RD.STORERKEY 			
			LEFT JOIN wh2.PUTAWAYSTRATEGY as whpas on whpas.PUTAWAYSTRATEGYKEY = s.PUTAWAYSTRATEGYKEY
		WHERE  (RD.RECEIPTKEY like ''' + @asn+''') and (r.externreceiptkey like '''+@nav+''') '+
		case when isnull(@receipttype,'')='' then '' else 'and R.[TYPE]='''+@receipttype+''' ' end+
		'GROUP BY s.SUSR10, RD.SKU,  RD.STORERKEY, pk.PACKKEY,
			R.RECEIPTKEY, S.DESCR, mf.COMPANY, PK.CASECNT, PK.PALLET, ST.COMPANY,  
			R.CARRIERNAME, R.CARRIERKEY, R.SUSR1, R.WAREHOUSEREFERENCE, 
			case when rd.lottable07=''STD'' then '''' else rd.lottable07 end, 
			r.externreceiptkey,s.susr4, r.type, case when rd.lottable08=''STD'' then '''' else rd.lottable08 end,R.POKEY,
			rtrim(ltrim(substring(whpas.descr, charindex('':'', whpas.descr)+1, len(whpas.descr) - charindex('':'', whpas.descr)))),S.STDCUBE'
	--print @sql --
	exec (@sql)
	
--	create table #SKUERR(STORERKEY varchar(15) COLLATE Cyrillic_General_CI_AS,PUTAWAYZONE varchar(10) COLLATE Cyrillic_General_CI_AS, SKU varchar(50) COLLATE Cyrillic_General_CI_AS,ERR varchar(max) COLLATE Cyrillic_General_CI_AS)
--	exec ('insert into #SKUERR select STORERKEY, SKU,'''' ERR from wh2.SKU')
--	exec ('insert into #SKUERR select s.STORERKEY, s.putawayzone, s.SKU, '''' ERR from wh2.SKU s right join #ASN
--			on (s.storerkey=#ASN.storerkey and s.sku=#ASN.sku)')

--	exec ('insert into #SKUERR select distinct SKU,'''' ERR from wh2.SKU')


	--set @sql='
	--update #asn
	--set ER2=ER2+''����� �����;''
	--from #asn join ' + @wh+'.sku s  
	--	on (#asn.storerkey=s.storerkey and #asn.sku=s.sku)
	--where s.adddate = s.editdate'
	--exec(@sql)

	set @sql='
	update #asn
	set ER2=ER2+''��� ���� ������; ''
	from #asn join ' + @wh+'.sku s  
		on (#asn.storerkey=s.storerkey and #asn.sku=s.sku)
	where s.STDGROSSWGT=0
	'

	exec(@sql)
	set @sql='
	update #asn
	set ER2=ER2+''�� ������ ����� ������; ''
	
	from #asn join ' + @wh+'.sku s  
		on (#asn.storerkey=s.storerkey and #asn.sku=s.sku)
	where s.STDCUBE=0
	'
	exec(@sql)

set @sql='
	update #asn
	set ER2=ER2+''��� ������ ������; ''

	from #asn join ' + @wh+'.sku s  
		on (#asn.storerkey=s.storerkey and #asn.sku=s.sku)
	where (s.SKUGROUP=''STD'' AND SKUGROUP='''')
	'
	exec(@sql)

--set @sql='
--	update #asn
--	set ER2=ER2+''��� ��������� ��������������; ''

--	from #asn join ' + @wh+'.sku s  
--		on (#asn.storerkey=s.storerkey and #asn.sku=s.sku)
--	where (s.STRATEGYKEY=''STD'')
--	'
--	exec(@sql)

set @sql='
	update #asn
	set ER2=ER2+''��� ���� ����������; ''

	from #asn join ' + @wh+'.sku s  
		on (#asn.storerkey=s.storerkey and #asn.sku=s.sku)
	where (s.PUTAWAYZONE=''RACK'')
	'
	exec(@sql)

set @sql='
	update #asn
	set ER2=ER2+''��� ��������� ����������; ''

	from #asn join ' + @wh+'.sku s  
		on (#asn.storerkey=s.storerkey and #asn.sku=s.sku)
	where (s.PUTAWAYSTRATEGYKEY=''STD'')
	'
	exec(@sql)

--set @sql='
--	update #asn
--	set ER2=ER2+''��� ��������; ''

--	from #asn join ' + @wh+'.sku s  
--		on (#asn.storerkey=s.storerkey and #asn.sku=s.sku)
--	where (s.PACKKEY=''STD'')
--	'
--	exec(@sql)

--set @sql='
--	update #SKUERR
--	set ERR=ERR+''��� RFDEFAULTPACK; ''

--	from #SKUERR join ' + @wh+'.sku s  
--		on (#SKUERR.storerkey=s.storerkey and #SKUERR.sku=s.sku)
--	where (s.RFDEFAULTPACK=''STD'')
--	'
--	exec(@sql)

--set @sql='
--	update #SKUERR
--	set ERR=ERR+''��� ������ �������������; ''

--	from #SKUERR join ' + @wh+'.sku s  
--		on (#SKUERR.storerkey=s.storerkey and #SKUERR.sku=s.sku)
--	where (s.CARTONGROUP=''STD'')
--	'
--	exec(@sql)

set @sql='
	update #asn
	set ER2=ER2+''��� �����-����; ''
	from #asn left join ' + @wh+'.altsku alt  
		on (#asn.storerkey=alt.storerkey and #asn.sku=alt.sku)
	where (alt.altsku is null)
	'
exec(@sql)
	
	
--set @sql='
--	update #asn
--	set ER2=ER2+''��� ������ �����-����� ������� ������ ��������; ''
--	from 
--	#asn join ' + @wh+'.sku s on (#asn.storerkey=s.storerkey and #asn.sku=s.sku)
--			join ' + @wh+'.altsku alt on (#asn.storerkey=alt.storerkey and #asn.sku=alt.sku)
--	where alt.packkey<>s.packkey
--	'
--	exec(@sql)

set @sql='
update #asn
	set ER2=ER2+''�� ��������� ������ ������; ''
	from #asn
	where wh2.novex_checkNeedSetPickLoc(storerkey,sku)>0'
exec(@sql)

	
	select receiptkey, sum(qtyreceived) sumReceived, 
		sum(qtyreceived/case when CASECNT=0 then 1 else CASECNT end) sumCaseReceived into #summary from #asn group by receiptkey
	
	select asn.*, bm.componentsku, asn.QTYEXPECTED*bm.qty compQTY, sk2.descr compname,
			sumCaseReceived, sumReceived, isnull(sk2.susr4,'��.') componentBaseMeasure,
			len(isnull(st.SUSR3,'''')) LENSUSR, dbo.GetEAN128(asn.sku) EANSKU
		from #asn asn
			left join wh2.billofmaterial as bm on bm.sku = asn.sku and bm.storerkey = asn.storerkey
			left join wh2.sku sk2 on sk2.sku=bm.componentsku and sk2.storerkey = bm.storerkey
			left join #summary sm on sm.receiptkey = asn.receiptkey
			left join wh2.STORER st on asn.STORERKEY=st.STORERKEY
		--where asn.qtyexpected <> 0
	
	
	drop table #asn
	drop table #summary

--whpas.descr
--(SELECT COMPANY FROM  wh2.STORER WHERE      (STORERKEY = ''NORD'')) AS SLK, 


END


