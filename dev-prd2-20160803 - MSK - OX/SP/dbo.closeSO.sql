--################################################################################################
-- Процедура отмена заказа на отгрузку и расформирования накладной
--################################################################################################
ALTER PROCEDURE [dbo].closeSO
	@orderkey varchar(10) -- номер отгрузки
AS

declare @st varchar(5)



select @st=status from wh1.orders where ORDERKEY=@orderkey

--if @st<'92'
--	begin
--		--update wh1.orders set STATUS='98' where ORDERKEY=@orderkey -- меняем статус заказа
--		--declare @transmitlogkey varchar(10)
--		--exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
		
--		----записать в лог событие об отмене заказа
--		--insert wh1.transmitlog (whseid, transmitlogkey, tablename, key1, ADDWHO) 
--		--values ('WH1', @transmitlogkey, 'CancelSO', @orderkey, 'CancelSO')	

--	end

select pd.caseid,od.ORDERLINENUMBER, od.sku,s.DESCR, od.LOTTABLE02, td.qty otbor, td.FROMLOC, td.TOID, td.editdate ADDDATE, u.usr_lname+' '+u.usr_fname editWHO
from wh1.orderdetail od
	join wh1.sku s on s.SKU=od.sku
	join wh1.PICKDETAIL pd on od.ORDERKEY=pd.ORDERKEY and od.ORDERLINENUMBER=pd.ORDERLINENUMBER
	join wh1.taskdetail td on td.PICKDETAILKEY=pd.PICKDETAILKEY and td.STATUS=9
	join ssaadmin.pl_usr u on u.usr_login=td.EDITWHO
where od.ORDERKEY=@orderkey
order by 1,2















