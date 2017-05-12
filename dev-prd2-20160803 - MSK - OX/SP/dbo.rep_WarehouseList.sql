
/* процедура выборки списка складов для отчетов*/
ALTER PROCEDURE [dbo].[rep_WarehouseList] 
AS
	select * from dbo.WarehouseList where Enabled=1 order by Name

