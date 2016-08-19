/*
@only_buys,@only_sells:
0,0 = без фильтра
0,1 = только продажи
1,0 = только закупки
1,1 = только закупки и продажи
*/
ALTER FUNCTION dbo.udf_get_lots_journal(
	@sku varchar(50),
	@lot varchar(50),
	@date_from datetime,
	@date_to datetime,
	@only_buys bit,
	@only_sells bit
)
returns @TIMELINE table (
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
as
begin
	
	set @sku = nullif(rtrim(@sku),'')
	set @lot = nullif(rtrim(@lot),'')
	if @lot is NOT NULL select @sku = SKU from wh1.LOT where LOT = @lot
	
--	if @sku is NOT NULL or @lot is NOT NULL or @date_from is NOT NULL or @date_to is NOT NULL
	insert into @TIMELINE
	-- Приход/расход
	select
		i.SERIALKEY, 'ITRN' as [SOURCE],
		i.TRANTYPE, i.SKU, isnull(nullif(i.LOT,''),l.LOT) as LOT,
		i.FROMLOC,fl.LOCATIONTYPE as FROM_LOCTYPE,
		l.LOT as TR_LOT,
		i.TOLOC,tl.LOCATIONTYPE as TO_LOCTYPE,
		i.QTY,
		case when ( isnull(fl.LOCATIONTYPE,'') not in ('','PICKTO') and tl.LOCATIONTYPE not in ('STAGED','PICK') )
				or tr.SERIALKEY is NOT NULL -- если есть Трансфер, эту запись аннулируем
				--or ( i.FROMLOC in ('') and i.TOLOC in ('LOST') ) -- движуха по LOST'у не интересует(?)
			then - i.QTY
			else 0
		end as CORRECTION_QTY,
		i.SOURCEKEY,i.SOURCETYPE,
		coalesce(a.ADJUSTMENTKEY,r.RECEIPTKEY/*,t.ORDERKEY*/,o.ORDERKEY) as DOC_KEY,
		coalesce(a.ADJUSTMENTLINENUMBER,r.RECEIPTLINENUMBER/*,t.ORDERLINENUMBER*/,o.ORDERLINENUMBER) as DOC_LINE,
		i.ADDDATE, i.EDITDATE, i.EDITWHO
--, i.*
--, tr.*
--, a.*
	from wh1.ITRN i
		left join wh1.LOC fl on fl.LOC = i.FROMLOC
		left join wh1.LOC tl on tl.LOC = i.TOLOC
		left join wh1.ADJUSTMENTDETAIL a on i.TRANTYPE = 'AJ' and i.TOLOC not in ('LOST') and substring(i.SOURCEKEY,1,10) = a.ADJUSTMENTKEY and substring(i.SOURCEKEY,11,5) = a.ADJUSTMENTLINENUMBER
		left join wh1.RECEIPTDETAIL r on i.TRANTYPE = 'DP' and i.TOLOC not in ('LOST') and substring(i.SOURCEKEY,1,10) = r.RECEIPTKEY and substring(i.SOURCEKEY,11,5) = r.RECEIPTLINENUMBER
--		left join wh1.TASKDETAIL t on i.TRANTYPE = 'MV' and i.TOLOC not in ('LOST') and t.SOURCEKEY = i.SOURCEKEY and i.SOURCEKEY > ''
		left join wh1.ORDERDETAIL o on i.TRANTYPE = 'WD' and i.TOLOC not in ('LOST') and substring(i.SOURCEKEY,1,10) = o.ORDERKEY and substring(i.SOURCEKEY,11,5) = o.ORDERLINENUMBER
		left join wh1.LOTATTRIBUTE l on l.SKU = i.SKU
			and ( l.LOTTABLE01 = i.LOTTABLE01 or l.LOTTABLE01 is NULL and i.LOTTABLE01 is NULL ) -- упаковка
			and ( l.LOTTABLE02 = i.LOTTABLE02 or l.LOTTABLE02 is NULL and i.LOTTABLE02 is NULL ) -- серия Аналит
			and ( l.LOTTABLE03 = i.LOTTABLE03 or l.LOTTABLE03 is NULL and i.LOTTABLE03 is NULL ) -- наличие сертификата
			and ( l.LOTTABLE04 = i.LOTTABLE04 or l.LOTTABLE04 is NULL and i.LOTTABLE04 is NULL ) -- дата производства
			and ( l.LOTTABLE05 = i.LOTTABLE05 or l.LOTTABLE05 is NULL and i.LOTTABLE05 is NULL ) -- срок годности
			and ( l.LOTTABLE06 = i.LOTTABLE06 or l.LOTTABLE06 is NULL and i.LOTTABLE06 is NULL ) -- <не используется>
			and ( l.LOTTABLE07 = i.LOTTABLE07 or l.LOTTABLE07 is NULL and i.LOTTABLE07 is NULL ) -- признак брака
			and ( l.LOTTABLE08 = i.LOTTABLE08 or l.LOTTABLE08 is NULL and i.LOTTABLE08 is NULL ) -- признак запрета ФСН
		left join wh1.TRANSFERDETAIL tr
			left join wh1.LOC tfl on tfl.LOC = tr.FROMLOC
			left join wh1.LOC ttl on ttl.LOC = tr.TOLOC
		on @only_buys = 0 and @only_sells = 0
			and i.SOURCETYPE in ('ntrTransferDetailAdd')
			and substring(i.SOURCEKEY,1,10) = tr.TRANSFERKEY
			and substring(i.SOURCEKEY,11,5) = tr.TRANSFERLINENUMBER
			and ( tr.FROMLOC <> tr.TOLOC -- изменение атрибутов здесь и далее игнорируем, но выводим
				or tr.FROMQTY <> tr.TOQTY
				or ( tr.FROMLOC in ('PTV') and tr.TOLOC in ('LOST') )
				or ( tr.FROMLOC in ('LOST') and tr.TOLOC in ('PTV') )
			)
			and not ( -- перемещения по складу
				   ( tr.FROMLOC in ('PTV','PICKTO') and ttl.LOCATIONTYPE in ('PICK') )
				or ( tfl.LOCATIONTYPE in ('PICK') and tr.TOLOC in ('PTV','PICKTO') )
			)
			--and tfl.LOCATIONTYPE <> ttl.LOCATIONTYPE and tfl.LOCATIONFLAG <> ttl.LOCATIONFLAG
			--and (
			--	( i.SKU = tr.FROMSKU and isnull(fl.LOCATIONTYPE,'') not in ('PICKTO') and isnull(fl.LOCATIONFLAG,'') not in ('NONE') /* tr.FROMLOC not in ('LOST','PICKTO','BAD_PICKTO','HOL_PICKTO','SD_PICKTO','PL_KONTR','EA_IN','PTV') */ )
			--	or
			--	( i.SKU = tr.TOSKU and isnull(tl.LOCATIONTYPE,'') not in ('PICKTO') and isnull(tl.LOCATIONFLAG,'') not in ('NONE') /* tr.TOLOC not in ('LOST','PICKTO','BAD_PICKTO','HOL_PICKTO','SD_PICKTO','PL_KONTR','EA_IN','PTV') */ )
			--)
	where i.TRANTYPE in ('AJ','DP','WD')
		and (
			( @only_buys = 0 and @only_sells = 0 )
			or
			( @only_buys = 1 and i.TRANTYPE = 'DP' )
			or
			( @only_sells = 1 and i.TRANTYPE = 'WD' )
		)
		--and i.FROMLOC not in ('PRIEM_EA','EA_IN')
		--and i.TOLOC not in ('LOST','PICKTO','BAD_PICKTO','HOL_PICKTO','SD_PICKTO','PL_KONTR','EA_IN')
		and ( @sku is NULL or i.SKU = @sku )
		and ( @lot is NULL or i.LOT = @lot or (i.LOT = '' and l.LOT = @lot) )
		and ( @date_from is NULL or i.EDITDATE >= @date_from )
		and ( @date_to is NULL or i.EDITDATE < @date_to )
		--and i.SOURCETYPE not in ('ntrTransferDetailAdd')
		--and tr.SERIALKEY is NULL -- вместо фильтра корректируем

--		and i.ADDDATE between '20110802' and '20110804'
--	order by i.ADDDATE, i.TRANTYPE

	union all

	-- Перемещения
	select
		i.SERIALKEY, 'ITRN' as [SOURCE],
		i.TRANTYPE, i.SKU, isnull(nullif(i.LOT,''),l.LOT) as LOT,
		i.FROMLOC,fl.LOCATIONTYPE,
		NULL as TR_LOT,
		i.TOLOC,tl.LOCATIONTYPE,
		i.QTY,
		case when isnull(fl.LOCATIONTYPE,'') in ('PICK','CASE','PND','PICKTO','OTHER','STAGED') --and fl.LOC <> 'LOST'
		and isnull(tl.LOCATIONTYPE,'') in ('PICK','CASE','PND','PICKTO','OTHER')
			then - i.QTY
			else 0
		end as CORRECTION_QTY,
		i.SOURCEKEY,i.SOURCETYPE,
		t.ORDERKEY as DOC_KEY,
		t.ORDERLINENUMBER as DOC_LINE,
		i.ADDDATE, i.EDITDATE, i.EDITWHO
--,tl.*,i.*
	from wh1.ITRN i
		join wh1.LOC fl on fl.LOC = i.FROMLOC
		join wh1.LOC tl on tl.LOC = i.TOLOC
		left join wh1.TASKDETAIL t on i.TRANTYPE = 'MV' and t.SOURCEKEY = i.SOURCEKEY and i.SOURCEKEY > ''
		left join wh1.LOTATTRIBUTE l on l.SKU = i.SKU
			and ( l.LOTTABLE01 = i.LOTTABLE01 or l.LOTTABLE01 is NULL and i.LOTTABLE01 is NULL ) -- упаковка
			and ( l.LOTTABLE02 = i.LOTTABLE02 or l.LOTTABLE02 is NULL and i.LOTTABLE02 is NULL ) -- серия Аналит
			and ( l.LOTTABLE03 = i.LOTTABLE03 or l.LOTTABLE03 is NULL and i.LOTTABLE03 is NULL ) -- наличие сертификата
			and ( l.LOTTABLE04 = i.LOTTABLE04 or l.LOTTABLE04 is NULL and i.LOTTABLE04 is NULL ) -- дата производства
			and ( l.LOTTABLE05 = i.LOTTABLE05 or l.LOTTABLE05 is NULL and i.LOTTABLE05 is NULL ) -- срок годности
			and ( l.LOTTABLE06 = i.LOTTABLE06 or l.LOTTABLE06 is NULL and i.LOTTABLE06 is NULL ) -- <не используется>
			and ( l.LOTTABLE07 = i.LOTTABLE07 or l.LOTTABLE07 is NULL and i.LOTTABLE07 is NULL ) -- признак брака
			and ( l.LOTTABLE08 = i.LOTTABLE08 or l.LOTTABLE08 is NULL and i.LOTTABLE08 is NULL ) -- признак запрета ФСН
	where @only_buys = 0 and @only_sells = 0
		and i.TRANTYPE = 'MV'
		and isnull(fl.LOCATIONTYPE,'') not in ('CASE','PICK')
		and isnull(tl.LOCATIONTYPE,'') in ('CASE','PICK','PND')
--		and i.FROMLOC not in ('PRIEM','PRIEM_EA','EA_IN')
--		and i.TOLOC not in ('LOST','PL_KONTR')--('LOST','PICKTO','BAD_PICKTO','HOL_PICKTO','SD_PICKTO','PL_KONTR','EA_IN','PTV')
--?		and i.SOURCETYPE not in ('NSPRFRL01','NSPRFRL02') --что это?
		and ( @sku is NULL or i.SKU = @sku )
		and ( @lot is NULL or i.LOT = @lot or (i.LOT = '' and l.LOT = @lot) )
		and ( @date_from is NULL or i.EDITDATE >= @date_from )
		and ( @date_to is NULL or i.EDITDATE < @date_to )

--/*
	union all

	select
		i.SERIALKEY, 'ITRN' as [SOURCE],
		i.TRANTYPE, i.SKU, isnull(nullif(i.LOT,''),l.LOT) as LOT,
		i.FROMLOC,fl.LOCATIONTYPE,
		NULL as TR_LOT,
		i.TOLOC,tl.LOCATIONTYPE,
		- i.QTY as QTY,
		case when isnull(fl.LOCATIONTYPE,'') in ('CASE','PICK','OTHER')
		and isnull(tl.LOCATIONTYPE,'') in ('CASE','PICKTO','PND','OTHER','STAGED') --and tl.LOC <> 'LOST'
			then i.QTY
			else 0
		end as CORRECTION_QTY,
		i.SOURCEKEY,i.SOURCETYPE,
		t.ORDERKEY as DOC_KEY,
		t.ORDERLINENUMBER as DOC_LINE,
		i.ADDDATE, i.EDITDATE, i.EDITWHO
--,tl.*,i.*
	from wh1.ITRN i
		join wh1.LOC fl on fl.LOC = i.FROMLOC
		join wh1.LOC tl on tl.LOC = i.TOLOC
		left join wh1.TASKDETAIL t on i.TRANTYPE = 'MV' and t.SOURCEKEY = i.SOURCEKEY and i.SOURCEKEY > ''
		left join wh1.LOTATTRIBUTE l on l.SKU = i.SKU
			and ( l.LOTTABLE01 = i.LOTTABLE01 or l.LOTTABLE01 is NULL and i.LOTTABLE01 is NULL ) -- упаковка
			and ( l.LOTTABLE02 = i.LOTTABLE02 or l.LOTTABLE02 is NULL and i.LOTTABLE02 is NULL ) -- серия Аналит
			and ( l.LOTTABLE03 = i.LOTTABLE03 or l.LOTTABLE03 is NULL and i.LOTTABLE03 is NULL ) -- наличие сертификата
			and ( l.LOTTABLE04 = i.LOTTABLE04 or l.LOTTABLE04 is NULL and i.LOTTABLE04 is NULL ) -- дата производства
			and ( l.LOTTABLE05 = i.LOTTABLE05 or l.LOTTABLE05 is NULL and i.LOTTABLE05 is NULL ) -- срок годности
			and ( l.LOTTABLE06 = i.LOTTABLE06 or l.LOTTABLE06 is NULL and i.LOTTABLE06 is NULL ) -- <не используется>
			and ( l.LOTTABLE07 = i.LOTTABLE07 or l.LOTTABLE07 is NULL and i.LOTTABLE07 is NULL ) -- признак брака
			and ( l.LOTTABLE08 = i.LOTTABLE08 or l.LOTTABLE08 is NULL and i.LOTTABLE08 is NULL ) -- признак запрета ФСН
	where @only_buys = 0 and @only_sells = 0
		and i.TRANTYPE = 'MV'
		and isnull(fl.LOCATIONTYPE,'') in ('CASE','PICK')
		and isnull(tl.LOCATIONTYPE,'') not in ('PICK')
--		and i.FROMLOC not in ('LOST','PICKTO','BAD_PICKTO','HOL_PICKTO','SD_PICKTO','PL_KONTR','EA_IN','PTV')
--		and i.TOLOC not in ('PRIEM_EA','EA_IN')
--?		and i.SOURCETYPE not in ('NSPRFRL01','NSPRFRL02') --что это?
		and ( @sku is NULL or i.SKU = @sku )
		and ( @lot is NULL or i.LOT = @lot or (i.LOT = '' and l.LOT = @lot) )
		and ( @date_from is NULL or i.EDITDATE >= @date_from )
		and ( @date_to is NULL or i.EDITDATE < @date_to )
--*/

	union all

	select
		t.SERIALKEY, 'TRANSFERDETAIL' as [SOURCE],
		'TR' as TRANTYPE, t.FROMSKU, t.FROMLOT,
		t.FROMLOC,fl.LOCATIONTYPE,
		l.LOT as TR_LOT,
		t.TOLOC,tl.LOCATIONTYPE,
		- t.FROMQTY as QTY,
		case when ( t.FROMLOC <> t.TOLOC -- изменение атрибутов здесь и далее игнорируем, но выводим
			or t.FROMQTY <> t.TOQTY
			or ( t.FROMLOC in ('PTV') and t.TOLOC in ('LOST') )
			or ( t.FROMLOC in ('LOST') and t.TOLOC in ('PTV') )
		)
		and not ( -- перемещения по складу
			   ( t.FROMLOC in ('PTV','PICKTO') and tl.LOCATIONTYPE in ('PICK') )
			or ( fl.LOCATIONTYPE in ('PICK') and t.TOLOC in ('PTV','PICKTO') )
		)
		--and not ( t.FROMLOT <> l.LOT and t.FROMLOC in ('LOST') ) -- возврат из LOSTа со сменой ЛОТа
			then 0
			else t.FROMQTY
		end as CORRECTION_QTY,
--		case when isnull(fl.LOCATIONTYPE,'') in ('CASE','PICK') and isnull(tl.LOCATIONTYPE,'') in ('CASE','PICK')
--				or t.FROMLOC = t.TOLOC
--			then t.FROMQTY
--			else 0
--		end as CORRECTION_QTY,
		t.TRANSFERKEY + isnull(t.TRANSFERLINENUMBER,'') as SOURCEKEY,NULL as SOURCETYPE,
		t.TRANSFERKEY as DOC_KEY,
		t.TRANSFERLINENUMBER as DOC_LINE,
		t.ADDDATE, t.EDITDATE, t.EDITWHO
--,t.*
	from wh1.TRANSFERDETAIL t
		left join wh1.LOC fl on fl.LOC = t.FROMLOC
		left join wh1.LOC tl on tl.LOC = t.TOLOC
		left join wh1.LOTATTRIBUTE l on l.SKU = t.TOSKU
			and ( l.LOTTABLE01 = t.LOTTABLE01 or l.LOTTABLE01 is NULL and t.LOTTABLE01 is NULL ) -- упаковка
			and ( l.LOTTABLE02 = t.LOTTABLE02 or l.LOTTABLE02 is NULL and t.LOTTABLE02 is NULL ) -- серия Аналит
			and ( l.LOTTABLE03 = t.LOTTABLE03 or l.LOTTABLE03 is NULL and t.LOTTABLE03 is NULL ) -- наличие сертификата
			and ( l.LOTTABLE04 = t.LOTTABLE04 or l.LOTTABLE04 is NULL and t.LOTTABLE04 is NULL ) -- дата производства
			and ( l.LOTTABLE05 = t.LOTTABLE05 or l.LOTTABLE05 is NULL and t.LOTTABLE05 is NULL ) -- срок годности
			and ( l.LOTTABLE06 = t.LOTTABLE06 or l.LOTTABLE06 is NULL and t.LOTTABLE06 is NULL ) -- <не используется>
			and ( l.LOTTABLE07 = t.LOTTABLE07 or l.LOTTABLE07 is NULL and t.LOTTABLE07 is NULL ) -- признак брака
			and ( l.LOTTABLE08 = t.LOTTABLE08 or l.LOTTABLE08 is NULL and t.LOTTABLE08 is NULL ) -- признак запрета ФСН
	where @only_buys = 0 and @only_sells = 0
		and t.FROMQTY <> 0 and t.[STATUS] > 0
		and ( @sku is NULL or t.FROMSKU = @sku )
		and ( @lot is NULL or t.FROMLOT = @lot )
		and ( @date_from is NULL or t.EDITDATE >= @date_from )
		and ( @date_to is NULL or t.EDITDATE < @date_to )
		--and not ( fl.LOC = 'LOST' and tl.LOC = 'LOST' )
		and ( t.FROMLOC <> t.TOLOC or t.FROMQTY <> t.TOQTY )
		--and t.FROMLOC not in ('LOST','PICKTO','BAD_PICKTO','HOL_PICKTO','SD_PICKTO','PL_KONTR','EA_IN','PTV')
		--and isnull(fl.LOCATIONTYPE,'') not in ('PICKTO','PICK','STAGED','PND') -- CASE,PICKTO,STAGED,PICK,PND,IDZ,OTHER

	union all

	select
		t.SERIALKEY, 'TRANSFERDETAIL' as [SOURCE],
		'TR' as TRANTYPE, t.TOSKU, l.LOT,
		t.FROMLOC,fl.LOCATIONTYPE,
		t.FROMLOT as TR_LOT,
		t.TOLOC,tl.LOCATIONTYPE,
		t.TOQTY as QTY,
		case when ( t.FROMLOC <> t.TOLOC -- изменение атрибутов здесь и далее игнорируем, но выводим
			or t.FROMQTY <> t.TOQTY
			or ( t.FROMLOC in ('PTV') and t.TOLOC in ('LOST') )
			or ( t.FROMLOC in ('LOST') and t.TOLOC in ('PTV') )
		)
		and not ( -- перемещения по складу
			   ( t.FROMLOC in ('PTV','PICKTO') and tl.LOCATIONTYPE in ('PICK') )
			or ( fl.LOCATIONTYPE in ('PICK') and t.TOLOC in ('PTV','PICKTO') )
		)
			then 0
			else - t.TOQTY
		end as CORRECTION_QTY,
--		case when isnull(fl.LOCATIONTYPE,'') in ('CASE','PICK') and isnull(tl.LOCATIONTYPE,'') in ('CASE','PICK')
--				or t.FROMLOC = t.TOLOC
--			then - t.TOQTY
--			else 0
--		end as CORRECTION_QTY,
		t.TRANSFERKEY + isnull(t.TRANSFERLINENUMBER,'') as SOURCEKEY,NULL as SOURCETYPE,
		t.TRANSFERKEY as DOC_KEY,
		t.TRANSFERLINENUMBER as DOC_LINE,
		t.ADDDATE, t.EDITDATE, t.EDITWHO
--,t.*
	from wh1.TRANSFERDETAIL t
		left join wh1.LOC fl on fl.LOC = t.FROMLOC
		left join wh1.LOC tl on tl.LOC = t.TOLOC
		left join wh1.LOTATTRIBUTE l on l.SKU = t.TOSKU
			and ( l.LOTTABLE01 = t.LOTTABLE01 or l.LOTTABLE01 is NULL and t.LOTTABLE01 is NULL ) -- упаковка
			and ( l.LOTTABLE02 = t.LOTTABLE02 or l.LOTTABLE02 is NULL and t.LOTTABLE02 is NULL ) -- серия Аналит
			and ( l.LOTTABLE03 = t.LOTTABLE03 or l.LOTTABLE03 is NULL and t.LOTTABLE03 is NULL ) -- наличие сертификата
			and ( l.LOTTABLE04 = t.LOTTABLE04 or l.LOTTABLE04 is NULL and t.LOTTABLE04 is NULL ) -- дата производства
			and ( l.LOTTABLE05 = t.LOTTABLE05 or l.LOTTABLE05 is NULL and t.LOTTABLE05 is NULL ) -- срок годности
			and ( l.LOTTABLE06 = t.LOTTABLE06 or l.LOTTABLE06 is NULL and t.LOTTABLE06 is NULL ) -- <не используется>
			and ( l.LOTTABLE07 = t.LOTTABLE07 or l.LOTTABLE07 is NULL and t.LOTTABLE07 is NULL ) -- признак брака
			and ( l.LOTTABLE08 = t.LOTTABLE08 or l.LOTTABLE08 is NULL and t.LOTTABLE08 is NULL ) -- признак запрета ФСН
		join ( -- "левый" трансфер (который не засветился на остатках) игнорируем
			select distinct LOT, LOC
			from wh1.LOTxLOCxID
		--	where ( @sku is NULL or @sku = '' or SKU = @sku ) and ( @lot is NULL or @lot = '' or LOT = @lot )
		) x on x.LOT = l.LOT and x.LOC = tl.LOC
	where @only_buys = 0 and @only_sells = 0
		and t.TOQTY <> 0 and t.[STATUS] > 0
		and ( @sku is NULL or t.TOSKU = @sku )
		and ( @lot is NULL or l.LOT = @lot )
		and ( @date_from is NULL or t.EDITDATE >= @date_from )
		and ( @date_to is NULL or t.EDITDATE < @date_to )
		--and not ( fl.LOC = 'LOST' and tl.LOC = 'LOST' )
		and ( t.FROMLOC <> t.TOLOC or t.FROMQTY <> t.TOQTY )
		--and t.TOLOC not in ('LOST','PICKTO','BAD_PICKTO','HOL_PICKTO','SD_PICKTO','PL_KONTR','EA_IN','PTV')
		--and isnull(tl.LOCATIONTYPE,'') not in ('PICKTO','PICK','STAGED','PND') -- CASE,PICKTO,STAGED,PICK,PND,IDZ,OTHER
	
	return
end

