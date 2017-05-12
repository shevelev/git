-- =============================================
-- Author:		<KIR, Logicon.Ekaterinburg>
-- Create date: <09.12.2015>
-- =============================================
-- Сформировать лот06 из данных инфор
-- =============================================
ALTER PROCEDURE [WH1].[compare_Physical_DAX_LOT06] 
   @sku varchar(50),
   @lot06 varchar(50) OUTPUT,
   @lot varchar(10) OUTPUT
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	declare @i int
	declare @s varchar(50)

	set @LOT06 =''
	set @lot = ''
--	set @sku = '20504'

	-- проверяем есть ли правильные лот06
	select @i = count(distinct(lottable06)) 
	from wh1.LOTATTRIBUTE LA, wh1.lotxlocxid LC 
	where LA.sku = @sku  and qty = 0 and la.LOT = lc.LOT and LEN(lottable06) = 25
	--print @i

	if @i>0
	  begin
		select top 1 @LOT06 = lottable06, @lot = LA.LOT 
		from wh1.LOTATTRIBUTE LA, wh1.lotxlocxid LC 
		where LA.sku = @sku  and qty = 0 and la.LOT = lc.LOT and LEN(lottable06) = 25
		order by SUBSTRING(lottable06,14,8) desc	  
	  end
	else
	  begin
	--	print 'нет'
		-- нет правильных значений берем любое где qty = 0
		select top 1 @LOT06 = lottable06, @lot = LA.LOT 
		from wh1.LOTATTRIBUTE LA, wh1.lotxlocxid LC
		where LA.sku = @sku  and qty = 0 and la.LOT = lc.LOT 
		order by lottable06
	  end  
  
--print '@LOT06 = ' + @LOT06
END

