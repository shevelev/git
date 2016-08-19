-- =============================================
-- Автор:		Смехнов Антон
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 15.10.2009 (НОВЭКС)
-- Описание: Проверка потребности назначения ячеек отбора
--			Функция возвращает количество ячеек отбора, которые нужно назначить для товара
-- =============================================
ALTER FUNCTION [WH1].[novex_checkNeedSetPickLoc] 
	(@Storer as varchar(15),
	 @SkuName as varchar(50))
RETURNS int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	-- SET NOCOUNT ON;
--##############################################################################

--declare @Storer as varchar(15), @SkuName as varchar(50)
--set @Storer='92'
--set @SkuName='00020'
declare @ZONE as varchar(10)
declare @countLOC as int
declare @needLOC as int

--set @needLOC=0

--print '>>> Проверка потребности назначения ячейки отбора для товара STORERKEY='+isnull(@Storer,'<NULL>')+' SKU='+isnull(@SkuName,'<NULL>')
--print '1.0. Проверка потребности в назначении ячейки отбора'
--print '...1.1. Ищем зону для назначения ячеек отбора...'
--Выбирается зона, указанная в карточке товара. Последние 2 символа зоны заменяются на "EA"
--Предполагается что зоны коробочного хранения имеют постфикс "CS", а штучного "EA"
select @ZONE=left(s.putawayzone,len(s.putawayzone)-2)+'EA'
from sku s
where s.storerkey=@Storer and s.sku=@SkuName
--СПИСОК ИСКЛЮЧЕНИЙ
and
(s.putawayzone in		-- обрабатываем только зоны в которых есть разделение на штучный и коробочный отбор
	(
	select pz.putawayzone
	from putawayzone pz
	join putawayzone pzEA on (left(pz.putawayzone,len(pz.putawayzone)-2)+'EA'=pzEA.putawayzone)
	join putawayzone pzCS on (left(pz.putawayzone,len(pz.putawayzone)-2)+'CS'=pzCS.putawayzone)
	)
 and
 (s.putawayzone not like 'BRAK%')	-- исключаем ячейки брака
 and
 (s.storerkey<>'000000001')			-- исключаем обработку Владельца М-Видео
 and									-- обрабатываем только зоны стеллажного хранения без напольных ячеек
 (select top 1 loc from loc l where l.putawayzone=left(s.putawayzone,len(s.putawayzone)-2)+'EA') like '[1-9]___.[1-9].[1-9]'
  and									-- исключаем зоны с ячееками неустановленного объема
 (select top 1 isnull(cubiccapacity,0) from loc l where l.putawayzone=left(s.putawayzone,len(s.putawayzone)-2)+'EA')>0
)
--print '......найдена зона: '+isnull(@ZONE,'<NULL>')

if (@ZONE is not null) 
begin
-- print '...1.2. Проверяем наличие настроенных ячеек отбора...'
 select @countLOC=isnull(count(sxl.sku),0)
		from
		skuxloc sxl join loc l on (sxl.loc=l.loc)
		where
--проверка соответствия назначенной ячейки отбора требуемой зоне размещения отключена
--		(l.putawayzone=@ZONE)
--		and
		(sxl.storerkey=@Storer and sxl.sku=@SkuName)
		and
		( (	sxl.locationtype='PICK'
			and
			sxl.qtylocationminimum>0
			and
			sxl.qtylocationlimit>0
			and
			sxl.allowreplenishfromcasepick=1)
		)
 --print '...1.3. Найдено '+cast(@countLOC as varchar)+' ячеек'
 --устанавливаем количество ячеек отбора требуемых для товара
 --06.11.2009 исправлено на 1 товар - 1 ячейка отбора
 select @needLOC=
	(case
--	 when s.shelflifeindicator='Y' and @countLOC>1	then 0
--	 when s.shelflifeindicator='Y' and @countLOC<2	then 2-@countLOC
--	 when s.shelflifeindicator='N' and @countLOC>0	then 0
--	 when s.shelflifeindicator='N' and @countLOC=0	then 1
	 when @countLOC>0								then 0
													else 1
	 end)
from sku s
where s.storerkey=@Storer and s.sku=@SkuName
-- if @needLOC>0
--	print '...Для данного товара требуется назначить '+cast(@countLOC as varchar)+' ячеек отбора'
-- else
--	print '...Для данного товара не требуется назначение ячеек отбора. ЯЧЕЙКИ УЖЕ НАЗНАЧЕНЫ.'

end
else
begin
 set @needLOC=-1
-- print '...Для данного товара не требуется назначение ячеек отбора. ЗОНА РАЗМЕЩЕНИЯ НЕ ТРЕБУЕТ НАЗНАЧАНИЯ ЯЧЕЕК.'
end

RETURN @needLOC
END

