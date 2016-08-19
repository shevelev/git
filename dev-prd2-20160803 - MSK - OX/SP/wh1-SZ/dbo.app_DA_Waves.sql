--################################################################################################
--         ��������� ������� ����� ��� ������ � (@type = 'new')
--                   ��������� ������			(@type = 'detail')
--################################################################################################
ALTER PROCEDURE [dbo].[app_DA_Waves]
	@wavekey varchar (10), -- ����� �����
	@wavedescr varchar (15), -- ������������ �����
	@orderkey varchar (15), -- ����� ������
	@carriercode varchar (15), -- ��� �����������/�����������
	@type varchar (10)

AS
declare 
	@wavedetailkey varchar (10) -- ����� ������ �����

print '>>> app_DA_Waves >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
print '@wavekey: '+case when @wavekey is null then 'null' else @wavekey end +'. @wavedescr: '+case when @wavedescr is null then 'null' else @wavedescr end+'. @orderkey: '+case when @orderkey is null then 'null' else @orderkey end+'. @type: '+case when @type is null then 'null' else @type end+'.'

if @type = 'new'
	begin
		print 'DAW.1. ���� ��� ����� �����.'
		exec dbo.DA_GetNewKey 'wh1','WAVEKEY',@wavekey output	
		-- ��������� ����� �����
		print 'DAW.2. ��������� ����� Wavekey: ' + @Wavekey
		insert into	wh1.wave (whseid, wavekey, descr, dispatchcasepickmethod, EXTERNALWAVEKEY)
			select 'WH1', @wavekey, @wavedescr, '1', @carriercode
	end

	print 'DAW.3. ����� �������, ��������� ������.'
NewWaveDetailKey:
	select @wavedetailkey = max(wd.wavedetailkey)
		from wh1.wavedetail wd where wd.wavekey = @wavekey
		group by wd.wavedetailkey
	if @wavedetailkey is null or ltrim(rtrim(@wavedetailkey)) = '' set @wavedetailkey = '0000000001' else 
		set @wavedetailkey = right('000000000' + convert(varchar(10),convert(int,@wavedetailkey) + 1),10)
	-- ��������� ������ �����
	begin try
		print 'DAW.4. ��������� ������ � ����� Wavekey: ' + @Wavekey + '. Wavedetail: ' + @Wavedetailkey
		insert into wh1.wavedetail (whseid, wavekey, wavedetailkey, orderkey)
			select 'WH1', @wavekey, @wavedetailkey, @orderkey
	end try
	begin catch
		-- � ������ ���������� ����� - ������ ������
		print 'DAW.5. Wavekey: ' + @Wavekey + '. ������������� ���� Wavedetail: ' + @Wavedetailkey
		goto NewWaveDetailKey
	end catch

	print 'DAW.6. ��������� ���� b_vat � ������ ��� ���������� �����'
		update wh1.orders set b_vat = @Wavekey where orderkey = @orderkey
--
--	if @Return = 'CheckQtyOrderWave' goto CheckQtyOrderWave
--	else goto NextStep
print '<<< app_DA_Waves <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'

