-- =============================================
-- Author:		Сандаков В.В.
-- Create date: 29.07.08
-- Description:	отчет "Список отгруженых заказов с резервом"
-- =============================================
ALTER PROCEDURE [dbo].[rep_List_of_Shipped_Orders_with_reserve](@operator varchar(20))
AS

--/*------------------------------*/
--declare @operator varchar(20)
--set @operator = ''
--/*------------------------------*/

declare @sql varchar(max)

set @sql = 'select od.orderkey, od.externorderkey, od.externlineno, od.openqty, od.qtyallocated, od.shippedqty, od.sku , od.editwho, pl.usr_name
from wh1.orders o 
join wh1.orderdetail od on o.orderkey = od.orderkey
left join ssaadmin.pl_usr pl on pl.usr_login = od.editwho
where od.qtyallocated > 0 
	and od.shippedqty = 0 
	and o.status >= 92'
	+case when isnull(@operator,'')='' then '' else ' and pl.usr_name like '''+@operator+'''' end

exec (@sql)

