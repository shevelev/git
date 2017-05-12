-- =============================================
-- Автор:		Смехнов Антон
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 12.11.2009 (НОВЭКС)
-- Описание: Список товаров по которым необходимо назначить ячейку отбора

-- =============================================
ALTER PROCEDURE [WH2].[novex_ListBadSKU] 
AS

--делаем копии таблиц, что б не было блокировок на следующем шаге
select * into #STORER from WH2.storer
select distinct lld.storerkey, lld.sku, s.cartongroup, cast(s.notes1 as varchar(255)) notes1 into #BALANCE
	from WH2.lotxlocxid lld join WH2.sku s on (lld.storerkey=s.storerkey and lld.sku=s.sku) where lld.qty>0

--несмотря на кажущуюся простоту, это очень тяжелый запрос. Доступ к данному отчету нужно ограничить, что б не вешали SQL сервер
select st.company, s.storerkey, s.sku, s.cartongroup, s.notes1
from #BALANCE s join #STORER st on (s.storerkey=st.storerkey)
where WH2.novex_checkNeedSetPickLoc(s.storerkey,s.sku)>0
order by s.cartongroup, s.notes1

