-- =============================================
-- Author:		����� �����
-- Create date: 13.05.2008
-- Description:	��� ������ ������� �������� ������ (������� �����) ����� 6, �������
-- ������� ��� ����������� ���������� ��� �������� �������������� �������
-- =============================================
ALTER PROCEDURE [dbo].[rep_ZCurrentCapacityWarehouse6] 
	@wh VarChar(30)
AS
BEGIN
	set @wh = upper(@wh)
	declare @sql varchar(max)
	set @sql = 'select loc, SUM('+@wh+'.skuxloc.qty*'+@wh+'.sku.stdcube) as cube
  from '+@wh+'.skuxloc (nolock) left join '+@wh+'.sku (nolock) 
    on '+@wh+'.sku.sku = '+@wh+'.skuxloc.sku 
  where loc LIKE ''PICKTO%'' or loc LIKE ''STAGE%'' or loc = ''PD''
  group by loc
  order by loc'
    exec (@sql)
END

