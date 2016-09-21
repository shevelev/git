-- =============================================
-- Author:		<KIR, Logicon.Ekaterinburg>
-- Create date: <21.12.2015>
-- =============================================
-- выбираем записи step 1. ƒелаем записи дл€ физикл и физикл_дакс.
--  
-- =============================================
ALTER PROCEDURE [WH1].[compare_Step_1] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @iP int, @iD int, @i int			-- кол-во записей в таблицах по условию в физикл, дакс и временна€.
declare @sku varchar(50), @L02 varchar(50), @L04 varchar(50),@L05 varchar(50), @skl varchar(50), @stp varchar(1)
declare @LOT06 varchar(50),@LOT varchar(10)	-- дл€ формировани€ фиктивной лот06 и лот в инфор
declare @LOC varchar(10)
declare @QTY_P decimal

/*ќбъ€вл€ем курсор*/
DECLARE curCURSOR CURSOR READ_ONLY
/*«аполн€ем курсор*/
FOR
select sku, susr1, susr4, susr5, skld,LOC,LOT,qty from prd2.wh1.PHYSICALtmp
where step = 'Step 1'
group by sku, susr1, susr4, susr5, skld,LOC,LOT,qty
/*ќткрываем курсор*/
OPEN curCURSOR
/*¬ыбираем первую строку*/
FETCH NEXT FROM curCURSOR INTO @sku, @L02, @L04, @L05, @skl, @LOC, @LOT, @QTY_P
/*¬ыполн€ем в цикле перебор строк*/
WHILE @@FETCH_STATUS = 0
  BEGIN
	
		--select @LOT = LOT 
		--from prd2.wh1.PHYSICALtmp
		--where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl
		
--print '@LOT = ' + @LOT
	
		if LEN(@LOT) > 0
			select top 1 @LOT06 = lottable06 
			from WH1.LOTATTRIBUTE 
			where LOT = @LOT and (lottable04 = @L04 or lottable04 is null) and (lottable05 = @L05 or lottable05 is null) and lottable02 =@L02 and SKU = @sku
			order by substring(lottable06,14,8)
		else
			exec wh1.compare_Physical_DAX_LOT06 @sku, @LOT06 output, @LOT output
--print '@LOT06 = ' + @LOT06	 	
		--перенести данные в PHYSICAL
--<COMMENT>
/*	
		insert into prd2.wh1.PHYSICAL
		select WHSEID,TEAM,STORERKEY,SKU,@LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
		UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
		SUSR7,SUSR8,SUSR9,SUSR10 from prd2.wh1.PHYSICALtmp
		where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and lot=@LOT and loc =@loc and qty = @QTY_P
*/
--</COMMENT>
		--перенести данные в PHYSICAL_DAX
		insert into prd2.wh1.PHYSICAL_DAX
		select WHSEID,TEAM,STORERKEY,SKU,@LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
		UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
		SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, 'Step 1' from prd2.wh1.PHYSICALtmp
--		where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and lot=@LOT and loc =@loc and qty = @QTY_P
		where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and lot=@LOT and loc =@loc and qty = @QTY_P

	FETCH NEXT FROM curCURSOR INTO @sku, @L02, @L04, @L05, @skl, @LOC, @LOT, @QTY_P
  END
CLOSE curCURSOR
DEALLOCATE curCURSOR -- удалить из пам€ти 
END

