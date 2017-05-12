-- ОБЪЕДИНЕНИЕ КОРРЕКТИРОВОК ДЛЯ ОТПРАВКИ В ХОСТ-СИСТЕМУ
-- ЗАПУСКАЕТСЯ ПЕРИОДИЧЕСКИ ЧЕРЕЗ MSSQL SERVER AGENT

ALTER PROCEDURE [dbo].[proc_DA_AdjustmentBatchMake]
	@wh varchar(10)
AS

declare @adkey varchar(10)
declare @tlogkey varchar(10)

SET NOCOUNT ON

if 0 = (select count(*) from DA_Adjustment where batchkey is null)
	return

--получить номер для пакета корректировок
exec dbo.DA_GetNewKey @wh,'daadjustmentbatch', @adkey output

--получить номер для записи в лог
exec dbo.DA_GetNewKey @wh,'eventlogkey', @tlogkey output

begin tran
	update DA_Adjustment set batchkey = @adkey 
	where whseid = @wh and batchkey is null

	if @@ERROR = 0 
	begin
		--записать в лог событие о готовности объединенной корректировки
		insert wh1.transmitlog (whseid, transmitlogkey, tablename, key1) 
		values (@wh, @tlogkey, 'adjustmentbatch', @adkey)
	end

if @@ERROR = 0 commit tran
else rollback tran

