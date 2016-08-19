--################################################################################################
-- Процедура включает/исключает ЗО из Волн и Загрузок, и отображает список ЗО
-- Принадлежность ЗО к Волне устанавливается значением поля o.ORDERGROUP
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

---- o.TRANSPORTATIONSERVICE - (заполняется вручную через интерфейс стационарного места)
----							ячейка сборки заказа (PICKTO). Значение используется для печати в листах отбора.
--################################################################################################
ALTER PROCEDURE [dbo].[proc_OrdersTransport]
	@dateLow		datetime,
	@dateHigh		datetime,
	@Orderkey		varchar(10)='',	-- номер ЗО
	@Wavekey		varchar(10)='',	-- номер Волны
	@flag			varchar(1)='',	-- флаг '-' исключить/'+' включить/'' просмотр
	@Driver			varchar(10)='',	-- код Водителя
	@Car			varchar(10)='',	-- номер машины
	@RouteDirection	varchar(20)='',	-- направление доставки
 	@loadid			varchar (10)='',-- номер загрузки

	@shiptime		datetime,		-- требуемая дата отгрузки
	@readyFlag		varchar(1)='1',	-- флаг передачи заказа на обработку складом '1'-отдать в обработку TRANSPORTATIONMODE

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

print 'Определяем статус Волны по статусам ЗО'
select @status=max(cast(o.status as int)) from wh1.orders o
	where o.ordergroup=@newWave and @newWave<>''
print '...@Wavekey:'+@newWave+' status='+cast(isnull(@status,-1) as varchar)

print 'Определяем готовность Волны для передачи на склад по готовности ЗО'
select @ReadyWave=isnull(max(o.Transportationmode),'1') from wh1.orders o
	where o.ordergroup=@newWave and @newWave<>''
if @ReadyWave>'1' set @ReadyWave='2'
print '...@ReadyWave='+@ReadyWave

print 'Проверяем включен ли заказ в Волну'
if (isnull(@Orderkey,'')<>'')
select @ISinWave=case when o.ordergroup<>'' and o.ordergroup is not null then 1 else 0 end
	from wh1.orders o
	where o.orderkey=@Orderkey
print '...ISinWave='+cast(@ISinWave as varchar)

print '...Извлекаем ФИО водителя, номер и тип машины'
select @DriverName=isnull(company,'') from wh1.storer where storerkey=@Driver
select @CarNumber=isnull(vat,''), @CarType=isnull(company,'') from wh1.storer where storerkey=@Car
print '...@Driver:'+@Driver+' ('+@DriverName+') @Car:'+@Car+' ('+@CarNumber+')('+@CarType+')'

print '1. Определяем ветку алгоритма (просмотр/добавление/исключение записей)'
if (@flag='+' and @newWave<>'' and @activeLoad<>'' and @Orderkey<>'' and ISNULL(@status,-1)<10 and @ISinWave=0)
begin
		print '2. Выбрана ветка: Добавление ЗО в существующую Волну и Загрузку'
		print '...прописываем в шапку ЗО номер Волны @Wave='+@newWave+' и флаг готовности, соответствующий Волне @ReadyWave='+@ReadyWave
		update o set ordergroup=@newWave,Transportationmode=@ReadyWave
		 from wh1.orders o where o.orderkey=@Orderkey

		print '...переформируем существующую Волну: '+@newWave
		exec dbo.app_Wave @newWave

		print '...добавляем ЗО:'+@orderkey+' в Загрузку: '+isnull(@activeLoad,'<NULL>')
		exec dbo.app_Load	@orderkey,		-- номер ЗО
 							@activeLoad,	-- номер загрузки
							@RouteDirection,-- направление доставки
							@Driver,		-- код перевозчика/экспедитора
							@DriverName,	-- ФИО Водителя/Экспедитора
							@Car,			-- код машины
							@CarType,		-- тип машины
							@CarNumber,		-- номер машины
							@validDate,		-- требуемая дата отгрузки
							'+',
 							@activeLoad OUTPUT		-- номер активной Загрузки
		print '2. Добавление ЗО в существующую Волну и Загрузку завершено.'

end

if (@flag='-' and @Orderkey<>'' and ISNULL(@status,-1)<10)
begin
		print '3. Выбрана ветка: Удаление ЗО из существующей Волны и Загрузки'
		print '...запоминаем номер Волны и Загрузки'
		select @newWave=isnull(o.ordergroup,''), @activeLoad=isnull(o.loadid,'')
		from wh1.orders o	join wh1.Wave w on (o.ordergroup=w.wavekey)	-- эти join нужны для проверки существования
							join wh1.Loadhdr l on (o.loadid=l.loadid)	-- соответствующих Волн и Загрузок
		where o.orderkey=@Orderkey
		print '...очищаем номер Волны и флаг готовности передачи на склад в шапке ЗО'
		update o
		set ordergroup='',Transportationmode='1' from wh1.orders o	where o.orderkey=@Orderkey

		print '...переформируем Волну'
		if (isnull(@newWave,'')<>'') exec dbo.app_Wave @newWave,@Driver,@Car,@RouteDirection

		print '...исключаем ЗО:'+@orderkey+' из Загрузки: '+isnull(@activeLoad,'<NULL>')
		exec dbo.app_Load	@orderkey,		-- номер ЗО
 							@activeLoad,	-- номер загрузки
							@RouteDirection,-- направление доставки
							@Driver,		-- код перевозчика/экспедитора
							@DriverName,	-- ФИО Водителя/Экспедитора
							@Car,			-- код машины
							@CarType,		-- тип машины
							@CarNumber,		-- номер машины
							@validDate,		-- требуемая дата отгрузки
							'-',
 							@activeLoad OUTPUT		-- номер активной Загрузки
		print '3. Исключение ЗО из Волны и Загрузки завершено.'

end

if (@flag='+' and isnull(@Wavekey,'')='' and @Orderkey<>'' and @ISinWave=0)
begin
		print '4. Выбрана ветка: Добавление ЗО в новую Волну и Загрузку'
		print '...получаем номер новой Волны'
		exec dbo.DA_GetNewKey 'wh1','WAVEKEY',@newWave output
		print '...получен номер @newWave='+@newWave

		print '...прописываем номер Волны в ЗО'
		update o set ordergroup=@newWave from wh1.orders o where o.orderkey=@Orderkey

		print '...Создаем новую Волну'
		exec dbo.app_Wave @newWave,@Driver,@Car,@RouteDirection

		print '...добавляем ЗО:'+@orderkey+' в Загрузку: '+isnull(@activeLoad,'<NULL>')
		exec dbo.app_Load	@orderkey,		-- номер ЗО
 							@activeLoad,	-- номер загрузки
							@RouteDirection,-- направление доставки
							@Driver,		-- код перевозчика/экспедитора
							@DriverName,	-- ФИО Водителя/Экспедитора
							@Car,			-- код машины
							@CarType,		-- тип машины
							@CarNumber,		-- номер машины
							@validDate,		-- требуемая дата отгрузки
							'+',
 							@activeLoad OUTPUT		-- номер активной Загрузки
		print '4. Добавление ЗО в новую Волну и Загрузку завершено.'

end

if (@flag='' and isnull(@Wavekey,'')<>'' and isnull(@loadid,'')<>'')
begin
		print '5. Выбрана ветка: Обновление шапки Волны и Загрузки'
		if ISNULL(@status,-1)<10
		begin
			print '...Волна еще не запущена в обработку. Разрешено обновлять все.'
			print '...Обновляем шапки Заказов'
			update wh1.orders
			set	externalloadid = upper(@RouteDirection),
				INTERMODALVEHICLE=isnull(@Driver,''),
				CarrierCode=@Car,
				DriverName=@DriverName,
				CarrierName=@CarType,
				TrailerNumber=@CarNumber,
				Transportationmode=@readyStatus	--флаг передачи рейса на обработку складу
			where loadid=@loadid
			print '...Обновляем шапку Волны'
			update wh1.wave
			set	 externalwavekey=@Driver,
				 descr=upper(@RouteDirection)
			where wavekey=@Wavekey
			print '...Обновляем шапку Загрузки'
			update wh1.loadhdr
			set	externalid=upper(@RouteDirection),
				carrierid=@Driver,
				trailerid=@Car,
				departuretime=isnull(@shiptime,getdate())
			where loadid=@loadid
		end
		else
		begin
			print '...Волна уже запущена в обработку. Разрешено обновлять только машину и водителя.'
			print '...Обновляем шапки Заказов'
			update wh1.orders
			set	externalloadid = upper(@RouteDirection),
				INTERMODALVEHICLE=isnull(@Driver,''),
				CarrierCode=@Car,
				DriverName=@DriverName,
				CarrierName=@CarType,
				TrailerNumber=@CarNumber
			where loadid=@loadid
			print '...Обновляем шапку Волны'
			update wh1.wave
			set	 externalwavekey=@Driver,
				 descr=upper(@RouteDirection)
			where wavekey=@Wavekey
			print '...Обновляем шапку Загрузки'
			update wh1.loadhdr
			set	externalid=upper(@RouteDirection),
				carrierid=@Driver,
				trailerid=@Car
			where loadid=@loadid
		end
end



print 'Устанавливаем активную волну @activeWave=' + @newWave
set @activeWave=@newWave

print 'Запоминаем общие параметры по Волне/Загрузке'
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

print '6. Возвращаем записи для отчета----------------------------------'
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
--отбираем все не отгруженные заказы
--и любые заказы, не включенные в загрузку, но попадающие в заданый диапазон дат по требуемой дате доставки, с фильтром по направлению
 ( (isnull(o.loadid,'')='')
		and (cast(o.status as int)<14 or o.RequestedShipDate between isnull(@dateLow,getdate()-1) and isnull(@dateHigh+1,getdate()+2) ) 
		and (st_c.susr2 like isnull(left(@RouteDirection,10),'')+'%' or isnull(st_c.susr2,'')='')
 )
OR
--все заказы из Загрузок, попадающих в заданный диапазон и заказы активной(обрабатываемой) Загрузки
 ( (isnull(o.loadid,'')<>'')
		and (( [load].departuretime between isnull(@dateLow,getdate()-1) and isnull(@dateHigh,getdate()+2)  
				and (o.externalloadid like isnull(left(@RouteDirection,10),'')+'%' or isnull(o.externalloadid,'')='')
			  )
			  or 
			 o.loadid=@activeLoad )
 ) 

group by	o.OrderKey

