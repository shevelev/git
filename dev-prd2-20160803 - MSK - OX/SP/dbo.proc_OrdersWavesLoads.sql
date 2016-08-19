--################################################################################################
-- ��������� ��������/��������� �� �� ���� � ��������, � ���������� ������ ��
-- �������������� �� � ����� ��������������� ��������� ���� o.ORDERGROUP
-- �������������� �� � �������� ��������������� ��������� ���� o.LOADID
---- ���������� ������ �����:
---- o.INTERMODALVEHICLE	- ��� ��������/�����������
---- o.ROUTE - ��� �������� ���� "TS"+right(LOADID,8)
---- o.STOP	 - ������ ��������� �� �������� ��������. ��� ������� ������ ��������� ��������� ���������
---- o.EXTERNALLOADID - ����������� �������� ���� ("��������", "�����" � �.�.)
---- o.carriercode	- ��� ������ �� ����������� storer
---- o.DriverName	- ��� ��������/�����������
---- o.CarrierName	- ��� ������
---- o.TrailerNumber- ����� ������			

---- o.TRANSPORTATIONSERVICE - (����������� ������� ����� ��������� ������������� �����)
----							������ ������ ������ (PICKTO). �������� ������������ ��� ������ � ������ ������.
--################################################################################################
ALTER PROCEDURE [dbo].[proc_OrdersWavesLoads]
	@dateLow		datetime,
	@dateHigh		datetime,
	@Orderkey		varchar(10)='',	-- ����� ��
	@Wavekey		varchar(10)='',	-- ����� �����
	@flag			varchar(1)='',	-- ���� '-' ���������/'+' ��������/'' ��������
	@Driver			varchar(10)='',	-- ��� ��������
	@Car			varchar(10)='',	-- ����� ������
	@RouteDirection	varchar(10)='',	-- ����������� ��������
 	@loadid			varchar (10)='',-- ����� ��������
	@shiptime		datetime,		-- ��������� ���� ��������

	@activeWave varchar(10) OUTPUT,
	@activeLoad varchar(10) OUTPUT
AS

declare @newWave varchar(10),
		@status int,
		@DriverName varchar(45),
		@CarNumber	varchar(18),
		@CarType	varchar(45),
		@validDate	datetime

print '>>> dbo.proc_OrdersWavesLoads >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
set @newWave=isnull(@Wavekey,'')
set @activeLoad=isnull(@loadid,'')
set @validDate=isnull(@shiptime,getdate())

print '���������� ������ ����� �� �������� ��'
select @status=max(cast(o.status as int)) from wh1.orders o
	where o.ordergroup=@newWave and @newWave<>''
print '...@Wavekey:'+@newWave+' status='+cast(isnull(@status,-1) as varchar)

print '...��������� ��� ��������, ����� � ��� ������'
select @DriverName=isnull(company,'') from wh1.storer where storerkey=@Driver
select @CarNumber=isnull(vat,''), @CarType=isnull(company,'') from wh1.storer where storerkey=@Car
print '...@Driver:'+@Driver+' ('+@DriverName+') @Car:'+@Car+' ('+@CarNumber+')('+@CarType+')'

print '1. ���������� ����� ��������� (��������/����������/���������� �������)'
if (@flag='+' and @newWave<>'' and @activeLoad<>'' and @Orderkey<>'' and ISNULL(@status,-1)<10)
begin
		print '2. ������� �����: ���������� �� � ������������ ����� � ��������'
		print '...����������� � ����� �� ����� ����� @Wave='+@newWave
		update o set ordergroup=@newWave from wh1.orders o where o.orderkey=@Orderkey

		print '...������������� ������������ �����: '+@newWave
		exec dbo.app_Wave @newWave

		print '...��������� ��:'+@orderkey+' � ��������: '+isnull(@activeLoad,'<NULL>')
		exec dbo.app_Load	@orderkey,		-- ����� ��
 							@activeLoad,	-- ����� ��������
							@RouteDirection,-- ����������� ��������
							@Driver,		-- ��� �����������/�����������
							@DriverName,	-- ��� ��������/�����������
							@Car,			-- ��� ������
							@CarType,		-- ��� ������
							@CarNumber,		-- ����� ������
							@validDate,		-- ��������� ���� ��������
							'+',
 							@activeLoad OUTPUT		-- ����� �������� ��������
		print '2. ���������� �� � ������������ ����� � �������� ���������.'

end

if (@flag='-' and @Orderkey<>'' and ISNULL(@status,-1)<10)
begin
		print '3. ������� �����: �������� �� �� ������������ ����� � ��������'
		print '...���������� ����� ����� � ��������'
		select @newWave=isnull(o.ordergroup,''), @activeLoad=isnull(o.loadid,'')
		from wh1.orders o	join wh1.Wave w on (o.ordergroup=w.wavekey)	-- ��� join ����� ��� �������� �������������
							join wh1.Loadhdr l on (o.loadid=l.loadid)	-- ��������������� ���� � ��������
		where o.orderkey=@Orderkey
		print '...������� ����� ����� � ��'
		update o
		set ordergroup='' from wh1.orders o	where o.orderkey=@Orderkey

		print '...������������� �����'
		if (isnull(@newWave,'')<>'') exec dbo.app_Wave @newWave,@Driver,@Car,@RouteDirection

		print '...��������� ��:'+@orderkey+' �� ��������: '+isnull(@activeLoad,'<NULL>')
		exec dbo.app_Load	@orderkey,		-- ����� ��
 							@activeLoad,		-- ����� ��������
							@RouteDirection,-- ����������� ��������
							@Driver,		-- ��� �����������/�����������
							@DriverName,	-- ��� ��������/�����������
							@Car,			-- ��� ������
							@CarType,		-- ��� ������
							@CarNumber,		-- ����� ������
							@validDate,		-- ��������� ���� ��������
							'-',
 							@activeLoad OUTPUT		-- ����� �������� ��������
		print '3. ���������� �� �� ����� � �������� ���������.'

end

if (@flag='+' and isnull(@Wavekey,'')='' and @Orderkey<>'')
begin
		print '4. ������� �����: ���������� �� � ����� ����� � ��������'
		print '...�������� ����� ����� �����'
		exec dbo.DA_GetNewKey 'wh1','WAVEKEY',@newWave output
		print '...������� ����� @newWave='+@newWave

		print '...����������� ����� ����� � ��'
		update o set ordergroup=@newWave from wh1.orders o where o.orderkey=@Orderkey

		print '...������� ����� �����'
		exec dbo.app_Wave @newWave,@Driver,@Car,@RouteDirection

		print '...��������� ��:'+@orderkey+' � ��������: '+isnull(@activeLoad,'<NULL>')
		exec dbo.app_Load	@orderkey,		-- ����� ��
 							@activeLoad,		-- ����� ��������
							@RouteDirection,-- ����������� ��������
							@Driver,		-- ��� �����������/�����������
							@DriverName,	-- ��� ��������/�����������
							@Car,			-- ��� ������
							@CarType,		-- ��� ������
							@CarNumber,		-- ����� ������
							@validDate,		-- ��������� ���� ��������
							'+',
 							@activeLoad OUTPUT		-- ����� �������� ��������
		print '4. ���������� �� � ������������ ����� � �������� ���������.'

end

print '������������� �������� ����� @activeWave=' + @newWave
set @activeWave=@newWave

print '4.5 �������� ������ �� ��������� �������, ��� ���������� ����������� ����������--'
select  
o.storerkey,
o.externalloadid,
o.loadid,
o.route,
o.INTERMODALVEHICLE,
o.CarrierCode,
o.drivername,
o.CarrierName,
o.TrailerNumber,
o.ordergroup,
o.stop,
o.OrderDate,
o.RequestedShipDate,
o.ExternOrderKey,
o.susr4,
o.OrderKey,
o.Status,
o.ConsigneeKey,
o.c_company,o.c_city,o.c_address1,o.c_address2,o.c_address3,o.c_address4,
o.b_company,o.b_city,o.b_address1,o.b_address2,o.b_address3,o.b_address4,
od.sku,od.originalqty,od.qtypicked,od.shippedqty,od.unitprice,
o.transportationservice,
o.door,
o.susr1,
o.susr2,
o.susr3,
o.editdate
into #preList
from wh1.orders o join wh1.orderdetail od on (o.orderkey=od.orderkey)
where
	(o.orderdate between isnull(@dateLow,getdate()-1) and isnull(@dateHigh,getdate()+2))
	or
	(cast(o.status as int)<92)

print '5. ���������� ������ ��� ������----------------------------------'
select 
o.storerkey			SupplierKey,
st.company			SupplierName,

o.externalloadid	RouteDirection,

o.loadid,
o.route,
o.INTERMODALVEHICLE	Driver,
o.CarrierCode		Car,
o.drivername		DriverName,
o.CarrierName		CarType,
o.TrailerNumber		CarNumber,
o.ordergroup		Wavekey,
[load].departuretime,

o.stop				[Stop],
o.OrderDate,
o.RequestedShipDate,
o.ExternOrderKey,
o.susr4				ExternDocNumber,
o.OrderKey,
cast(o.Status as int) [Status],
os.description		StatusDescr,
o.ConsigneeKey,
o.c_company			C_Name,
st_c.susr2			C_RouteDirection,
case
	when isnull(o.c_address1,'')+isnull(o.c_address2,'')+isnull(o.c_address3,'')+isnull(o.c_address4,'')=''
		then isnull(o.b_city,'')+left(', ',len(isnull(o.b_city,'')))+isnull(o.b_address1,'')+isnull(o.b_address2,'')+isnull(o.b_address3,'')+isnull(o.b_address4,'')
	else isnull(o.c_city,'')+left(', ',len(isnull(o.c_city,'')))+isnull(o.c_address1,'')+isnull(o.c_address2,'')+isnull(o.c_address3,'')+isnull(o.c_address4,'')
end					C_Address,
o.B_Company			ByerKey,
o.B_company			B_Name,
case
	when isnull(o.b_address1,'')+isnull(o.b_address2,'')+isnull(o.b_address3,'')+isnull(o.b_address4,'')=''
		then isnull(o.c_city,'')+left(', ',len(isnull(o.c_city,'')))+isnull(o.c_address1,'')+isnull(o.c_address2,'')+isnull(o.c_address3,'')+isnull(o.c_address4,'')
	else isnull(o.c_city,'')+left(', ',len(isnull(o.c_city,'')))+isnull(o.c_address1,'')+isnull(o.c_address2,'')+isnull(o.c_address3,'')+isnull(o.c_address4,'')
end					b_Address,
case
	when isnull(o.ordergroup,'')=''  and isnull(o.loadid,'')='' and cast(o.status as int)<10 then '+'
	when isnull(o.ordergroup,'')<>'' and isnull(o.loadid,'')<>''and cast(o.status as int)<10 then '-'
	else ''
end operation,


round(count(o.sku)*sum(o.originalqty*s.stdcube*s.stdgrosswgt),3)	Scope,
ROUND(sum((o.qtypicked+o.shippedqty)*s.stdcube*s.stdgrosswgt)
	/ sum(case o.originalqty*s.stdcube*s.stdgrosswgt when 0 then 1 else o.originalqty*s.stdcube*s.stdgrosswgt end) *100,0)			PercentComplete,
count(o.sku)														SkuCount,
round(sum(o.originalqty*s.stdcube),3)								OrderedCube,
round(sum(o.originalqty*s.stdgrosswgt)/1000,3)						OrderedWeight,
round(sum((o.qtypicked+o.shippedqty)*s.stdcube),3)				CompletedCube,
round(sum((o.qtypicked+o.shippedqty)*s.stdgrosswgt)/1000,3)		CompletedWeight,
sum(o.originalqty*o.unitprice)									OrderedSUM,
sum(o.shippedqty*o.unitprice)										ShippedSUM,

o.transportationservice	PickToZone,
max(o.door)				OutDoor,
o.susr1				DocType,
o.susr2				OperationType,
o.susr3				Sklad,
@newWave			activeWaveKey,
@activeLoad			activeLoad,
o.editdate,
st2.COMPANY,
st2.ADDRESS1, st2.ADDRESS2, st2.ADDRESS3, st2.ADDRESS4
--into dbo.del_OrdersCons
from #preList o
		join wh1.storer st on (o.storerkey=st.storerkey)
		left join wh1.storer st_c on (o.consigneekey=st_c.storerkey)
		join wh1.orderstatussetup os on (o.status=os.code)
		join wh1.sku s on (o.storerkey=s.storerkey and o.sku=s.sku)
		left join wh1.loadhdr [load] on (o.loadid=[load].loadid)
		LEFT join wh1.storer st2 on (o.CONSIGNEEKEY=st2.STORERKEY)

group by	o.storerkey,
			st.company,
			o.externalloadid,
			o.loadid,
			o.route,
			o.INTERMODALVEHICLE,
			o.CarrierCode,
			o.drivername,
			o.CarrierName,
			o.TrailerNumber,
			o.ordergroup,
			[load].departuretime,
			o.stop,
			o.OrderDate,
			o.RequestedShipDate,
			o.susr4,
			o.ExternOrderKey,
			o.OrderKey,
			o.Status,
			os.description,
			o.ConsigneeKey,
			o.c_company,
			st_c.susr2,
			o.c_city,o.c_address1,o.c_address2,o.c_address3,o.c_address4,
			o.B_Company,
			o.b_company,
			o.b_city,o.b_address1,o.b_address2,o.b_address3,o.b_address4,
			o.transportationservice,
		  --o.door,
			o.susr1,
			o.susr2,
			o.susr3,
			o.editdate,
			st2.COMPANY,
st2.ADDRESS1, st2.ADDRESS2, st2.ADDRESS3, st2.ADDRESS4
--order by st_c.susr2, cast(o.status as int), o.RequestedShipDate

