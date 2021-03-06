-- �������� ������ ������

ALTER PROCEDURE [dbo].[proc_DA_OrderLinePacked]
(
	@wh varchar(10),
	@transmitlogkey varchar (10)
)
AS

SET NOCOUNT ON
SET XACT_ABORT ON

if @wh <> 'wh1'
begin
	raiserror('������������ ����� %s',16,1,@wh)
	return
end

declare	@orderkey varchar (10) -- ����� ������
declare	@key2 varchar (10)     -- ����� ������ ������
declare @linecnt  int
declare @linecnt2 int
declare @result table
(	
	[storerkey] varchar(15),
	[externorderkey] varchar(32),
	[type] varchar(10),
	[susr1] varchar(30),
	[susr2] varchar(30),
	[susr3] varchar(30),
	[consigneekey] varchar(10),
	[b_company] varchar(10),
	[carriercode] varchar(10),
	[sku] varchar(10),
	[packedqty] varchar(30)
)

select @orderkey = o.orderkey, @key2 = tl.key2 from wh1.orders o, wh1.transmitlog tl 
where tl.transmitlogkey = @transmitlogkey and o.orderkey = tl.key1

-- ���� �� ��� ������ ������ ���������, ��� ��������� ��� ���������� � ����-�������, �� �� ��������� ����

-- pickdetail.status = ''6'' ����������� ������ ������
-- pickdetail.status = ''9'' ����������� ������ ������

-- pickdetail.pdudf2 = ''6'' ������� ������ ������ � �������� � HOST ������� ����� ��������
-- pickdetail.pdudf2 = ''9'' ������� ������ ������ � �������� � HOST ������� ����� ��������

select @linecnt  = count(*) from wh1.pickdetail where orderkey = @orderkey
select @linecnt2 = count(*) from wh1.pickdetail where orderkey = @orderkey and [status]='6' and isnull(pdudf2,'')=''

if @linecnt = @linecnt2
begin
	--�������� ����� ��� ������ � ���
	exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
	
	--�������� � ��� ������� �� �������� ������
	insert wh1.transmitlog (whseid, transmitlogkey, tablename, key1) 
	values ('WH1', @transmitlogkey, 'orderpacked', @orderkey)

	-- ��������� ������ � �������� � ����-�������
	update wh1.pickdetail set pdudf2 = isnull(pdudf2,'')+ '6' where orderkey = @orderkey
end

select 'CUSTOMERORDERLINEPACKED' as filetype, * from @result

