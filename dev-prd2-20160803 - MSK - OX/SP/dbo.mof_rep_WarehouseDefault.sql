/* выбор склада по умолчанию для отчетов */
ALTER PROCEDURE [dbo].[mof_rep_WarehouseDefault] 
AS
	select top 1 * from dbo.WarehouseList where defwh=1 and Enabled=1  order by Name

