/*
 * Статистика по заказам №2 (по объему)
 */
ALTER PROCEDURE [rep].[Statistics_of_shipments_WeightVolume]
	@date_from datetime = NULL,
	@date_to datetime = NULL
as
begin
	set NOCOUNT on
	
	select
		@date_from = cast(round(cast(@date_from as real), 0, 1) as smalldatetime),
		@date_to = cast(round(cast(@date_to as real), 0, 1) as smalldatetime) + 1

	select
		--isnull(cl.[DESCRIPTION],s.FREIGHTCLASS) as FREIGHTCLASS,
		isnull(cl.[DESCRIPTION],'???') as FREIGHTCLASS,
		count(distinct od.ORDERKEY) as ORDERKEY,
		count(distinct od.ORDERKEY + od.ORDERLINENUMBER) as ORDERLINENUMBER,
		sum((od.QTYPICKED + od.SHIPPEDQTY) * s.STDGROSSWGT) as STDGROSSWGT,
		sum((od.QTYPICKED + od.SHIPPEDQTY) * s.STDCUBE) as STDCUBE
	from wh1.ORDERS o
		join wh1.ORDERDETAIL od
			join wh1.SKU s
				left join wh1.CODELKUP cl on cl.CODE = s.FREIGHTCLASS and cl.LISTNAME = 'FREIGHTCLS' -- может быть левый текст
			on s.SKU = od.SKU and s.STORERKEY = od.STORERKEY
		on od.ORDERKEY = o.ORDERKEY
	where o.[STATUS] >= 78 -- проконтролированы
		and o.ORDERDATE >= @date_from and o.ORDERDATE < @date_to
	--group by isnull(cl.[DESCRIPTION],s.FREIGHTCLASS)
	group by cl.[DESCRIPTION]

end

