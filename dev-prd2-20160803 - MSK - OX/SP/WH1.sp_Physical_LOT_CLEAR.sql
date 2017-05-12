-- =============================================
-- Author:		<KIR, Logicon.Ekaterinburg>
-- Create date: <16.12.2015>
-- =============================================
-- Заполнить в автоматическом режиме ПУСТЫЕ значения
-- поля LOT в таблице физикл. 
-- =============================================
ALTER PROCEDURE [WH1].[sp_Physical_LOT_CLEAR] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--=============================================================================================
--=============================================================================================

declare @tblP varchar(50)
declare @str varchar(1000)
declare @sku varchar(50), @L02 varchar(50), @L04 varchar(50),@L05 varchar(50), @invTag varchar(20),@LOC varchar(10)
declare @i int, @lot varchar(10), @qty1 decimal, @qty2 decimal

-- скопировать все записи с пустыми значениями поля лот 
select @tblP = '[WH1].[PHYSICAL_LOT_NULL_' + convert(varchar(8),getutcdate(),112) + ']'
-- если есть такая таблца то не трогаем, если нет, то делаем новую.
if OBJECT_ID (@tblP) is null 
  begin
	select @str = 'select * into ' + @tblP + ' from [WH1].[PHYSICAL] where LOT ='''' and QTY >0'
	--print @str
	exec(@str)
  end
  
 -- временная таблица для учета макс инвентаритэг
if object_id('tempdb..#tmpMaxInvent') is not null drop table #tmpMaxInvent

CREATE TABLE #tmpMaxInvent(
	[INVENT] [varchar](18) NOT NULL,
	[SKU] [varchar](50) NOT NULL,
	[SUSR1] [varchar](30) NULL,
	[SUSR4] [datetime] NULL,
	[SUSR5] [datetime] NULL,
	[LOC] [varchar](10) NOT NULL)
	
-- наполнение макс инвентаритэг
insert into #tmpMaxInvent
select MAX(INVENTORYTAG), sku, susr1, susr4, susr5, loc 
from wh1.PHYSICAL
where wh1.PHYSICAL.STATUS = 0 and LOT = '' and QTY > 0
group by sku, susr1, susr4, susr5, loc	

-- собрать в курсор 
DECLARE curCURSOR CURSOR READ_ONLY
/*Заполняем курсор*/
--SET curCURSOR  = CURSOR READ_ONLY --CURSOR SCROLL
FOR
select INVENT, sku, susr1, susr4, susr5, loc from #tmpMaxInvent
--where /*qty > 0 
--and */ sku ='14645'
--group by sku, susr1, susr4, susr5, loc 
/*Открываем курсор*/
OPEN curCURSOR
/*Выбираем первую строку*/
FETCH NEXT FROM curCURSOR INTO @invTag, @sku, @L02, @L04, @L05, @loc
/*Выполняем в цикле перебор строк*/
WHILE @@FETCH_STATUS = 0
BEGIN
	--print '!'
	-- по сочетаниям параметров выбираем подходящие партии 
	-- и смотрим для них данные в lotxlocxid
	select @i = COUNT(*) from WH1.lotxlocxid
	where QTY > 0 and loc = @loc and lot in
	(select lOT 
	from wh1.LOTATTRIBUTE 
	where SKU = @sku and LOTTABLE02 = @L02 and LOTTABLE04 = @L04 and LOTTABLE05 = @L05)

	-- разбор значений @i
	if @i > 0
	  begin
		if @i =1
		  begin
			--print 'одно совпадение'
			select @lot = lot
			from WH1.lotxlocxid
			where QTY > 0 and loc = @loc and lot in
			(select lOT 
			from wh1.LOTATTRIBUTE 
			where SKU = @sku and LOTTABLE02 = @L02 and LOTTABLE04 = @L04 and LOTTABLE05 = @L05)						
		  end
		else
		  begin
			print 'много совпадений'
			-- учтем кол-во если совпало отлично, нет - не беда.
			select @qty1 = qty 
			from wh1.physical 
			where INVENTORYTAG = @invTag and SKU = @sku and SUSR1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and LOC = @loc

			select @i = COUNT(*)
			from WH1.lotxlocxid
			where QTY = @qty1 and loc = @loc and lot in
			(select lOT 
			from wh1.LOTATTRIBUTE 
			where SKU = @sku and LOTTABLE02 = @L02 and LOTTABLE04 = @L04 and LOTTABLE05 = @L05)
			
			if @i = 1
			  begin
				--есть однозначное совпадение
				select @lot = lot
				from WH1.lotxlocxid
				where QTY = @qty1 and loc = @loc and lot in
				(select lOT 
				from wh1.LOTATTRIBUTE 
				where SKU = @sku and LOTTABLE02 = @L02 and LOTTABLE04 = @L04 and LOTTABLE05 = @L05)				
			  end
			else  
			  begin
				--нет однозначного совпадения. Тогда выбираем один с макимальным кол-вом товара
				select top 1 @lot = lot
				from WH1.lotxlocxid
				where QTY >0 and loc = @loc and lot in
				(select lOT 
				from wh1.LOTATTRIBUTE 
				where SKU = @sku and LOTTABLE02 = @L02 and LOTTABLE04 = @L04 and LOTTABLE05 = @L05)	
				order by QTY desc			
			  end
		  end
	  end
	else
	  begin
		--нет никаких совпадений
		--print 'нет никаких совпадений'
		-- подбираем партию с кол-вом 0 и максимальным серийником игнорируя ячейку.
		select top 1 @lot = la.lot 
		from wh1.LOTATTRIBUTE LA, wh1.lotxlocxid LC
		where LA.sku = @sku  and qty = 0 and la.LOT = lc.LOT and la.LOTTABLE02 = @L02 and la.LOTTABLE04 = @L04 and la.LOTTABLE05 = @L05
		order by SUBSTRING(lottable06,14,8) desc		
	  end
	  
	if LEN(@lot) > 0
	begin
		--запишем значение в физикл
		print @sku
		update wh1.physical
		set LOT = @lot
		where INVENTORYTAG = @invTag and sku = @sku and susr1 = @L02 and susr4 = @L04 and susr5 = @L05 and loc = @loc
	  end	  
	  	  
FETCH NEXT FROM curCURSOR INTO @invTag, @sku, @L02, @L04, @L05, @loc
END
CLOSE curCURSOR
DEALLOCATE curCURSOR -- удалить из памяти
  
if object_id('tempdb..#tmpMaxInvent') is not null drop table #tmpMaxInvent
--============================================================================================
--=============================================================================================
END

