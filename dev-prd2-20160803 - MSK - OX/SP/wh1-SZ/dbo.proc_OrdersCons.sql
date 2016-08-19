--################################################################################################
-- Процедура включает/исключает ЗО из Волн, и отображает список ЗО
-- Принадлежность ЗО к Волне устанавливается значением поля o.ORDERGROUP
---- в поле o.INTERMODALVEHICLE(Перевозчик) записывается код Водителя/Экспедитора
---- в поле o.LOADID( записывается код документа Загрузка
---- в поле o.... (Маршрут) записывается код маршрута (префикс "TS"+код документа загрузка)
---- в поле o.... (...) записывается текстовое описание направления доставки
--################################################################################################
ALTER PROCEDURE [dbo].[proc_OrdersCons]
	@dateLow datetime,
	@dateHigh datetime,
	@Orderkey varchar(10)='',		-- номер ЗО
	@Wavekey varchar(10)='',		-- номер Волны
	@flag varchar(1)='',			-- флаг '-' исключить/'+' включить/'' просмотр
	@Driver		varchar(10)='',		-- код Водителя
	@Car		varchar(10)='',		-- номер машины
	@Route		varchar(10)='',		-- маршрут (направление)
	@Storerkey	varchar(10)='',		-- фильтр по Владельцу
	@activeWave varchar(10) OUTPUT
AS

declare @newWave varchar(10),
		@status int,
		@DriverName varchar(45),
		@CarNumber	varchar(18),
		@CarType	varchar(45)
print '>>> dbo.proc_OrderCons >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'

print '...Извлекаем статус Волны по статусам ЗО'
set @newWave=isnull(@Wavekey,'')
select @status=max(cast(o.status as int)) from wh1.orders o
	where o.ordergroup=@newWave and @newWave<>''
print '...@Wavekey:'+@newWave+' status='+cast(isnull(@status,-1) as varchar)

print '...Извлекаем ФИО водителя и номер машины'
select @DriverName=company from wh1.storer where storerkey=@Driver
set @DriverName=isnull(@DriverName,'')
select @CarNumber=vat, @CarType=company from wh1.storer where storerkey=@Car
set @CarNumber=isnull(@CarNumber,'')
set @CarType=isnull(@CarType,'')
print '...@Driver:'+@Driver+' ('+@DriverName+' @Car:'+@Car+' ('+@CarNumber+')('+@CarType+')'

print '1. Определяем ветку алгоритма (просмотр/добавление/исключение записей)'
if (@flag='+' and @newWave<>'' and @Orderkey<>'' and ISNULL(@status,-1)<10)
begin
		print '2. Выбрана ветка: Добавление ЗО в существующую Волну'
		print '...прописываем в ЗО номер Волны:'+@newWave+' код водителя:'+@Driver+' код машины:'+@Car+' направление:'+@Route
		update o
		set ordergroup=@newWave,
			INTERMODALVEHICLE=isnull(@Driver,''),
			DriverName=@DriverName,
			CarrierCode=@Car,
			CarrierName=@CarType,
			TrailerNumber=@CarNumber,			
			[route]=isnull(@Route,'')
		from wh1.orders o
		where o.orderkey=@Orderkey

		print '...переформируем существющую Волну: '+@newWave
		exec dbo.app_Wave @newWave
end

if (@flag='-' and @Orderkey<>'' and ISNULL(@status,-1)<10)
begin
		print '3. Выбрана ветка: Удаление ЗО из существующей Волны'
		print '...запоминаем номер Волны'
		select @newWave=isnull(o.ordergroup,'')
		from wh1.orders o join wh1.Wave w on (o.ordergroup=w.wavekey)
		where o.orderkey=@Orderkey
		print '...очищаем номер Волны в ЗО'
		update o
		set ordergroup='',
			INTERMODALVEHICLE='',
			DriverName='',
			CarrierCode='',
			CarrierName='',
			TrailerNumber='',			
			[route]=''
		from wh1.orders o
		where o.orderkey=@Orderkey
		print '...переформируем Волну'
		if (isnull(@newWave,'')<>'') exec dbo.app_Wave @newWave,@Driver,@Car,@Route
end

if (@flag='+' and isnull(@Wavekey,'')='' and @Orderkey<>'')
begin
		print '4. Выбрана ветка: Добавление ЗО в новую Волну'
		print '...получаем номер новой Волны'
		exec dbo.DA_GetNewKey 'wh1','WAVEKEY',@newWave output
		print '...получен номер @newWave='+@newWave

		print '...прописываем номер Волны в ЗО'
		update o
		set ordergroup=@newWave,
			INTERMODALVEHICLE=@Driver,
			DriverName=@DriverName,
			CarrierCode=@Car,
			CarrierName=@CarType,
			TrailerNumber=@CarNumber,			
			[route]=@Route
		from wh1.orders o
		where o.orderkey=@Orderkey
		print '...Создаем новую Волну'
		exec dbo.app_Wave @newWave,@Driver,@Car,@Route
end

set @activeWave=@newWave
print '5. Возвращаем записи для отчета----------------------------------'
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

o.stop				[Stop],
o.OrderDate,
o.RequestedShipDate,
o.ExternOrderKey,
o.susr4				ExternDocNumber,
o.OrderKey,
o.Status,
os.description		StatusDescr,
o.ConsigneeKey,
o.c_company			C_Name,
st_c.susr2			C_RouteDirection,
isnull(o.c_address1,'')+isnull(o.c_address2,'')+isnull(o.c_address3,'')+isnull(o.c_address4,'') C_Address,
o.B_Company			ByerKey,
o.b_company			B_Name,
isnull(o.b_address1,'')+isnull(o.b_address2,'')+isnull(o.b_address3,'')+isnull(o.b_address4,'') b_Address,

case
	when isnull(o.ordergroup,'')='' and cast(o.status as int)<10 then '+'
	when isnull(o.ordergroup,'')<>'' and cast(o.status as int)<10 then '-'
	else ''
end operation,


round(count(od.sku)*sum(od.originalqty*s.stdcube*s.stdgrosswgt),3)	Scope,
ROUND(sum((od.qtypicked+od.shippedqty)*s.stdcube*s.stdgrosswgt)
	/ sum(case od.originalqty*s.stdcube*s.stdgrosswgt when 0 then 1 else od.originalqty*s.stdcube*s.stdgrosswgt end) *100,0)			PercentComplete,
count(od.sku)														SkuCount,
round(sum(od.originalqty*s.stdcube),3)								OrderedCube,
round(sum(od.originalqty*s.stdgrosswgt)/1000,3)						OrderedWeight,
round(sum((od.qtypicked+od.shippedqty)*s.stdcube),3)				CompletedCube,
round(sum((od.qtypicked+od.shippedqty)*s.stdgrosswgt)/1000,3)		CompletedWeight,
sum(od.originalqty*od.unitprice)									OrderedSUM,
sum(od.shippedqty*od.unitprice)										ShippedSUM,

o.transportationservice	PickToZone,
o.door				OutDoor,
o.susr1				DocType,
o.susr2				OperationType,
o.susr3				Sklad,
@newWave			activeWaveKey
--into dbo.del_OrdersCons
from wh1.orders o
		join wh1.storer st on (o.storerkey=st.storerkey)
		left join wh1.storer st_c on (o.consigneekey=st_c.storerkey)
		join wh1.orderstatussetup os on (o.status=os.code)
		join wh1.orderdetail od on (o.orderkey=od.orderkey)
		join wh1.sku s on (od.storerkey=s.storerkey and od.sku=s.sku)
where 
 (o.orderdate between isnull(@dateLow,'19900101') and isnull(@dateHigh,getdate()+2))
and 
 ((o.storerkey=@Storerkey and (o.ordergroup='' or o.ordergroup is null)) or (@Storerkey='' or @Storerkey is null))

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
			o.stop,
			o.OrderDate,
			o.RequestedShipDate,
			o.ExternOrderKey,
			o.susr4,
			o.OrderKey,
			o.Status,
			os.description,
			o.ConsigneeKey,
			o.c_company,
			st_c.susr2,
			o.c_address1,o.c_address2,o.c_address3,o.c_address4,
			o.B_Company,
			o.b_company,
			o.b_address1,o.b_address2,o.b_address3,o.b_address4,
			o.transportationservice,
			o.door,
			o.susr1,
			o.susr2,
			o.susr3
order by cast(o.status as int), o.orderdate

