-- ������ �� ������� --

ALTER PROCEDURE [dbo].[proc_DA_PurchaseOrder]
	@source varchar(500) = null
AS
BEGIN	

declare @allowUpdate  int
declare @id           int
declare @externpokey  varchar(20)
declare @storerkey    varchar(15)
declare @sku          varchar(10)
declare @pokey        varchar(10)
declare @asn          varchar(10)
declare @errmsg       varchar(max)
declare @skip_unk_sku varchar(50)
declare @send_error   bit

set @send_error = 0
set @errmsg = ''
set @skip_unk_sku = 'N'

BEGIN TRY

print '1. ���������� ����������� ���������� ��'
	select @allowUpdate = allowUpdate from dbo.DA_MessageTypes where MessageKey = 'PO'

print '2. �������� ������� ������'

print '2.1 �������� ���� externpokey'
	if 0 < (select count(*) from DA_PurchaseOrderHead where rtrim(isnull(externpokey,''))='')
		raiserror ('�� ������ externpokey � ��������� ��',16,1)

	set @id = null
	select top 1 @id = id, @externpokey = externpokey from DA_PurchaseOrderDetail 
	where (externpokey is null) or (externpokey not in (select externpokey from DA_PurchaseOrderHead))

	if @id is not null
		raiserror ('����������� ��������� ��� ������� �� (EXTERNPOKEY=%s)',16,2,@externpokey)

print '2.2. �������� ��������� ����������'
--�������� � �������� ������� ����������� �� ������, �.�. ���� � DA_PurchaseOrderHead
--����� ��������� ���������� � ���������� EXTERNPOKEY, �� ���������, ��� ����� ����
--������������ ������ (DA_PurchaseOrderDetail ������� � DA_PurchaseOrderHead �� EXTERNPOKEY) 
	set @id = null
	select top 1 @id = h.id, @externpokey = h.externpokey from DA_PurchaseOrderHead h
	where h.id < (select max(id) from DA_PurchaseOrderHead h2 where h2.externpokey = h.externpokey)
	
	if @id is not null
		raiserror ('��������� �� � �������� ������� (EXTERNPOKEY=%s)',16,3,@externpokey)

print '2.3. �������� ����������� ���������� ��'
	if(@allowUpdate = 0)
	begin
		set @id = null
		select top 1 @id = h.id, @externpokey = h.externpokey 
		from DA_PurchaseOrderHead h left join wh1.po p on h.externpokey = p.externpokey
		where p.pokey is not null order by id

		if(@id is not null)
			raiserror ('���������� �� ��������� ���������� allowUpdate (EXTERNPOKEY=%s)',16,4,@externpokey)
	end

	set @id = null

	select top 1 @id = h.id, @externpokey = h.externpokey, @asn = p.otherreference 
	from DA_PurchaseOrderHead h, wh1.po p 
	where h.externpokey = p.externpokey and isnull(p.otherreference,'') != ''
	order by id

	if(@id is not null)
		raiserror ('���������� �� ���������: �� ������� � ��� (EXTERNPOKEY=%s; ���=%s)',16,5,@externpokey,@asn)

print '2.4. �������� ���������� (storerkey) � ���������� (������.)'
	set @id = null
	select top 1 @id = id, @externpokey = externpokey 
	from DA_PurchaseOrderHead h left join wh1.storer s on h.storerkey = s.storerkey
	where (s.serialkey is null) order by h.id

	if @id is not null
		raiserror ('���������� (storerkey) �� ������/����������� � ����������� storer (EXTERNPOKEY=%s)',16,6,@externpokey)

print '2.5. �������� ���������� (seller) � ���������� (��������.)'
	update DA_PurchaseOrderHead set seller = null where rtrim(seller)=''
	-- ���� ��������� ������, �� ������ ���� � �����������
	set @id = null
	select top 1 @id = id, @externpokey = externpokey 
	from DA_PurchaseOrderHead h left join wh1.storer s on h.seller = s.storerkey
	where (h.seller is not null) and (s.serialkey is null) order by h.id

	if @id is not null
		raiserror ('��������� (seller) ����������� � ����������� storer (EXTERNPOKEY=%s)',16,7,@externpokey)

print '2.6. �������� ���������� (storerkey) � �������'
	set @id = null
	select top 1 @id = h.id, @externpokey = h.externpokey 
	from DA_PurchaseOrderDetail d, DA_PurchaseOrderHead h 
	where h.externpokey = d.externpokey and h.storerkey != d.storerkey

	if @id is not null
		raiserror ('���������� (storerkey) � ������� � ��������� �� ��������� (EXTERNPOKEY=%s)',16,8,@externpokey)

print '2.7. �������� sku � �������'
	-- ���������� ������� � ����������� ������� ��� ������������ ���� �����
	select @skip_unk_sku=[value] from DA_SETTINGS where parameter='custom.po.skip_unknown_sku' and [enabled]=1
	
	-- ��������� ������� � ����������� �������
	select d.id, 0 as done into #t_errdetail 
	from DA_PurchaseOrderDetail d left join wh1.sku s on d.storerkey=s.storerkey and d.sku=s.sku
	where s.serialkey is null order by d.id
		
	if(@@rowcount > 0)
	begin
		while 1=1 -- ������� ��������� �������  � ������������ ���������
		begin
			set @id = null
			select top 1 @id=d.id, @externpokey=d.externpokey, @storerkey=d.storerkey, @sku=d.sku
			from DA_PurchaseOrderDetail d, #t_errdetail t 
			where d.id=t.id and done=0

			if(@id is null) break -- ������� ��������
			
			select @errmsg = @errmsg
				 + '����� �� ������/����������� � ����������� sku (EXTERNPOKEY=' + @externpokey + ', STORERKEY=' + @storerkey + ', SKU='+ @sku + ')'
				 + char(0x0d) + char(0x0a)

			-- ���� ����� ���� ���������, � raiserror �������� ������ ���� �������
			if(@skip_unk_sku = 'N') break

			set @send_error = 1
			update #t_errdetail set done=1 where id=@id
		end
		
		if(@skip_unk_sku = 'Y')
			delete DA_PurchaseOrderDetail where id in (select e.id from #t_errdetail e)

		drop table #t_errdetail

		if(@skip_unk_sku = 'N')
			raiserror(@errmsg,16,9)
	end
/*	
	set @id = null
	select top 1 @id = d.id, @externpokey = d.externpokey, @storerkey = d.storerkey, @sku = d.sku
	from DA_PurchaseOrderDetail d left join wh1.sku s on d.storerkey=s.storerkey and d.sku=s.sku
	where s.serialkey is null order by d.id

	if @id is not null
		raiserror ('����� �� ������/����������� � ����������� sku (EXTERNPOKEY=%s, STORERKEY=%s, SKU=%s)',16,9,@externpokey,@storerkey,@sku)
*/

print '2.8. ���������, ��� �� ������ �� �����������'
	set @id = null
	select top 1 @id = d.id, @externpokey = d.externpokey, @storerkey = d.storerkey, @sku = d.sku
	from DA_PurchaseOrderDetail d 
	where d.id < (select max(id) from DA_PurchaseOrderDetail d2 
					where d2.externpokey=d.externpokey and d2.storerkey=d.storerkey and d2.sku=d.sku)

	if @id is not null
		raiserror ('����� ����������� � ������� �� (EXTERNPOKEY=%s, STORERKEY=%s, SKU=%s)',16,10,@externpokey,@storerkey,@sku)

print '2.9. �������� ���-�� ������ � �������'
	set @id = null
	select top 1 @id = id, @externpokey = externpokey, @storerkey = storerkey, @sku = sku 
	from DA_PurchaseOrderDetail where isnull(qtyexpected, 0) <= 0 order by id

	if @id is not null
		raiserror ('�������� ���-�� ������ (EXTERNPOKEY=%s, STORERKEY=%s, SKU=%s)',16,11,@externpokey,@storerkey,@sku)

print '3. �������� / ���������� ��'

while 1=1 
begin
	set @id = null
	select top 1 @id = id, @externpokey = externpokey from DA_PurchaseOrderHead order by id
	if @id is null break

	-- ����� �� ��� ��� ���������� ?
	set @pokey = null
	select @pokey = pokey from wh1.po p where p.externpokey = @externpokey

	--���������� ������ ��
	if(@pokey is null)
	begin
		--�������� ����� ��� ���������
		exec dbo.DA_GetNewKey 'wh1','po',@pokey output
	
		insert into wh1.po (
		      whseid, pokey,  externpokey,  storerkey,    vesseldate,sellersreference,buyersreference,  potype,  susr1,  susr2,  susr3,  susr4, notes)
		select 'wh1',@pokey,h.externpokey,h.storerkey,h.expecteddate,        h.seller,    h.storerkey,h.potype,h.susr1,h.susr2,h.susr3,h.susr4, h.notes
			from DA_PurchaseOrderHead h where id = @id
	end
	--���������� ������������� ��
	else
	begin
		update p set 
			p.storerkey = h.storerkey,
			p.vesseldate = h.expecteddate,
			p.sellersreference = h.seller,
			p.buyersreference = h.storerkey,
			p.potype = h.potype,
			p.susr1 = h.susr1,
			p.susr2 = h.susr2,
			p.susr3 = h.susr3,
			p.susr4 = h.susr4,
			p.notes = h.notes
		from wh1.po p, DA_PurchaseOrderHead h
		where p.externpokey = h.externpokey and h.id = @id

		delete wh1.podetail where externpokey=@externpokey 
	end

	-- +0 ����� �������� ������� id, ����� � ����� ������� ����� 2 identity = ������
	select d.id+0 id, identity(int,1,1) linenumber into #LineNumTab 
	from DA_PurchaseOrderDetail d where d.externpokey=@externpokey 

	insert into wh1.podetail (whseid, pokey, polinenumber,  
			storerkey,  externpokey,  sku,skudescription,   qtyordered,  qtyadjusted,  unitprice,  packkey, uom,unit_cost)
	select  'wh1',@pokey, 
			replicate ('0',5-len(cast(l.linenumber as varchar))) + cast(l.linenumber as varchar),
			d.storerkey,d.externpokey,d.sku, s.descr,d.qtyexpected,d.qtyexpected,d.unitprice,s.packkey,'EA',isnull(d.tax01,0)
		from DA_PurchaseOrderDetail d inner join #LineNumTab l on ((d.id=l.id) and (d.externpokey=@externpokey))
			left join wh1.sku s on (s.storerkey=d.storerkey and s.sku=d.sku)

	drop table #LineNumTab

	-- ��������� �������������� ���������� ����
	update p set p.sellername = s.company
	from wh1.po p inner join wh1.storer s on (pokey=@pokey and s.storerkey=p.sellersreference)

	update p set p.buyername = s.company
	from wh1.po p inner join wh1.storer s on (pokey=@pokey and s.storerkey=p.buyersreference)

	update p set skudescription = s.descr
	from wh1.podetail p inner join wh1.sku s on (pokey=@pokey and s.storerkey=p.storerkey and s.sku=p.sku)

	-- �� ���������
	delete DA_PurchaseOrderHead where id=@id
	delete DA_PurchaseOrderDetail where externpokey=@externpokey
end

END TRY
BEGIN CATCH
	declare @error_message nvarchar(4000)
	declare @error_severity int
	declare @error_state int
	
	set @error_message  = ERROR_MESSAGE()
	set @error_severity = ERROR_SEVERITY()
	set @error_state    = ERROR_STATE()

	raiserror (@error_message, @error_severity, @error_state)
END CATCH

END

