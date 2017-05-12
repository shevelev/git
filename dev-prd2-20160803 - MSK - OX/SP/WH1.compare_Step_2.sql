-- =============================================
-- Author:		<KIR, Logicon.Ekaterinburg>
-- Create date: <21.12.2015>
-- =============================================
-- ��� 2: if @iP = 1 and @iD = 1 
--  
-- =============================================
ALTER PROCEDURE [WH1].[compare_Step_2] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--================================================================================================================================
declare @iP int, @iD int, @i int			-- ���-�� ������� � �������� �� ������� � ������, ���� � ���������.
declare @sku varchar(50), @L02 varchar(50), @L04 varchar(50),@L05 varchar(50), @skl varchar(50), @stp varchar(1)
declare @LOT06 varchar(50),@LOT varchar(10)	-- ��� ������������ ��������� ���06 � ��� � �����
declare @TestStep varchar(500)
declare @QTY_P decimal, @QTY_D decimal		-- ���-�� ������ � ����� � ������ ��������

/*��������� ������*/
DECLARE curCURSORstp2 CURSOR READ_ONLY
/*��������� ������*/
FOR
select sku, susr1, susr4, susr5, skld from prd2.wh1.PHYSICALtmp
where step = 'Step 2'-- and sku = '10184'
/*��������� ������*/
OPEN curCURSORstp2
/*�������� ������ ������*/
FETCH NEXT FROM curCURSORstp2 INTO @sku, @L02, @L04, @L05, @skl
/*��������� � ����� ������� �����*/
WHILE @@FETCH_STATUS = 0
  BEGIN
	--print 'Step 2'
--==================================================================================================================
set @LOT = ''
		set @TestStep = 'Step 2: if @iP = 1 and @iD = 1'
--		print '		' + @TestStep		
		--�������� ��������� ���-�� � ������ � ����

		SELECT @QTY_P = QTY FROM prd2.wh1.PHYSICALtmp 
		where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl-- and LOC = @LOC

		SELECT @QTY_D = INVENTQTYPHYSICALONHAND FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
		where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
		and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl

--print '@QTY_P = ' + convert(varchar(30),@QTY_P) + ' @QTY_D = '+  convert(varchar(30), @QTY_D)	

		if @QTY_P < @QTY_D
		  begin
			--���������
			set @TestStep = @TestStep + '( if @QTY_P < @QTY_D )'
			
			-- ���06 ����� �� ����. � �������������� qty �� ������
			SELECT top 1 @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
			and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl
			
			--��� ����� �� ������������
			if LEN(@lot06)>0
				select top 1 @LOT = LOT 
				from wh1.LOTATTRIBUTE 
				where lottable06 = @LOT06 and (lottable04 = @L04 or lottable04 is null) and (lottable05 = @L05 or lottable05 is null) and lottable02 = @L02 and SKU = @sku
				order by substring(lottable06,14,8)
			else
				exec wh1.compare_Physical_DAX_LOT06 @sku, @LOT06 output, @LOT output
--<COMMENT> �������� �����!
/*
			insert into prd2.wh1.PHYSICAL
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10 from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl	
*/					
--</COMMENT> �������� �����!
			--��������� ������ � PHYSICAL_DAX
			insert into prd2.wh1.PHYSICAL_DAX
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, @TestStep from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl
						
		  end
		if @QTY_P = @QTY_D
		  begin
			--�����������
			set @TestStep = @TestStep + '( if @QTY_P = @QTY_D )'
			
			-- ���06 ����� �� ����. � �������������� qty �� ������
			SELECT top 1 @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
			and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl	
			
			--��� ����� �� ������������
			if LEN(@lot06)>0
				select top 1 @LOT = LOT 
				from wh1.LOTATTRIBUTE 
				where lottable06 = @LOT06 and (lottable04 = @L04 or lottable04 is null) and (lottable05 = @L05 or lottable05 is null) and lottable02 = @L02 and SKU = @sku
				order by substring(lottable06,14,8)
			else
				exec wh1.compare_Physical_DAX_LOT06 @sku, @LOT06 output, @LOT output
--<COMMENT> �������� �����!
/*
			insert into prd2.wh1.PHYSICAL
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10 from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl	
*/					
--</COMMENT> �������� �����!						

			--��������� ������ � PHYSICAL_DAX
			insert into prd2.wh1.PHYSICAL_DAX
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, @TestStep from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl --and lot=@lot	
		  end
		if @QTY_P > @QTY_D
		  begin
			--�������
			set @TestStep = @TestStep + '( if @QTY_P > @QTY_D )'
--print @TestStep
			--� �������������� ������� ������� qty ������ ��� � ����. ���06 ����� �� ����.  
			SELECT top 1 @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
			and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl

--print '1'
--print '@LOT06 = '	+ @LOT06		
			--��� ����� �� ������������
			if LEN(@lot06)>0
				select top 1 @LOT = LOT 
				from wh1.LOTATTRIBUTE 
				where lottable06 = @LOT06 and (lottable04 = @L04 or lottable04 is null) and (lottable05 = @L05 or lottable05 is null) and lottable02 = @L02 and SKU = @sku
				order by substring(lottable06,14,8)
			else
				exec wh1.compare_Physical_DAX_LOT06 @sku, @LOT06 output, @LOT output
--print '2'	
--print '@LOT = '	+ @LOT	

--<COMMENT> �������� �����!
/*				
			insert into prd2.wh1.PHYSICAL
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_D,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10 from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl
*/					
--</COMMENT> �������� �����!
			
			--��������� ������ � PHYSICAL_DAX
			insert into prd2.wh1.PHYSICAL_DAX
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_D,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, @TestStep from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl --and lot=@lot
							
--print '3'			
			--��������� ����� ������ ��� ���������� ������� qty. ���06 ��������� ��� � ������ 3.1
			exec wh1.compare_Physical_DAX_LOT06 @sku, @LOT06 OUTPUT, @LOT OUTPUT
--print '4'
			select @QTY_D = @QTY_P - @QTY_D
--print '@QTY_D =' + convert(varchar(20),@QTY_D)

--<COMMENT> �������� �����!
/*	
			insert into prd2.wh1.PHYSICAL
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_D,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10 from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl
*/					
--</COMMENT> �������� �����!
			insert into prd2.wh1.PHYSICAL_DAX
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_D,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, @TestStep from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl -- and lot=@lot
--print '5'						
		  end
--==================================================================================================================
	FETCH NEXT FROM curCURSORstp2 INTO @sku, @L02, @L04, @L05, @skl
  END
CLOSE curCURSORstp2
DEALLOCATE curCURSORstp2 -- ������� �� ������
--================================================================================================================================
END

