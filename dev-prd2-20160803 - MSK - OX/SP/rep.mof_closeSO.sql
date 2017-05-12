--################################################################################################
-- Процедура отмена заказа на отгрузку и расформирования накладной
--################################################################################################
ALTER PROCEDURE [rep].[mof_closeSO]
	@orderkey varchar(10) -- номер отгрузки
AS

declare @st varchar(5)



select @st=status from wh2.orders where ORDERKEY=@orderkey

if @st<'92'
	begin
		update wh2.orders set STATUS='98' where ORDERKEY=@orderkey -- меняем статус заказа
		declare @transmitlogkey varchar(10)
		exec dbo.DA_GetNewKey 'wh2','eventlogkey',@transmitlogkey output
		
		--записать в лог событие об отмене заказа
		insert wh2.transmitlog (whseid, transmitlogkey, tablename, key1, ADDWHO) 
		values ('wh2', @transmitlogkey, 'CancelSO', @orderkey, 'CancelSO')
		
		--записываем статус в хистори по заказу
		insert wh2.orderstatushistory (ORDERLINENUMBER,orderkey, whseid, ordertype, status, addwho, adddate ,comments)
		values ('',@orderkey, 'wh2', 'SO', '98', 'CanselSO', getdate(), 'CancelSO.. report')

	end

select pd.caseid,od.ORDERLINENUMBER, od.sku,s.DESCR, od.LOTTABLE02,td.TOLOC, td.qty otbor, td.FROMLOC, td.TOID, td.editdate ADDDATE, u.usr_lname+' '+u.usr_fname editWHO
from wh2.orderdetail od
	join wh2.sku s on s.SKU=od.sku
	join wh2.PICKDETAIL pd on od.ORDERKEY=pd.ORDERKEY and od.ORDERLINENUMBER=pd.ORDERLINENUMBER
	join wh2.taskdetail td on td.PICKDETAILKEY=pd.PICKDETAILKEY and td.STATUS=9
	join ssaadmin.pl_usr u on u.usr_login=td.EDITWHO
where od.ORDERKEY=@orderkey
order by 1,2















