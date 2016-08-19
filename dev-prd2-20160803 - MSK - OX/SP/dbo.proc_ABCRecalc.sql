

-- =============================================
-- Автор:		Смехнов Антон
-- Проект:		СМАЙЛ, г.Казань
-- Дата создания: 20.08.2010 (СМАЙЛ)
-- Описание: пересчет группы оборачиваемости товара
--	Данная процедура осуществляет пересчет группы оборачиваемости товара в пределах групп товара (значение поля SKUGROUP)
--	Группы оборачиваемости A,B,C и D. Деление на группы настраивается установкой долей в таблице CODELKUP.
--	Дополнительно вводится группа оборачиваемости X. X- это товары, для которых анализ ABC не проводится.
--  Управление данными товарами ведется только вручную. Установка группы X осуществялется только вручную через интерфейс INFOR
-- =============================================
ALTER PROCEDURE [dbo].[proc_ABCRecalc] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--Считываем параметры настройки алгоритма из CODELKUP
declare @defaultABCGroup as varchar(1),
		@recalcPeriod	as int,
		@Aoffset		as int,
		@Boffset		as int,
		@Coffset		as int,
		@Doffset		as int
		
		set @defaultABCGroup='A'
		set @Aoffset=80
		set @Boffset=15
		set @Coffset=5
		set @Doffset=0


--##############################################################################
--Формируем сокращенный список товаров. Исключаем группу X
select s.storerkey, s.sku, isnull(s.abc,'A') abc
into #balance
from wh1.sku s
where isnull(s.abc,@defaultABCGroup)<>'X'
--drop table #balance

--Считаем объем отгрузок за последние неделю (отгруженные отборы)
select B.storerkey,B.sku,isnull(sum(pd.qty),0) shipQTY
into #ship
from #balance B left join wh1.pickdetail pd on (pd.storerkey=B.storerkey and pd.sku=B.sku)
where pd.status='9' and (pd.editdate between getdate()-7 and getdate())
group by pd.storerkey,pd.sku

--Запоминаем настройки ячеек отбора
select sxl.storerkey,sxl.sku,max(sxl.qtylocationminimum) minQTY,max(sxl.qtylocationlimit) maxQTY
into #minmax
from wh1.skuxloc sxl join #balance B on (sxl.storerkey=B.storerkey and sxl.sku=B.sku)
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
from wh1.sku sku join #SKUup UP on (Sku.storerkey=UP.storerkey and Sku.sku=UP.sku)

update sku
set sku.abc=DOWN.newABC
from wh1.sku sku join #SKUdown DOWN on (Sku.storerkey=DOWN.storerkey and Sku.sku=DOWN.sku)

END





