CREATE proc dbo.rep_buys_and_sells
	@date_from datetime = NULL,
	@date_to datetime = NULL,
	@description varchar(200) = NULL,
	@area varchar(50) = NULL
as
begin
	set NOCOUNT on
	
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
	
	declare
		@_sku varchar(50),
		@_lot varchar(10),
		@only_buys bit = 1,
		@only_sells bit = 1
	
	if @area = 'sell' select @only_buys = 0
	if @area = 'buy' select @only_sells = 0
	
	set @description = nullif(rtrim(@description),'')
	
	if @description is NULL
		insert into @TIMELINE
		select *
		from dbo.udf_get_lots_journal(NULL,NULL,@date_from,@date_to,@only_buys,@only_sells) j
	else
	begin
		-- проверено: курсор по конкретрым товарам работает быстрее неопределенного фильтра
		declare C cursor fast_forward read_only for
			select distinct l.SKU, l.LOT
			from wh1.LOTATTRIBUTE l
				join wh1.SKU s on s.STORERKEY = l.STORERKEY AND s.SKU = l.SKU
			where s.DESCR like '%' + replace(@description,' ','%') + '%'
		
		open C
		
		while 1=1
		begin
			fetch from C into @_sku, @_lot
			if @@FETCH_STATUS <> 0 break
			
			insert into @TIMELINE
			select *
			from dbo.udf_get_lots_journal(@_sku,@_lot,@date_from,@date_to,@only_buys,@only_sells) j
			
		end
		
		close C
		deallocate C
		
	end
	
	select
		t.SERIALKEY,
		case t.TRANTYPE
			when 'DP' then 'Закупка'
			when 'WD' then 'Продажа'
			else t.TRANTYPE
		end as TRANTYPE,
		dateadd(month,(year(t.EDITDATE) - 1900) * 12 + datepart(month,t.EDITDATE) - 1,0) as EDITDATE,
		year(t.EDITDATE) as EDITYEAR,
		case month(t.EDITDATE)
			when 1 then 'Январь'
			when 2 then 'Февраль'
			when 3 then 'Март'
			when 4 then 'Апрель'
			when 5 then 'Май'
			when 6 then 'Июнь'
			when 7 then 'Июль'
			when 8 then 'Август'
			when 9 then 'Сентябрь'
			when 10 then 'Октябрь'
			when 11 then 'Ноябрь'
			when 12 then 'Декабрь'
		end as EDITMONTH,
		s.SKU,
		s.DESCR,
		isnull(nullif(l.LOTTABLE02,''),'б/с') as SERIAL,
		l.LOTTABLE05 as EXP_DATE,
		t.QTY + t.CORRECTION_QTY as ACCEPTED_QTY
	into #TRANSACTIONS
	from @TIMELINE t
		join wh1.LOTATTRIBUTE l on l.LOT = t.LOT
		join wh1.SKU s on s.STORERKEY = l.STORERKEY and s.SKU = l.SKU
	
	select * from #TRANSACTIONS order by EDITDATE
	--select distinct
	--	SERIALKEY, EDITDATE, EDITWHO,
	--	TRANTYPE, DOC_EXTERNKEY, DOC_KEY, DOC_LINE,
	--	SKU, DESCR, SERIAL, EXP_DATE,
	--	sum(QTY) as QTY, nullif(sum(ACCEPTED_QTY),0) as ACCEPTED_QTY,
	--	FROMLOC, TOLOC,
	--	DROPID, CASEID
	--from #TRANSACTIONS
	--group by
	--	SERIALKEY, EDITDATE, EDITWHO,
	--	TRANTYPE, DOC_EXTERNKEY, DOC_KEY, DOC_LINE,
	--	SKU, DESCR, SERIAL, EXP_DATE,
	--	FROMLOC, TOLOC,
	--	DROPID, CASEID
	--having sum(QTY) <> 0 or sum(ACCEPTED_QTY) <> 0
	--order by EDITDATE
end

