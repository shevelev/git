-- =============================================
-- Автор:		Тын Максим
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 07.12.2009 (НОВЭКС)
-- Описание: Выявление не размещенных товаров по номеру ПУО
-- =============================================


ALTER PROCEDURE [dbo].[repF03_SKUfromASNtoLOC] ( 
	@wh varchar(30),
	@ASNkey varchar(10)
)
as

	declare @sql varchar(max)

select rcd.receiptkey, isnull(lld.id,'NE') id, lld.lot, lld.storerkey, st.company, lld.sku, sk.descr, lld.loc, sum(lld.qty ) qty
into #result_table
from wh1.receiptdetail rcd
	join wh1.lotxlocxid lld on rcd.tolot=lld.lot and lld.qty>0														
	join wh1.storer st on rcd.storerkey=st.storerkey
	join wh1.sku sk on rcd.sku=sk.sku
								
where 1=2 and rcd.receiptkey='0000002314' 
group by rcd.receiptkey, isnull(lld.id,'NE'), lld.lot, lld.storerkey, st.company, lld.sku, sk.descr, lld.loc


set @sql='
	insert into #result_table
	select 
		rcd.receiptkey, 
		isnull(lld.id,''NE'') id, 
		lld.lot, 
		lld.storerkey, 
		st.company, 
		lld.sku, 
		sk.descr, 
		lld.loc, 
		(lld.qty ) qty

from wh1.receiptdetail rcd
	join '+@wh+'.lotxlocxid lld on rcd.toid=lld.id	
								and rcd.sku=lld.sku
								and rcd.storerkey=lld.storerkey
								and lld.loc like ''VOROTA16''
								and lld.qty>0
	join '+@wh+'.storer st on rcd.storerkey=st.storerkey
	join '+@wh+'.sku sk on rcd.sku=sk.sku and rcd.storerkey=sk.storerkey
								
where rcd.status=''9''
		and rcd.receiptkey='''+@ASNkey+'''
group by rcd.receiptkey, isnull(lld.id,''NE''), lld.lot, lld.storerkey, st.company, lld.sku, sk.descr, lld.loc, lld.qty

'

print (@sql)
exec (@sql)

select *
from #result_table

drop table #result_table

