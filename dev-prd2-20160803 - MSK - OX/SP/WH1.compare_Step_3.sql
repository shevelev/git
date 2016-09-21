-- =============================================
-- Author:		<KIR, Logicon.Ekaterinburg>
-- Create date: <21.12.2015>
-- =============================================
-- ��� 3: if @iP = 1 and @iD > 1 
-- ���� ������ �� ������ �.3 
-- =============================================
ALTER PROCEDURE [WH1].[compare_Step_3]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--=======================================================================================================================================
	--print '3: if @iP = 1 and @iD > 1-- ���� ������ �� ������ �.3'
declare @iP int, @iD int, @i int			-- ���-�� ������� � �������� �� ������� � ������, ���� � ���������.
declare @sku varchar(50), @L02 varchar(50), @L04 varchar(50),@L05 varchar(50), @skl varchar(50), @stp varchar(1)
declare @LOT06 varchar(50),@LOT varchar(10)	-- ��� ������������ ��������� ���06 � ��� � �����
declare @TestStep varchar(500)
declare @QTY_P decimal, @QTY_D decimal		-- ���-�� ������ � ����� � ������ ��������


/*��������� ������*/
DECLARE curCURSORstp3 CURSOR READ_ONLY
/*��������� ������*/
FOR
select sku, susr1, susr4, susr5, skld from prd2.wh1.PHYSICALtmp
where step = 'Step 3' --and sku = '49169'
/*��������� ������*/
OPEN curCURSORstp3
/*�������� ������ ������*/
FETCH NEXT FROM curCURSORstp3 INTO @sku, @L02, @L04, @L05, @skl
/*��������� � ����� ������� �����*/
WHILE @@FETCH_STATUS = 0
  BEGIN
	--print 'Step 3'
--==================================================================================================================
		set @TestStep = 'Step 3 if @iP = 1 and @iD > 1'
--		print '		' + @TestStep

		--�������� ��������� ���-�� � ������ � ����

		SELECT @QTY_P = QTY FROM prd2.wh1.PHYSICALtmp 
		where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl-- and LOC = @LOC

		--���� ����� �� qty
		SELECT @QTY_D = sum(INVENTQTYPHYSICALONHAND) FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
		where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
		and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl
		
--print '@QTY_P = ' + convert(varchar(30),@QTY_P) + '@QTY_D = ' + convert(varchar(30),@QTY_D)

		if @QTY_P < @QTY_D
		  begin
			--���������
			set @TestStep = @TestStep + '( if @QTY_P < @QTY_D )'
			--=============================================================================================================
			-- � ����� �������������� �� ���-�� ������� � ���� � ��������� ���-�� qty �� ������ � qty ������ ������ � ����. 
			--���� qty �� ������ ������, �� � �������������� ������� ����� qty �� ����. ���06 ����� �� ����. 
			--��� ������� ����� ��������� qty �� ������ �� qty �� ����. 
			--� ������ ��� qty �� ������ < qty �� ���� � �������������� ������� qty �� ������. ���06 ����� �� ����.
			--����� �� ����� ��� ���������� qty � ������ = 0.
			--=============================================================================================================

			DECLARE Cur1 CURSOR FOR
			SELECT itemid, INVENTSERIALID, MANUFACTUREDATE, EXPIREDATE, INVENTLOCATIONID --INVENTQTYPHYSICALONHAND, INVENTBATCHID 
			 FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			 where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
			 and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl
			 group by itemid, INVENTSERIALID, MANUFACTUREDATE, EXPIREDATE, INVENTLOCATIONID
--			 order by substring(INVENTBATCHID,14,8) desc
			OPEN Cur1
			FETCH NEXT FROM Cur1 INTO @sku, @L02, @L04, @L05, @skl  ---@QTY_D, @LOT06
			WHILE @@FETCH_STATUS = 0
			 BEGIN
				
				SELECT @QTY_D = sum(INVENTQTYPHYSICALONHAND) FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
				where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
				and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl 

				SELECT top 1 @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
				where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
				and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl 

				if @QTY_P > @QTY_D
				  begin
					set @QTY_P = @QTY_P - @QTY_D
				  end
				else  	
				  begin
					set @QTY_D = @QTY_P
					set @QTY_P = 0
				  end
				
				if @L02 = '��' or @L02 = '��' set @L02 = ''		  
				--��� ����� �� ������������
				select top 1 @LOT = LOT from WH1.LOTATTRIBUTE 
				where lottable06 = @LOT06 and (lottable04 = @L04 or lottable04 is null) and (lottable05 = @L05 or lottable05 is null) and lottable02 =@L02 and SKU = @sku
				
--print '���������'
--print '@L02 = ' + @L02
--print '@LOT06 = ' + @LOT06 
--print '@LOT = ' + @LOT
--print 'lottable04 = ' + @L04
--print 'lottable05 = ' + @L05				
				
				
--if @LOT is null print 'SKU =' + @sku + '@LOT06 = ' + @LOT06 + '@QTY_P < @QTY_D'

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
				where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl				

				if @QTY_P = 0 break
			      
				FETCH NEXT FROM Cur1 INTO @sku, @L02, @L04, @L05, @skl   --@QTY_D, @LOT06
			 END
			CLOSE Cur1
			DEALLOCATE Cur1
			
		  end
		if @QTY_P = @QTY_D
		  begin
			--�����������
			set @TestStep = @TestStep + '( if @QTY_P = @QTY_D )'
			-- � �������������� ������� ��������� ���-�� ������� � ������ �� ������� ��� � ������� ����.
			--=============================================================================================================
			-- � ����� �������������� �� ���-�� ������� � ���� � ��������� ���-�� qty �� ������ � qty ������ ������ � ����. 
			--���� qty �� ������ ������, �� � �������������� ������� ����� qty �� ����. ���06 ����� �� ����. 
			--��� ������� ����� ��������� qty �� ������ �� qty �� ����. 
			--� ������ ��� qty �� ������ < qty �� ���� � �������������� ������� qty �� ������. ���06 ����� �� ����.
			--����� �� ����� ��� ���������� qty � ������ = 0.
			--=============================================================================================================

			DECLARE Cur1 CURSOR FOR
			SELECT itemid, INVENTSERIALID, MANUFACTUREDATE, EXPIREDATE, INVENTLOCATIONID --INVENTQTYPHYSICALONHAND, INVENTBATCHID 
			 FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			 where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
			 and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl
			 group by itemid, INVENTSERIALID, MANUFACTUREDATE, EXPIREDATE, INVENTLOCATIONID
--			 order by substring(INVENTBATCHID,14,8) desc
			OPEN Cur1
			FETCH NEXT FROM Cur1 INTO  @sku, @L02, @L04, @L05, @skl  --@QTY_D, @LOT06
			WHILE @@FETCH_STATUS = 0
			 BEGIN

				SELECT @QTY_D = sum(INVENTQTYPHYSICALONHAND) FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
				where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
				and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl 

				SELECT top 1 @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
				where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
				and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl 

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
 
				if @L02 = '��' or @L02 = '��' set @L02 = ''				  
				--��� ����� �� ������������
				select top 1 @LOT = LOT from WH1.LOTATTRIBUTE 
				where lottable06 = @LOT06 and (lottable04 = @L04 or lottable04 is null) and (lottable05 = @L05 or lottable05 is null) and lottable02 =@L02 and SKU = @sku
				
--print @TestStep
--print '@LOT06 = ' + @LOT06 
--print '@LOT = ' + @LOT
--print 'lottable02 = ' + @L02
--print 'lottable04 = ' + @L04
--print 'lottable05 = ' + @L05				
--if @LOT is null print 'SKU =' + @sku + '@LOT06 = ' + @LOT06 + '@QTY_P = @QTY_D'

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
				where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl

				if @QTY_P = 0 break
			      
				FETCH NEXT FROM Cur1 INTO  @sku, @L02, @L04, @L05, @skl  --@QTY_D, @LOT06
			 END
			CLOSE Cur1
			DEALLOCATE Cur1
			
		  end
		if @QTY_P > @QTY_D
		  begin
			--�������
			set @TestStep = @TestStep + '( if @QTY_P > @QTY_D )'
--print 'SKU = ' + @SKU
			--=============================================================================================================
			-- � ����� �������������� �� ���-�� ������� � ���� � ��������� ��������� qty �� ������ � qty ������ ������ � ����. 
			--���� qty �� ������ ������, �� � �������������� ������� ����� qty �� ����. ���06 ����� �� ����. 
			--��� ������� ����� ��������� qty �� ������ �� qty �� ����. 
			--� ������ ��� qty �� ������ < qty �� ���� � �������������� ������� qty �� ������. ���06 ����� �� ����.
			--=============================================================================================================
----------------------------------------------------------------------------------------------------------------------------------------------------------------
			DECLARE Cur1 CURSOR FOR
			SELECT itemid, INVENTSERIALID, MANUFACTUREDATE, EXPIREDATE, INVENTLOCATIONID --INVENTQTYPHYSICALONHAND, INVENTBATCHID 
			 FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			 where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
			 and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl
			 group by itemid, INVENTSERIALID, MANUFACTUREDATE, EXPIREDATE, INVENTLOCATIONID
--			 order by substring(INVENTBATCHID,14,8) desc
			OPEN Cur1
			FETCH NEXT FROM Cur1 INTO @sku, @L02, @L04, @L05, @skl  --@QTY_D, @LOT06
			WHILE @@FETCH_STATUS = 0
			 BEGIN

				SELECT @QTY_D = sum(INVENTQTYPHYSICALONHAND) FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
				where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
				and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl 

				SELECT top 1 @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
				where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
				and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl 

--print '@QTY_P = ' + convert(varchar(30),@QTY_P) + '@QTY_D = ' + convert(varchar(30),@QTY_D)

				set @QTY_P = @QTY_P - @QTY_D
				  
				if @L02 = '��' or @L02 = '��' set @L02 = ''
				--��� ����� �� ������������
				select top 1 @LOT = LOT from WH1.LOTATTRIBUTE 
				where lottable06 = @LOT06 and (lottable04 = @L04 or lottable04 is null) and (lottable05 = @L05 or lottable05 is null) and lottable02 =@L02 and SKU = @sku

--print @TestStep
--print '@LOT06 = ' + @LOT06 
--print 'lottable02 = ' + @L02
--print 'lottable04 = ' + @L04
--print 'lottable05 = ' + @L05
				
--if @LOT is null print 'SKU =' + @sku + '@LOT06 = ' + @LOT06 + '@QTY_P = @QTY_D'

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
				where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl

				FETCH NEXT FROM Cur1 INTO @sku, @L02, @L04, @L05, @skl  --@QTY_D, @LOT06
			 END
			CLOSE Cur1
			DEALLOCATE Cur1
----------------------------------------------------------------------------------------------------------------------------------------------------------------
			--�� �������� �������� ��������� ����� ������. ���06 ��������� ��� � ������ 3.1.  
set @LOT06 = ''
set @LOT = ''
			exec wh1.compare_Physical_DAX_LOT06 @sku, @LOT06 OUTPUT, @LOT OUTPUT
--print '����� �����'			
--print '@QTY_P = ' + convert(varchar(30),@QTY_P) + '@QTY_D = ' + convert(varchar(30),@QTY_D)

-- �� ����			select @QTY_D = @QTY_P - @QTY_D
--print '����� �������'			
--print '@QTY_P = ' + convert(varchar(30),@QTY_P) + '@QTY_D = ' + convert(varchar(30),@QTY_D)

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
--==================================================================================================================
	FETCH NEXT FROM curCURSORstp3 INTO @sku, @L02, @L04, @L05, @skl
  END
CLOSE curCURSORstp3
DEALLOCATE curCURSORstp3 -- ������� �� ������  	
--=======================================================================================================================================
END

