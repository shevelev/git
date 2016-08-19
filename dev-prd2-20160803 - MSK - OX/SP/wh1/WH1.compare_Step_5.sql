-- =============================================
-- Author:		<KIR, Logicon.Ekaterinburg>
-- Create date: <21.12.2015>
-- =============================================
-- ��� 5:  if @iP > 1 and @iD > 1   
-- ����� �� ����� �.5 
-- =============================================
ALTER PROCEDURE [WH1].[compare_Step_5]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--=======================================================================================================================================
--=======================================================================================================================================
--	print '5: if @iP > 1 and @iD > 1'
--=======================================================================================================================================
declare @iP int, @iD int, @i int			-- ���-�� ������� � �������� �� ������� � ������, ���� � ���������.
declare @sku varchar(50), @L02 varchar(50), @L04 varchar(50),@L05 varchar(50), @skl varchar(50), @stp varchar(1)
declare @LOT06 varchar(50),@LOT varchar(10)	-- ��� ������������ ��������� ���06 � ��� � �����
declare @TestStep varchar(500)
declare @QTY_P decimal, @QTY_D decimal		-- ���-�� ������ � ����� � ������ ��������
declare @LOC varchar(10)
declare @QTY_D1 decimal,@dLOT06 varchar(40), @dID int		--��� ������ ������� #tmpDAX
declare @recQTY decimal,@QTY_P1 decimal						-- ���-�� ��� ����� � ������

CREATE TABLE #tmpDAX(
	[dQTY] [decimal](18) NULL,
	[dLOT06] [varchar](40) NULL,
	[dID] [int] IDENTITY(1,1) NOT NULL)

/*��������� ������*/
DECLARE curCURSORstp5 CURSOR READ_ONLY
/*��������� ������*/
FOR
select sku, susr1, susr4, susr5, skld from prd2.wh1.PHYSICALtmp
where step = 'Step 5' --and sku = '1055'
group by sku, susr1, susr4, susr5, skld
/*��������� ������*/
OPEN curCURSORstp5
/*�������� ������ ������*/
FETCH NEXT FROM curCURSORstp5 INTO @sku, @L02, @L04, @L05, @skl
/*��������� � ����� ������� �����*/
WHILE @@FETCH_STATUS = 0
  BEGIN
	--print 'Step 5'
--==================================================================================================================
		set @TestStep = 'Step 5 if @iP > 1 and @iD > 1'
--		print '		' + @TestStep
		
		--�������� ��������� ���������� ���-�� � ������ � ��������� �������� ������� qty �� ����.
		
		SELECT @QTY_P = sum(QTY) FROM prd2.wh1.PHYSICALtmp 
		where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl-- and LOC = @LOC

		SELECT @QTY_D = sum(INVENTQTYPHYSICALONHAND) FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
		where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
		and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl

--print '@QTY_P = ' + convert(varchar(30),@QTY_P) 
--print '@QTY_D = ' + convert(varchar(30),@QTY_D)
--print '-------------------------------------------'
		if @QTY_P <= @QTY_D
		  begin
			--���������
			set @TestStep = @TestStep + '( if @QTY_P < @QTY_D )'
			--=============================================================================================================
			--� ����� �������������� �� ���-�� ������� � ���� � ��������� ��������� qty �� ������ � qty ������ ������ � ����. 
			--���� qty �� ������ ������, �� � �������������� ������� ����� qty �� ����. ���06 ����� �� ����. 
			--��� ������� ����� ��������� qty �� ������ �� qty �� ����. 
			--� ������ ��� qty �� ������ < qty �� ���� � �������������� ������� qty �� ������. ���06 ����� �� ����.
			--����� �� ����� ��� ���������� qty � ������ = 0.
			--=============================================================================================================
--print '@QTY_P = ' + convert(varchar(30),@QTY_P) + '@QTY_D = ' + convert(varchar(30),@QTY_D)

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			--�������� ��������� ������� ������� �� ����
			if object_id('tempdb..#tmpDAX') is not null delete #tmpDAX
			INSERT INTO #tmpDAX
			SELECT INVENTQTYPHYSICALONHAND, INVENTBATCHID 
			FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
			and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl			
			order by substring(INVENTBATCHID,14,8) desc, INVENTQTYPHYSICALONHAND desc
			
			/*��������� ������ �� ������ �� ������*/
			DECLARE curCURSORstp51 CURSOR READ_ONLY
			/*��������� ������*/
			FOR
			select QTY,LOC from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl
			order by qty desc
			/*��������� ������*/
			OPEN curCURSORstp51
			/*�������� ������ ������*/
			FETCH NEXT FROM curCURSORstp51 INTO @QTY_P, @LOC
			/*��������� � ����� ������� �����*/
			WHILE @@FETCH_STATUS = 0
			  BEGIN
--				print '���� �� ������'
				--==================================================================================================================
				WHILE @QTY_P > 0
				  begin
					select top 1 @QTY_D1 = dQTY, @dlot06 = dLOT06, @dID = dID from #tmpDAX where dQTY > 0 order by dID

--print '@QTY_P = ' + convert(varchar(20),@QTY_P)
--print '@@QTY_D1 = ' + convert(varchar(20),@QTY_D1)					
					if @QTY_P > @QTY_D1
					  begin
						set @QTY_P = @QTY_P - @QTY_D1
						set @recQTY = @QTY_D1
						set @QTY_D1 = 0
					  end
					else
					  begin
						set @recQTY = @QTY_P
						set @QTY_D1 = @QTY_D1 - @QTY_P
						set @QTY_P = 0
					  end

					update #tmpDAX
					set dQTY = @QTY_D1 
					from #tmpDAX
					where dID = @dID
					
					
--print '@@@recQTY = ' + convert(varchar(20),@recQTY)		

					--��� ����� �� ������������
					if @L02 = '��' or @L02 = '��' set @L02 = ''	
					select top 1 @LOT = LOT from WH1.LOTATTRIBUTE 
					where lottable06 = @dlot06 and (lottable04 = @L04 or lottable04 is null) and (lottable05 = @L05 or lottable05 is null) and lottable02 =@L02 and SKU = @sku
--<COMMENT> �������� �����!				  
					-- ������ � ������
					--insert into prd2.wh1.PHYSICAL
					--select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@recQTY,PACKKEY,
					--UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
					--SUSR7,SUSR8,SUSR9,SUSR10 from prd2.wh1.PHYSICALtmp
					--where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and loc = @LOC
--</COMMENT> �������� �����!						
					--��������� ������ � PHYSICAL_DAX
					insert into prd2.wh1.PHYSICAL_DAX
					select top 1 WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@recQTY,PACKKEY,
					UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
					SUSR7,SUSR8,SUSR9,SUSR10,skld, @dlot06, @TestStep from prd2.wh1.PHYSICALtmp
					where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and loc = @LOC	
									  
				  end
				
				--==================================================================================================================
				FETCH NEXT FROM curCURSORstp51 INTO @QTY_P, @LOC
			  END
			CLOSE curCURSORstp51
			DEALLOCATE curCURSORstp51 -- ������� �� ������
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++	
		  end	  
		if @QTY_P = @QTY_D
		  begin
			--�����������
			set @TestStep = @TestStep + '( if @QTY_P = @QTY_D )'
			-- � �������������� ������� ��������� ���-�� ������� � ������ �� ������� ��� � ������� ����.
--print '@QTY_P = ' + convert(varchar(30),@QTY_P) + '@QTY_D = ' + convert(varchar(30),@QTY_D)

			--=============================================================================================================
			-- � ����� �������������� �� ���-�� ������� � ���� � ��������� ��������� qty �� ������ � qty ������ ������ � ����. 
			--���� qty �� ������ ������, �� � �������������� ������� ����� qty �� ����. ���06 ����� �� ����. 
			--��� ������� ����� ��������� qty �� ������ �� qty �� ����. 
			--� ������ ��� qty �� ������ < qty �� ���� � �������������� ������� qty �� ������. ���06 ����� �� ����.
			--����� �� ����� ��� ���������� qty � ������ = 0 �� ���� ��� ����� � ��������� �������.
			--=============================================================================================================		
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			--�������� ��������� ������� ������� �� ����
			if object_id('tempdb..#tmpDAX') is not null delete from #tmpDAX
			INSERT INTO #tmpDAX
			SELECT INVENTQTYPHYSICALONHAND, INVENTBATCHID 
			FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
			and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl			
			order by substring(INVENTBATCHID,14,8) desc, INVENTQTYPHYSICALONHAND desc
			
			/*��������� ������ �� ������ �� ������*/
			DECLARE curCURSORstp51 CURSOR READ_ONLY
			/*��������� ������*/
			FOR
			select QTY,LOC from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl
			order by qty desc
			/*��������� ������*/
			OPEN curCURSORstp51
			/*�������� ������ ������*/
			FETCH NEXT FROM curCURSORstp51 INTO @QTY_P, @LOC
			/*��������� � ����� ������� �����*/
			WHILE @@FETCH_STATUS = 0
			  BEGIN
--				print '���� �� ������'
				--==================================================================================================================
				WHILE @QTY_P > 0
				  begin
					select top 1 @QTY_D1 = dQTY, @dlot06 = dLOT06, @dID = dID from #tmpDAX where dQTY > 0 order by dID

--print '@QTY_P = ' + convert(varchar(20),@QTY_P)
--print '@@QTY_D1 = ' + convert(varchar(20),@QTY_D1)					
					if @QTY_P > @QTY_D1
					  begin
						set @QTY_P = @QTY_P - @QTY_D1
						set @recQTY = @QTY_D1
						set @QTY_D1 = 0
					  end
					else
					  begin
						set @recQTY = @QTY_P
						set @QTY_D1 = @QTY_D1 - @QTY_P
						set @QTY_P = 0
					  end

					update #tmpDAX
					set dQTY = @QTY_D1
					from #tmpDAX
					where dID = @dID
					
					
--print '@@@recQTY = ' + convert(varchar(20),@recQTY)		

					--��� ����� �� ������������
					if @L02 = '��' or @L02 = '��' set @L02 = ''	
					select top 1 @LOT = LOT from WH1.LOTATTRIBUTE 
					where lottable06 = @dlot06 and (lottable04 = @L04 or lottable04 is null) and (lottable05 = @L05 or lottable05 is null) and lottable02 =@L02 and SKU = @sku
--<COMMENT> �������� �����!				  
					-- ������ � ������
					--insert into prd2.wh1.PHYSICAL
					--select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@recQTY,PACKKEY,
					--UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
					--SUSR7,SUSR8,SUSR9,SUSR10 from prd2.wh1.PHYSICALtmp
					--where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and loc = @LOC
--</COMMENT> �������� �����!						
					--��������� ������ � PHYSICAL_DAX
					insert into prd2.wh1.PHYSICAL_DAX
					select top 1 WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@recQTY,PACKKEY,
					UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
					SUSR7,SUSR8,SUSR9,SUSR10,skld, @dlot06, @TestStep from prd2.wh1.PHYSICALtmp
					where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and loc = @LOC	
									  
				  end
				
				--==================================================================================================================
				FETCH NEXT FROM curCURSORstp51 INTO @QTY_P, @LOC
			  END
			CLOSE curCURSORstp51
			DEALLOCATE curCURSORstp51 -- ������� �� ������
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

		  end
		  
		if @QTY_P > @QTY_D
		  begin
			--�������
			set @TestStep = @TestStep + '( if @QTY_P > @QTY_D )'
			----� �������������� ������� ��������� ���-�� ������� � ������ �� ������� ��� � ������� ����. 
			--=============================================================================================================
			-- � ����� �������������� �� ���-�� ������� � ���� � ��������� ��������� qty �� ������ � qty ������ ������ � ����. 
			--���� qty �� ������ ������, �� � �������������� ������� ����� qty �� ����. ���06 ����� �� ����. 
			--��� ������� ����� ��������� qty �� ������ �� qty �� ����. 
			--� ������ ��� qty �� ������ < qty �� ���� � �������������� ������� qty �� ������. ���06 ����� �� ����.
			--=============================================================================================================		
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			--�������� ��������� ������� ������� �� ����
			if object_id('tempdb..#tmpDAX') is not null delete from #tmpDAX

			INSERT INTO #tmpDAX
			SELECT INVENTQTYPHYSICALONHAND, INVENTBATCHID 
			FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = '��') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
			and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl			
			order by substring(INVENTBATCHID,14,8) desc, INVENTQTYPHYSICALONHAND desc
			
			/*��������� ������ �� ������ �� ������*/
			DECLARE curCURSORstp51 CURSOR READ_ONLY
			/*��������� ������*/
			FOR
			select QTY,LOC from prd2.wh1.PHYSICALtmp
			where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl
			order by qty desc
			/*��������� ������*/
			OPEN curCURSORstp51
			/*�������� ������ ������*/
			FETCH NEXT FROM curCURSORstp51 INTO @QTY_P1, @LOC
			/*��������� � ����� ������� �����*/
			WHILE @@FETCH_STATUS = 0
			  BEGIN
--				print '���� �� ������'
				--==================================================================================================================

				WHILE @QTY_P1 > 0
				  begin
					set @QTY_D1 = 0				  
				  
					select top 1 @QTY_D1 = dQTY, @dlot06 = dLOT06, @dID = dID from #tmpDAX where dQTY > 0 order by dID
--print '-----------	������ �����'
--print '@QTY_D = ' + convert(varchar(20),@QTY_D)
--print '@QTY_P1 = ' + convert(varchar(20),@QTY_P1)
--print '@@@QTY_D1 = ' + convert(varchar(20),@QTY_D1)		
			
					if @QTY_D1 is null set @QTY_D1 = 0 
					
					if @QTY_P1 > @QTY_D1
					  begin
						if @QTY_D1 > 0 
							set @recQTY = @QTY_D1
						else
							set @recQTY = @QTY_P1
					  end
					else
					  begin
						set @recQTY = @QTY_P1
					  end
					  
					set @QTY_P1 = @QTY_P1 - @recQTY
					set @QTY_D = @QTY_D - @recQTY  
					
--print '����� ����������:'					  
--print '@@@recQTY = ' + convert(varchar(20),@recQTY)
--print '@QTY_P1 = ' + convert(varchar(20),@QTY_P1)	
--print '@@@@@QTY_D = ' + convert(varchar(20),@QTY_D)	
					
					if @QTY_D >= 0		-- ���� �������� ���-�� ������
					  begin
--print 'real'
						update #tmpDAX
						set dQTY = dQTY - @recQTY
						from #tmpDAX
						where dID = @dID

						select @QTY_D1 = sum(dQTY) from #tmpDAX

--print 'sum(dQTY) = '+ convert(varchar(20),@QTY_D1)
						--��� ����� �� ������������
						if @L02 = '��' or @L02 = '��' set @L02 = ''	
						select top 1 @LOT = LOT from WH1.LOTATTRIBUTE 
						where lottable06 = @dlot06 and (lottable04 = @L04 or lottable04 is null) and (lottable05 = @L05 or lottable05 is null) and lottable02 =@L02 and SKU = @sku
						
--<COMMENT> �������� �����!					  
						-- ������ � ������
						--insert into prd2.wh1.PHYSICAL
						--select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@recQTY,PACKKEY,
						--UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
						--SUSR7,SUSR8,SUSR9,SUSR10 from prd2.wh1.PHYSICALtmp
						--where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and loc = @LOC
--</COMMENT> �������� �����!	
						
						--��������� ������ � PHYSICAL_DAX
						insert into prd2.wh1.PHYSICAL_DAX
						select top 1 WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@recQTY,PACKKEY,
						UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
						SUSR7,SUSR8,SUSR9,SUSR10,skld, @dlot06, @TestStep from prd2.wh1.PHYSICALtmp
						where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and loc = @LOC	
					  end
					else		--�������
					  begin

--print 'over'
			---------------------------------------------------------------------------------------------------------------------------
			--			--�� �������� �������� ��������� ����� ������. ���06 ��������� ��� � ������ 3.1.
			---------------------------------------------------------------------------------------------------------------------------  
						exec wh1.compare_Physical_DAX_LOT06 @sku, @LOT06 OUTPUT, @LOT OUTPUT

			--print '@sku = ' + @sku
			--print '@@LOT06 = ' + @LOT06
			--print '@@@LOT = ' + @LOT
			
--<COMMENT> �������� �����!
/*
						insert into prd2.wh1.PHYSICAL
						select top 1 WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@recQTY,PACKKEY,
						UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
						SUSR7,SUSR8,SUSR9,SUSR10 from prd2.wh1.PHYSICALtmp
						where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and loc = @LOC
*/					
--</COMMENT> �������� �����!
							
						--��������� ������ � PHYSICAL_DAX
						insert into prd2.wh1.PHYSICAL_DAX
						select top 1 WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@recQTY,PACKKEY,
						UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
						SUSR7,SUSR8,SUSR9,SUSR10,skld, @dlot06, @TestStep from prd2.wh1.PHYSICALtmp
						where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl and loc = @LOC
					  
					  end
				  end
				
				--==================================================================================================================
				FETCH NEXT FROM curCURSORstp51 INTO @QTY_P1, @LOC
			  END
			CLOSE curCURSORstp51
			DEALLOCATE curCURSORstp51 -- ������� �� ������
			
--print '@QTY_P = ' + convert(varchar(20),@QTY_P)			
			
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		  end
--==================================================================================================================
	FETCH NEXT FROM curCURSORstp5 INTO @sku, @L02, @L04, @L05, @skl
  END
CLOSE curCURSORstp5
DEALLOCATE curCURSORstp5 -- ������� �� ������  	
--=======================================================================================================================================
--=======================================================================================================================================
--=======================================================================================================================================
	
END

