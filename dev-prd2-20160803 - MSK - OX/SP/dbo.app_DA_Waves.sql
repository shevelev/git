--################################################################################################
--         процедура создает волну для заказа и (@type = 'new')
--                   добавляет детали			(@type = 'detail')
--################################################################################################
ALTER PROCEDURE [dbo].[app_DA_Waves]
	@wavekey varchar (10), -- номер волны
	@wavedescr varchar (15), -- наименование волны
	@orderkey varchar (15), -- номер заказа
	@carriercode varchar (15), -- код перевозчика/экспедитора
	@type varchar (10)

AS
declare 
	@wavedetailkey varchar (10) -- номер строки волны

print '>>> app_DA_Waves >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
print '@wavekey: '+case when @wavekey is null then 'null' else @wavekey end +'. @wavedescr: '+case when @wavedescr is null then 'null' else @wavedescr end+'. @orderkey: '+case when @orderkey is null then 'null' else @orderkey end+'. @type: '+case when @type is null then 'null' else @type end+'.'

if @type = 'new'
	begin
		print 'DAW.1. Ключ для новой волны.'
		exec dbo.DA_GetNewKey 'wh1','WAVEKEY',@wavekey output	
		-- вставляем шапку волны
		print 'DAW.2. Добавляем волну Wavekey: ' + @Wavekey
		insert into	wh1.wave (whseid, wavekey, descr, dispatchcasepickmethod, EXTERNALWAVEKEY)
			select 'WH1', @wavekey, @wavedescr, '1', @carriercode
	end

	print 'DAW.3. Волна создана, добавляем детали.'
NewWaveDetailKey:
	select @wavedetailkey = max(wd.wavedetailkey)
		from wh1.wavedetail wd where wd.wavekey = @wavekey
		group by wd.wavedetailkey
	if @wavedetailkey is null or ltrim(rtrim(@wavedetailkey)) = '' set @wavedetailkey = '0000000001' else 
		set @wavedetailkey = right('000000000' + convert(varchar(10),convert(int,@wavedetailkey) + 1),10)
	-- вставляем детали волны
	begin try
		print 'DAW.4. Добавляем детали в волну Wavekey: ' + @Wavekey + '. Wavedetail: ' + @Wavedetailkey
		insert into wh1.wavedetail (whseid, wavekey, wavedetailkey, orderkey)
			select 'WH1', @wavekey, @wavedetailkey, @orderkey
	end try
	begin catch
		-- в случае повторения ключа - номера строки
		print 'DAW.5. Wavekey: ' + @Wavekey + '. Повторяющийся ключ Wavedetail: ' + @Wavedetailkey
		goto NewWaveDetailKey
	end catch

	print 'DAW.6. Обновляем поле b_vat в заказе для заполнения волны'
		update wh1.orders set b_vat = @Wavekey where orderkey = @orderkey
--
--	if @Return = 'CheckQtyOrderWave' goto CheckQtyOrderWave
--	else goto NextStep
print '<<< app_DA_Waves <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'

