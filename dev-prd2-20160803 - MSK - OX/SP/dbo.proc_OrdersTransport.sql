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
ALTER PROCEDURE [dbo].[proc_OrdersTransport]
	@dateLow		datetime,
	@dateHigh		datetime,
	@Orderkey		varchar(10)='',	-- ����� ��
	@Wavekey		varchar(10)='',	-- ����� �����
	@flag			varchar(1)='',	-- ���� '-' ���������/'+' ��������/'' ��������
	@Driver			varchar(10)='',	-- ��� ��������
	@Car			varchar(10)='',	-- ����� ������
	@RouteDirection	varchar(20)='',	-- ����������� ��������
 	@loadid			varchar (10)='',-- ����� ��������

	@shiptime		datetime,		-- ��������� ���� ��������
	@readyFlag		varchar(1)='1',	-- ���� �������� ������ �� ��������� ������� '1'-������ � ��������� TRANSPORTATIONMODE

	@activeWave varchar(10) OUTPUT,
	@activeLoad varchar(10) OUTPUT
AS

declare @newWave varchar(10),
		@status int,
		@DriverName varchar(45),
		@CarNumber	varchar(18),
		@CarType	varchar(45),
		@validDate	datetime,
		@readyStatus varchar(1),
		@ISinWave	int,
		@TotalVolume float,
		@TotalWeight float,
		@OrdersCount int,
		@ReadyState	varchar(1),
		@ReadyWave varchar(1)

print '>>> dbo.[proc_OrdersTransport] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
set @newWave=isnull(@Wavekey,'')
set @activeLoad=isnull(@loadid,'')
set @validDate=isnull(@shiptime,
		cast(
		 cast(year(getdate()) as varchar(4))
		 + replicate('0',2-len(cast(month(getdate()) as varchar(2))))+cast(month(getdate()) as varchar(2))
		 + replicate('0',2-len(cast(day(getdate()) as varchar(2)))) +cast(day(getdate()) as varchar(2))
		 + ' 20:00'
		as datetime)
						)
set @TotalVolume=0
set @TotalWeight=0
set @OrdersCount=0
set @ReadyState=''
select @readyStatus=case when isnull(@readyFlag,'')='1' then '2' else '1' end

print '���������� ������ ����� �� �������� ��'
select @status=max(cast(o.status as int)) from wh1.orders o
	where o.ordergroup=@newWave and @newWave<>''
print '...@Wavekey:'+@newWave+' status='+cast(isnull(@status,-1) as varchar)

print '���������� ���������� ����� ��� �������� �� ����� �� ���������� ��'
select @ReadyWave=isnull(max(o.Transportationmode),'1') from wh1.orders o
	where o.ordergroup=@newWave and @newWave<>''
if @ReadyWave>'1' set @ReadyWave='2'
print '...@ReadyWave='+@ReadyWave

print '��������� ������� �� ����� � �����'
if (isnull(@Orderkey,'')<>'')
select @ISinWave=case when o.ordergroup<>'' and o.ordergroup is not null then 1 else 0 end
	from wh1.orders o
	where o.orderkey=@Orderkey
print '...ISinWave='+cast(@ISinWave as varchar)

print '...��������� ��� ��������, ����� � ��� ������'
select @DriverName=isnull(company,'') from wh1.storer where storerkey=@Driver
select @CarNumber=isnull(vat,''), @CarType=isnull(company,'') from wh1.storer where storerkey=@Car
print '...@Driver:'+@Driver+' ('+@DriverName+') @Car:'+@Car+' ('+@CarNumber+')('+@CarType+')'

print '1. ���������� ����� ��������� (��������/����������/���������� �������)'
if (@flag='+' and @newWave<>'' and @activeLoad<>'' and @Orderkey<>'' and ISNULL(@status,-1)<10 and @ISinWave=0)
begin
		print '2. ������� �����: ���������� �� � ������������ ����� � ��������'
		print '...����������� � ����� �� ����� ����� @Wave='+@newWave+' � ���� ����������, ��������������� ����� @ReadyWave='+@ReadyWave
		update o set ordergroup=@newWave,Transportationmode=@ReadyWave
		 from wh1.orders o where o.orderkey=@Orderkey

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
		print '...������� ����� ����� � ���� ���������� �������� �� ����� � ����� ��'
		update o
		set ordergroup='',Transportationmode='1' from wh1.orders o	where o.orderkey=@Orderkey

		print '...������������� �����'
		if (isnull(@newWave,'')<>'') exec dbo.app_Wave @newWave,@Driver,@Car,@RouteDirection

		print '...��������� ��:'+@orderkey+' �� ��������: '+isnull(@activeLoad,'<NULL>')
		exec dbo.app_Load	@orderkey,		-- ����� ��
 							@activeLoad,	-- ����� ��������
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

if (@flag='+' and isnull(@Wavekey,'')='' and @Orderkey<>'' and @ISinWave=0)
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
		print '4. ���������� �� � ����� ����� � �������� ���������.'

end

if (@flag='' and isnull(@Wavekey,'')<>'' and isnull(@loadid,'')<>'')
begin
		print '5. ������� �����: ���������� ����� ����� � ��������'
		if ISNULL(@status,-1)<10
		begin
			print '...����� ��� �� �������� � ���������. ��������� ��������� ���.'
			print '...��������� ����� �������'
			update wh1.orders
			set	externalloadid = upper(@RouteDirection),
				INTERMODALVEHICLE=isnull(@Driver,''),
				CarrierCode=@Car,
				DriverName=@DriverName,
				CarrierName=@CarType,
				TrailerNumber=@CarNumber,
				Transportationmode=@readyStatus	--���� �������� ����� �� ��������� ������
			where loadid=@loadid
			print '...��������� ����� �����'
			update wh1.wave
			set	 externalwavekey=@Driver,
				 descr=upper(@RouteDirection)
			where wavekey=@Wavekey
			print '...��������� ����� ��������'
			update wh1.loadhdr
			set	externalid=upper(@RouteDirection),
				carrierid=@Driver,
				trailerid=@Car,
				departuretime=isnull(@shiptime,getdate())
			where loadid=@loadid
		end
		else
		begin
			print '...����� ��� �������� � ���������. ��������� ��������� ������ ������ � ��������.'
			print '...��������� ����� �������'
			update wh1.orders
			set	externalloadid = upper(@RouteDirection),
				INTERMODALVEHICLE=isnull(@Driver,''),
				CarrierCode=@Car,
				DriverName=@DriverName,
				CarrierName=@CarType,
				TrailerNumber=@CarNumber
			where loadid=@loadid
			print '...��������� ����� �����'
			update wh1.wave
			set	 externalwavekey=@Driver,
				 descr=upper(@RouteDirection)
			where wavekey=@Wavekey
			print '...��������� ����� ��������'
			update wh1.loadhdr
			set	externalid=upper(@RouteDirection),
				carrierid=@Driver,
				trailerid=@Car
			where loadid=@loadid
		end
end



print '������������� �������� ����� @activeWave=' + @newWave
set @activeWave=@newWave

print '���������� ����� ��������� �� �����/��������'
if isnull(@activeLoad,'')<>''
begin
	select	@TotalVolume=round(sum(s.stdcube*od.openqty),2),
		@TotalWeight=round(sum(s.stdgrosswgt*od.openqty)/1000,2),
		@ReadyState=case max(o.Transportationmode) when '2' then '1' else '' end 
	from wh1.orders o
	join wh1.orderdetail od on o.orderkey=od.orderkey
	join wh1.sku s on (od.storerkey=s.storerkey and od.sku=s.sku)
	where o.loadid=@activeLoad
	group by o.loadid
	select @OrdersCount=count(orderkey) from wh1.orders where loadid=@activeLoad
end

print '6. ���������� ������ ��� ������----------------------------------'
select 
max(o.storerkey)			SupplierKey,
max(st.company)				SupplierName,

max(o.externalloadid)		RouteDirection,

max(isnull(o.loadid,''))	LoadID,
max(o.INTERMODALVEHICLE)	Driver,
max(o.CarrierCode)			Car,
max(o.drivername)			DriverName,
max(o.CarrierName)			CarType,
max(o.TrailerNumber)		CarNumber,
max(o.ordergroup)			Wavekey,
max([load].departuretime)	departuretime,

max(o.OrderDate)			OrderDate,
max(o.RequestedShipDate)	RequestedShipDate,
max(o.ExternOrderKey)		ExternOrderKey,
max(o.susr4)				ExternDocNumber,
o.OrderKey,
max(cast(o.Status as int))	[Status],
max(os.description)			StatusDescr,
max(o.ConsigneeKey)			ConsigneeKey,
max(o.c_company)			C_Name,
max(st_c.susr2)				C_RouteDirection,
max(
case
	when isnull(o.c_address1,'')+isnull(o.c_address2,'')+isnull(o.c_address3,'')+isnull(o.c_address4,'')=''
		then isnull(o.b_city,'')+left(', ',len(isnull(o.b_city,'')))+isnull(o.b_address1,'')+isnull(o.b_address2,'')+isnull(o.b_address3,'')+isnull(o.b_address4,'')
	else isnull(o.c_city,'')+left(', ',len(isnull(o.c_city,'')))+isnull(o.c_address1,'')+isnull(o.c_address2,'')+isnull(o.c_address3,'')+isnull(o.c_address4,'')
end)						C_Address,
max(o.B_Company)			ByerKey,
max(o.b_company)			B_Name,
max(
case
	when isnull(o.ordergroup,'')=''  and isnull(o.loadid,'')='' and cast(o.status as int)<10 then '+'
	when isnull(o.ordergroup,'')<>'' and isnull(o.loadid,'')<>''and cast(o.status as int)<10 then '-'
	else ''
end)						operation,

case max(o.transportationmode) when '2' then '1' else '' end		ReadyFlag,

round(sum(od.originalqty*s.stdcube),3)								OrderedCube,
round(sum(od.originalqty*s.stdgrosswgt)/1000,3)						OrderedWeight,

max(o.transportationservice)										PickToZone,
round( sum(
			(case when od.qtyallocated+od.qtypicked+od.shippedqty>0
						then (od.qtypicked+od.shippedqty)/(od.qtyallocated+od.qtypicked+od.shippedqty) 
						else 0 end)
			* (case when s.stdcube=0 then 1 else s.stdcube end))
		/(case when sum(s.stdcube)=0 then 1 else sum(s.stdcube) end)*100
	 ,0)		
					PercentComplete,
@newWave			activeWaveKey,
@activeLoad			activeLoad,
max(o.editdate)		editdate,
@TotalVolume		activeTotalVolume,
@TotalWeight		activeTotalWeight,
@OrdersCount		activeOrdersCount,
@ReadyState			activeReadyFlag,
max(o.containerqty) containerqty
from wh1.orders o
		join wh1.orderdetail od on (o.orderkey=od.orderkey)
		join wh1.storer st on (o.storerkey=st.storerkey)
		join wh1.storer st_c on (o.consigneekey=st_c.storerkey)
		join wh1.orderstatussetup os on (o.status=os.code)
		join wh1.sku s on (od.storerkey=s.storerkey and od.sku=s.sku)
		left join wh1.loadhdr [load] on (o.loadid=[load].loadid)
where 
--�������� ��� �� ����������� ������
--� ����� ������, �� ���������� � ��������, �� ���������� � ������� �������� ��� �� ��������� ���� ��������, � �������� �� �����������
 ( (isnull(o.loadid,'')='')
		and (cast(o.status as int)<14 or o.RequestedShipDate between isnull(@dateLow,getdate()-1) and isnull(@dateHigh+1,getdate()+2) ) 
		and (st_c.susr2 like isnull(left(@RouteDirection,10),'')+'%' or isnull(st_c.susr2,'')='')
 )
OR
--��� ������ �� ��������, ���������� � �������� �������� � ������ ��������(��������������) ��������
 ( (isnull(o.loadid,'')<>'')
		and (( [load].departuretime between isnull(@dateLow,getdate()-1) and isnull(@dateHigh,getdate()+2)  
				and (o.externalloadid like isnull(left(@RouteDirection,10),'')+'%' or isnull(o.externalloadid,'')='')
			  )
			  or 
			 o.loadid=@activeLoad )
 ) 

group by	o.OrderKey

