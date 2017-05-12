-- =============================================
-- Author:		<KIR, Logicon.Ekaterinburg>
-- Create date: <16.12.2015>
-- =============================================
-- ��������� � �������������� ������ ������ ��������
-- ���� LOT � ������� ������. 
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

-- ����������� ��� ������ � ������� ���������� ���� ��� 
select @tblP = '[WH1].[PHYSICAL_LOT_NULL_' + convert(varchar(8),getutcdate(),112) + ']'
-- ���� ���� ����� ������ �� �� �������, ���� ���, �� ������ �����.
if OBJECT_ID (@tblP) is null 
  begin
	select @str = 'select * into ' + @tblP + ' from [WH1].[PHYSICAL] where LOT ='''' and QTY >0'
	--print @str
	exec(@str)
  end
  
 -- ��������� ������� ��� ����� ���� ������������
if object_id('tempdb..#tmpMaxInvent') is not null drop table #tmpMaxInvent

CREATE TABLE #tmpMaxInvent(
	[INVENT] [varchar](18) NOT NULL,
	[SKU] [varchar](50) NOT NULL,
	[SUSR1] [varchar](30) NULL,
	[SUSR4] [datetime] NULL,
	[SUSR5] [datetime] NULL,
	[LOC] [varchar](10) NOT NULL)
	
-- ���������� ���� ������������
insert into #tmpMaxInvent
select MAX(INVENTORYTAG), sku, susr1, susr4, susr5, loc 
from wh1.PHYSICAL
where wh1.PHYSICAL.STATUS = 0 and LOT = '' and QTY > 0
group by sku, susr1, susr4, susr5, loc	

-- ������� � ������ 
DECLARE curCURSOR CURSOR READ_ONLY
/*��������� ������*/
--SET curCURSOR  = CURSOR READ_ONLY --CURSOR SCROLL
FOR
select INVENT, sku, susr1, susr4, susr5, loc from #tmpMaxInvent
--where /*qty > 0 
--and */ sku ='14645'
--group by sku, susr1, susr4, susr5, loc 
/*��������� ������*/
OPEN curCURSOR
/*�������� ������ ������*/
FETCH NEXT FROM curCURSOR INTO @invTag, @sku, @L02, @L04, @L05, @loc
/*��������� � ����� ������� �����*/
WHILE @@FETCH_STATUS = 0
BEGIN
	--print '!'
	-- �� ���������� ���������� �������� ���������� ������ 
	-- � ������� ��� ��� ������ � lotxlocxid
	select @i = COUNT(*) from WH1.lotxlocxid
	where QTY > 0 and loc = @loc and lot in
	(select lOT 
	from wh1.LOTATTRIBUTE 
	where SKU = @sku and LOTTABLE02 = @L02 and LOTTABLE04 = @L04 and LOTTABLE05 = @L05)

	-- ������ �������� @i
	if @i > 0
	  begin
		if @i =1
		  begin
			--print '���� ����������'
			select @lot = lot
			from WH1.lotxlocxid
			where QTY > 0 and loc = @loc and lot in
			(select lOT 
			from wh1.LOTATTRIBUTE 
			where SKU = @sku and LOTTABLE02 = @L02 and LOTTABLE04 = @L04 and LOTTABLE05 = @L05)						
		  end
		else
		  begin
			print '����� ����������'
			-- ����� ���-�� ���� ������� �������, ��� - �� ����.
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
				--���� ����������� ����������
				select @lot = lot
				from WH1.lotxlocxid
				where QTY = @qty1 and loc = @loc and lot in
				(select lOT 
				from wh1.LOTATTRIBUTE 
				where SKU = @sku and LOTTABLE02 = @L02 and LOTTABLE04 = @L04 and LOTTABLE05 = @L05)				
			  end
			else  
			  begin
				--��� ������������ ����������. ����� �������� ���� � ����������� ���-��� ������
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
		--��� ������� ����������
		--print '��� ������� ����������'
		-- ��������� ������ � ���-��� 0 � ������������ ���������� ��������� ������.
		select top 1 @lot = la.lot 
		from wh1.LOTATTRIBUTE LA, wh1.lotxlocxid LC
		where LA.sku = @sku  and qty = 0 and la.LOT = lc.LOT and la.LOTTABLE02 = @L02 and la.LOTTABLE04 = @L04 and la.LOTTABLE05 = @L05
		order by SUBSTRING(lottable06,14,8) desc		
	  end
	  
	if LEN(@lot) > 0
	begin
		--������� �������� � ������
		print @sku
		update wh1.physical
		set LOT = @lot
		where INVENTORYTAG = @invTag and sku = @sku and susr1 = @L02 and susr4 = @L04 and susr5 = @L05 and loc = @loc
	  end	  
	  	  
FETCH NEXT FROM curCURSOR INTO @invTag, @sku, @L02, @L04, @L05, @loc
END
CLOSE curCURSOR
DEALLOCATE curCURSOR -- ������� �� ������
  
if object_id('tempdb..#tmpMaxInvent') is not null drop table #tmpMaxInvent
--============================================================================================
--=============================================================================================
END

