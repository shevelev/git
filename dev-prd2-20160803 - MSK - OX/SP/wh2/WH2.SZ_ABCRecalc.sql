-- =============================================
-- Автор:		Смехнов Антон
-- Проект:		Северо-Запад, г.Санкт-Петербург
-- Дата создания: 26.05.2011 (Северо-Запад)
-- Описание: пересчет группы оборачиваемости товара
--	Данная процедура осуществляет пересчет группы оборачиваемости товара.
--	Под группой оборачиваемости понимается частота появления товара в Заказах на отгрузку. 
--  Т.е. как часто производится отбор товара на складе. Количество единиц товара и кратность заводской упаковке не учитывается.
--	Распределение групп по долям прописывается в поле long_value в таблице CODELKUP
--  Глубина анализа для расчета статистики в переменной ABCPERIOD в листе SYSVAR таблицы CODELKUP
--  Товары группы оборачиваемости X исключаются из обработки. X- это товары, для которых настройка ячеек отбора производится вручную.
-- =============================================
ALTER PROCEDURE [WH2].[SZ_ABCRecalc] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--##############################################################################
--Выбираем товары с остатком на складе. Исключаем группу X
select s.storerkey, s.sku 
into #balance
from WH2.lotxlocxid lld
join WH2.sku s on (s.storerkey=lld.storerkey and s.sku=lld.sku)
where isnull(s.abc,'B')<>'X' and lld.qty>0
group by s.storerkey, s.sku
--drop table #balance

--Отбираем продажи за последние ABCPERIOD дней
select distinct pd.orderkey,pd.storerkey,pd.sku
into #shipHistory
from WH2.pickdetail pd
where pd.status='9' and (pd.editdate between getdate()-cast(WH2.GetFromCODELKUP('SYSVAR','ABCPERIOD') AS int) and getdate())

--Считаем количество продаж
select SH.storerkey,SH.sku,count(SH.sku) shipCOUNT, cast(0.0 as real) as accum, cast('B' as varchar(1)) as ABC
into #ship
from #shipHistory SH join #balance B on (SH.storerkey=B.storerkey and SH.sku=B.sku)
group by SH.storerkey,SH.sku

--Рассчитываем группу ABC
	DECLARE @totalCOUNT as real --если объявить её как int потом при делении int на int может сработать приведение типа и дробную часть потеряем
	DECLARE @shipCOUNT as int, @v1 as varchar(50), @v2 as varchar(50)
	set @totalCOUNT=0
	set @shipCOUNT=0
	DECLARE SKUList_cursor CURSOR
		FOR SELECT storerkey,sku,shipCOUNT FROM #ship order by shipCOUNT desc
		FOR UPDATE OF accum 
	OPEN SKUList_cursor
	FETCH NEXT FROM SKUList_cursor into @v1,@v2,@shipCOUNT

	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @totalCOUNT=@totalCOUNT+ISNULL(@shipCOUNT,0)
		update #ship set accum=@totalCOUNT where CURRENT OF SKUList_cursor
		FETCH NEXT FROM SKUList_cursor into @v1,@v2,@shipCOUNT
	END
	CLOSE SKUList_cursor
	DEALLOCATE SKUList_cursor
	
	declare @A as real, @B as real, @C as real
	select @A=cast(isnull(LONG_VALUE,'0') as real) from WH2.CODELKUP where LISTNAME='ABC' and CODE='A'
	select @B=cast(isnull(LONG_VALUE,'0') as real) from WH2.CODELKUP where LISTNAME='ABC' and CODE='B'
	select @C=cast(isnull(LONG_VALUE,'0') as real) from WH2.CODELKUP where LISTNAME='ABC' and CODE='C'
	UPDATE #ship set ABC='A' WHERE (accum/@totalCOUNT) <= @A
	UPDATE #ship set ABC='C' WHERE (accum/@totalCOUNT) >= @A+@B

--Обновляем группу оборачиваемости для товаров	 
update WH2.SKU
set sku.abc=S.ABC
from WH2.sku sku join #ship S on (sku.storerkey=S.storerkey and sku.sku=S.sku)

END

