--################################################################################################
-- ��������� ������ ������ �� �������� � ��������������� ���������
--################################################################################################
ALTER PROCEDURE [rep].[closeSO]
	@orderkey varchar(10) -- ����� ��������
AS

declare @st varchar(5)



select @st=status from wh1.orders where ORDERKEY=@orderkey

if @st<'92'
	begin
		update wh1.orders set STATUS='98', EXTERNORDERKEY='OLD'+EXTERNORDERKEY where ORDERKEY=@orderkey -- ������ ������ ������
		declare @transmitlogkey varchar(10)
		exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
		
		--�������� � ��� ������� �� ������ ������
		insert wh1.transmitlog (whseid, transmitlogkey, tablename, key1, ADDWHO) 
		values ('WH1', @transmitlogkey, 'CancelSO', @orderkey, 'CancelSO')
		
		--���������� ������ � ������� �� ������
		insert wh1.orderstatushistory (ORDERLINENUMBER,orderkey, whseid, ordertype, status, addwho, adddate ,comments)
		values ('',@orderkey, 'WH1', 'SO', '98', 'CanselSO', getdate(), 'CancelSO.. report')

	end

select pd.caseid,od.ORDERLINENUMBER, od.sku,s.DESCR, od.LOTTABLE02,td.TOLOC, td.qty otbor, td.FROMLOC, td.TOID, td.editdate ADDDATE, u.usr_lname+' '+u.usr_fname editWHO
from wh1.orderdetail od
	join wh1.sku s on s.SKU=od.sku
	join wh1.PICKDETAIL pd on od.ORDERKEY=pd.ORDERKEY and od.ORDERLINENUMBER=pd.ORDERLINENUMBER
	join wh1.taskdetail td on td.PICKDETAILKEY=pd.PICKDETAILKEY and td.STATUS=9
	join ssaadmin.pl_usr u on u.usr_login=td.EDITWHO
where od.ORDERKEY=@orderkey
order by 1,2














