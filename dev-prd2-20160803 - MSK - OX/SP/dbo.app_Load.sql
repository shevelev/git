--################################################################################################
-- ��������� ��������/��������� �� �� ��������
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
--################################################################################################
ALTER PROCEDURE [dbo].[app_Load]
			@orderkey	varchar (10)='',	-- �����
 			@loadid		varchar (10)='',	-- ����� ��������
			@RouteDirection varchar (20)='',-- ����������� ��������
			@Driver		varchar (15)='',	-- ��� �����������/�����������
			@DriverName varchar (45)='',	-- ��� ��������/�����������
			@trailerId	varchar (10)='',	-- ��� ������
			@CarType	varchar (45)='',	-- ��� ������
			@CarNumber	varchar (18)='',	-- ����� ������
			@shiptime	datetime,
			@operation	varchar(1)='',

 			@activeloadid varchar (10) OUTPUT		-- ����� �������� ��������
AS
declare
			@loadstopid int,			-- ������������� ����� (��������� ��������) � ��������
			@stop int,					-- ����� ����� � ��������
			@loadorderdetailid int,		-- ������������� ������ � ������� � ��������
			@storerkey varchar (15),	-- ��� ���������
			@consigneekey varchar (15),	-- ��� �������� �����
			@test	varchar(50),

			@expectedQty	float,
			@expectedVolume	float,
			@expectedWeight	float,
			@totalQty		float,
			@totalVolume	float,
			@totalWeight	float

--select	@loadid='0000001182',
--		@Driver='V00010',
--		@DriverName='������ �.�.',
--		@trailerId='T0011',
--		@RouteDirection='��������',
--		@orderkey='0000000449',
--		@shiptime=getdate(),
--		@operation='+'

print '>>>> dbo.app_Load >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
select @storerkey=storerkey, @consigneekey=consigneekey
	from wh1.orders where orderkey=@orderkey
set @activeloadid=@loadid

print '����� ����� ���������. ����������/���������� �� �� ��������.'
--###################################################################
if (@operation='+' and isnull(@orderkey,'')<>'')
begin
print '...������� ���������� ������ � ��������'

 print '......��������� ���������� �� �������� loadid='+isnull(@activeloadid,'<NULL>')
 if (select top 1 loadid from wh1.loadhdr where loadid=@activeloadid) is null
 begin
	print '.........������� ����� ��������'
	print '.........loadid=' + isnull(@activeloadid,'<NULL>')+ ' �� ����������'
	exec dbo.DA_GetNewKey 'wh1','CARTONID',@activeloadid output	
	print '.........����� ����� �������� loadid: ' + @activeloadid
	print '.........��������� ����� ��������'
	insert wh1.loadhdr (whseid,  loadid,                   externalid, [route],             carrierid, [status], door,  trailerid, departuretime)
		select           'WH1', @activeloadid, upper(@RouteDirection), 'TS'+right(@activeloadid,8), @Driver,      '0',   'VOROTA', @trailerId, isnull(@shiptime,getdate())
 end
 print '......�������� ��� ����������'

 print '......��������� ������ �������� � ������'
 if	(select [status] from wh1.loadhdr where loadid=@activeloadid)='0'
	and
	(select isnull(cast([status] as int),100) from wh1.orders where orderkey=@orderkey)<10
 begin

	print '.........��������� �� ������� �� ����� � ����� ������ �������� ?'
	select @test=max(ls.loadid)
		from wh1.loadorderdetail lod 
			left join wh1.loadstop ls on lod.loadstopid=ls.loadstopid
		where lod.shipmentorderid=@orderkey
	if @test is null
	begin
		print '............����� ��� �� ������� �� � ���� ��������. ����� ������������.'
		print '............��������� ���� � ��������'
		exec dbo.DA_GetNewKey 'wh1','LOADSTOPID',@loadstopid output	
		print '...............������������� ��������� � �������� loadstopid: ' + convert(varchar(10),@loadstopid)
		-- ������ ����� ����������� � ����� ���������
		select @stop=isnull(max(stop),0)+1 from wh1.loadstop
		where loadid=@activeloadid
		insert wh1.loadstop (whseid,        loadid,  loadstopid,  stop, status)
			select            'WH1', @activeloadid, @loadstopid, @stop,    '0'
	
		print '............��������� ����� �� �������� � �������� @stop='+cast(@stop as varchar)
		exec dbo.DA_GetNewKey 'wh1','LOADORDERDETAILID',@loadorderdetailid output	
		insert wh1.loadorderdetail (whseid, loadstopid, loadorderdetailid, storer, shipmentorderid, customer)
							select 'WH1', @loadstopid, @loadorderdetailid, @storerkey, @orderkey, @consigneekey

		print '............��������� ����� ������. ����������� ������ ��������.'
		print '............loadid='+@activeloadid+' route='+'TS'+right(@activeloadid,8)+' stop='+cast(@stop as varchar)+' �����������(externalloadid)='+isnull(upper(@RouteDirection),'<NULL>')
		update wh1.orders set	loadid = @activeloadid,
								[route]= 'TS'+right(@activeloadid,8),
								[stop] = cast(@stop as varchar(10)),
								externalloadid = upper(@RouteDirection),
								INTERMODALVEHICLE=isnull(@Driver,''),
								CarrierCode=@trailerId,
								DriverName=@DriverName,
								CarrierName=@CarType,
								TrailerNumber=@CarNumber			
				where orderkey = @orderkey

		print '............��������� ���������� �� ���������� ������, ���� � �.�.'
		print '............�� ������ �������� ��� !  ��� ��� ���� ��� !!!'
		--			@expectedQty	float,
		--			@expectedVolume	float,
		--			@expectedWeight	float,
		--			@totalQty		float,
		--			@totalVolume	float,
		--			@totalWeight	float
	end
	print '.........����� orderkey='+@orderkey+' ��� ������� � �������� loadid='+@test

 end
 else
 print '......��������� ������ ��� �������� ��� ������. ���������� ������ � �������� ��������� !'

print '...��������� ��������� ����� "���������� ������ � ��������"'
end

--###################################################################
if (@operation='-' and isnull(@orderkey,'')<>'' and isnull(@activeloadid,'')<>'')
begin
print '...������� ���������� ������ �� ��������'

 print '......��������� ���������� �� �������� loadid='+isnull(@activeloadid,'<NULL>')+' � ����� orderkey='+isnull(@orderkey,'<NULL>')
 if (select top 1 loadid from wh1.loadhdr where loadid=@activeloadid) is not null
	and
	(select top 1 orderkey from wh1.orders where orderkey=@orderkey) is not null
 begin
	print '.........��������� ������ �������� � ������'
	if	(select [status] from wh1.loadhdr where loadid=@activeloadid)='0'
	and
	(select isnull(cast([status] as int),100) from wh1.orders where orderkey=@orderkey)<10
	begin
		print '............��������� ����� �� �������� �� ��������'
		select @loadstopid=max(loadstopid) from wh1.loadorderdetail where shipmentorderid=@orderkey
		delete from wh1.loadorderdetail where shipmentorderid=@orderkey

		print '............������� ��������� �� �������� @loadstopid='+cast(@loadstopid as varchar)
		delete from wh1.loadstop where loadstopid=@loadstopid
	
		print '............��������� ����� ������. ������� ������ ��������.'
		update wh1.orders set	loadid = '',
								[route]= '',
								[stop] = '',
								externalloadid = '',
								INTERMODALVEHICLE='',
								CarrierCode='',
								DriverName='',
								CarrierName='',
								TrailerNumber=''			
				where orderkey = @orderkey

		print '............��������� ���������� �� ���������� ������, ���� ��������'
		print '............���� ��� ����������� ����� ����� �������� ��� !  ��� ��� ���� ��� !!!'
		--			@expectedQty	float,
		--			@expectedVolume	float,
		--			@expectedWeight	float,
		--			@totalQty		float,
		--			@totalVolume	float,
		--			@totalWeight	float


	end
	else
	print '.........��������� ������ ��� �������� ��� ������. ���������� ������ �� �������� ��������� !'

 end
 else
 print '......�������� �� ����������. ���������� ����� ��������� ��������.'

print '...��������� ��������� ����� "���������� ������ �� ��������"'
end
print '<<<< dbo.app_Load <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'


/*
wh1.loadhdr -- ������� ����� ��������
	loadid -- pk ������������� �������� wh1.ncounter.cartonid

wh1.loadorderdetail -- ������� ������� � ���������
	loadorderdetailid -- pk ������������� ������ � ������� ������ � �������� wh1.ncounter.loadorderdetailid
	shipmentorder -- ����� ������ �� ��������
	loadstopid -- ������������� ��������� ��� ������ wh1.loadstop

wh1.loadunitdetail -- ������� ����������� ������ �������
	loadunitdetailid -- pk 

wh1.loadstop -- ������� ���������
	stop -- ����� ���������
	loadstopid -- pk ������������� ��������� wh1.ncounter.loadstopid
	loadid -- ������������� �������� wh1.loadhdr

wh1.loadplanning -- ???
	loadplanningkey -- pk ������������� ??? wh1.ncounter.loadplanning
*/

