--################################################################################################
-- Процедура включает/исключает ЗО из Загрузок
-- Принадлежность ЗО к Загрузке устанавливается значением поля o.LOADID
---- Назначение прочих полей:
---- o.INTERMODALVEHICLE	- код Водителя/Экспедитора
---- o.ROUTE - код маршрута вида "TS"+right(LOADID,8)
---- o.STOP	 - нормер остановки на маршруте доставки. Для каждого Заказа создается отдельная остановка
---- o.EXTERNALLOADID - направление доставки вида ("РУБЦОВСК", "БИЙСК" и т.д.)
---- o.carriercode	- код машины по справочнику storer
---- o.DriverName	- ФИО Водителя/Экспедитора
---- o.CarrierName	- тип машины
---- o.TrailerNumber- номер машины			
--################################################################################################
ALTER PROCEDURE [dbo].[app_Load]
			@orderkey	varchar (10)='',	-- заказ
 			@loadid		varchar (10)='',	-- номер загрузки
			@RouteDirection varchar (20)='',-- направление доставки
			@Driver		varchar (15)='',	-- код перевозчика/экспедитора
			@DriverName varchar (45)='',	-- ФИО Водителя/Экспедитора
			@trailerId	varchar (10)='',	-- код машины
			@CarType	varchar (45)='',	-- тип машины
			@CarNumber	varchar (18)='',	-- номер машины
			@shiptime	datetime,
			@operation	varchar(1)='',

 			@activeloadid varchar (10) OUTPUT		-- номер активной Загрузки
AS
declare
			@loadstopid int,			-- идентификатор стопа (остановки маршрута) в загрузке
			@stop int,					-- номер стопа в загрузке
			@loadorderdetailid int,		-- идентификатор строки с заказом в загрузке
			@storerkey varchar (15),	-- код владельца
			@consigneekey varchar (15),	-- код торговой точки
			@test	varchar(50),

			@expectedQty	float,
			@expectedVolume	float,
			@expectedWeight	float,
			@totalQty		float,
			@totalVolume	float,
			@totalWeight	float

--select	@loadid='0000001182',
--		@Driver='V00010',
--		@DriverName='Крюков Е.В.',
--		@trailerId='T0011',
--		@RouteDirection='Рубцовск',
--		@orderkey='0000000449',
--		@shiptime=getdate(),
--		@operation='+'

print '>>>> dbo.app_Load >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
select @storerkey=storerkey, @consigneekey=consigneekey
	from wh1.orders where orderkey=@orderkey
set @activeloadid=@loadid

print 'Выбор ветки алгоритма. Добавление/исключение ЗО из Загрузки.'
--###################################################################
if (@operation='+' and isnull(@orderkey,'')<>'')
begin
print '...Выбрано добавление Заказа в Загрузку'

 print '......Проверяем существует ли загрузка loadid='+isnull(@activeloadid,'<NULL>')
 if (select top 1 loadid from wh1.loadhdr where loadid=@activeloadid) is null
 begin
	print '.........Создаем новую Загрузку'
	print '.........loadid=' + isnull(@activeloadid,'<NULL>')+ ' не существует'
	exec dbo.DA_GetNewKey 'wh1','CARTONID',@activeloadid output	
	print '.........Номер новой загрузки loadid: ' + @activeloadid
	print '.........Добавляем шапку загрузки'
	insert wh1.loadhdr (whseid,  loadid,                   externalid, [route],             carrierid, [status], door,  trailerid, departuretime)
		select           'WH1', @activeloadid, upper(@RouteDirection), 'TS'+right(@activeloadid,8), @Driver,      '0',   'VOROTA', @trailerId, isnull(@shiptime,getdate())
 end
 print '......Загрузка уже существует'

 print '......Проверяем статус Загрузки и Заказа'
 if	(select [status] from wh1.loadhdr where loadid=@activeloadid)='0'
	and
	(select isnull(cast([status] as int),100) from wh1.orders where orderkey=@orderkey)<10
 begin

	print '.........Проверяем не включен ли Заказ в какую нибудь Загрузку ?'
	select @test=max(ls.loadid)
		from wh1.loadorderdetail lod 
			left join wh1.loadstop ls on lod.loadstopid=ls.loadstopid
		where lod.shipmentorderid=@orderkey
	if @test is null
	begin
		print '............Заказ еще не включен ни в одну Загрузку. Можно обрабатывать.'
		print '............Добавляем СТОП в загрузку'
		exec dbo.DA_GetNewKey 'wh1','LOADSTOPID',@loadstopid output	
		print '...............Идентификатор остановки в загрузке loadstopid: ' + convert(varchar(10),@loadstopid)
		-- каждый заказ добавляется в новую остановку
		select @stop=isnull(max(stop),0)+1 from wh1.loadstop
		where loadid=@activeloadid
		insert wh1.loadstop (whseid,        loadid,  loadstopid,  stop, status)
			select            'WH1', @activeloadid, @loadstopid, @stop,    '0'
	
		print '............Добавляем заказ на отгрузку в загрузку @stop='+cast(@stop as varchar)
		exec dbo.DA_GetNewKey 'wh1','LOADORDERDETAILID',@loadorderdetailid output	
		insert wh1.loadorderdetail (whseid, loadstopid, loadorderdetailid, storer, shipmentorderid, customer)
							select 'WH1', @loadstopid, @loadorderdetailid, @storerkey, @orderkey, @consigneekey

		print '............Обновляем шапку заказа. Прописываем данные Загрузки.'
		print '............loadid='+@activeloadid+' route='+'TS'+right(@activeloadid,8)+' stop='+cast(@stop as varchar)+' направление(externalloadid)='+isnull(upper(@RouteDirection),'<NULL>')
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

		print '............Обновляем информацию по ожидаемому объему, весу и т.д.'
		print '............НЕ ЗАБУДЬ ДОПИСАТЬ КОД !  ТУТ ЕГО ПОКА НЕТ !!!'
		--			@expectedQty	float,
		--			@expectedVolume	float,
		--			@expectedWeight	float,
		--			@totalQty		float,
		--			@totalVolume	float,
		--			@totalWeight	float
	end
	print '.........Заказ orderkey='+@orderkey+' уже включен в загрузку loadid='+@test

 end
 else
 print '......Обработка Заказа или Загрузки уже начата. Добавление Заказа в Загрузку запрещено !'

print '...Завершена обработка ветки "добавление Заказа в Загрузку"'
end

--###################################################################
if (@operation='-' and isnull(@orderkey,'')<>'' and isnull(@activeloadid,'')<>'')
begin
print '...Выбрано исключение Заказа из Загрузки'

 print '......Проверяем существует ли загрузка loadid='+isnull(@activeloadid,'<NULL>')+' и Заказ orderkey='+isnull(@orderkey,'<NULL>')
 if (select top 1 loadid from wh1.loadhdr where loadid=@activeloadid) is not null
	and
	(select top 1 orderkey from wh1.orders where orderkey=@orderkey) is not null
 begin
	print '.........Проверяем статус Загрузки и Заказа'
	if	(select [status] from wh1.loadhdr where loadid=@activeloadid)='0'
	and
	(select isnull(cast([status] as int),100) from wh1.orders where orderkey=@orderkey)<10
	begin
		print '............Исключаем Заказ на отгрузку из Загрузки'
		select @loadstopid=max(loadstopid) from wh1.loadorderdetail where shipmentorderid=@orderkey
		delete from wh1.loadorderdetail where shipmentorderid=@orderkey

		print '............Удаляем остановку из загрузки @loadstopid='+cast(@loadstopid as varchar)
		delete from wh1.loadstop where loadstopid=@loadstopid
	
		print '............Обновляем шапку заказа. Стираем данные Загрузки.'
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

		print '............Обновляем информацию по ожидаемому объему, весу Загрузки'
		print '............Если это понадобится нужно бутет написать код !  ТУТ ЕГО ПОКА НЕТ !!!'
		--			@expectedQty	float,
		--			@expectedVolume	float,
		--			@expectedWeight	float,
		--			@totalQty		float,
		--			@totalVolume	float,
		--			@totalWeight	float


	end
	else
	print '.........Обработка Заказа или Загрузки уже начата. Исключение Заказа из Загрузки запрещено !'

 end
 else
 print '......Загрузка не существует. Выполнение ветки алгоритма прервано.'

print '...Завершена обработка ветки "исключение Заказа из Загрузки"'
end
print '<<<< dbo.app_Load <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'


/*
wh1.loadhdr -- таблица шапок загрузок
	loadid -- pk идентификатор загрузки wh1.ncounter.cartonid

wh1.loadorderdetail -- таблица заказов в загрузках
	loadorderdetailid -- pk идентификатор строки с номером заказа в загрузке wh1.ncounter.loadorderdetailid
	shipmentorder -- номер заказа на отгрузку
	loadstopid -- идентификатор остановки для заказа wh1.loadstop

wh1.loadunitdetail -- таблица погрузочных единиц заказов
	loadunitdetailid -- pk 

wh1.loadstop -- таблица остановок
	stop -- номер остановки
	loadstopid -- pk идентификатор остановки wh1.ncounter.loadstopid
	loadid -- идентификатор загрузки wh1.loadhdr

wh1.loadplanning -- ???
	loadplanningkey -- pk идентификатор ??? wh1.ncounter.loadplanning
*/

