CREATE proc [rep].[mof_Transaction_with_products]
	@date_from datetime = NULL,
	@date_to datetime = NULL,
	@sku varchar(50) = NULL,
	@serial varchar(50) = NULL,
	@description varchar(200) = NULL
as
begin
	set NOCOUNT on
	
	select
		@sku = nullif(rtrim(@sku),''),
		@serial = nullif(rtrim(@serial),''),
		@description = nullif(rtrim(@description),'')
	
	declare
		@_sku varchar(50),
		@_lot varchar(10)
	
	declare @TIMELINE table (
		SERIALKEY int,
		[SOURCE] varchar(50),
		TRANTYPE varchar(10),
		SKU varchar(50),
		LOT varchar(10),
		FROMLOC varchar(10),
		FROM_LOCTYPE varchar(10),
		TR_LOT varchar(10),
		TOLOC varchar(10),
		TO_LOCTYPE varchar(10),
		QTY decimal(22,5),
		CORRECTION_QTY decimal(22,5),
		SOURCEKEY varchar(20),
		SOURCETYPE varchar(30),
		DOC_KEY varchar(10),
		DOC_LINE varchar(10),
		ADDDATE datetime,
		EDITDATE datetime,
		EDITWHO varchar(18)
	)
	
	-- проверено: курсор по конкретрым товарам работает быстрее неопределенного фильтра
	declare C cursor fast_forward read_only for
		select distinct l.SKU, l.LOT
		from wh2.LOTATTRIBUTE l
			join wh2.SKU s on s.STORERKEY = l.STORERKEY AND s.SKU = l.SKU
		where ( (@date_from is NOT NULL and @date_to is NOT NULL) or @sku is NOT NULL or @serial is NOT NULL or @description is NOT NULL )
			and ( @sku is NULL or l.SKU = @sku )
			and ( @serial is NULL or l.LOTTABLE02 = @serial )
			and ( @description is NULL or s.DESCR like '%' + replace(@description,' ','%') + '%' )
	
	open C
	
	while 1=1
	begin
		fetch from C into @_sku, @_lot
		if @@FETCH_STATUS <> 0 break
		
--select @_sku, @_lot
		
		insert into @TIMELINE
		select *
		from dbo.udf_get_lots_journal(@_sku,@_lot,@date_from,@date_to,0,0) j
		
	end
	
	close C
	deallocate C
	
	-- -- 8< -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	
	declare @PO table (
		RECEIPTKEY varchar(50),
		POKEYS varchar(500),
		EXTERNPOKEYS varchar(500)
	)
	
	declare
		@doc_key varchar(50),
		@pokeys varchar(500),
		@externpokeys varchar(500)
	
	declare C cursor fast_forward read_only for
		select distinct DOC_KEY from @TIMELINE where TRANTYPE = 'DP'
	
	open C
	
	while 1=1
	begin
		fetch from C into @doc_key
		if @@FETCH_STATUS <> 0 break
		
		set @pokeys = NULL
		set @externpokeys = NULL
		
		select
			@pokeys = isnull(@pokeys+', ','') + POKEY,
			@externpokeys = isnull(@externpokeys+', ','') + EXTERNPOKEY
		from wh2.PO
		where OTHERREFERENCE = @doc_key
		
		insert into @PO values (@doc_key,@pokeys,@externpokeys)
		
	end
	
	close C
	deallocate C
	
	
	select
		t.SERIALKEY,
		t.EDITDATE,
		isnull(td.EDITWHO,t.EDITWHO) as EDITWHO,
		case t.TRANTYPE
			when 'AJ' then 'Корректировка'
			when 'DP' then 'Вложение'
			when 'MV' then 'Перемещение'
			when 'WD' then 'Изъятие'
			when 'TR' then 'Трансфер'
		end as TRANTYPE,
		case t.TRANTYPE
			--when 'AJ' then a.ADJUSTMENTKEY
			when 'DP' then po.EXTERNPOKEYS
			--when 'MV' then t.ORDERKEY
			when 'WD' then o.EXTERNORDERKEY
			--when 'TR' then ?
			else NULL
		end as DOC_EXTERNKEY,
		case when t.TRANTYPE = 'DP' then po.POKEYS else t.DOC_KEY end as DOC_KEY,
		t.DOC_LINE,
		s.SKU,
		s.DESCR,
		isnull(nullif(l.LOTTABLE02,''),'б/с') as SERIAL,
		l.LOTTABLE05 as EXP_DATE,
		t.QTY,
		t.QTY + t.CORRECTION_QTY as ACCEPTED_QTY,
		t.FROMLOC, t.TOLOC,
		td.CASEID as DROPID,
		td.CASEID
	into #TRANSACTIONS
	from @TIMELINE t
		join wh2.LOTATTRIBUTE l on l.LOT = t.LOT
		join wh2.SKU s on s.STORERKEY = l.STORERKEY and s.SKU = l.SKU
		left join wh2.ADJUSTMENT a on t.TRANTYPE = 'AJ' and t.DOC_KEY = a.ADJUSTMENTKEY
--		left join wh2.RECEIPT r on t.TRANTYPE = 'DP' and t.DOC_KEY = r.RECEIPTKEY
		left join @PO po on t.TRANTYPE = 'DP' and po.RECEIPTKEY = t.DOC_KEY
--		left join wh2.TASKDETAIL t on t.TRANTYPE = 'MV' and t.SOURCEKEY = i.SOURCEKEY and i.SOURCEKEY > ''
		left join wh2.ORDERS o on t.TRANTYPE = 'WD' and t.DOC_KEY = o.ORDERKEY
		left join wh2.PICKDETAIL p
			left join wh2.TASKDETAIL td on td.PICKDETAILKEY = p.PICKDETAILKEY and td.LOT = p.LOT and td.CASEID = p.CASEID
		on t.TRANTYPE = 'WD' and p.ORDERKEY = t.DOC_KEY and p.ORDERLINENUMBER = t.DOC_LINE
	
	
	;with tree (DROPID, CHILDID, THREAD, LEVEL) as (
		select d.DROPID, d.CHILDID, d.CHILDID, 1
		from #TRANSACTIONS t
			join wh2.DROPIDDETAIL d on d.CHILDID = t.CASEID
		union all
		select d.DROPID, d.CHILDID, t.THREAD, t.LEVEL + 1
		from wh2.DROPIDDETAIL d
			join tree t on d.CHILDID = t.DROPID
	)
	update t set
		DROPID = x.DROPID
	from #TRANSACTIONS t
		join (select THREAD as CASEID, DROPID, row_number() over (partition by THREAD order by LEVEL desc) as RN from tree) x on x.CASEID = t.CASEID
	where x.RN = 1
	
	--select distinct * from #TRANSACTIONS order by EDITDATE
	select distinct
		SERIALKEY, EDITDATE, EDITWHO,
		TRANTYPE, DOC_EXTERNKEY, DOC_KEY, DOC_LINE,
		SKU, DESCR, SERIAL, EXP_DATE,
		sum(QTY) as QTY, nullif(sum(ACCEPTED_QTY),0) as ACCEPTED_QTY,
		FROMLOC, TOLOC,
		DROPID, CASEID
	from #TRANSACTIONS
	group by
		SERIALKEY, EDITDATE, EDITWHO,
		TRANTYPE, DOC_EXTERNKEY, DOC_KEY, DOC_LINE,
		SKU, DESCR, SERIAL, EXP_DATE,
		FROMLOC, TOLOC,
		DROPID, CASEID
	having sum(QTY) <> 0 or sum(ACCEPTED_QTY) <> 0
	order by EDITDATE
end


