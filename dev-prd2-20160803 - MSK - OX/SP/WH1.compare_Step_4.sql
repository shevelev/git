-- =============================================
-- Author:		<KIR, Logicon.Ekaterinburg>
-- Create date: <21.12.2015>
-- =============================================
-- ��� 4:  if @iP > 1 and @iD = 1   
-- ����� � ����� �.4 
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
declare @iP int, @iD int, @i int			-- ���-�� ������� � �������� �� ������� � ������, ���� � ���������.
declare @sku varchar(50), @L02 varchar(50), @L04 varchar(50),@L05 varchar(50), @skl varchar(50), @stp varchar(1)
declare @LOT06 varchar(50),@LOT varchar(10)	-- ��� ������������ ��������� ���06 � ��� � �����
declare @TestStep varchar(500)
declare @QTY_P decimal, @QTY_D decimal		-- ���-�� ������ � ����� � ������ ��������
declare @recQTY decimal						-- ���-�� ������ � ������ � ����� ������
declare @LOC varchar(10)

/*��������� ������*/
DECLARE curCURSORstp4 CURSOR READ_ONLY
/*��������� ������*/
FOR
select sku, susr1, susr4, susr5, skld from prd2.wh1.PHYSICALtmp
where step = 'Step 4' --and sku = '14859' 
group by sku, susr1, susr4, susr5, skld
/*��������� ������*/
OPEN curCURSORstp4
/*�������� ������ ������*/
FETCH NEXT FROM curCURSORstp4 INTO @sku, @L02, @L04, @L05, @skl
/*��������� � ����� ������� �����*/
WHILE @@FETCH_STATUS = 0
  BEGIN
	--print 'Step 4'
--==================================================================================================================
		set @TestStep = 'Step 4 if @iP > 1 and @iD = 1'
		--print '		' + @TestStep

		--�������� ��������� ���-�� � ������ � ����

		SELECT @QTY_P = sum(QTY) FROM prd2.wh1.PHYSICALtmp 
		where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl

		SELECT @QTY_D = INVENTQTYPHYSICALONHAND FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
		where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
		and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl

--print '@QTY_P = ' + convert(varchar(30),@QTY_P) 
--print '@QTY_D = ' + convert(varchar(30),@QTY_D)

		if @QTY_P < @QTY_D
		  begin
			--���������
			set @TestStep = @TestStep + '( if @QTY_P < @QTY_D )'
			
			-- � �������������� ������� ������ ���� ������ � ��������� ��������� qty �� ������ � ���06 �� ����.
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
			and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl

			--��� ����� �� ������������
			if @L02 = '��' or @L02 = '��' set @L02 = ''	
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE 
			where lottable06 = @LOT06 and (lottable04 = @L04 or lottable04 is null) and (lottable05 = @L05 or lottable05 is null) and lottable02 =@L02 and SKU = @sku
--<COMMENT> �������� �����!
/*			
			insert into prd2.wh1.PHYSICAL
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,QTY,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10 from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl
*/					
--</COMMENT> �������� �����!				
			--��������� ������ � PHYSICAL_DAX
			insert into prd2.wh1.PHYSICAL_DAX
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,QTY,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, @TestStep from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl			
			
		  end
		if @QTY_P = @QTY_D
		  begin
			--�����������
			set @TestStep = @TestStep + '( if @QTY_P = @QTY_D )'
			
			-- � �������������� ������� ������ ���� ������ � ��������� ��������� qty �� ������ � ���06 �� ����.
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
			and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl

			--��� ����� �� ������������
			if @L02 = '��' or @L02 = '��' set @L02 = ''	
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE 
			where lottable06 = @LOT06 and (lottable04 = @L04 or lottable04 is null) and (lottable05 = @L05 or lottable05 is null) and lottable02 =@L02 and SKU = @sku
--<COMMENT> �������� �����!
/*
			insert into prd2.wh1.PHYSICAL
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,QTY,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10 from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl
*/					
--</COMMENT> �������� �����!				
			--��������� ������ � PHYSICAL_DAX
			insert into prd2.wh1.PHYSICAL_DAX
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,QTY,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, @TestStep from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl		
		  end
		if @QTY_P > @QTY_D
		  begin
			--�������
			set @TestStep = @TestStep + '( if @QTY_P > @QTY_D )'
--print @TestStep
--print 'sku = ' + @sku
		
			--� �������������� ������� ������ ������ ��� � ������ � ��������� qty �� ���� � ���06 �� ����.  
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
			and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl

--print '@LOT06 = ' + @LOT06

			--��� ����� �� ������������
			if @L02 = '��' or @L02 = '��' set @L02 = ''	
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
			
			/*��������� ������*/
			DECLARE curCURSORstp41 CURSOR READ_ONLY
			/*��������� ������*/
			FOR
			select QTY,LOC from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl
			order by qty desc
			/*��������� ������*/
			OPEN curCURSORstp41
			/*�������� ������ ������*/
			FETCH NEXT FROM curCURSORstp41 INTO @QTY_P, @LOC
			/*��������� � ����� ������� �����*/
			WHILE @@FETCH_STATUS = 0
			  BEGIN
				--print '���� �� ������'
				--==================================================================================================================

--print '	��	@QTY_P = ' + convert(varchar(20),@QTY_P)
--print '	��	@QTY_D = ' + convert(varchar(20),@QTY_D)				
				if @QTY_D > @QTY_P
				  begin
					set @QTY_D = @QTY_D - @QTY_P  
				  end
				else
				  begin
				    if @QTY_D > 0
				      begin
						if @recQTY = 0 and @QTY_P > @QTY_D-- �������
--						if @recQTY = 0	-- �������
						  begin
							set @recQTY = @QTY_P - @QTY_D

							--�� �������� �������� ��������� ����� ������. ���06 ��������� ��� � ������ 3.1
							exec wh1.compare_Physical_DAX_LOT06 @sku, @LOT06 OUTPUT, @LOT OUTPUT
--<COMMENT> �������� �����!
/*
							insert into prd2.wh1.PHYSICAL
							select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@recQTY,PACKKEY,
							UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
							SUSR7,SUSR8,SUSR9,SUSR10 from prd2.wh1.PHYSICALtmp
							where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and loc = @LOC
*/					
--</COMMENT> �������� �����!								
							--��������� ������ � PHYSICAL_DAX
							insert into prd2.wh1.PHYSICAL_DAX
							select top 1 WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@recQTY,PACKKEY,
							UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
							SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, @TestStep from prd2.wh1.PHYSICALtmp
							where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and loc = @LOC
							order by qty desc				   

							--� �������������� ������� ������ ������ ��� � ������ � ��������� qty �� ���� � ���06 �� ����.  
							SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
							where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
							and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl

							--��� ����� �� ������������
							if @L02 = '��' or @L02 = '��' set @L02 = ''	
							select top 1 @LOT = LOT from WH1.LOTATTRIBUTE 
							where lottable06 = @LOT06 and (lottable04 = @L04 or lottable04 is null) and (lottable05 = @L05 or lottable05 is null) and lottable02 =@L02 and SKU = @sku
							
						  end
						
						set @QTY_P = @QTY_D
						set @QTY_D = 0
					  end
				  end
--print '	�����	@QTY_P = ' + convert(varchar(20),@QTY_P)
--print '	�����	@QTY_D = ' + convert(varchar(20),@QTY_D)
--print '	�����	@recQTY = ' + convert(varchar(20),@recQTY)	

--<COMMENT> �������� �����!
/*
				insert into prd2.wh1.PHYSICAL
				select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
				UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
				SUSR7,SUSR8,SUSR9,SUSR10 from prd2.wh1.PHYSICALtmp
				where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and loc = @LOC
*/					
--</COMMENT> �������� �����!
					
				--��������� ������ � PHYSICAL_DAX
				insert into prd2.wh1.PHYSICAL_DAX
				select top 1 WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
				UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
				SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, @TestStep from prd2.wh1.PHYSICALtmp
				where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and loc = @LOC
				--==================================================================================================================
				FETCH NEXT FROM curCURSORstp41 INTO @QTY_P, @LOC
			  END
			CLOSE curCURSORstp41
			DEALLOCATE curCURSORstp41 -- ������� �� ������
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
		  end	

--==================================================================================================================
	FETCH NEXT FROM curCURSORstp4 INTO @sku, @L02, @L04, @L05, @skl
  END
CLOSE curCURSORstp4
DEALLOCATE curCURSORstp4 -- ������� �� ������  	
--=======================================================================================================================================
--=======================================================================================================================================
END

