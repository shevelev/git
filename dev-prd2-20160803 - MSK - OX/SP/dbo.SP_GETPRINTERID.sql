
-- =============================================
-- Author:		LOGICON
-- Create date: 18.04.2014
-- Description:	Возвращает идентификатор принтера 
--              для печати отгрузочной этикетки
--              в процессе контроля собранного ящика
-- Правка 01.04.2015 Шевелев С.С.: Изменено поле обработки с внешнего номера на поле c_zip
-- =============================================
ALTER PROCEDURE [dbo].[SP_GETPRINTERID] 
	@wms_userid varchar(30),
	@wh varchar(10),
	@caseid varchar(30),
	@printerid varchar(30)output	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
--	select @printerid =
--      CASE (o.c_zip)
--         WHEN '1' THEN 'P02'
--         ELSE 'P01' --должен быть 01 для печати на белой бумаге.
--      END
--from wh1.PICKDETAIL pd
--	join wh1.orders o on pd.ORDERKEY=o.ORDERKEY
--where pd.CASEID=@caseid
--
--[WH1].[SPECIALPRINTERCONFIG]  Настройки ip принтера
--
	if @wh='wh1'
		begin
			select @printerid =
				  CASE (o.c_zip)
					 WHEN '1' THEN 'P02'
					 ELSE 'P01' --должен быть 01 для печати на белой бумаге.
				  END
			from wh1.PICKDETAIL pd
				join wh1.orders o on pd.ORDERKEY=o.ORDERKEY
			where pd.CASEID=@caseid
		end
	else if @wh='wh2'
		begin
			set @printerid='P05'
		end
	else
		begin
			set @printerid='NO'
		end
	
--	set @printerid=@printerid
	
	--set @printerid = 'P01'
	
	insert into DA_InboundErrorsLog (source,msg_errdetails) values ('print','печать этикеток для ящика: '+@caseid+ ' ' + @printerid + ' wms/wh: ' + @wms_userid + '-' + @wh)
	
END














