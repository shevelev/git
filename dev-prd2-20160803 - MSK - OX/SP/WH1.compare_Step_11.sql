-- =============================================
-- Author:		<KIR, Logicon.Ekaterinburg>
-- Create date: <29.12.2015>
-- =============================================
-- выбираем записи step 1. Делаем записи из физикл_дакс в [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPOST].
--  
-- =============================================
ALTER PROCEDURE [WH1].[compare_Step_11]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--================================================================================================================================
declare @iD int, @i int			-- кол-во записей в таблицах по условию в дакс. 
declare @sku varchar(50), @L02 varchar(50), @L04 varchar(50),@L05 varchar(50), @skl varchar(50), @LOT06 varchar(50)
declare @nmSku varchar(250), @intRecID bigint, @strJournal varchar(10)
declare @intLN decimal, @intLN_tmp decimal
declare @QTY_P decimal, @QTY_D decimal, @QTY_rec decimal
declare @BCS nvarchar(70) --BarCodeString			ШК из WMS Infor
declare @DTtrns datetime, @DT datetime
 
/*
Date					Текущую дату										@DT/getutcdate()
Type					1													1
ItemId					Код товара bp WMS Infor								@sku
BarCodeString			ШК из WMS Infor										@BCS nvarchar(70) /   altsku из wh1.altsku но его можно не передавать
InventLocationId		Склад из WMS Infor									skld из физикалдакс
InventSerialId			Серию из WMS Infor									lo2 susr1
ManufactureDate			Дата производства из WMS Infor						l04
ExpireDate				Срок годности из WMS Infor							l05
QtyWMS					Не заполняется										передаем '0'
Status					5
Error					Новая строка										передаем ''
TransDate				Текущую дату										@DTtrns/getutcdate
ItemName				Наименование из WMS Infor							select @nmSku = notes1 from prd2.WH1.sku where sku = '10005' варчар (250)
InventBatchId			Партия из WMS Infor									lot06!
InventQtyOnHandWMS		Инвентаризированное кол-во							sum(QTY)/ @QTY_D
InventQtyPhysicalOnHand	0													'0'
Complete				false												'0'
JournalId				Из таблицы SZ_ImpInventSumFromWMSPrev				JournalId - nvarchar(10)
LineNum					Max значение +1 в разрезе JournalId					decimal
dataAreaId				SZ
RecId					Счетчик. +1 к максимальному текущем3у значению		сами формируем bigint

a.	Склад
b.	Серия
c.	Дата производства
d.	Срок годности
e.	Партия
*/


/*Объявляем курсор*/
DECLARE curCURSOR CURSOR READ_ONLY
/*Заполняем курсор*/
FOR
select skld, susr1, susr4, susr5, LOT06, sku, sum(qty) from prd2.wh1.PHYSICAL_DAX
--where (step = 'Step 1' or step = 'Step 2: if @iP = 1 and @iD = 1( if @QTY_P < @QTY_D )') and qty > 0
where qty > 0-- and sku = '39855' and (step like 'Step 5%')
group by skld, susr1, susr4, susr5, LOT06, sku
/*Открываем курсор*/
OPEN curCURSOR
/*Выбираем первую строку*/
FETCH NEXT FROM curCURSOR INTO @skl, @L02, @L04, @L05, @LOT06, @sku, @QTY_P
/*Выполняем в цикле перебор строк*/
WHILE @@FETCH_STATUS = 0
  BEGIN

	--print ''
--print convert(varchar(30),@QTY_P)

	set @iD = 0
	
	-- @L02
	if len(@L02) = 0 or @L02 IS NULL set @L02 = 'БС'
	
	-- Даты
	if LEN(@L04) = 0 or @L04 IS NULL set @L04 = '19000101'
	if LEN(@L05) = 0 or @L05 IS NULL set @L05 = '19000101'
	
	-- наименование товара
	select top 1 @nmSku = convert(nvarchar(250),notes1) from prd2.WH1.sku where sku = @sku

	-- узнать journal
	select top 1 @strJournal = journalid from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSprev] where ItemId = @sku

	-- есть или нет товар по аналитикам в прев
	select @iD = COUNT(*) from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSprev] 
	where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = 'бс') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
	and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl and InventBatchId = @LOT06 
	
	IF @iD IS NULL SET @iD = 0
	
	SET @i = @iD		-- в цикле будем узнавать что последняя запись
	
	if @iD = 0
	  begin
		-- узнать lineNum
		select @intLN = MAX(LineNum) from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
		
		--@intLN_tmp
		select @intLN_tmp = MAX(LineNum) from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPOST]
		
		if @intLN_tmp > @intLN set @intLN = @intLN_tmp
		
		-- увеличиваем lineNum на единичку.
		set @intLN = @intLN +1
		
		-- узнать RecId
		select @intRecID = MAX(RecId) from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPOST]

		if @intRecID is null set @intRecID = 0
		set @intRecID = @intRecID +1

		insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPost] 
		(Date, Type, ItemId, BarCodeString, InventLocationId, InventSerialId, ManufactureDate, ExpireDate, QtyWMS, Status, Error, 
		TransDate, ItemName, InventBatchId, InventQtyOnHandWMS, InventQtyPhysicalOnHand, 
		Complete, JournalId, LineNum, dataAreaId, RecId)
		values
		(getutcdate(), 1, @sku, '', @skl, @L02, @L04, @L05, 0, 5, '',
		 getutcdate(), @nmSku, @LOT06, @QTY_P, 0,
		 0, @strJournal, @intLN, 'SZ', @intRecID)	
	  end
	else
	  begin
		-- тут есть записи в [SZ_ImpInventSumFromWMSPrev] в цикле перебираем по лайнумам.
--		print 'есть записи'

		/*Объявляем курсор*/
		DECLARE curCURSOR_Prev CURSOR READ_ONLY
		/*Заполняем курсор*/
		FOR
		select DATE, BarCodeString, TransDate, ItemName, InventQtyPhysicalOnHand, JournalId, LineNum
		from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
		where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = 'бс') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101')
		and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl and InventBatchId = @LOT06
		ORDER BY LineNum DESC
		/*Открываем курсор*/
		OPEN curCURSOR_Prev
		/*Выбираем первую строку*/
		FETCH NEXT FROM curCURSOR_Prev INTO @DT, @BCS, @DTtrns, @nmSku, @QTY_D, @strJournal, @intLN
		/*Выполняем в цикле перебор строк*/
		WHILE @@FETCH_STATUS = 0
		  BEGIN
			--==================================================================================================================
--print 'вошли'
--print '@QTY_P = ' + convert(varchar(30),@QTY_P)
--print '@QTY_D = ' + convert(varchar(30),@QTY_D)
--print '@iD = ' + convert(varchar(30),@iD)
--print 'sku' + @sku


			if @iD = 1 set @QTY_rec = @QTY_P

			if @iD > 1
			  begin
				if @QTY_P <= @QTY_D 
				  begin
					set @QTY_rec = @QTY_P
					set @QTY_P = 0
				  end
				else
				  begin
					-- тут от кол-ва записей. на последнию списываем все.
					if @i > 1
					  begin
						set @QTY_rec = @QTY_D
						set @QTY_P = @QTY_P - @QTY_rec
					  end
					else
					  begin
						set @QTY_rec = @QTY_P
					  end
				  end
			  end
			
--print convert(varchar(30),@QTY_rec)

			-- узнать RecId
			select @intRecID = MAX(RecId) from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPOST]

			if @intRecID is null set @intRecID = 0
			set @intRecID = @intRecID + 1

			-- сравнивание кол-в товара: в единичном варианте пишем из дакс
			
			insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPost] 
			(Date, Type, ItemId, BarCodeString, InventLocationId, InventSerialId, ManufactureDate, ExpireDate, QtyWMS, Status, Error, 
			TransDate, ItemName, InventBatchId, InventQtyOnHandWMS, InventQtyPhysicalOnHand, 
			Complete, JournalId, LineNum, dataAreaId, RecId)
			values
			(@DT, 1, @sku, @BCS, @skl, @L02, @L04, @L05, 0, 5, '',
			 @DTtrns, @nmSku, @LOT06, @QTY_rec, 0,
			 0, @strJournal, @intLN, 'SZ', @intRecID)
			
			if @QTY_P = 0 break
			set @i = @i - 1
			
			--==================================================================================================================
			FETCH NEXT FROM curCURSOR_Prev INTO @DT, @BCS, @DTtrns, @nmSku, @QTY_D, @strJournal, @intLN
		  END
		CLOSE curCURSOR_Prev
		DEALLOCATE curCURSOR_Prev -- удалить из памяти

		
		--select @DT = p.DATE, @BCS = BarCodeString, @DTtrns = TransDate, @nmSku = ItemName, @QTY_D = InventQtyOnHandWMS,
		--@strJournal = JournalId, @intLN = LineNum
		--from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev] as p
		--where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = 'бс') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
		--and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl and InventBatchId = @LOT06
	
		---- пока для примера что одна запись.
		
		---- узнать RecId
		--select @intRecID = MAX(RecId) from [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPOST]

		--if @intRecID is null set @intRecID = 0
		--set @intRecID = @intRecID +1

		---- сравнивание кол-в товара: в единичном варианте пишем из дакс
		
		--insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPost] 
		--(Date, Type, ItemId, BarCodeString, InventLocationId, InventSerialId, ManufactureDate, ExpireDate, QtyWMS, Status, Error, 
		--TransDate, ItemName, InventBatchId, InventQtyOnHandWMS, InventQtyPhysicalOnHand, 
		--Complete, JournalId, LineNum, dataAreaId, RecId)
		--values
		--(@DT, 1, @sku, @BCS, @skl, @L02, @L04, @L05, 0, 5, '',
		-- @DTtrns, @nmSku, @LOT06, @QTY_P, 0,
		-- 0, @strJournal, @intLN, 'SZ', @intRecID)			
			
	  end
	  
	FETCH NEXT FROM curCURSOR INTO @skl, @L02, @L04, @L05, @LOT06, @sku, @QTY_P
  END
CLOSE curCURSOR
DEALLOCATE curCURSOR -- удалить из памяти 




--
END

