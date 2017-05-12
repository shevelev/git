-- ����� �� �������� --

ALTER PROCEDURE [dbo].[proc_DA_ShipmentOrder_for_del]
	@source varchar(500) = null
as  

declare @id int
declare @externorderkey varchar(32)
declare @orderkey varchar(10)
declare @storerkey varchar(15)
declare @sku varchar(10)
declare @skugroup2 varchar(30)
declare @susr1 varchar(30)
declare @errmsg varchar(max)
declare @send_error bit
declare @skip_unk_sku varchar(10)

CREATE TABLE [#t_errdetail](
	id int not null, -- id ��������� ������ ������ �� DA_ShipmentOrderDetail
	done bit		 -- ���� ���������
)

set @send_error = 0
set @errmsg = ''
set @skip_unk_sku = 'N'

BEGIN TRY

print '1. ������'

update DA_ShipmentOrderHead set [type] = '0' where [type] <> '0'
update DA_ShipmentOrderDetail set tax01 = 0 where tax01 is null
update DA_ShipmentOrderDetail set ngtd = substring(isnull(ngtd,''),1,30)

update DA_ShipmentOrderHead set consigneekey = b_company where isnull(consigneekey,'')=''
update DA_ShipmentOrderHead set b_company = consigneekey where isnull(b_company,'')=''

print '2. �������� ������� ������'

print '2.1 �������� ���� externorderkey'
	if 0 < (select count(*) from DA_ShipmentOrderHead where rtrim(isnull(externorderkey,''))='')
		raiserror ('�� ������ externorderkey � ��������� ��',16,1)

	set @id = null
	select top 1 @id = id, @externorderkey = externorderkey from DA_ShipmentOrderDetail 
	where (externorderkey is null) or (externorderkey not in (select externorderkey from DA_ShipmentOrderHead))

	if @id is not null
		raiserror ('����������� ��������� ��� ������� �� (EXTERNORDERKEY=%s)',16,2,@externorderkey)

print '2.2. �������� ��������� ����������'
--�������� � �������� ������� ����������� �� ������, �.�. ���� � DA_ShipmentOrderHead
--����� ��������� ���������� � ���������� EXTERNORDERKEY, �� ���������, ��� ����� ����
--������������ ������ (DA_ShipmentOrderDetail ������� � DA_ShipmentOrderHead �� EXTERNORDERKEY) 
	set @id = null
	select top 1 @id = h.id, @externorderkey = h.externorderkey from DA_ShipmentOrderHead h
	where h.id < (select max(id) from DA_ShipmentOrderHead h2 where h2.externorderkey = h.externorderkey)
	
	if @id is not null
		raiserror ('��������� �� � �������� ������� (EXTERNORDERKEY=%s)',16,3,@externorderkey)

print '2.3. �������� ������� ���������� (�� ��������� ��������� ������)'
	set @id = null
	select top 1 @id = h.id, @externorderkey = h.externorderkey 
	from DA_ShipmentOrderHead h left join wh1.orders o on h.externorderkey = o.externorderkey
	where o.orderkey is not null order by id

	if(@id is not null)
		raiserror ('���������� �� ��������� (EXTERNORDERKEY=%s)',16,4,@externorderkey)

print '2.4. �������� ���������'
	set @id = null
	select top 1 @id = id, @externorderkey = externorderkey 
	from DA_ShipmentOrderHead h left join wh1.storer s on h.storerkey = s.storerkey
	where (s.serialkey is null) order by h.id

	if @id is not null
		raiserror ('�������� (storerkey) ����������� � ����������� storer (EXTERNORDERKEY=%s)',16,5,@externorderkey)

	set @id = null
	select top 1 @id = h.id, @externorderkey = h.externorderkey 
	from DA_ShipmentOrderDetail d, DA_ShipmentOrderHead h 
	where h.externorderkey = d.externorderkey and h.storerkey != d.storerkey

	if @id is not null
		raiserror ('�������� (storerkey) � ������� � ��������� �� ��������� (EXTERNORDERKEY=%s)',16,6,@externorderkey)

print '2.5. �������� ����� ��������'
	set @id = null
	select top 1 @id = id, @externorderkey = externorderkey 
	from DA_ShipmentOrderHead h left join wh1.storer s on h.consigneekey = s.storerkey
	where (s.serialkey is null) order by h.id

	if @id is not null
		raiserror ('����� �������� (consigneekey) ����������� � ����������� storer (EXTERNORDERKEY=%s)',16,7,@externorderkey)

print '2.6. �������� ����������� (��������.)'
	update DA_ShipmentOrderHead set carriercode = null where rtrim(carriercode)=''
	-- ���� ��� ������, �� ������ ���� � �����������
	set @id = null
	select top 1 @id = id, @externorderkey = externorderkey 
	from DA_ShipmentOrderHead h left join wh1.storer s on h.carriercode = s.storerkey
	where (h.carriercode is not null) and (s.serialkey is null) order by h.id

	if @id is not null
		raiserror ('��� ����������� (carriercode) ����������� � ����������� storer (EXTERNORDERKEY=%s)',16,8,@externorderkey)

print '2.7. ���������, ��� � �� ������ �� �����������'
	set @id = null
	select top 1 @id = d.id, @externorderkey = d.externorderkey, @storerkey = d.storerkey, @sku = d.sku
	from DA_ShipmentOrderDetail d 
	where d.id < (select max(id) from DA_ShipmentOrderDetail d2 
					where d2.externorderkey=d.externorderkey and d2.storerkey=d.storerkey and d2.sku=d.sku)

	if @id is not null
		raiserror ('����� ����������� � ������� �O (EXTERNORDERKEY=%s, STORERKEY=%s, SKU=%s)',16,9,@externorderkey,@storerkey,@sku)

print '2.8. �������� sku � �������'
	-- ���������� ������� � ����������� ������� ��� ������������ ���� �����
	select @skip_unk_sku=[value] from DA_SETTINGS where parameter='custom.so.skip_unknown_sku' and [enabled]=1
	
	-- ��������� ������� � ����������� �������
	insert #t_errdetail (id, done)
		select od.id, 0 as done
		from DA_ShipmentOrderDetail od left join wh1.sku s on od.storerkey=s.storerkey and od.sku=s.sku
		where s.serialkey is null order by od.id

	if(@@rowcount > 0)
	begin		
		while 1=1 -- ������� ��������� �������  � ������������ ���������
		begin
			set @id = null

			select top 1 @id = d.id, @externorderkey = d.externorderkey, @storerkey = d.storerkey, @sku = d.sku
			from DA_ShipmentOrderDetail d, #t_errdetail t 
			where d.id=t.id and done=0

			if(@id is null) break -- ������� ��������

			select @errmsg = @errmsg
				 + '����� �� ������/����������� � ����������� sku (EXTERNORDERKEY=' + @externorderkey + ', STORERKEY=' + @storerkey + ', SKU='+ @sku + ')'
				 + char(0x0d) + char(0x0a)

			-- ���� ����� ���� ���������, � raiserror �������� ������ ���� �������
			if(@skip_unk_sku = 'N') break

			set @send_error = 1
			update #t_errdetail set done=1 where id=@id
		end

		if(@skip_unk_sku = 'Y')
		begin
			delete DA_ShipmentOrderDetail where id in (select e.id from #t_errdetail e)
			delete #t_errdetail
		end
		else
			raiserror(@errmsg,16,10)
	end

print '2.9. �������� ���-�� ������ � �������'
	while 1=1
	begin
		set @id = null
		select top 1 @id = id, @externorderkey = externorderkey, @storerkey = storerkey, @sku = sku 
		from DA_ShipmentOrderDetail where isnull(openqty, 0) < 0 order by id

		if @id is null break

		set @send_error = 1
		delete DA_ShipmentOrderDetail where id=@id

		set @errmsg = @errmsg + 
			'�������� ���������� ������ (EXTERNORDERKEY=' + @externorderkey + ', STORERKEY=' + @storerkey + ', SKU=' + @sku + ')' + 
			char(0x0d) + char(0x0a)			
	end

print '2.10. �������� storerxsku'
	insert #t_errdetail (id, done)
		select od.id, 0 as done
		from DA_ShipmentOrderHead da
		join DA_ShipmentOrderDetail od on (da.storerkey=od.storerkey and da.externorderkey=od.externorderkey)
		join wh1.sku sk on (od.storerkey=sk.storerkey and od.sku=sk.sku)
		join wh1.storer sr on (od.storerkey=sr.storerkey)
		left join wh1.storerxsku x on (sr.susr1 = x.storergroup and sk.skugroup2=x.skugroup) 
		where x.id is null --x.skugroup is null

	if(@@rowcount > 0)
	begin		
		while 1=1
		begin
			set @id = null
			select top 1 @id=d.id, @externorderkey=d.externorderkey, @storerkey=d.storerkey, @sku=d.sku, @susr1=sr.susr1, @skugroup2=sk.skugroup2 
			from DA_ShipmentOrderDetail d, wh1.sku sk, wh1.storer sr, #t_errdetail t 
			where d.id=t.id and done=0 and d.storerkey = sr.storerkey and d.storerkey = sk.storerkey and d.sku = sk.sku

			if(@id is null) break

			set @send_error = 1

			select @errmsg = @errmsg + '��� ������������ � storerxsku (EXTERNORDERKEY=' + @externorderkey + ', STORERKEY=' + @storerkey + ', SKU=' + @sku + ', STORERGROUP=' + @susr1 + ', SKUGROUP=' + @skugroup2 + ')' + char(0x0d) + char(0x0a)
			update #t_errdetail set done=1 where id=@id
		end
	
		delete DA_ShipmentOrderDetail where id in (select e.id from #t_errdetail e)
		delete #t_errdetail
	end

print '3. �������� / ���������� ��'

while 1=1 
begin
	set @id = null
	select top 1 @id = id, @externorderkey = externorderkey from DA_ShipmentOrderHead order by id
	if @id is null break

	--�������� ����� ��� ���������
	exec dbo.DA_GetNewKey 'wh1','order',@orderkey output

	insert into wh1.orders (
			whseid, orderkey,  externorderkey,  storerkey, 
			[type], susr1, susr2, susr3, susr4,
			consigneekey, c_company,
			c_city,	c_contact1,	c_contact2,
			b_city,	b_contact1,	b_contact2, b_company,
			c_address1,	c_address2,	c_address3,	c_address4,	
			b_address1,	b_address2,	b_address3,	b_address4,				
			carriercode, requestedshipdate,
			transportationmode, door)
	select 'wh1', 
			@orderkey, h.externorderkey, h.storerkey,
			h.[type],  h.susr1,	h.susr2, h.susr3, h.susr4,
			h.consigneekey, s.company,
			h.c_city, h.c_contact1,	h.c_contact2,
			h.b_city, h.b_contact1, h.b_contact2, h.b_company,
			substring(h.c_address,1,45),substring(h.c_address,46,45),substring(h.c_address,91,45),substring(h.c_address,136,45),
			substring(h.b_address,1,45),substring(h.b_address,46,45),substring(h.b_address,91,45),substring(h.b_address,136,45),
			h.carriercode, h.requestedshipdate,
			'1', -- ������� (������) �� wh1.codelkup (LASTNAME='TRANSPMODE',CODE='1')
			'VOROTA'
		from DA_ShipmentOrderHead h, wh1.storer s where id = @id and s.storerkey = h.consigneekey

		-- +0 ����� �������� ������� id, ����� � ����� ������� ����� 2 identity = ������
		select d.id+0 id, identity(int,1,1) linenumber into #LineNumTab 
		from DA_ShipmentOrderDetail d where d.externorderkey=@externorderkey 

		insert into wh1.orderdetail (whseid, orderkey, 
				orderlinenumber, 
				externorderkey, storerkey, sku, openqty, originalqty, unitprice, tax01, packkey, uom, susr1)
		select  'wh1', @orderkey, 
				replicate ('0',5-len(cast(l.linenumber as varchar))) + cast(l.linenumber as varchar),
				d.externorderkey, d.storerkey, d.sku, d.openqty, d.openqty, d.unitprice, d.tax01, s.packkey, 'EA', d.ngtd
			from DA_ShipmentOrderDetail d inner join #LineNumTab l on ((d.id=l.id) and (d.externorderkey=@externorderkey))
				left join wh1.sku s on (s.storerkey=d.storerkey and s.sku=d.sku)

		-- �������������� ����
		update od set 
--			����������: 14/10/2009 ������� �����
--						��� ����� ������ �� ���� ������������ � ������ ������ ����� ���������
--						�� ����������� ���������� ����, � ������������ ���� ��������� �� ��� ������������
--			od.shelflife = case when sk.shelflifeindicator='Y' then x.shelflife else '0' end,
			od.shelflife = case when sk.shelflifeindicator='Y' and sk.rotateby='Lottable05' then isnull(x.shelflife,0)
								when sk.shelflifeindicator='Y' and sk.rotateby='Lottable04' then isnull(sk.shelflife-x.shelflife,0)
								else '0' end,
			od.allocatestrategykey = isnull(st.allocatestrategykey, 'STD5'),			
			od.preallocatestrategykey = isnull(st.preallocatestrategykey, 'STD5'),
			od.allocatestrategytype = isnull(ast.allocatestrategytype, '2'),
			od.skurotation = sk.rotateby,
			od.product_weight = sk.grosswgt * od.openqty,
			od.product_cube = sk.cube * od.openqty,
			od.cartongroup = sk.cartongroup + isnull(x.pallettype,'')
		from wh1.orderdetail od
			inner join DA_ShipmentOrderHead da on (da.id = @id and da.externorderkey = od.externorderkey)
			inner join wh1.storer sr on (sr.storerkey = da.consigneekey)
			inner join wh1.sku sk on (sk.sku = od.sku and sk.storerkey = od.storerkey)
			inner join wh1.storerxsku x on (x.storergroup = sr.susr1 and x.skugroup = sk.skugroup2)
			left join wh1.strategy st on (st.strategykey = sk.strategykey + isnull(x.packtype,''))
			left join wh1.allocatestrategy ast on (ast.allocatestrategykey=st.allocatestrategykey)

	drop table #LineNumTab
	
	delete DA_ShipmentOrderDetail where externorderkey=@externorderkey
	delete DA_ShipmentOrderHead where id=@id	
end

END TRY
BEGIN CATCH
	declare @error_message nvarchar(4000)
	declare @error_severity int
	declare @error_state int
	
	set @error_message  = ERROR_MESSAGE()
	set @error_severity = ERROR_SEVERITY()
	set @error_state    = ERROR_STATE()

	set @send_error = 0
	raiserror (@error_message, @error_severity, @error_state)
END CATCH

if @send_error = 1
begin
	exec app_DA_SendMail @source, @errmsg
end

drop table #t_errdetail

