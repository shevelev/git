ALTER PROCEDURE [dbo].[proc_DA_Order]
as  
--############################################################### ����� �� ��������
print '1.1. ������ ���� �������������� ���������� ���������� flag = 0'
	select * into ##DA_OrderHead from DA_OrderHead where flag = 0
print '1.2. ������ ���� ������� ���������� � flag = 0'
	select oh.id ohid, identity(int,1,1) orderlinenumber, od.* into ##DA_OrderDetail from DA_OrderDetail od join ##DA_OrderHead oh on od.externorderkey = oh.externorderkey and od.flag = 0

print '2. ����� ���������� �������� ������� ���������� ����� ����������'
print '2.1. ���������� ���� ������� ��������� ������� "������"'
	update ##DA_OrderHead set flag = 3, because = '������������� � ������ ������� ��������'
	select doh.externorderkey, max (doh.id) id into #da_uni
		from ##DA_OrderHead doh left join ##DA_OrderHead dos on doh.externorderkey = dos.externorderkey
		group by doh.externorderkey
print '2.2. ���������� ������� ���������� ������� "�����������"'
	update doh set doh.flag = 0, doh.because = ''
		from ##DA_OrderHead doh join #da_uni du on doh.id = du.id
print '2.3. ���������� ���� ������� ������� ������� "������"'
	update ##DA_OrderDetail set flag = 3, because = '������������� ��������' where flag = 0
print '2.4. ���������� ������� ������� ������� "�����������"'
	update dod set dod.flag = 0, dod.because = ''
		from ##DA_OrderDetail dod join ##DA_OrderHead doh on dod.ohid = doh.id where doh.flag = 0

print '3. ��������� �������� ������� ������'
--print '	-- ��������� �������� null �� empty � ���� ordergroup�'
--	update ##DA_OrderHead set ordergroup = ''
--		where ordergroup is null
print '3.1. �������� �� ������������� ���������� ����������'
	declare @allowUpdate int
	select @allowUpdate = allowUpdate from dbo.DA_MessageTypes where MessageKey = 'SO'
print '3.1.0. ������� ����� ������ �� ����� ���� ����� consolidation'
	update ##DA_OrderHead set flag = 3, because = '������� ����� ������ �� ����� ���� ����� consolidation'
		where externorderkey = 'consolidation'
print '3.1.1. ��������� flag �� ����������, ������������ � ���� ��� allowupdate = 0'
	update doh set doh.flag = 3, doh.because = '��������� ������������ ���������� ��������� (������������� ��������)'
		from ##DA_OrderHead doh join wh1.Orders o on doh.externorderkey = o.externorderkey
	where doh.flag = 0 and @allowUpdate = 0

--????????????????????????????????????????????????????????????
--print '3.1.2. �������� ������������� ������������������ ������, ���� ����� ��� ��� ����� � ������������'
--	delete from oc 
--		from wh1.orders_c oc join ##DA_OrderHead doh on oc.externorderkey = doh.externorderkey
--		where doh.flag = 0 and not oc.orderkey in (select orderkey from wh1.orders where externorderkey = 'consolidation')
--	delete from odc
--		from wh1.orderdetail_c odc join ##DA_OrderHead doh on odc.externorderkey = doh.externorderkey
--		where doh.flag = 0 and not odc.orderkey in (select orderkey from wh1.orders where externorderkey = 'consolidation')
--????????????????????????????????????????????????????????????
			
print '3.1.2. ��������� flag �� ����������, ������������ � consolidation �������'
	update doh set doh.flag = 3, doh.because = '��������� ������������ ���������� � ����������������� ������ - ��������� (������������� ��������)'
		from ##DA_OrderHead doh join wh1.Orders_c o on doh.externorderkey = o.externorderkey
	where doh.flag = 0 and @allowUpdate = 0

	update dod set dod.flag = 3, dod.because = '������ � ��������� ���������'
		from ##DA_OrderHead doh join ##DA_OrderDetail dod on doh.id = dod.ohid
	where doh.flag = 3 and dod.flag = 0

print '3.2. ���������� ������� � ������������� ��� 0 �����������'
	update ##DA_OrderDetail set flag = 2, because = '������������� ���������� � ������ ������' where openqty <= 0

print '3.3. ��������� ������� ����������� ������������ � �����������'
	update doh set doh.flag = 2, doh.because = '���������� ���������� � ����������� storer'
		from ##DA_OrderHead doh where not doh.storerkey in (select storerkey from wh1.storer) and doh.flag = 0

print '3.4.1. ��������� ������� ����������� �������� ����� � �����������'
	update doh set doh.flag = 2, doh.because = '��������� �������� ����� � ����������� storer'
		from ##DA_OrderHead doh where not doh.consigneekey in (select storerkey from wh1.storer) and doh.flag = 0

print '3.4.2. ��������� ������� ��������������� null (�������� �����)'
	update doh set doh.flag = 2, doh.because = '����������� �������� ����� consigneekey'
		from ##DA_OrderHead doh where (doh.consigneekey is null or rtrim(ltrim(doh.consigneekey)) = '') and doh.flag = 0
print '3.4.3. ��������� ������� ���������� null (����������)'
	update doh set doh.b_company = case when doh.b_company is null or rtrim(ltrim(doh.b_company)) = '' then '' else doh.b_company end
		from ##DA_OrderHead doh

print '3.4.1. ��������� ������� ����������� ����������� � �����������'
	update doh set doh.flag = 2, doh.because = '��������� ���������� � ����������� consigneekey'
		from ##DA_OrderHead doh where not doh.b_company in (select storerkey from wh1.storer) and doh.flag = 0 and doh.b_company != ''

print '3.5. ��������� ������� ����������� ������������ � �����������'
	update doh set doh.flag = 2, doh.because = '��������� ���������� � ����������� storer'
		from ##DA_OrderHead doh where not doh.carriercode in (select storerkey from wh1.storer) and doh.flag = 0

print '3.6. ���������� � ������������ ���� ������� �� ������������ �������'
	update dod set dod.flag = 2, dod.because = '������ � ��������� ���������'
		from ##DA_OrderHead doh join ##DA_OrderDetail dod on doh.id = dod.ohid
		where doh.flag = 2 and dod.flag = 0

print '3.7. ��������� ������� ����������� ������� � �����������'
	update dod set dod.flag = 2, dod.because = '��������� ����� � ����������� sku'
		from ##DA_OrderDetail dod where not dod.sku + dod.storerkey in (select sku + storerkey from wh1.sku) and dod.flag = 0


--print '3.7.1. ��������� ����� �� ���������� � ���������� ���������'
--	update doh set doh.flag = 2, because = '� ����� �� ����� ���������� ���� ����������� �����'
--		from ##DA_OrderDetail dod join ##DA_OrderHead doh on doh.id = dod.ohid
--		where dod.flag > 1 and doh.flag = 0
--print '3.7.2. ���������� � ������������ ���� ������� �� ������������ �������'
--	update dod set dod.flag = 2, dod.because = '� ����� �� ����� ��������� ���� ������������ �����.'
--		from ##DA_OrderHead doh join ##DA_OrderDetail dod on doh.id = dod.ohid
--		where doh.flag = 2 and dod.flag = 0


print '3.8. ������� ������������ ���������� � ��������� ������'
	update doh set c_company = st.company
		from ##DA_OrderHead doh join wh1.Storer st on doh.consigneekey = st.storerkey

print '3.9. ������� ������������ ����������� � ��������� ������'
	update doh set doh.carriername = st.company
		from ##DA_OrderHead doh join wh1.Storer st on doh.carriercode = st.storerkey	

print '3.10. ������� ��� ���������� � ��������� ������'
	update doh set doh.c_vat = st.vat
		from ##DA_OrderHead doh join wh1.Storer st on doh.consigneekey = st.storerkey	

print '3.11. ������� ������� � ��������� ������'
	update doh set doh.c_address1 = st.address1, doh.c_address2 = st.address2, doh.c_address3 = st.address3, doh.c_address4 = st.address4
		from ##DA_OrderHead doh join wh1.Storer st on doh.consigneekey = st.storerkey

print '3.12. �������� ���� �� � ������ ���� ���� ������'
	if (select count (dod.id) from ##DA_Orderdetail dod join ##DA_OrderHead doh on doh.id = dod.ohid where dod.flag = 0) = 0
		begin
			print '3.12.1. � ������ ��� �� ����� ������ ������'
			update doh set doh.flag = 2, doh.because = '� ������ ��� �� ����� ���������� ������'
				from ##DA_OrderHead doh 
			where doh.flag = 0
			goto nextstep
		end


print '3.9. ������������ ����� ������ ������������, ��������� ��� ������ ������'
update dod set dod.allocatestrategykey = ast.allocatestrategykey, dod.preallocatestrategykey = stg.preallocatestrategykey, dod.allocatestrategytype = ast.allocatestrategytype, 
dod.cartongroup = s.cartongroup + case when stxs.pallet is null or rtrim(ltrim(stxs.pallet)) = '' then '' else rtrim(ltrim(stxs.pallet)) end, dod.packkey = s.packkey, dod.shelflife = stxs.shelflife
--select s.strategykey + ltrim(rtrim(stxs.packtype)) strategy, s.cartongroup + case when stxs.pallet is null or rtrim(ltrim(stxs.pallet)) = '' then '' else stxs.pallet end cartongroup
	from ##DA_OrderHead doh join ##DA_OrderDetail dod on doh.id = dod.ohid -- ������ ����� � ��������
		join wh1.sku s on dod.sku = s.sku and dod.storerkey = s.storerkey -- ������ � �������� sku ��� ��������� ��� ������ cartongroup, � ��������� ����������
		join wh1.storer st on st.storerkey = case when doh.b_company is null or ltrim(rtrim(doh.b_company)) = '' then doh.consigneekey else doh.b_company end -- susr1 ��� ���������� (��� �������)
		join wh1.storerxsku stxs on stxs.susr1 = st.susr1 and stxs.busr4 = s.busr4 -- ����������� ����� �� ����� ��������, ���� ������������, 
		join wh1.strategy stg on stg.strategykey = (s.strategykey + case when ltrim(rtrim(stxs.packtype)) = '' or stxs.packtype is null then '' else stxs.packtype end) -- ����� ����� ��� ����� ���������
		join wh1.allocatestrategy ast on ast.allocatestrategykey = stg.allocatestrategykey
	where dod.flag = 0 and doh.flag = 0

update dod set dod.flag = 2, dod.because = '��� ����������� ������ ������������ �/��� ���������'
	from ##DA_OrderDetail dod where dod.allocatestrategykey is null or rtrim(ltrim(dod.allocatestrategykey)) = ''

print '4.0. �������� ������� ����������� �������'
	if (select count(externorderkey) from ##DA_OrderHead where flag = 0) = 0 
		begin
			print '4.1. ����������� ������� ���'
		end
	else
		begin
			print '4.2. ���� ����������� �����. ������������.'
			exec app_DA_OrderIn
		end

nextstep:
print '5. �������� ����������'
print '5.1. ��������� flag = 2 � ������ ��������� ����������'
	update doh set doh.flag = 2, doh.because = case when doh.because is null or doh.because = '' then '������ � ������� ���������' else doh.because end
		from ##DA_OrderHead doh join ##DA_OrderDetail dod on doh.id = dod.ohid
		where dod.flag = 2 or dod.flag = 3
print '5.2.1. �������� ����������'
	delete from DA_OrderHead
		from DA_OrderHead oh join ##DA_OrderHead doh on oh.id = doh.id 
		where doh.flag = 0 or doh.flag = 1
print '5.2.2. �������� �������'
	delete from DA_OrderDetail
		from DA_OrderDetail od join ##DA_OrderDetail dod on od.id = dod.id
			where dod.flag = 0 or dod.flag = 1

print '5.3.1 ��������� Flag �� ��������� � �������� �������'
	update o set o.flag = doh.flag, o.because = doh.because
		from ##DA_OrderHead doh join DA_OrderHead o on o.externorderkey = doh.externorderkey
		where o.flag = 0 -- ��� ���������� ����������� ���� ������
print '5.3.2. ��������� Flag � ��� ������������ �������� �� ������ � ������� �������'
	update od set od.flag = dod.flag, od.because = dod.because,
		od.allocatestrategykey = dod.allocatestrategykey,
		od.preallocatestrategykey = dod.preallocatestrategykey,
		od.allocatestrategytype = dod.allocatestrategytype, 
		od.cartongroup = dod.cartongroup,
		od.packkey = dod.packkey
		from ##DA_OrderDetail dod join DA_OrderDetail od on od.id = dod.id

print '6. ���������� ����������� � ������������� ��������� ������'
	if (select count (flag) from ##DA_OrderHead where flag > 1) > 0
		begin
			declare @body varchar(max)
			set @body = 'Date: ' + convert(varchar(10),getdate(),21) + char(10) + char(13)
			select @body = @body + 'ExternOrderkey: ' + drh.externorderkey + '. �������: ' + drh.because + char(10) + char(13) from ##DA_OrderHead drh where drh.flag > 1
			exec app_DA_SendMail 'ORDER.', @body
		end

drop table #da_uni
drop table ##DA_OrderDetail
drop table ##DA_OrderHead

