-- =============================================
-- Author:		<KIR, Logicon.Ekaterinburg>
-- Create date: <08.12.2015>
-- =============================================
-- Сопоставить количественные данные товара по партиям внутри одного 
-- склада в таблице физикл и дакс 
-- =============================================
ALTER PROCEDURE [WH1].[compare_Physical_DAX]
	@IsCopyTable varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--=============================================================================================
--	Объявления
--=============================================================================================
declare @sku varchar(50), @L02 varchar(50), @L04 varchar(50),@L05 varchar(50), @skl varchar(50) 
declare @invTag varchar(20), @LOC varchar(10)
declare @iP int, @iD int, @i int			-- кол-во записей в таблицах по условию в физикл, дакс и временная.
declare @LOT06 varchar(50),@LOT varchar(10)	-- для формирования фиктивной лот06 и лот в инфор
declare @TestStep varchar(500)				-- запишем с какого шага запись (а так же тмп стринговая).
declare @QTY_P decimal, @QTY_D decimal		-- кол-во товара в одной и другой таблицах
-- WH1.PHYSICAL - первоначальная таблица.
-- если @IsCopyTable = real, то копируем в сторонку и по окончании процедуры результирующую копирем на место PHYSICAL для постирования.
-- #tmpPHYSICAL - временная таблица копии первоначальной с добавленными полями.
-- PHYSICALtmp - временная результирующая таблица. по идее из нее постирование
--=============================================================================================
--=============================================================================================

set @i = 1

 if @IsCopyTable = 'real'
   begin
	select * into wh1.PHYSICAL_ORIGINAL from [WH1].[PHYSICAL]
   end

-- создать временную таблицу с физикл
if object_id('tempdb..#tmpPHYSICAL') is not null drop table #tmpPHYSICAL

CREATE TABLE #tmpPHYSICAL(
	[SERIALKEY] [int] IDENTITY(1,1) NOT NULL,
	[WHSEID] [varchar](30) NULL,
	[TEAM] [varchar](1) NOT NULL,
	[STORERKEY] [varchar](15) NOT NULL,
	[SKU] [varchar](50) NOT NULL,
	[LOC] [varchar](10) NOT NULL,
	[LOT] [varchar](10) NOT NULL,
	[ID] [varchar](18) NOT NULL,
	[INVENTORYTAG] [varchar](18) NOT NULL,
	[QTY] [decimal](22, 5) NOT NULL,
	[PACKKEY] [varchar](50) NULL,
	[UOM] [varchar](10) NULL,
	[STATUS] [varchar](1) NULL,
	[ADDDATE] [datetime] NOT NULL,
	[ADDWHO] [varchar](18) NOT NULL,
	[EDITDATE] [datetime] NOT NULL,
	[EDITWHO] [varchar](18) NOT NULL,
	[SUSR1] [varchar](30) NULL,
	[SUSR2] [varchar](30) NULL,
	[SUSR3] [varchar](30) NULL,
	[SUSR4] [datetime] NULL,
	[SUSR5] [datetime] NULL,
	[SUSR6] [varchar](30) NULL,
	[SUSR7] [varchar](30) NULL,
	[SUSR8] [varchar](30) NULL,
	[SUSR9] [varchar](30) NULL,
	[SUSR10] [varchar](30) NULL,
	[skld] [varchar](20) NULL,
	LOT06 [varchar](40) NULL,
	Step [varchar](500) NULL)

-- наполнить таблицу тмпфизикл данными из физикл где статус = 0
insert into #tmpPHYSICAL (WHSEID,TEAM,STORERKEY,SKU,LOC,LOT,ID,INVENTORYTAG,QTY,PACKKEY,
		UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
		SUSR7,SUSR8,SUSR9,SUSR10)
select WHSEID,TEAM,STORERKEY,SKU,LOC,LOT,ID,INVENTORYTAG,QTY,PACKKEY,
		UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
		SUSR7,SUSR8,SUSR9,SUSR10
from WH1.PHYSICAL	
where status = 0

-- заполняем поле склад
UPDATE #tmpPHYSICAL 
SET SKLD = SKLAD 
FROM #tmpPHYSICAL AS P
 join wh1.LOC loc on loc.LOC =p.loc
 join dbo.WHTOZONE w on w.zone = loc.PUTAWAYZONE
where len(p.loc)>0

-- Создадим результирующую таблицу и переносим в нее записи из физикл где товар = 0. 
-- если нет таблички - создаем пустую, если есть - удаляем данные.
if OBJECT_ID ('wh1.PHYSICALtmp') is null 
  begin
	select * into wh1.PHYSICALtmp from [WH1].[PHYSICAL] where QTY = 0
	ALTER TABLE [WH1].[PHYSICALtmp] ADD LOT06 VARCHAR(40) NULL
	ALTER TABLE [WH1].[PHYSICALtmp] ADD skld VARCHAR(20) NULL
	ALTER TABLE [WH1].[PHYSICALtmp] ADD Step VARCHAR(500) NULL	
  end
else
  begin
	delete from wh1.PHYSICALtmp
  end
  
-- временная таблица для учета макс инвентаритэг
if object_id('tempdb..#tmpMaxInvent') is not null drop table #tmpMaxInvent

CREATE TABLE #tmpMaxInvent(
	[INVENT] [varchar](18) NOT NULL,
	[SKU] [varchar](50) NOT NULL,
	[LOT] [varchar](10) NULL,
	[LOC] [varchar](10) NULL,
	[skld] [varchar](20) NULL,
	[tQTY] [decimal](22, 5) NULL)

-- наполнение макс инвентаритэг
insert into #tmpMaxInvent
select MAX(INVENTORYTAG), sku, lot, loc, skld, 0
from #tmpPHYSICAL 
where status = 0
group by sku, lot, loc, skld

update #tmpMaxInvent
set tQTY = QTY
from #tmpMaxInvent as tI, #tmpPHYSICAL as tP
where ti.SKU = tp.SKU and ti.LOT = tp.LOT and ti.LOC = tp.LOC and INVENT = INVENTORYTAG 

-- создадим курсор с полным набором по таблице #tmpMaxInvent
--===============================================================================
-- выбираем уникальные сочетания товара по полям @sku, @L02, @L04, @L05, @loc, @skl
-- далее сверяем в обоих таблицах.
--===============================================================================
/*Объявляем курсор*/
DECLARE curCURSOR CURSOR READ_ONLY
/*Заполняем курсор*/
FOR
--select INVENT, sku, susr1, susr4, susr5, loc, skld from #tmpMaxInvent
select INVENT, sku, lot, loc, skld from #tmpMaxInvent
where tQTY > 0 --sku ='10010'
/*Открываем курсор*/
OPEN curCURSOR
/*Выбираем первую строку*/
--FETCH NEXT FROM curCURSOR INTO @invTag, @sku, @L02, @L04, @L05, @loc, @skl
FETCH NEXT FROM curCURSOR INTO @invTag, @sku, @LOT, @loc, @skl
/*Выполняем в цикле перебор строк*/
WHILE @@FETCH_STATUS = 0
BEGIN
	
	select top 1 @L02 =susr1, @L04 = SUSR4, @L05 =SUSR5 from #tmpPHYSICAL where SKU = @sku and LOC = @LOC and INVENTORYTAG = @invTag and LOT = @LOT
	
	-- определяем кол-во записей  по таблицам.
	SELECT @iP = COUNT(*) FROM #tmpPHYSICAL 
	where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and INVENTORYTAG = @invTag and LOC = @LOC
	SELECT @iD = COUNT(*) FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
	where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl

print 'проход = ' + convert(varchar(2),@i) 
print '@iP = '+ convert(varchar(10),@iP) + ' @iD= ' + convert(varchar(10),@iD)
print '		SKU =' + @sku + ' @L02 ='+ @L02 +' @L04 = '+@L04+' @L05 = '+@L05+' skld = '+@skl+' loc = '+@loc+ ' @invTag = '+@invTag

	set @LOT06 = ''
--=========================================================================================================================
--	смотрим в какой раздел попали. п.1
--=========================================================================================================================
    if @iP > 0 and @iD = 0  -- излишки
      begin
		set @TestStep = 'if @iP > 0 and @iD = 0'
--		print '		' + @TestStep
		-- если лот в физикл есть, то брать лот06 из лотатрибутов
		-- если нет - надо сформировать лот06 из данных инфора

		select @LOT = LOT 
		from #tmpPHYSICAL
		where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and LOC = @LOC
--print '@LOT = ' + @LOT	
		if LEN(@LOT) > 0
			select top 1 @LOT06 = lottable06 from WH1.LOTATTRIBUTE where LOT = @LOT and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
		else
			exec wh1.compare_Physical_DAX_LOT06 @sku, @LOT06 output, @LOT output
--print '3'		
		--перенести данные в PHYSICALtmp
		insert into wh1.PHYSICALtmp
		select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,QTY,PACKKEY,
		UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
		SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
		where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and LOC = @LOC
      end
--=========================================================================================================================
--	смотрим в какой раздел попали. п.2
--=========================================================================================================================
    if @iP = 1 and @iD = 1  -- по одной записи п.2
      begin
		set @TestStep = 'if @iP = 1 and @iD = 1'
--		print '		' + @TestStep		
		--Проводим сравнение кол-ва в физикл и дакс

		SELECT @QTY_P = QTY FROM #tmpPHYSICAL 
		where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and LOC = @LOC

		SELECT @QTY_D = INVENTQTYPHYSICALONHAND FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
		where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl

--print '@QTY_P = ' + convert(varchar(30),@QTY_P) + ' @QTY_D = '+  convert(varchar(30), @QTY_D)	

		if @QTY_P < @QTY_D
		  begin
			--НЕДОСТАЧА
			set @TestStep = @TestStep + '( if @QTY_P < @QTY_D )'
			-- лот06 берем из дакс. в результирующую qty из физикл
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl
			
			--лот берем из лотатрибутов
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
			
			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC		
		  end
		if @QTY_P = @QTY_D
		  begin
			--СООТВЕТСВИЕ
			set @TestStep = @TestStep + '( if @QTY_P = @QTY_D )'
			-- лот06 берем из дакс. в результирующую qty из физикл
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl
			
			--лот берем из лотатрибутов
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
						
			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC			
		  end
		if @QTY_P > @QTY_D
		  begin
			--ИЗЛИШКИ
			set @TestStep = @TestStep + '( if @QTY_P > @QTY_D )'
--print @TestStep
			--В результирующей таблице значене qty ставим как в дакс. Лот06 берем из дакс.  
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl
--print '1'
--print '@LOT06 = '	+ @LOT06		
			--лот берем из лотатрибутов
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
--print '2'	
--print '@LOT = '	+ @LOT					
			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_D,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and LOC = @LOC	
--print '3'			
			--Формируем новую запись где записываем излишек qty. Лот06 формируем как в пункте 3.1
			exec wh1.compare_Physical_DAX_LOT06 @sku, @LOT06 OUTPUT, @LOT OUTPUT

			select @QTY_D = @QTY_P - @QTY_D

			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_D,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and LOC = @LOC		
		  end		  		
      end
--=========================================================================================================================
--	смотрим в какой раздел попали. п.3
--=========================================================================================================================
   if @iP = 1 and @iD > 1  -- одна запись ко многим п.3
      begin
		set @TestStep = 'if @iP = 1 and @iD > 1'
--		print '		' + @TestStep
		--Проводим сравнение кол-ва в физикл и суммарное значение записей qty из дакс.
		SELECT @QTY_P = QTY FROM #tmpPHYSICAL 
		where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and LOC = @LOC
		SELECT @QTY_D = SUM(INVENTQTYPHYSICALONHAND) FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
		where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl

		if @QTY_P < @QTY_D
		  begin
			--НЕДОСТАЧА
			set @TestStep = @TestStep + '( if @QTY_P < @QTY_D )'
			--=============================================================================================================
			-- В цикле организованном по кол-ву записей в дакс – проверяем кол-во qty из физикл с qty каждой записи в дакс. 
			--Если qty из физикл больше, то в результирующую таблицу пишем qty из дакс. Лот06 берем из дакс. 
			--При проходе цикла уменьшаем qty из физикл на qty из дакс. 
			--В записи где qty из физикл < qty из дакс в результирующую таблицу qty из физикл. Лот06 берем из дакс.
			--Выход из цикла при достижении qty в физикл = 0.
			--=============================================================================================================

			DECLARE Cur1 CURSOR FOR
			SELECT INVENTQTYPHYSICALONHAND, INVENTBATCHID 
			 FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			 where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and
			 EXPIREDATE= @L05 and INVENTLOCATIONID = @skl 
			order by substring(INVENTBATCHID,14,8) desc
			OPEN Cur1
			FETCH NEXT FROM Cur1 INTO @QTY_D, @LOT06
			WHILE @@FETCH_STATUS = 0
			 BEGIN

--print '@QTY_P = ' + convert(varchar(30),@QTY_P) + '@QTY_D = ' + convert(varchar(30),@QTY_D)

				if @QTY_P > @QTY_D
				  begin
					set @QTY_P = @QTY_P - @QTY_D
				  end
				else  	
				  begin
					set @QTY_D = @QTY_P
					set @QTY_P = 0
				  end
				  
				--лот берем из лотатрибутов
				select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
				  
				insert into wh1.PHYSICALtmp
				select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_D,PACKKEY,
				UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
				SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
				where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and LOC = @LOC

				if @QTY_P = 0 break
			      
				FETCH NEXT FROM Cur1 INTO @QTY_D, @LOT06
			 END
			CLOSE Cur1
			DEALLOCATE Cur1
			
		  end
		if @QTY_P = @QTY_D
		  begin
			--СООТВЕТСВИЕ
			set @TestStep = @TestStep + '( if @QTY_P = @QTY_D )'
			-- В результирующую таблицу переносим кол-во записей и данные по партиям как в таблице дакс.
----???????????????????? нормально ли что из одной записи делаем несколько, возможно с разными партиями.
--			insert into wh1.PHYSICALtmp
--			select WHSEID,TEAM,STORERKEY,SKU,LOC,LOT,ID,INVENTORYTAG,d.INVENTQTYPHYSICALONHAND,PACKKEY,
--			UOM,p.STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
--			SUSR7,SUSR8,SUSR9,SUSR10,skld, d.INVENTBATCHID, left(@TestStep ,500)
--			from #tmpPHYSICAL as p, [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev] as d
--			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and LOC = @LOC and 
--			d.itemid = SKU and INVENTSERIALID = susr1 and MANUFACTUREDATE = SUSR4 and EXPIREDATE= SUSR5 and 
--			INVENTLOCATIONID = skld
			--=============================================================================================================
			-- В цикле организованном по кол-ву записей в дакс – проверяем кол-во qty из физикл с qty каждой записи в дакс. 
			--Если qty из физикл больше, то в результирующую таблицу пишем qty из дакс. Лот06 берем из дакс. 
			--При проходе цикла уменьшаем qty из физикл на qty из дакс. 
			--В записи где qty из физикл < qty из дакс в результирующую таблицу qty из физикл. Лот06 берем из дакс.
			--Выход из цикла при достижении qty в физикл = 0.
			--=============================================================================================================

			DECLARE Cur1 CURSOR FOR
			SELECT INVENTQTYPHYSICALONHAND, INVENTBATCHID 
			 FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			 where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and
			 EXPIREDATE= @L05 and INVENTLOCATIONID = @skl 
			order by substring(INVENTBATCHID,14,8) desc
			OPEN Cur1
			FETCH NEXT FROM Cur1 INTO @QTY_D, @LOT06
			WHILE @@FETCH_STATUS = 0
			 BEGIN

--print '@QTY_P = ' + convert(varchar(30),@QTY_P) + '@QTY_D = ' + convert(varchar(30),@QTY_D)

				if @QTY_P > @QTY_D
				  begin
					set @QTY_P = @QTY_P - @QTY_D
				  end
				else  	
				  begin
					set @QTY_D = @QTY_P
					set @QTY_P = 0
				  end
				  
				--лот берем из лотатрибутов
				select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
				  
				insert into wh1.PHYSICALtmp
				select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_D,PACKKEY,
				UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
				SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
				where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and LOC = @LOC

				if @QTY_P = 0 break
			      
				FETCH NEXT FROM Cur1 INTO @QTY_D, @LOT06
			 END
			CLOSE Cur1
			DEALLOCATE Cur1
			
		  end
		if @QTY_P > @QTY_D
		  begin
			--ИЗЛИШКИ
			set @TestStep = @TestStep + '( if @QTY_P > @QTY_D )'

			--лот берем из лотатрибутов
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
				
			--В результирующую таблицу переносим кол-во записей и данные по партиям как в таблице дакс. 
			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,d.INVENTQTYPHYSICALONHAND,PACKKEY,
			UOM,p.STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, d.INVENTBATCHID, left(@TestStep,500)
			from #tmpPHYSICAL as p, [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev] as d
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and LOC = @LOC and 
			d.itemid = SKU and INVENTSERIALID = susr1 and MANUFACTUREDATE = SUSR4 and EXPIREDATE= SUSR5 and 
			INVENTLOCATIONID = skld			
			
			--На величину излишков формируем новую запись. Лот06 формируем как в пункте 3.1.  
			exec wh1.compare_Physical_DAX_LOT06 @sku, @LOT06 OUTPUT, @LOT OUTPUT

			select @QTY_D = @QTY_P - @QTY_D

			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_D,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC	
			
		  end		  		
      end
--=========================================================================================================================
--	смотрим в какой раздел попали. п.4
--=========================================================================================================================
    if @iP > 1 and @iD = 1  -- много к одной п.4
      begin
		set @TestStep = 'if @iP > 1 and @iD = 1'
--		print '		' + @TestStep
		--Проводим сравнение суммарного кол-ва в физикл и qty из дакс.
		SELECT @QTY_P = SUM(QTY) FROM #tmpPHYSICAL 
		where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC
		SELECT @QTY_D = INVENTQTYPHYSICALONHAND FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
		where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl

		if @QTY_P < @QTY_D
		  begin
			--НЕДОСТАЧА
			set @TestStep = @TestStep + '( if @QTY_P < @QTY_D )'
			-- В результирующую таблицу делаем ОДНУ запись с суммарным значением qty из физикл и лот06 из дакс.
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl

			--лот берем из лотатрибутов
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
			
			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC	
		  end
		if @QTY_P = @QTY_D
		  begin
			--СООТВЕТСВИЕ
			set @TestStep = @TestStep + '( if @QTY_P = @QTY_D )'
			-- В результирующую таблицу делаем ОДНУ запись с суммарным значением qty из физикл и лот06 из дакс.
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl

			--лот берем из лотатрибутов
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
			
			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC		
		  end
		if @QTY_P > @QTY_D
		  begin
			--ИЗЛИШКИ
			set @TestStep = @TestStep + '( if @QTY_P > @QTY_D )'
			--В результирующую таблицу делаем ОДНУ запись с значением qty из дакс и лот06 из дакс.  
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl

			--лот берем из лотатрибутов
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
			
			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_D,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC		
			
			--На величину излишков формируем новую запись. Лот06 формируем как в пункте 3.1
			exec wh1.compare_Physical_DAX_LOT06 @sku, @LOT06 OUTPUT, @LOT OUTPUT

			select @QTY_D = @QTY_P - @QTY_D

			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_D,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC
		  end	
      end
--=========================================================================================================================
--	смотрим в какой раздел попали. п.5
--=========================================================================================================================
    if @iP > 1 and @iD > 1  -- много ко много п.5
      begin
		set @TestStep = 'if @iP > 1 and @iD > 1'
--		print '		' + @TestStep		
		--Проводим сравнение суммарного кол-ва в физикл и суммарное значение записей qty из дакс.
		SELECT @QTY_P = SUM(QTY) FROM #tmpPHYSICAL 
		where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl 
		SELECT @QTY_D = SUM(INVENTQTYPHYSICALONHAND) FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
		where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl

		if @QTY_P <= @QTY_D
		  begin
			--НЕДОСТАЧА
			set @TestStep = @TestStep + '( if @QTY_P < @QTY_D )'
			--=============================================================================================================
			-- В цикле организованном по кол-ву записей в дакс – проверяем суммарную qty из физикл с qty каждой записи в дакс. 
			--Если qty из физикл больше, то в результирующую таблицу пишем qty из дакс. Лот06 берем из дакс. 
			--При проходе цикла уменьшаем qty из физикл на qty из дакс. 
			--В записи где qty из физикл < qty из дакс в результирующую таблицу qty из физикл. Лот06 берем из дакс.
			--Выход из цикла при достижении qty в физикл = 0.
			--=============================================================================================================
print '@QTY_P = ' + convert(varchar(30),@QTY_P) + '@QTY_D = ' + convert(varchar(30),@QTY_D)

			DECLARE Cur2 CURSOR FOR
			SELECT INVENTQTYPHYSICALONHAND, INVENTBATCHID 
			FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and
			EXPIREDATE= @L05 and INVENTLOCATIONID = @skl order by substring(INVENTBATCHID,14,8) desc
			OPEN Cur2
			FETCH NEXT FROM Cur2 INTO @QTY_D, @LOT06
			WHILE @@FETCH_STATUS = 0
			 BEGIN

				if @QTY_P > @QTY_D
				  begin
					set @QTY_P = @QTY_P - @QTY_D
				  end
				else		  	
				if @QTY_P <= @QTY_D
				  begin
					set @QTY_D = @QTY_P
					set @QTY_P = 0
				  end
--print '@QTY_P = ' + convert(varchar(30),@QTY_P) + '@QTY_D = ' + convert(varchar(30),@QTY_D)				  

				--лот берем из лотатрибутов
				select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02

				insert into wh1.PHYSICALtmp
				select top 1 WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_D,PACKKEY,
				UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
				SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
				where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC

				if @QTY_P = 0 break
			      
				FETCH NEXT FROM Cur2 INTO @QTY_D, @LOT06
			 END
			CLOSE Cur2
			DEALLOCATE Cur2
		  end
		  
		if @QTY_P = @QTY_D
		  begin
			--СООТВЕТСВИЕ
			set @TestStep = @TestStep + '( if @QTY_P = @QTY_D )'
			-- В результирующую таблицу переносим кол-во записей и данные по партиям как в таблице дакс.
print '@QTY_P = ' + convert(varchar(30),@QTY_P) + '@QTY_D = ' + convert(varchar(30),@QTY_D)

			--=============================================================================================================
			-- В цикле организованном по кол-ву записей в дакс – проверяем суммарную qty из физикл с qty каждой записи в дакс. 
			--Если qty из физикл больше, то в результирующую таблицу пишем qty из дакс. Лот06 берем из дакс. 
			--При проходе цикла уменьшаем qty из физикл на qty из дакс. 
			--В записи где qty из физикл < qty из дакс в результирующую таблицу qty из физикл. Лот06 берем из дакс.
			--Выход из цикла при достижении qty в физикл = 0 по идее это будет в последнем проходе.
			--=============================================================================================================		
			DECLARE Cur2 CURSOR FOR
			SELECT INVENTQTYPHYSICALONHAND, INVENTBATCHID 
			FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and
			EXPIREDATE= @L05 and INVENTLOCATIONID = @skl order by substring(INVENTBATCHID,14,8) desc
			OPEN Cur2
			FETCH NEXT FROM Cur2 INTO @QTY_D, @LOT06
			WHILE @@FETCH_STATUS = 0
			 BEGIN

				if @QTY_P > @QTY_D
				  begin
					set @QTY_P = @QTY_P - @QTY_D
				  end
				else		  	
				if @QTY_P <= @QTY_D
				  begin
					set @QTY_D = @QTY_P
					set @QTY_P = 0
				  end
--print '@QTY_P = ' + convert(varchar(30),@QTY_P) + '@QTY_D = ' + convert(varchar(30),@QTY_D)				  

				--лот берем из лотатрибутов
				select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02

				insert into wh1.PHYSICALtmp
				select top 1 WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_D,PACKKEY,
				UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
				SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
				where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC

				if @QTY_P = 0 break
			      
				FETCH NEXT FROM Cur2 INTO @QTY_D, @LOT06
			 END
			CLOSE Cur2
			DEALLOCATE Cur2
		  end
		  
		if @QTY_P > @QTY_D
		  begin
			--ИЗЛИШКИ
			set @TestStep = @TestStep + '( if @QTY_P > @QTY_D )'
			----В результирующую таблицу переносим кол-во записей и данные по партиям как в таблице дакс. 
			--=============================================================================================================
			-- В цикле организованном по кол-ву записей в дакс – проверяем суммарную qty из физикл с qty каждой записи в дакс. 
			--Если qty из физикл больше, то в результирующую таблицу пишем qty из дакс. Лот06 берем из дакс. 
			--При проходе цикла уменьшаем qty из физикл на qty из дакс. 
			--В записи где qty из физикл < qty из дакс в результирующую таблицу qty из физикл. Лот06 берем из дакс.
			--=============================================================================================================		
			DECLARE Cur2 CURSOR FOR
			SELECT INVENTQTYPHYSICALONHAND, INVENTBATCHID 
			FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and
			EXPIREDATE= @L05 and INVENTLOCATIONID = @skl order by substring(INVENTBATCHID,14,8) desc
			OPEN Cur2
			FETCH NEXT FROM Cur2 INTO @QTY_D, @LOT06
			WHILE @@FETCH_STATUS = 0
			 BEGIN

				set @QTY_P = @QTY_P - @QTY_D

--print '@QTY_P = ' + convert(varchar(30),@QTY_P) + '@QTY_D = ' + convert(varchar(30),@QTY_D)	

				--лот берем из лотатрибутов
				select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
			  
				insert into wh1.PHYSICALtmp
				select top 1 WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_D,PACKKEY,
				UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
				SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
				where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC
			      
				FETCH NEXT FROM Cur2 INTO @QTY_D, @LOT06
			 END
			CLOSE Cur2
			DEALLOCATE Cur2

			--На величину излишков формируем новую запись. Лот06 формируем как в пункте 3.1.  
			exec wh1.compare_Physical_DAX_LOT06 @sku, @LOT06 OUTPUT, @LOT OUTPUT

--			select @QTY_D = @QTY_P - @QTY_D

			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC
		  end
      end
----------------------------------------------

print 'проход END'
print ''
select @i = @i+1 

--FETCH NEXT FROM curCURSOR INTO @invTag, @sku, @L02, @L04, @L05, @loc, @skl
FETCH NEXT FROM curCURSOR INTO @invTag, @sku, @LOT, @loc, @skl
END
CLOSE curCURSOR
DEALLOCATE curCURSOR -- удалить из памяти

-- наполнить таблицу тмпфизикл данными из физикл где товар = 0 и статус = 0
/*insert into #tmpPHYSICAL (WHSEID,TEAM,STORERKEY,SKU,LOC,LOT,ID,INVENTORYTAG,QTY,PACKKEY,
		UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
		SUSR7,SUSR8,SUSR9,SUSR10)
select WHSEID,TEAM,STORERKEY,SKU,LOC,LOT,ID,INVENTORYTAG,QTY,PACKKEY,
		UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
		SUSR7,SUSR8,SUSR9,SUSR10
from WH1.PHYSICAL	
where qty = 0 and status = 0
*/

 if @IsCopyTable = 'real'
   begin
	delete from wh1.PHYSICAL
	
	insert into WH1.PHYSICAL (WHSEID,TEAM,STORERKEY,SKU,LOC,LOT,ID,INVENTORYTAG,QTY,PACKKEY,
		UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
		SUSR7,SUSR8,SUSR9,SUSR10)
	select WHSEID,TEAM,STORERKEY,SKU,LOC,LOT,ID,INVENTORYTAG,QTY,PACKKEY,
		UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
		SUSR7,SUSR8,SUSR9,SUSR10
	from wh1.PHYSICALtmp	
   end

--=============================================================================================
--=============================================================================================
	SET NOCOUNT OFF;
END

