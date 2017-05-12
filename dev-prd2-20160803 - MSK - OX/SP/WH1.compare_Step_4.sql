-- =============================================
-- Author:		<KIR, Logicon.Ekaterinburg>
-- Create date: <21.12.2015>
-- =============================================
-- Шаг 4:  if @iP > 1 and @iD = 1   
-- много к одной п.4 
-- =============================================
ALTER PROCEDURE [WH1].[compare_Step_4]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--=======================================================================================================================================
--=======================================================================================================================================
	--print '4: if @iP > 1 and @iD = 1'
declare @iP int, @iD int, @i int			-- кол-во записей в таблицах по условию в физикл, дакс и временная.
declare @sku varchar(50), @L02 varchar(50), @L04 varchar(50),@L05 varchar(50), @skl varchar(50), @stp varchar(1)
declare @LOT06 varchar(50),@LOT varchar(10)	-- для формирования фиктивной лот06 и лот в инфор
declare @TestStep varchar(500)
declare @QTY_P decimal, @QTY_D decimal		-- кол-во товара в одной и другой таблицах
declare @recQTY decimal						-- кол-во товара в физикл в одной записи
declare @LOC varchar(10)

/*Объявляем курсор*/
DECLARE curCURSORstp4 CURSOR READ_ONLY
/*Заполняем курсор*/
FOR
select sku, susr1, susr4, susr5, skld from prd2.wh1.PHYSICALtmp
where step = 'Step 4' --and sku = '14859' 
group by sku, susr1, susr4, susr5, skld
/*Открываем курсор*/
OPEN curCURSORstp4
/*Выбираем первую строку*/
FETCH NEXT FROM curCURSORstp4 INTO @sku, @L02, @L04, @L05, @skl
/*Выполняем в цикле перебор строк*/
WHILE @@FETCH_STATUS = 0
  BEGIN
	--print 'Step 4'
--==================================================================================================================
		set @TestStep = 'Step 4 if @iP > 1 and @iD = 1'
		--print '		' + @TestStep

		--Проводим сравнение кол-ва в физикл и дакс

		SELECT @QTY_P = sum(QTY) FROM prd2.wh1.PHYSICALtmp 
		where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl

		SELECT @QTY_D = INVENTQTYPHYSICALONHAND FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
		where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = 'бс') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
		and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl

--print '@QTY_P = ' + convert(varchar(30),@QTY_P) 
--print '@QTY_D = ' + convert(varchar(30),@QTY_D)

		if @QTY_P < @QTY_D
		  begin
			--НЕДОСТАЧА
			set @TestStep = @TestStep + '( if @QTY_P < @QTY_D )'
			
			-- В результирующую таблицу делаем ОДНУ запись с суммарным значением qty из физикл и лот06 из дакс.
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = 'бс') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
			and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl

			--лот берем из лотатрибутов
			if @L02 = 'бс' or @L02 = 'БС' set @L02 = ''	
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE 
			where lottable06 = @LOT06 and (lottable04 = @L04 or lottable04 is null) and (lottable05 = @L05 or lottable05 is null) and lottable02 =@L02 and SKU = @sku
--<COMMENT> поменять схему!
/*			
			insert into prd2.wh1.PHYSICAL
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,QTY,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10 from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl
*/					
--</COMMENT> поменять схему!				
			--перенести данные в PHYSICAL_DAX
			insert into prd2.wh1.PHYSICAL_DAX
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,QTY,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, @TestStep from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl			
			
		  end
		if @QTY_P = @QTY_D
		  begin
			--СООТВЕТСВИЕ
			set @TestStep = @TestStep + '( if @QTY_P = @QTY_D )'
			
			-- В результирующую таблицу делаем ОДНУ запись с суммарным значением qty из физикл и лот06 из дакс.
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = 'бс') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
			and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl

			--лот берем из лотатрибутов
			if @L02 = 'бс' or @L02 = 'БС' set @L02 = ''	
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE 
			where lottable06 = @LOT06 and (lottable04 = @L04 or lottable04 is null) and (lottable05 = @L05 or lottable05 is null) and lottable02 =@L02 and SKU = @sku
--<COMMENT> поменять схему!
/*
			insert into prd2.wh1.PHYSICAL
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,QTY,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10 from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl
*/					
--</COMMENT> поменять схему!				
			--перенести данные в PHYSICAL_DAX
			insert into prd2.wh1.PHYSICAL_DAX
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,QTY,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, @TestStep from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl		
		  end
		if @QTY_P > @QTY_D
		  begin
			--ИЗЛИШКИ
			set @TestStep = @TestStep + '( if @QTY_P > @QTY_D )'
--print @TestStep
--print 'sku = ' + @sku
		
			--В результирующую таблицу делаем записи как в физикл с значением qty из дакс и лот06 из дакс.  
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = 'бс') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
			and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl

--print '@LOT06 = ' + @LOT06

			--лот берем из лотатрибутов
			if @L02 = 'бс' or @L02 = 'БС' set @L02 = ''	
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE 
			where lottable06 = @LOT06 and (lottable04 = @L04 or lottable04 is null) and (lottable05 = @L05 or lottable05 is null) and lottable02 =@L02 and SKU = @sku
--print '@LOT = ' + @LOT
--print @TestStep
--print '@LOT06 = ' + @LOT06 
--print 'lottable02 = ' + @L02
--print 'lottable04 = ' + @L04
--print 'lottable05 = ' + @L05
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
			set @recQTY = 0
			
			/*Объявляем курсор*/
			DECLARE curCURSORstp41 CURSOR READ_ONLY
			/*Заполняем курсор*/
			FOR
			select QTY,LOC from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl
			order by qty desc
			/*Открываем курсор*/
			OPEN curCURSORstp41
			/*Выбираем первую строку*/
			FETCH NEXT FROM curCURSORstp41 INTO @QTY_P, @LOC
			/*Выполняем в цикле перебор строк*/
			WHILE @@FETCH_STATUS = 0
			  BEGIN
				--print 'цикл по физикл'
				--==================================================================================================================

--print '	до	@QTY_P = ' + convert(varchar(20),@QTY_P)
--print '	до	@QTY_D = ' + convert(varchar(20),@QTY_D)				
				if @QTY_D > @QTY_P
				  begin
					set @QTY_D = @QTY_D - @QTY_P  
				  end
				else
				  begin
				    if @QTY_D > 0
				      begin
						if @recQTY = 0 and @QTY_P > @QTY_D-- излишки
--						if @recQTY = 0	-- излишки
						  begin
							set @recQTY = @QTY_P - @QTY_D

							--На величину излишков формируем новую запись. Лот06 формируем как в пункте 3.1
							exec wh1.compare_Physical_DAX_LOT06 @sku, @LOT06 OUTPUT, @LOT OUTPUT
--<COMMENT> поменять схему!
/*
							insert into prd2.wh1.PHYSICAL
							select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@recQTY,PACKKEY,
							UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
							SUSR7,SUSR8,SUSR9,SUSR10 from prd2.wh1.PHYSICALtmp
							where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and loc = @LOC
*/					
--</COMMENT> поменять схему!								
							--перенести данные в PHYSICAL_DAX
							insert into prd2.wh1.PHYSICAL_DAX
							select top 1 WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@recQTY,PACKKEY,
							UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
							SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, @TestStep from prd2.wh1.PHYSICALtmp
							where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and loc = @LOC
							order by qty desc				   

							--В результирующую таблицу делаем записи как в физикл с значением qty из дакс и лот06 из дакс.  
							SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
							where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = 'бс') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
							and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl

							--лот берем из лотатрибутов
							if @L02 = 'бс' or @L02 = 'БС' set @L02 = ''	
							select top 1 @LOT = LOT from WH1.LOTATTRIBUTE 
							where lottable06 = @LOT06 and (lottable04 = @L04 or lottable04 is null) and (lottable05 = @L05 or lottable05 is null) and lottable02 =@L02 and SKU = @sku
							
						  end
						
						set @QTY_P = @QTY_D
						set @QTY_D = 0
					  end
				  end
--print '	после	@QTY_P = ' + convert(varchar(20),@QTY_P)
--print '	после	@QTY_D = ' + convert(varchar(20),@QTY_D)
--print '	после	@recQTY = ' + convert(varchar(20),@recQTY)	

--<COMMENT> поменять схему!
/*
				insert into prd2.wh1.PHYSICAL
				select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
				UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
				SUSR7,SUSR8,SUSR9,SUSR10 from prd2.wh1.PHYSICALtmp
				where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and loc = @LOC
*/					
--</COMMENT> поменять схему!
					
				--перенести данные в PHYSICAL_DAX
				insert into prd2.wh1.PHYSICAL_DAX
				select top 1 WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
				UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
				SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, @TestStep from prd2.wh1.PHYSICALtmp
				where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and loc = @LOC
				--==================================================================================================================
				FETCH NEXT FROM curCURSORstp41 INTO @QTY_P, @LOC
			  END
			CLOSE curCURSORstp41
			DEALLOCATE curCURSORstp41 -- удалить из памяти
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
		  end	

--==================================================================================================================
	FETCH NEXT FROM curCURSORstp4 INTO @sku, @L02, @L04, @L05, @skl
  END
CLOSE curCURSORstp4
DEALLOCATE curCURSORstp4 -- удалить из памяти  	
--=======================================================================================================================================
--=======================================================================================================================================
END

