ALTER PROCEDURE [dbo].[rep52_PODiv22] (
	/*   Приемный акт */
	@pk varchar(15)
)AS
--declare @pk varchar(15)
--set @pk='0000000726'


select
	pd.SKU,
	'' ddd,
	sum(pd.QTYADJUSTED) zak,
	sum(pd.QTYRECEIVED) otgr,
	case when sum(pd.QTYADJUSTED) - sum(pd.qtyreceived) > 0
			then sum(pd.QTYADJUSTED) - sum(pd.qtyreceived)
			else 0
		end as ned,
	case when sum(pd.QTYADJUSTED) - sum(pd.qtyreceived) < 0
			then sum(pd.qtyreceived) - sum(pd.QTYADJUSTED)
			else 0
		end as izl,
	sum(pd.qtyrejected) brak,
	substring(p.EXTERNPOKEY, 0, (len(p.EXTERNPOKEY) - 2)) as extn,
	p.pokey,
	st.CompanyName,
	--la.LOTTABLE01,
	la.LOTTABLE02,
	case when isnull(la.LOTTABLE02, '') = ''
			then 'б\с'
			else la.LOTTABLE02
		end as atr2,
	la.LOTTABLE04,
	la.LOTTABLE05,
	isnull(p.susr2, '') skll,
	p.EFFECTIVEDATE,
	tov.busr3 ud,
	case when (tov.SKUGROUP2 = 'Сильнодействующие') or (tov.FREIGHTCLASS = '6')
			then 'Сильнодействующие'
			else '1 Склад'
		end as FGr,
	p.BUYERSREFERENCE,
	isnull(
		nullif(left(p.BUYERADDRESS4, len(p.BUYERADDRESS4) - charindex(' ',reverse(p.BUYERADDRESS4))),''),
		substring(p.BUYERSREFERENCE, 0, charindex(' ', p.BUYERSREFERENCE))
	) nak,
	isnull(
		nullif(ltrim(right(p.BUYERADDRESS4, charindex(' ',reverse(p.BUYERADDRESS4)))),''),
		substring(p.BUYERSREFERENCE,charindex(' ', p.BUYERSREFERENCE) + 1,len(p.BUYERSREFERENCE))
	) dat,
	--left(p.BUYERADDRESS4,case when charindex(' ',p.BUYERADDRESS4) = 0 then len(p.BUYERADDRESS4) else charindex(' ',p.BUYERADDRESS4)-1 end) nak,
	--right(p.BUYERADDRESS4,case when charindex(' ',p.BUYERADDRESS4)-1 = 0 then len(p.BUYERADDRESS4) else len(p.BUYERADDRESS4)-charindex(' ',p.BUYERADDRESS4) end) dat,
	tov.SKUGROUP,
	tov.busr2,
	rec.editdate
	into #temper
from wh1.po p
	join wh1.podetail pd on p.POKEY = pd.POKEY
		and (
		    	pd.QTYREJECTED != '0'
		    	or pd.QTYRECEIVED != '0'
		    	or pd.QTYADJUSTED != '0'
		    )
	left join wh1.storer st on p.SELLERNAME = st.storerkey
	left join wh1.LOTATTRIBUTE la on la.LOT = pd.SUSR5
	join wh1.CODELKUP ck on ck.CODE = pd.UOM and ck.LISTNAME = 'package'
	left join wh1.SKU tov on tov.SKU = pd.SKU
	left join wh1.RECEIPT rec on rec.receiptkey = p.OTHERREFERENCE
where pd.POKEY = @pk
group by
	pd.SKU,
	p.EXTERNPOKEY,
	p.pokey,
	st.CompanyName,
	--la.LOTTABLE01,
	la.LOTTABLE02,
	la.LOTTABLE04,
	la.LOTTABLE05,
	p.susr2,
	p.EFFECTIVEDATE,
	tov.busr3,
	tov.SKUGROUP2,
	tov.FREIGHTCLASS,
	p.BUYERSREFERENCE,
	p.BUYERADDRESS4,
	tov.SKUGROUP,
	tov.busr2,
	rec.editdate


update #temper set ned = NULL where ned = '0'
update #temper set izl = NULL where izl = '0'
update #temper set brak = NULL where brak = '0'
			
select
	t.*,
	case when s.NOTES1 is NULL
			then s.DESCR
			else s.NOTES1
		end as ss
from #temper t
	join wh1.SKU s on s.SKU = t.sku
order by s.DESCR

drop table #temper





