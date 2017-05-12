-- =============================================
-- Автор:		Смехнов Антон
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 20.11.2009 (НОВЭКС)
-- Описание: пересчет группы оборачиваемости товара
--	Данная процедура осуществляет пересчет группы оборачиваемости товара в пределах ячейки отбора !
--	Т.е. это не оборачиваемость товара в целом по складу !!! Это оборачиваемость именно в ячейке отбора !
--	Группа А означает, что в масштабах ячейки отбора товар отгружается в больших количествах. Группа D - наоборот.
--  Если QTYLOCATIONMINIMUM меньше чем объемы продаж товара за неделю, то группа оборачиваемости товара увеличивается.
--	Если QTYLOCATIONMINIMUM больше чем объемы продаж товара за неделю, то группа оборачиваемости товара уменьшается.
--  Автоматически группы оборачиваемости меняются только в пределах A->B->C->D и обратно A<-B<-C<-D
--  Установка группы X осуществялется только вручную через интерфейс INFOR
--  Товары группы оборачиваемости X исключаются из обработки. X- это товары, для которых настройка ячеек отбора производится вручную.
-- =============================================
ALTER PROCEDURE [WH2].[novex_ABCRecalc] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--##############################################################################
--Выбираем товары с остатком на складе. Исключаем группу X
select s.storerkey, s.sku, isnull(s.abc,'C') abc
into #balance
from WH2.lotxlocxid lld
join WH2.sku s on (s.storerkey=lld.storerkey and s.sku=lld.sku)
where isnull(s.abc,'C')<>'X' and lld.qty>0
group by s.storerkey, s.sku, isnull(s.abc,'C')
--drop table #balance

--Считаем объем продаж за последнюю неделю (отобранное количество товара)
select pd.storerkey,pd.sku,sum(pd.qty) shipQTY
into #ship
from WH2.pickdetail pd join #balance B on (pd.storerkey=B.storerkey and pd.sku=B.sku)
where pd.status='9' and (pd.editdate between getdate()-7 and getdate())
group by pd.storerkey,pd.sku

--Запоминаем настройки ячеек отбора
select sxl.storerkey,sxl.sku,max(sxl.qtylocationminimum) minQTY,max(sxl.qtylocationlimit) maxQTY
into #minmax
from WH2.skuxloc sxl join #balance B on (sxl.storerkey=B.storerkey and sxl.sku=B.sku)
where 
(sxl.qtylocationminimum>0 and sxl.qtylocationlimit>0 and sxl.allowreplenishfromcasepick=1)
group by sxl.storerkey,sxl.sku

--Выделяем товары по которым нужно уменьшить группу оборачиваемости
select B.storerkey,B.sku,M.minQTY,S.shipQTY, B.ABC oldABC,
	--если это группы A,B или С, то снижаем группу
	case when B.abc<>'X' and B.abc<>'D' then char(ascii(left(B.abc,1))+1) else B.abc end newABC
into #SKUdown
from #balance B
join #minmax M on (M.storerkey=B.storerkey and M.sku=B.sku)
join #ship S on (S.storerkey=B.storerkey and S.sku=B.sku)
where
M.minQTY>S.shipQTY*1.5 --минимальный остаток в ячейке отбора больше чем продажи за неделю с запасом 1.5

--Выделяем товары по которым нужно увеличить группу оборачиваемости
select B.storerkey,B.sku,M.minQTY,S.shipQTY, B.ABC oldABC,
	--если это группы B, C или D, то повышаем группу
	case when B.abc<>'X' and B.abc<>'A' then char(ascii(left(B.abc,1))-1) else B.abc end newABC
into #SKUup
from #balance B
join #minmax M on (M.storerkey=B.storerkey and M.sku=B.sku)
join #ship S on (S.storerkey=B.storerkey and S.sku=B.sku)
where
M.minQTY*1.5<S.shipQTY --минимальный остаток в ячейке отбора меньше чем продажи за неделю с запасом 1.5

--проверка. Этот перекрестный список должен быть пустым
--select S.*
--from #SKUdown S join #SKUup S1 on (S.storerkey=S1.storerkey and S.sku=S1.sku)

--Обновляем карточки товаров
update sku
set sku.abc=UP.newABC
from WH2.sku sku join #SKUup UP on (Sku.storerkey=UP.storerkey and Sku.sku=UP.sku)

update sku
set sku.abc=DOWN.newABC
from WH2.sku sku join #SKUdown DOWN on (Sku.storerkey=DOWN.storerkey and Sku.sku=DOWN.sku)

END

