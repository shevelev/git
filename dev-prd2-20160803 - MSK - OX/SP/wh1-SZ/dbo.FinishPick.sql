
ALTER PROCEDURE [dbo].[FinishPick](
	@orderkey VARCHAR(10)='',
	@additional_param int = 0
)
AS
DECLARE 
	@nezav int,
	@cantCancel int

SELECT @nezav = COUNT(*)
FROM Wh1.ORDERS
WHERE ORDERKEY = @orderkey

IF @nezav = 0
BEGIN
	Select'������ �������� ����� ��������'
	RETURN 
END

SELECT @cantCancel = COUNT(*)
FROM WH1.ORDERS
WHERE ORDERKEY =@orderkey and STATUS = '95'

IF @cantCancel > 0
BEGIN
	Select '������ �������� ����� (������ 95)'
	RETURN;
END

SELECT @nezav = COUNT(*)
FROM Wh1.PICKDETAIL
WHERE ORDERKEY = @orderkey and STATUS = 0

			
IF @nezav > 0 
	Select'������������� �����' 
ELSE IF @additional_param = 1
	BEGIN
		Select '����� ��������'
		UPDATE WH1.ORDERS
		SET status = 99, EXTERNORDERKEY='OLD'+EXTERNORDERKEY
		WHERE ORDERKEY = @orderkey
		
	INSERT INTO DA_InboundErrorsLog (source,msg_errdetails) 
	SELECT 'Orders99', '�������� ������ ������: ' + @orderkey
	
			
		--���������� ������ � ������� �� ������
		insert wh1.orderstatushistory (ORDERLINENUMBER,orderkey, whseid, ordertype, status, addwho, adddate ,comments)
		values ('',@orderkey, 'WH1', 'SO', '98', 'CanselSO', getdate(), 'CancelSO.. report')
	
		
	END
ELSE 
	Select '�������� �����?'



