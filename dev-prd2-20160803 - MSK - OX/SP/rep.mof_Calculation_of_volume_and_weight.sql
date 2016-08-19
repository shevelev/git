/* Отчет для расчета объема и веса товаров запланированных под отгрузку */
ALTER PROCEDURE [rep].[mof_Calculation_of_volume_and_weight] (
	@sd datetime = NULL,
	@time_sd varchar(5) = NULL,
	@ed datetime = NULL,
	@time_ed varchar(5) = NULL,
	@ro varchar(500) = ''
)
AS

--declare @sd datetime 
--declare @time_sd varchar(5)
--declare @ed datetime 
--declare @time_ed varchar(5)
--declare @ro varchar(3)

--set @sd ='20120101' set @time_sd='00:10'
--set @ed ='20120215' set @time_ed='16:00'
--set @ro ='15'

	set NOCOUNT on
	
	set @sd = dbo.udf_get_date_from_datetime(isnull(@sd,getdate()))
	set @ed = dbo.udf_get_date_from_datetime(isnull(@ed,getdate()))
	
	if dbo.sub_udf_common_regex_is_match(@time_sd,'^([01][0-9]|2[0-3]):[0-5][0-9]$') = 1
		set @sd = convert(datetime, convert(varchar(10),@sd,120) + ' ' + @time_sd + ':00',120)
	
	if dbo.sub_udf_common_regex_is_match(@time_ed,'^([01][0-9]|2[0-3]):[0-5][0-9]$') = 1
		set @ed = convert(datetime, convert(varchar(10),@ed,120) + ' ' + @time_ed + ':59',120)
	else
		set @ed = @ed + convert(time,'23:59:59.997')

--select @sd, @time_sd, @ed, @time_ed

create table #rez (
	ORDERKEY varchar(10),
	CASEID varchar(10),
	EXTERNORDERKEY varchar(20),
	adddate datetime,
	description varchar(100),
	address varchar(100),
	objom float,
	ves float,
	boxnum float
)


insert into #rez
select
	o.ORDERKEY,	--заказ
	pd.CASEID,
	o.EXTERNORDERKEY,	--внешний заказ
	o.ADDDATE,	--дата отгрузки
	oss.DESCRIPTION,	--статус заказа
	s.ADDRESS1 + '' + s.ADDRESS2 + '' + s.ADDRESS3 + '' + ADDRESS4 as address,	--адрес доставки
	case when o.status in ('02', '09')
			then sum(od.ORIGINALQTY * sku.STDCUBE)
			else case when o.STATUS = '19' or o.status between '51' and '78'
			     		then sum(pd.QTY * sku.stdcube)
			     		else 0
			     	end
		end as objom,	--объем
	case when o.status in ('02', '09')
			then sum(od.ORIGINALQTY * sku.STDGROSSWGT)
			else case when o.STATUS = '19' or o.status between '51' and '78'
			     		then sum(pd.QTY * sku.STDGROSSWGT)
			     		else 0
			     	end
		end as ves,	--вес
	case when o.status in ('68', '78')
			then case when pl.boxnum is NULL
			     		then ceiling(sum(pd.qty / p.casecnt))
			     		else pl.BOXNUM
			     	end
			else '0'
		end boxnum --количество ящиков
from wh2.ORDERS o
	join wh2.ORDERSTATUSSETUP oss on oss.CODE = o.status
	join wh2.STORER s on s.STORERKEY = o.CONSIGNEEKEY
	join wh2.ORDERDETAIL od
		left join wh2.PICKDETAIL pd
			left join wh2.PICKCONTROL_LABEL pl on pl.CASEID = pd.CASEID
			join wh2.LOTATTRIBUTE la
				join wh2.PACK p on p.PACKKEY = la.LOTTABLE01
			on la.LOT = pd.lot
		on pd.ORDERKEY = od.ORDERKEY and pd.ORDERLINENUMBER = od.ORDERLINENUMBER
		join wh2.SKU sku on sku.SKU = od.sku
	on od.ORDERKEY = o.ORDERKEY
	join wh2.LOADORDERDETAIL lod
		join wh2.LOADSTOP ls
			join wh2.LOADHDR lh on lh.LOADID = ls.LOADID
		on ls.LOADSTOPID = lod.LOADSTOPID
	on lod.SHIPMENTORDERID = o.ORDERKEY
where (lh.DEPARTURETIME between @sd and @ed)
    and (@ro = '' or lh.[ROUTE] = @ro)
	and o.[STATUS] in ('02','09','19','51','52','53','55','57','61','68','75','78')
	    --and o.ORDERKEY='0000041080'
group by	o.ORDERKEY,pd.caseid,o.EXTERNORDERKEY,o.ADDDATE,oss.[DESCRIPTION],
			s.ADDRESS1,s.ADDRESS2,s.ADDRESS3,s.ADDRESS4, o.[STATUS],pl.BOXNUM
order by o.ORDERKEY


select ROW_NUMBER() OVER(ORDER BY ORDERKEY) num, ORDERKEY, EXTERNORDERKEY, adddate, description, address, SUM(objom) o, SUM(ves) v, SUM(boxnum) b from #rez
group by ORDERKEY, EXTERNORDERKEY, adddate, description, address


drop table #rez

