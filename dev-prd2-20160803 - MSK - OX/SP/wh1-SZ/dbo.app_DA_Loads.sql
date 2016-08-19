ALTER PROCEDURE [dbo].[app_DA_Loads] 
	@storerkey varchar (15), -- код владельца
	@carriercode varchar (15) -- код перевозчика/экспедитора
AS
declare
		@Load varchar (10), -- необходимость формирования загрузок
		@loadid varchar (10), -- номер загрузки
		@loadstopid int, -- идентификатор стопа (остановки маршрута) в загрузке
		@loadorderdetailid int -- идентификатор строки с заказом в загрузке

--print '6. проверка необходимости формирования загрузок'
--	if @Load = 'yes'
--		begin
--			print '6.0. проверяем существует ли загрузка для storerkey: '+@storerkey+'. Carriercode: '+@carriercode+'.'
--			select top 1 @loadid = lh.loadid, @loadstopid = ls.loadstopid from wh1.loadhdr lh join wh1.loadstop ls on lh.loadid = ls.loadid
--				join wh1.loadorderdetail lod on lod.loadstopid = ls.loadstopid
--				join wh1.orders o on o.orderkey = lod.shipmentorderid
--					where (lh.door is null or ltrim(rtrim(lh.door)) = '') and lh.carrierid = @carriercode and 
--						lh.[route] = @carriercode and o.storerkey = @storerkey
--			if @loadid is null or ltrim(rtrim(@loadid)) = ''
--				begin
--					print '6.1. загрузки с door = '' или null для carrier: ' + @carriercode + ' нет. создаем загрузку.'
--					exec dbo.DA_GetNewKey 'wh1','CARTONID',@loadid output	
--					print 'Номер загрузки loadid: ' + @loadid
--					print '6.1.1. добавляем шапку загрузки'
--					insert wh1.loadhdr (whseid,  loadid,      [route],    carrierid, status, door,             trailerid)
--						select           'WH1', @loadid, @carriercode, @carriercode,    '0',   '', left(@carriername, 10)
--					print '6.1.2. добавляем СТОП в загрузку'
--					exec dbo.DA_GetNewKey 'wh1','LOADSTOPID',@loadstopid output	
--					print 'Идентификатор остановки в загрузке loadstopid: ' + convert(varchar(10),@loadstopid)
--					set @stop = 1 -- всегда одна остановка в загрузке
--					insert wh1.loadstop (whseid,  loadid,  loadstopid,  stop, status)
--						select            'WH1', @loadid, @loadstopid, @stop,    '0'
--				end
----			else
----				begin
----					print '6.1. загрузка со status = 0 для carrier: ' + @carriercode + ' есть. Loadid: ' + @Loadid
----					-- определение необходимых переменных
----					select top 1 @loadid = lh.loadid, @loadstopid = ls.loadstopid from wh1.loadhdr lh join wh1.loadstop ls on lh.loadid = ls.loadid
----						where (lh.door is null or ltrim(rtrim(lh.door)) = '') and lh.carrierid = @carriercode and lh.[route] = @carriercode and ls.stop = 1
----				end
--			print '6.2. добавляем заказ на отгрузку в загрузку'
--			exec dbo.DA_GetNewKey 'wh1','LOADORDERDETAILID',@loadorderdetailid output	
--			insert wh1.loadorderdetail (whseid, loadstopid, loadorderdetailid, storer, shipmentorderid, customer)
--				select 'WH1', @loadstopid, @loadorderdetailid, @storerkey, @orderkey, @consigneekey
--		end

