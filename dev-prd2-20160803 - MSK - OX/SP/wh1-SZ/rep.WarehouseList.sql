
/* ��������� ������� ������ ������� ��� �������*/
ALTER PROCEDURE [rep].[WarehouseList] 
AS
	select * from dbo.WarehouseList where Enabled=1 order by Name

