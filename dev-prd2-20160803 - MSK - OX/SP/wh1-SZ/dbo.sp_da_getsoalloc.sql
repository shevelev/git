
ALTER PROCEDURE [dbo].[sp_da_getsoalloc]
	@source varchar(500) = null
AS
-- Любая ошибка должна прерывать процедуру и передать исключение адаптеру
SET XACT_ABORT ON

