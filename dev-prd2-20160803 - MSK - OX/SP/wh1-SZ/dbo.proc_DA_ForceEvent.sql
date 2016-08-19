-- ====================================================
-- ��������� �������� ��������� �� Infor � host-�������
-- ====================================================
ALTER PROCEDURE [dbo].[proc_DA_ForceEvent]
	@wh    varchar(10), -- �����
	@event varchar(50), -- �������: orderpacked, ordershipped, asnclosed
	@key   varchar(10)  -- ����� ������
AS
BEGIN
	SET NOCOUNT ON	

	declare @tlkey varchar(10)
	declare @result as varchar
	declare @new_event bit	-- ��������� �������� ������� (������ ordershipped)

	set @new_event = 0

	if(@wh <> 'wh1' or @event not in ('orderpacked','ordershipped','asnclosed'))
	begin
		set @result='������� ������� ������� ��� �����'
		print @result
		select @result
		return
	end

	select top 1 @tlkey = transmitlogkey from wh1.transmitlog 
	where tablename=@event and key1=@key and whseid = @wh
	order by serialkey desc

	--���� ����� ������� �������, �� �� �� ��� ������������� ������� ordershipped.
	--������� ����� ��������� ������� ��������� �������� � ��������� ���.
	--��� ��� ��������� ��������� �� ������ ������� ������� ordershipped.
	if(@tlkey is null and @event = 'ordershipped')
	begin
		select top 1 @tlkey = transmitlogkey from wh1.transmitlog 
		where tablename='partialshipment' and key1=@key and whseid = @wh
		order by serialkey desc
		
		if(@tlkey is not null)
			set @new_event = 1			
	end

	if(@tlkey is null)
	begin
		set @result='��������� ������� �� ������� ��������� �� ������� � TRANSMITLOG'
		print @result
		select @result
		return
	end

	if(@event = 'asnclosed')
		update wh1.receipt set susr5 = null where receiptkey = @key

	update wh1.transmitlog set transmitflag9 = null where transmitlogkey = @tlkey

	if(@event = 'ordershipped' and @new_event = 1)
		select '������� "'+@event+'" �� ��������� � '+@key+' � ����� '+@wh+' �� �������. ����-�������� ���������� ������� �� �������� ������� � TRANSMITLOG.'
	else	
		select '������� "'+@event+'" �� ��������� � '+@key+' � ����� '+@wh+' ������� (transmitlogkey='+cast(@tlkey as varchar)+') � ��������� ��������...'
	
END

