--################################################################################################
-- Процедура отображает список ЗО
--################################################################################################
ALTER PROCEDURE [dbo].[proc_OrdersList]
	@dateLow		datetime,
	@dateHigh		datetime,
	@RouteDirection	varchar(20)='',	-- направление доставки
	@readyFlag		varchar(1)='1',	-- флаг передачи заказа на обработку складом '1'-отдать в обработку TRANSPORTATIONMODE
	@Storerkey		varchar(15)

AS

print '>>> dbo.proc_OrdersList >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'

print '1. Возвращаем записи для отчета----------------------------------'
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
round(count(od.sku)*sum(od.originalqty*s.stdcube*s.stdgrosswgt),1)	Scope,
max(o.transportationservice)										PickToZone,
round( sum(
			(case when od.qtyallocated+od.qtypicked+od.shippedqty>0
						then (od.qtypicked+od.shippedqty)/(od.qtyallocated+od.qtypicked+od.shippedqty) 
						else 0 end)
			* case when s.stdcube=0 then 1 else s.stdcube end )
		/(case when sum(s.stdcube)=0 then 1 else sum(s.stdcube) end)*100
	 ,0)		
					PercentComplete,
max(o.editdate)		editdate,
max(o.containerqty) containerqty
from wh1.orders o
		join wh1.orderdetail od on (o.orderkey=od.orderkey)
		join wh1.storer st on (o.storerkey=st.storerkey)
		join wh1.storer st_c on (o.consigneekey=st_c.storerkey)
		join wh1.orderstatussetup os on (o.status=os.code)
		join wh1.sku s on (od.storerkey=s.storerkey and od.sku=s.sku)
		left join wh1.loadhdr [load] on (o.loadid=[load].loadid)
where 
     --отбираем только заказы переданные на склад
 ( (isnull(@readyFlag,'1')='1' and o.transportationmode='2')
	or isnull(@readyFlag,'1')<>'1'
 )
 AND -- фильтр по Владельцу
 ( isnull(@Storerkey,'')='' or isnull(@Storerkey,'')=o.storerkey 
 )
 AND -- фильтр по Отмененным заказам
 ( o.type<>'26' 
 )
 AND -- все неотгруженные заказы независимо от диапазона дат
 (	cast(o.status as int)<92
	OR --заказы, не включенные в загрузку, но попадающие в заданый диапазон дат, с фильтром по направлению
	( (isnull(o.loadid,'')='')
		and (o.RequestedShipDate between isnull(@dateLow,getdate()-1) and isnull(@dateHigh+1,getdate()+2) ) 
		and (st_c.susr2 like isnull(left(@RouteDirection,10),'')+'%' or isnull(st_c.susr2,'')='')
	)
	OR --заказы, включенные в загрузку и попадающие в заданый диапазон дат, с фильтром по направлению
	( (isnull(o.loadid,'')<>'')
		and ( [load].departuretime between isnull(@dateLow,getdate()-1) and isnull(@dateHigh+1,getdate()+2)  
				and (o.externalloadid like isnull(left(@RouteDirection,10),'')+'%' or isnull(o.externalloadid,'')='')
			)
	) 
 )
group by	o.OrderKey

