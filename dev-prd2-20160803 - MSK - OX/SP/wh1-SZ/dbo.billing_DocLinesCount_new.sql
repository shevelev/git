--################################################################################################
-- Процедура подсчитывает количество строк приходных и расходных документов по Владельцам за указанный период
-- Для расходных документов также расчитывается % выполнения по соотношении суммы(стоимости) выполненного и заказанного товара
-- Проект НОВЭКС, Барнаул, 10.12.2009, Смехнов А.М.
--################################################################################################
ALTER PROCEDURE [dbo].[billing_DocLinesCount_new]
			@begindate	datetime,	
			@enddate	datetime
AS
--declare @begindate	datetime,	
--		@enddate	datetime
--select @begindate='20091010', @enddate='20091031'

---------------------------------------------------------------------------------------------------
print 'Подсчитываем строчки расхода'
--отбираем обработанные строки расхода
select od.storerkey, max(st.company) StorerName, od.orderkey, od.orderlinenumber, sum(td.qty) pickedQTY, max(od.originalQTY) originalQTY, max(od.unitprice) unitprice
into #preLinesCount1
from 
wh1.taskdetail td
join wh1.orderdetail od on td.orderkey = od.orderkey and td.orderlinenumber = od.orderlinenumber
join wh1.storer st on (od.storerkey=st.storerkey)
where	(td.editdate between @begindate and @enddate+1)
		and
		(td.status='9')
group by od.storerkey,od.orderkey,od.orderlinenumber

--суммируем строчки расхода
select PRE.storerkey, PRE.StorerName, count(PRE.orderlinenumber) ShipLinesCount,
		sum(PRE.pickedQTY*PRE.unitprice) pickedSUM,
		sum(PRE.originalQTY*PRE.unitprice) originalSUM,
		case when sum(PRE.unitprice)<>0 then 
			sum(PRE.pickedQTY*PRE.unitprice)/sum(PRE.originalQTY*PRE.unitprice) 
			else sum(PRE.pickedQTY)/sum(PRE.originalQTY) end UNcompletion
into #LinesCount1
from #preLinesCount1 PRE
group by PRE.storerkey, PRE.StorerName

---------------------------------------------------------------------------------------------------
print 'Подсчитываем строчки прихода'
select rd.storerkey, max(st.company) StorerName, count(rd.receiptkey) ReceiptLinesCount
into #LinesCount2
from wh1.receiptdetail rd
	join wh1.storer st on (rd.storerkey=st.storerkey)

where	(rd.editdate between @begindate and @enddate+1)
		and
		(rd.qtyexpected>0)
group by rd.storerkey

--drop table #LinesCount1

print 'Объединяем данные в одну таблицу и возвращаем записи для отчета'
select
case when LC1.storerkey is null then LC2.storerkey else LC1.storerkey end STORERKEY,
case when LC1.storername is null then LC2.storername else LC1.storername end STORERNAME,
isnull(LC1.ShipLinesCount,0)	ShipLinesCount,
isnull(LC2.ReceiptLinesCount,0)	ReceiptLinesCount,
isnull(LC1.pickedSUM,0)			ShipSUM,
isnull(LC1.OriginalSUM,0)		OriginalSUM,
isnull(LC1.UNcompletion,0)		UNCompletion
from #LinesCount1 LC1
	full outer join #LinesCount2 LC2 on (LC1.storerkey=LC2.storerkey)

