CREATE proc [rep].[Sku_movement2]
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
	
	if @date_to is NOT NULL and @date_to = cast(round(cast(@date_to as real), 0, 1) as datetime)
		set @date_to = @date_to + 1
	
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
		from wh1.LOTATTRIBUTE l
			join wh1.SKU s on s.STORERKEY = l.STORERKEY AND s.SKU = l.SKU
		where ( (@date_from is NOT NULL and @date_to is NOT NULL) or @sku is NOT NULL or @serial is NOT NULL or @description is NOT NULL )
			and ( @sku is NULL or l.SKU = @sku )
			and ( @serial is NULL or l.LOTTABLE02 = @serial )
			and ( @description is NULL or s.DESCR like '%' + replace(@description,' ','%') + '%' )
	
	open C
	
	while 1=1
	begin
		fetch from C into @_sku, @_lot
		if @@FETCH_STATUS <> 0 break
		
		insert into @TIMELINE
		select *
		from dbo.udf_get_lots_journal(@_sku,@_lot,NULL,NULL,0,0) j
		
	end
	
	close C
	deallocate C
	
	
	select
		f.SKU,
		s.DESCR,
		f.LOTTABLE02 as SERIAL,
		f.LOTTABLE05 as EXP_DATE,
		t.ACCEPTED_QTY,
		--sum(isnull(t.QTY+t.CORRECTION_QTY,0)) as ACCEPTED_QTY,
		f.FULL_QTY,
		--sum(f.QTY+f.CORRECTION_QTY) as FULL_QTY,
		l.STOCK_QTY
		--sum(l.QTY) as STOCK_QTY
	from (
		select
			t.SKU,
			la.STORERKEY,
			la.LOTTABLE02,
			la.LOTTABLE05,
			sum(QTY+CORRECTION_QTY) as FULL_QTY
		from @TIMELINE t
			join wh1.LOTATTRIBUTE la on la.LOT = t.LOT
		group by
			t.SKU,
			la.STORERKEY,
			la.LOTTABLE02,
			la.LOTTABLE05
	) f
		left join (
			select
				t.SKU,
				la.STORERKEY,
				la.LOTTABLE02,
				la.LOTTABLE05,
				sum(QTY+CORRECTION_QTY) as ACCEPTED_QTY
			from @TIMELINE t
				join wh1.LOTATTRIBUTE la on la.LOT = t.LOT
			where @date_to is NULL or t.EDITDATE <= @date_to
			group by
				t.SKU,
				la.STORERKEY,
				la.LOTTABLE02,
				la.LOTTABLE05
		) t on t.SKU = f.SKU
			and t.STORERKEY = f.STORERKEY
			and ( t.LOTTABLE02 = f.LOTTABLE02 or t.LOTTABLE02 is NULL and f.LOTTABLE02 is NULL )
			and ( t.LOTTABLE05 = f.LOTTABLE05 or t.LOTTABLE05 is NULL and f.LOTTABLE05 is NULL )
		left join (
			select
				la.SKU,
				la.STORERKEY,
				la.LOTTABLE02,
				la.LOTTABLE05,
				sum(l.QTY) as STOCK_QTY
			from wh1.LOT l
				join wh1.LOTATTRIBUTE la on la.LOT = l.LOT
			group by
				la.SKU,
				la.STORERKEY,
				la.LOTTABLE02,
				la.LOTTABLE05
		) l on l.SKU = f.SKU
			and l.STORERKEY = f.STORERKEY
			and ( l.LOTTABLE02 = f.LOTTABLE02 or l.LOTTABLE02 is NULL and f.LOTTABLE02 is NULL )
			and ( l.LOTTABLE05 = f.LOTTABLE05 or l.LOTTABLE05 is NULL and f.LOTTABLE05 is NULL )
		join wh1.SKU s on s.STORERKEY = f.STORERKEY and s.SKU = f.SKU
	
end

