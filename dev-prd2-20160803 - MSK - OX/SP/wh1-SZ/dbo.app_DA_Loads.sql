ALTER PROCEDURE [dbo].[app_DA_Loads] 
	@storerkey varchar (15), -- ��� ���������
	@carriercode varchar (15) -- ��� �����������/�����������
AS
declare
		@Load varchar (10), -- ������������� ������������ ��������
		@loadid varchar (10), -- ����� ��������
		@loadstopid int, -- ������������� ����� (��������� ��������) � ��������
		@loadorderdetailid int -- ������������� ������ � ������� � ��������

--print '6. �������� ������������� ������������ ��������'
--	if @Load = 'yes'
--		begin
--			print '6.0. ��������� ���������� �� �������� ��� storerkey: '+@storerkey+'. Carriercode: '+@carriercode+'.'
--			select top 1 @loadid = lh.loadid, @loadstopid = ls.loadstopid from wh1.loadhdr lh join wh1.loadstop ls on lh.loadid = ls.loadid
--				join wh1.loadorderdetail lod on lod.loadstopid = ls.loadstopid
--				join wh1.orders o on o.orderkey = lod.shipmentorderid
--					where (lh.door is null or ltrim(rtrim(lh.door)) = '') and lh.carrierid = @carriercode and 
--						lh.[route] = @carriercode and o.storerkey = @storerkey
--			if @loadid is null or ltrim(rtrim(@loadid)) = ''
--				begin
--					print '6.1. �������� � door = '' ��� null ��� carrier: ' + @carriercode + ' ���. ������� ��������.'
--					exec dbo.DA_GetNewKey 'wh1','CARTONID',@loadid output	
--					print '����� �������� loadid: ' + @loadid
--					print '6.1.1. ��������� ����� ��������'
--					insert wh1.loadhdr (whseid,  loadid,      [route],    carrierid, status, door,             trailerid)
--						select           'WH1', @loadid, @carriercode, @carriercode,    '0',   '', left(@carriername, 10)
--					print '6.1.2. ��������� ���� � ��������'
--					exec dbo.DA_GetNewKey 'wh1','LOADSTOPID',@loadstopid output	
--					print '������������� ��������� � �������� loadstopid: ' + convert(varchar(10),@loadstopid)
--					set @stop = 1 -- ������ ���� ��������� � ��������
--					insert wh1.loadstop (whseid,  loadid,  loadstopid,  stop, status)
--						select            'WH1', @loadid, @loadstopid, @stop,    '0'
--				end
----			else
----				begin
----					print '6.1. �������� �� status = 0 ��� carrier: ' + @carriercode + ' ����. Loadid: ' + @Loadid
----					-- ����������� ����������� ����������
----					select top 1 @loadid = lh.loadid, @loadstopid = ls.loadstopid from wh1.loadhdr lh join wh1.loadstop ls on lh.loadid = ls.loadid
----						where (lh.door is null or ltrim(rtrim(lh.door)) = '') and lh.carrierid = @carriercode and lh.[route] = @carriercode and ls.stop = 1
----				end
--			print '6.2. ��������� ����� �� �������� � ��������'
--			exec dbo.DA_GetNewKey 'wh1','LOADORDERDETAILID',@loadorderdetailid output	
--			insert wh1.loadorderdetail (whseid, loadstopid, loadorderdetailid, storer, shipmentorderid, customer)
--				select 'WH1', @loadstopid, @loadorderdetailid, @storerkey, @orderkey, @consigneekey
--		end

