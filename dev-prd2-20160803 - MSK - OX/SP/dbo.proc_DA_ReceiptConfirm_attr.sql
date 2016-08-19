ALTER PROCEDURE [dbo].[proc_DA_ReceiptConfirm_attr]
	
	@receiptkey1 varchar (10)
	as
	set nocount on
if @receiptkey1 is not NULL
begin
----Изменение партии DAX (Устраняем дублирующиеся партии и NA - 18.09.2015 Охунов
--1. исправляем все NA на партию инфра
select distinct rd.tolot, rd.receiptkey,  rd.sku 
into #lot6naedit
from
wh1.RECEIPTDETAIL rd 
where
rd.TOLOT is not null and rd.LOTTABLE06='NA'
and rd.RECEIPTKEY=@receiptkey1

update rd
set rd.LOTTABLE06=rd.tolot
from wh1.RECEIPTDETAIL rd right join #lot6naedit la
on rd.RECEIPTKEY=la.RECEIPTKEY 
and rd.SKU=la.SKU
and rd.TOLOT=la.TOLOT

update lat
set lat.LOTTABLE06=la.TOLOT
from wh1.LOTATTRIBUTE lat right join #lot6naedit la
on lat.SKU=la.SKU
and lat.lot=la.TOLOT

drop table #lot6naedit

--2. Исправляем дублирующиеся партии DAX (атрибут 6) для строк, которые имеют различные даты 04 и 05.

select rd.receiptkey, rd.sku,rd.RECEIPTLINENUMBER, rd.lottable06, rd.tolot,rd.LOTTABLE04, rd.LOTTABLE05,
   CASE 
	when RD.LOTTABLE06='NA' then  
	    RD.RECEIPTKEY+'-'+RD.RECEIPTLINENUMBER+'_'+CAST (Dense_RANK() over (PARTITION BY rd.lottable06 order by rd.LOTTABLE04+rd.LOTTABLE05) AS VARCHAR)
	else 
	    RD.lottable06+'_'+CAST (Dense_RANK() over (PARTITION BY rd.lottable06 order by rd.LOTTABLE04+rd.LOTTABLE05)AS VARCHAR)
	end as rrank
into #lot6edit
from
	    WH1.RECEIPTDETAIL rd right join
	    (SELECT r.RECEIPTKEY, r.SKU, r.LOTTABLE06, count(distinct r.LOTTABLE04+r.LOTTABLE05) count_lot
	    FROM [PRD2].[WH1].[RECEIPTDETAIL] r
		    left join wh1.RECEIPT rr on rr.RECEIPTKEY=r.RECEIPTKEY
		    left join wh1.po pd
					    on rr.POKEY=pd.POKEY
					    and pd.POTYPE = '0'
	    where  
		ltrim(rtrim(r.LOTTABLE02))='' and r.LOTTABLE06>''

	    group by r.LOTTABLE06, r.receiptkey, r.sku
	    having count(distinct r.LOTTABLE04+r.LOTTABLE05)>1) x
	     on x.RECEIPTKEY=rd.RECEIPTKEY and rd.SKU=x.SKU and rd.LOTTABLE06=x.LOTTABLE06
	where
	    rd.TOLOT is not null
	    and rd.RECEIPTKEY=@receiptkey1


update  rd1
set rd1.lottable06= x.rrank
from  WH1.RECEIPTDETAIL RD1 RIGHT JOIN 
	#lot6edit x
ON
    x.RECEIPTKEY=RD1.RECEIPTKEY and
    x.LOTTABLE04=RD1.LOTTABLE04 and
    x.LOTTABLE05=RD1.LOTTABLE05 and
    x.LOTTABLE06=RD1.LOTTABLE06 and
    x.SKU=RD1.SKU and
    x.TOLOT=RD1.TOLOT and
    x.RECEIPTLINENUMBER=rd1.RECEIPTLINENUMBER

update la
set la.LOTTABLE06=x.rrank
from
    wh1.lotattribute la right join 
    #lot6edit x on x.TOLOT = la.LOT

drop table #lot6edit
--------------------------------------------------------конец 18.09.2015	
end
