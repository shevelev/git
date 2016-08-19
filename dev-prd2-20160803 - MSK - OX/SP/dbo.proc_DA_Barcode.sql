
ALTER PROCEDURE [dbo].[proc_DA_Barcode]
	@source varchar(500) = null
AS
-- ����� ������ ������ ��������� ��������� � �������� ���������� ��������
SET XACT_ABORT ON

declare @allowUpdate int
declare @id          int
declare @storerkey   varchar(15)
declare @sku         varchar(10)
declare @altsku      varchar(50)


print '1. ���������� ����������� ���������� ��'
	select @allowUpdate = allowUpdate from dbo.DA_MessageTypes where MessageKey = 'BarCode'

print '3. ��������� �������� ������� ������'
print '3.1. �������� ������� ����������� ����� storerkey, sku  � altsku'
	if 0 < (select count(*) from DA_BARCODE 
			where (storerkey is null or rtrim(storerkey)='') or
				  (sku is null or rtrim(sku)='') or
				  (altsku is null or rtrim(altsku)=''))
	begin
		raiserror ('�� ������ �������� (storer) ��� ��� ������ (sku) ��� �����-��� (altsku)',16,1)
		return
	end

print '3.3. �������� ������� storer � ����������� storer'
	set @storerkey = null
	select top 1 @storerkey = b.storerkey 
	from DA_BARCODE b left join WH1.STORER s on b.storerkey=s.storerkey
	where s.serialkey is null

	if @storerkey is not null
	begin
		raiserror ('�������� ����������� � ����������� storer (STORERKEY=%s)',16,2,@storerkey)
		return		
	end

print '3.4. �������� ������� sku � ����������� sku'
	select @storerkey = null, @sku = null
	select top 1 @storerkey = b.storerkey, @sku = b.sku
	from DA_BARCODE b left join WH1.SKU s on b.storerkey=s.storerkey and b.sku=s.sku
	where s.serialkey is null

	if @storerkey is not null
	begin
		raiserror ('����� ����������� � ����������� sku (STORERKEY=%s, SKU=%s)',16,3,@storerkey,@sku)
		return		
	end

print '3.5. �������� ����� ��, �� ����� 13'
	select @storerkey = null, @sku = null
	select top 1 @storerkey=storerkey, @sku=sku, @altsku=altsku from DA_BARCODE where len(altsku)>13

	if @storerkey is not null
	begin
		raiserror ('����� �����-���� ��������� 13 �������� (STORERKEY=%s, SKU=%s, ALTSKU=%s)',16,4,@storerkey,@sku,@altsku)
		return		
	end

print '4. �������� ������� �� � ����'
	declare @cnt int
	select @storerkey = null, @sku = null, @altsku=null, @cnt = 0
	select top 1 @storerkey=storerkey, @sku=sku, @altsku=altsku 
	from DA_BARCODE bc

	select @cnt = count(*)
	from wh1.altsku alt 
	where  @storerkey=alt.storerkey and @sku=alt.sku and @altsku=alt.altsku 
	
	-- �� ����, 
	if @cnt > 0 
	begin
		if @allowupdate=0  -- ���������� ���������
			begin 
				raiserror ('���������� ���������. ����� �������� ��� ���� � ����.  (STORERKEY=%s, SKU=%s, ALTSKU=%s)',16,4,@storerkey,@sku,@altsku)
				return		
			end
		else
		-- �� ����, ���������� ���������
		begin
			print '4.1 ���������� �����-�����'
			update alt set 
				storerkey = bc.storerkey, 
				sku = bc.sku, 
				altsku = bc.altsku, 
				packkey = s.packkey, 
				defaultuom = s.rfdefaultuom
			from wh1.altsku alt
				join DA_barcode bc on bc.storerkey=alt.storerkey and bc.sku=alt.sku and bc.altsku=alt.altsku
				join wh1.sku s on  bc.storerkey=s.storerkey and bc.sku=s.sku
			select @@rowcount
			print '4.1 ���������� �����-�����'
			update alt set 
				storerkey = bc.storerkey, 
				sku = bc.sku, 
				altsku = bc.altsku, 
				packkey = s.packkey, 
				defaultuom = s.rfdefaultuom
			from wh2.altsku alt
				join DA_barcode bc on bc.storerkey=alt.storerkey and bc.sku=alt.sku and bc.altsku=alt.altsku
				join wh2.sku s on  bc.storerkey=s.storerkey and bc.sku=s.sku
			select @@rowcount
		end
	end
	else
	begin
		print '4.2 ���������� ����� �����-�����'
		insert into wh1.altsku (storerkey, sku, altsku, packkey, defaultuom)
			select b.storerkey, b.sku, b.altsku, s.packkey, s.rfdefaultuom 
			from wh1.sku s, DA_BARCODE b 
				left join wh1.altsku b1 
			on (b.storerkey=b1.storerkey and b.sku=b1.sku and b.altsku=b1.altsku)		
			where b1.serialkey is null and b.sku=s.sku and b.storerkey=s.storerkey
		select @@rowcount
		print '4.2 ���������� ����� �����-�����'
		insert into wh2.altsku (storerkey, sku, altsku, packkey, defaultuom)
			select b.storerkey, b.sku, b.altsku, s.packkey, s.rfdefaultuom 
			from wh2.sku s, DA_BARCODE b 
				left join wh2.altsku b1 
			on (b.storerkey=b1.storerkey and b.sku=b1.sku and b.altsku=b1.altsku)		
			where b1.serialkey is null and b.sku=s.sku and b.storerkey=s.storerkey
		select @@rowcount
	end
delete from DA_BARCODE
