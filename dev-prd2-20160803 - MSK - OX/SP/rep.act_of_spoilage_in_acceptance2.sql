
/* процедура выборки списка складов для отчетов*/
ALTER PROCEDURE [rep].[act_of_spoilage_in_acceptance2] 
AS
	select id,name,Description,DefWH from dbo.WarehouseList where Enabled=1 order by Name

