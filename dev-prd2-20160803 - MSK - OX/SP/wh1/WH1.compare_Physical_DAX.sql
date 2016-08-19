-- =============================================
-- Author:		<KIR, Logicon.Ekaterinburg>
-- Create date: <08.12.2015>
-- =============================================
-- ����������� �������������� ������ ������ �� ������� ������ ������ 
-- ������ � ������� ������ � ���� 
-- =============================================
ALTER PROCEDURE [WH1].[compare_Physical_DAX]
	@IsCopyTable varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--=============================================================================================
--	����������
--=============================================================================================
declare @sku varchar(50), @L02 varchar(50), @L04 varchar(50),@L05 varchar(50), @skl varchar(50) 
declare @invTag varchar(20), @LOC varchar(10)
declare @iP int, @iD int, @i int			-- ���-�� ������� � �������� �� ������� � ������, ���� � ���������.
declare @LOT06 varchar(50),@LOT varchar(10)	-- ��� ������������ ��������� ���06 � ��� � �����
declare @TestStep varchar(500)				-- ������� � ������ ���� ������ (� ��� �� ��� ����������).
declare @QTY_P decimal, @QTY_D decimal		-- ���-�� ������ � ����� � ������ ��������
-- WH1.PHYSICAL - �������������� �������.
-- ���� @IsCopyTable = real, �� �������� � �������� � �� ��������� ��������� �������������� ������� �� ����� PHYSICAL ��� ������������.
-- #tmpPHYSICAL - ��������� ������� ����� �������������� � ������������ ������.
-- PHYSICALtmp - ��������� �������������� �������. �� ���� �� ��� ������������
--=============================================================================================
--=============================================================================================

set @i = 1

 if @IsCopyTable = 'real'
   begin
	select * into wh1.PHYSICAL_ORIGINAL from [WH1].[PHYSICAL]
   end

-- ������� ��������� ������� � ������
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

-- ��������� ������� ��������� ������� �� ������ ��� ������ = 0
insert into #tmpPHYSICAL (WHSEID,TEAM,STORERKEY,SKU,LOC,LOT,ID,INVENTORYTAG,QTY,PACKKEY,
		UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
		SUSR7,SUSR8,SUSR9,SUSR10)
select WHSEID,TEAM,STORERKEY,SKU,LOC,LOT,ID,INVENTORYTAG,QTY,PACKKEY,
		UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
		SUSR7,SUSR8,SUSR9,SUSR10
from WH1.PHYSICAL	
where status = 0

-- ��������� ���� �����
UPDATE #tmpPHYSICAL 
SET SKLD = SKLAD 
FROM #tmpPHYSICAL AS P
 join wh1.LOC loc on loc.LOC =p.loc
 join dbo.WHTOZONE w on w.zone = loc.PUTAWAYZONE
where len(p.loc)>0

-- �������� �������������� ������� � ��������� � ��� ������ �� ������ ��� ����� = 0. 
-- ���� ��� �������� - ������� ������, ���� ���� - ������� ������.
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
  
-- ��������� ������� ��� ����� ���� ������������
if object_id('tempdb..#tmpMaxInvent') is not null drop table #tmpMaxInvent

CREATE TABLE #tmpMaxInvent(
	[INVENT] [varchar](18) NOT NULL,
	[SKU] [varchar](50) NOT NULL,
	[LOT] [varchar](10) NULL,
	[LOC] [varchar](10) NULL,
	[skld] [varchar](20) NULL,
	[tQTY] [decimal](22, 5) NULL)

-- ���������� ���� ������������
insert into #tmpMaxInvent
select MAX(INVENTORYTAG), sku, lot, loc, skld, 0
from #tmpPHYSICAL 
where status = 0
group by sku, lot, loc, skld

update #tmpMaxInvent
set tQTY = QTY
from #tmpMaxInvent as tI, #tmpPHYSICAL as tP
where ti.SKU = tp.SKU and ti.LOT = tp.LOT and ti.LOC = tp.LOC and INVENT = INVENTORYTAG 

-- �������� ������ � ������ ������� �� ������� #tmpMaxInvent
--===============================================================================
-- �������� ���������� ��������� ������ �� ����� @sku, @L02, @L04, @L05, @loc, @skl
-- ����� ������� � ����� ��������.
--===============================================================================
/*��������� ������*/
DECLARE curCURSOR CURSOR READ_ONLY
/*��������� ������*/
FOR
--select INVENT, sku, susr1, susr4, susr5, loc, skld from #tmpMaxInvent
select INVENT, sku, lot, loc, skld from #tmpMaxInvent
where tQTY > 0 --sku ='10010'
/*��������� ������*/
OPEN curCURSOR
/*�������� ������ ������*/
--FETCH NEXT FROM curCURSOR INTO @invTag, @sku, @L02, @L04, @L05, @loc, @skl
FETCH NEXT FROM curCURSOR INTO @invTag, @sku, @LOT, @loc, @skl
/*��������� � ����� ������� �����*/
WHILE @@FETCH_STATUS = 0
BEGIN
	
	select top 1 @L02 =susr1, @L04 = SUSR4, @L05 =SUSR5 from #tmpPHYSICAL where SKU = @sku and LOC = @LOC and INVENTORYTAG = @invTag and LOT = @LOT
	
	-- ���������� ���-�� �������  �� ��������.
	SELECT @iP = COUNT(*) FROM #tmpPHYSICAL 
	where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and INVENTORYTAG = @invTag and LOC = @LOC
	SELECT @iD = COUNT(*) FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
	where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl

print '������ = ' + convert(varchar(2),@i) 
print '@iP = '+ convert(varchar(10),@iP) + ' @iD= ' + convert(varchar(10),@iD)
print '		SKU =' + @sku + ' @L02 ='+ @L02 +' @L04 = '+@L04+' @L05 = '+@L05+' skld = '+@skl+' loc = '+@loc+ ' @invTag = '+@invTag

	set @LOT06 = ''
--=========================================================================================================================
--	������� � ����� ������ ������. �.1
--=========================================================================================================================
    if @iP > 0 and @iD = 0  -- �������
      begin
		set @TestStep = 'if @iP > 0 and @iD = 0'
--		print '		' + @TestStep
		-- ���� ��� � ������ ����, �� ����� ���06 �� ������������
		-- ���� ��� - ���� ������������ ���06 �� ������ ������

		select @LOT = LOT 
		from #tmpPHYSICAL
		where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and LOC = @LOC
--print '@LOT = ' + @LOT	
		if LEN(@LOT) > 0
			select top 1 @LOT06 = lottable06 from WH1.LOTATTRIBUTE where LOT = @LOT and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
		else
			exec wh1.compare_Physical_DAX_LOT06 @sku, @LOT06 output, @LOT output
--print '3'		
		--��������� ������ � PHYSICALtmp
		insert into wh1.PHYSICALtmp
		select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,QTY,PACKKEY,
		UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
		SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
		where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and LOC = @LOC
      end
--=========================================================================================================================
--	������� � ����� ������ ������. �.2
--=========================================================================================================================
    if @iP = 1 and @iD = 1  -- �� ����� ������ �.2
      begin
		set @TestStep = 'if @iP = 1 and @iD = 1'
--		print '		' + @TestStep		
		--�������� ��������� ���-�� � ������ � ����

		SELECT @QTY_P = QTY FROM #tmpPHYSICAL 
		where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and LOC = @LOC

		SELECT @QTY_D = INVENTQTYPHYSICALONHAND FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
		where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl

--print '@QTY_P = ' + convert(varchar(30),@QTY_P) + ' @QTY_D = '+  convert(varchar(30), @QTY_D)	

		if @QTY_P < @QTY_D
		  begin
			--���������
			set @TestStep = @TestStep + '( if @QTY_P < @QTY_D )'
			-- ���06 ����� �� ����. � �������������� qty �� ������
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl
			
			--��� ����� �� ������������
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
			
			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC		
		  end
		if @QTY_P = @QTY_D
		  begin
			--�����������
			set @TestStep = @TestStep + '( if @QTY_P = @QTY_D )'
			-- ���06 ����� �� ����. � �������������� qty �� ������
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl
			
			--��� ����� �� ������������
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
						
			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC			
		  end
		if @QTY_P > @QTY_D
		  begin
			--�������
			set @TestStep = @TestStep + '( if @QTY_P > @QTY_D )'
--print @TestStep
			--� �������������� ������� ������� qty ������ ��� � ����. ���06 ����� �� ����.  
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl
--print '1'
--print '@LOT06 = '	+ @LOT06		
			--��� ����� �� ������������
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
--print '2'	
--print '@LOT = '	+ @LOT					
			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_D,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and LOC = @LOC	
--print '3'			
			--��������� ����� ������ ��� ���������� ������� qty. ���06 ��������� ��� � ������ 3.1
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
--	������� � ����� ������ ������. �.3
--=========================================================================================================================
   if @iP = 1 and @iD > 1  -- ���� ������ �� ������ �.3
      begin
		set @TestStep = 'if @iP = 1 and @iD > 1'
--		print '		' + @TestStep
		--�������� ��������� ���-�� � ������ � ��������� �������� ������� qty �� ����.
		SELECT @QTY_P = QTY FROM #tmpPHYSICAL 
		where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and LOC = @LOC
		SELECT @QTY_D = SUM(INVENTQTYPHYSICALONHAND) FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
		where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl

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
				  
				--��� ����� �� ������������
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
			--�����������
			set @TestStep = @TestStep + '( if @QTY_P = @QTY_D )'
			-- � �������������� ������� ��������� ���-�� ������� � ������ �� ������� ��� � ������� ����.
----???????????????????? ��������� �� ��� �� ����� ������ ������ ���������, �������� � ������� ��������.
--			insert into wh1.PHYSICALtmp
--			select WHSEID,TEAM,STORERKEY,SKU,LOC,LOT,ID,INVENTORYTAG,d.INVENTQTYPHYSICALONHAND,PACKKEY,
--			UOM,p.STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
--			SUSR7,SUSR8,SUSR9,SUSR10,skld, d.INVENTBATCHID, left(@TestStep ,500)
--			from #tmpPHYSICAL as p, [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev] as d
--			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and LOC = @LOC and 
--			d.itemid = SKU and INVENTSERIALID = susr1 and MANUFACTUREDATE = SUSR4 and EXPIREDATE= SUSR5 and 
--			INVENTLOCATIONID = skld
			--=============================================================================================================
			-- � ����� �������������� �� ���-�� ������� � ���� � ��������� ���-�� qty �� ������ � qty ������ ������ � ����. 
			--���� qty �� ������ ������, �� � �������������� ������� ����� qty �� ����. ���06 ����� �� ����. 
			--��� ������� ����� ��������� qty �� ������ �� qty �� ����. 
			--� ������ ��� qty �� ������ < qty �� ���� � �������������� ������� qty �� ������. ���06 ����� �� ����.
			--����� �� ����� ��� ���������� qty � ������ = 0.
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
				  
				--��� ����� �� ������������
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
			--�������
			set @TestStep = @TestStep + '( if @QTY_P > @QTY_D )'

			--��� ����� �� ������������
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
				
			--� �������������� ������� ��������� ���-�� ������� � ������ �� ������� ��� � ������� ����. 
			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,d.INVENTQTYPHYSICALONHAND,PACKKEY,
			UOM,p.STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, d.INVENTBATCHID, left(@TestStep,500)
			from #tmpPHYSICAL as p, [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev] as d
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl and LOC = @LOC and 
			d.itemid = SKU and INVENTSERIALID = susr1 and MANUFACTUREDATE = SUSR4 and EXPIREDATE= SUSR5 and 
			INVENTLOCATIONID = skld			
			
			--�� �������� �������� ��������� ����� ������. ���06 ��������� ��� � ������ 3.1.  
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
--	������� � ����� ������ ������. �.4
--=========================================================================================================================
    if @iP > 1 and @iD = 1  -- ����� � ����� �.4
      begin
		set @TestStep = 'if @iP > 1 and @iD = 1'
--		print '		' + @TestStep
		--�������� ��������� ���������� ���-�� � ������ � qty �� ����.
		SELECT @QTY_P = SUM(QTY) FROM #tmpPHYSICAL 
		where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC
		SELECT @QTY_D = INVENTQTYPHYSICALONHAND FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
		where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl

		if @QTY_P < @QTY_D
		  begin
			--���������
			set @TestStep = @TestStep + '( if @QTY_P < @QTY_D )'
			-- � �������������� ������� ������ ���� ������ � ��������� ��������� qty �� ������ � ���06 �� ����.
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl

			--��� ����� �� ������������
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
			
			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC	
		  end
		if @QTY_P = @QTY_D
		  begin
			--�����������
			set @TestStep = @TestStep + '( if @QTY_P = @QTY_D )'
			-- � �������������� ������� ������ ���� ������ � ��������� ��������� qty �� ������ � ���06 �� ����.
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl

			--��� ����� �� ������������
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
			
			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_P,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC		
		  end
		if @QTY_P > @QTY_D
		  begin
			--�������
			set @TestStep = @TestStep + '( if @QTY_P > @QTY_D )'
			--� �������������� ������� ������ ���� ������ � ��������� qty �� ���� � ���06 �� ����.  
			SELECT @LOT06 = INVENTBATCHID FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
			where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl

			--��� ����� �� ������������
			select top 1 @LOT = LOT from WH1.LOTATTRIBUTE where lottable06 = @LOT06 and lottable04 = @L04 and lottable05 =@L05 and lottable02 =@L02
			
			insert into wh1.PHYSICALtmp
			select WHSEID,TEAM,STORERKEY,SKU,LOC,@LOT,ID,INVENTORYTAG,@QTY_D,PACKKEY,
			UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
			SUSR7,SUSR8,SUSR9,SUSR10,skld, @LOT06, left(@TestStep,500) from #tmpPHYSICAL
			where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl	and LOC = @LOC		
			
			--�� �������� �������� ��������� ����� ������. ���06 ��������� ��� � ������ 3.1
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
--	������� � ����� ������ ������. �.5
--=========================================================================================================================
    if @iP > 1 and @iD > 1  -- ����� �� ����� �.5
      begin
		set @TestStep = 'if @iP > 1 and @iD > 1'
--		print '		' + @TestStep		
		--�������� ��������� ���������� ���-�� � ������ � ��������� �������� ������� qty �� ����.
		SELECT @QTY_P = SUM(QTY) FROM #tmpPHYSICAL 
		where SKU = @sku and susr1 = @L02 and SUSR4 = @L04 and SUSR5 = @L05 and skld = @skl 
		SELECT @QTY_D = SUM(INVENTQTYPHYSICALONHAND) FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
		where itemid = @sku and INVENTSERIALID = @L02 and MANUFACTUREDATE = @L04 and EXPIREDATE= @L05 and INVENTLOCATIONID = @skl

		if @QTY_P <= @QTY_D
		  begin
			--���������
			set @TestStep = @TestStep + '( if @QTY_P < @QTY_D )'
			--=============================================================================================================
			-- � ����� �������������� �� ���-�� ������� � ���� � ��������� ��������� qty �� ������ � qty ������ ������ � ����. 
			--���� qty �� ������ ������, �� � �������������� ������� ����� qty �� ����. ���06 ����� �� ����. 
			--��� ������� ����� ��������� qty �� ������ �� qty �� ����. 
			--� ������ ��� qty �� ������ < qty �� ���� � �������������� ������� qty �� ������. ���06 ����� �� ����.
			--����� �� ����� ��� ���������� qty � ������ = 0.
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

				--��� ����� �� ������������
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
			--�����������
			set @TestStep = @TestStep + '( if @QTY_P = @QTY_D )'
			-- � �������������� ������� ��������� ���-�� ������� � ������ �� ������� ��� � ������� ����.
print '@QTY_P = ' + convert(varchar(30),@QTY_P) + '@QTY_D = ' + convert(varchar(30),@QTY_D)

			--=============================================================================================================
			-- � ����� �������������� �� ���-�� ������� � ���� � ��������� ��������� qty �� ������ � qty ������ ������ � ����. 
			--���� qty �� ������ ������, �� � �������������� ������� ����� qty �� ����. ���06 ����� �� ����. 
			--��� ������� ����� ��������� qty �� ������ �� qty �� ����. 
			--� ������ ��� qty �� ������ < qty �� ���� � �������������� ������� qty �� ������. ���06 ����� �� ����.
			--����� �� ����� ��� ���������� qty � ������ = 0 �� ���� ��� ����� � ��������� �������.
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

				--��� ����� �� ������������
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
			--�������
			set @TestStep = @TestStep + '( if @QTY_P > @QTY_D )'
			----� �������������� ������� ��������� ���-�� ������� � ������ �� ������� ��� � ������� ����. 
			--=============================================================================================================
			-- � ����� �������������� �� ���-�� ������� � ���� � ��������� ��������� qty �� ������ � qty ������ ������ � ����. 
			--���� qty �� ������ ������, �� � �������������� ������� ����� qty �� ����. ���06 ����� �� ����. 
			--��� ������� ����� ��������� qty �� ������ �� qty �� ����. 
			--� ������ ��� qty �� ������ < qty �� ���� � �������������� ������� qty �� ������. ���06 ����� �� ����.
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

				--��� ����� �� ������������
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

			--�� �������� �������� ��������� ����� ������. ���06 ��������� ��� � ������ 3.1.  
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

print '������ END'
print ''
select @i = @i+1 

--FETCH NEXT FROM curCURSOR INTO @invTag, @sku, @L02, @L04, @L05, @loc, @skl
FETCH NEXT FROM curCURSOR INTO @invTag, @sku, @LOT, @loc, @skl
END
CLOSE curCURSOR
DEALLOCATE curCURSOR -- ������� �� ������

-- ��������� ������� ��������� ������� �� ������ ��� ����� = 0 � ������ = 0
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

