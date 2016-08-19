/* ������ �� � ������ */
ALTER PROCEDURE [dbo].[rep53_test](
 	@dat1  datetime,
 	@dat2  datetime,
 	@vtn   varchar (50),
 	@vnn   varchar (50)
)
AS

	set @dat1= replace(upper(@dat1),';','')  -- ������� ; �� ����� ���������� ������������� ��� ���������� ������������.
	set @dat2= replace(upper(@dat2),';','') 

declare @date1 varchar(10), @date2 varchar(10)
	-- ��������� �������� ��� �� ���������� ����������.
	set @date1 = convert(varchar(10),@dat1,112)
	set @date2 = convert(varchar(10),dateadd(dy,1,@dat2),112)
	-- ���� ���� �� ������ ������ ����� ��������� ����, �������� ������������� ��� ����� ������ �������
	if @date1 is null set @date1 = '20000101' -- 1 ��� 2000
	if @date2 is null set @date2 = convert(varchar(10), dateadd(yy,1,getdate()),112) -- ���. ���� ���� ���
	-- � ������ ���� ���� ���������� ������� ��������������� ���������� �������
	declare @tmp varchar(10)
	if @date2 < @date1 
	begin
		select @tmp = @date2, @date2 = @date1
		select @date1 = @tmp
	end

SELECT     tt.ORDERKEY, tt.EXTERNORDERKEY, pd.CASEID, pd.ORDERLINENUMBER, pd.SKU, 
                      pd.QTY, pd.QTYMOVED, pd.STATUS
FROM         WH1.ORDERS tt
INNER JOIN WH1.ORDERDETAIL od ON tt.ORDERKEY =od.ORDERKEY
INNER JOIN WH1.PICKDETAIL pd ON tt.ORDERKEY = pd.ORDERKEY
                      
where tt.EXTERNORDERKEY like '%'+isnull(@vnn,'')+'%' 
and tt.ORDERKEY like '%'+isnull(@vtn,'')+'%' and (tt.adddate between @date1 and @date2)



