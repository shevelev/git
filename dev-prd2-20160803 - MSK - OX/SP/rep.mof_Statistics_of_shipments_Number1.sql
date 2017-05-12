/*
 * Статистика по заказам №1 (по количеству)
 */
ALTER PROCEDURE [rep].[mof_Statistics_of_shipments_Number1]
	@date_from datetime = NULL,
	@date_to datetime = NULL,
	@route varchar(4000) = NULL,
	@company varchar(max) = NULL
as
begin
	set NOCOUNT on
	
	select
		@date_from = cast(round(cast(@date_from as real), 0, 1) as smalldatetime),
		@date_to = cast(round(cast(@date_to as real), 0, 1) as smalldatetime) + 1,
		@route = nullif(rtrim(@route),''),
		@company = nullif(rtrim(@company),'')
	
	select
		o.[ROUTE], c.COMPANY,
		count(distinct od.ORDERKEY) as ORDERKEY,
		sum(od.ORDERLINENUMBER) as ORDERLINENUMBER,
		sum(od.QTY) as QTY,
		sum(pl.BOXNUM) as BOXNUM
	from wh2.ORDERS o
		left join wh2.STORER c on c.STORERKEY = o.CONSIGNEEKEY
		join (
			select
				ORDERKEY,
				count(ORDERLINENUMBER) as ORDERLINENUMBER,
				sum(QTYPICKED + SHIPPEDQTY) as QTY
			from wh2.ORDERDETAIL
			group by ORDERKEY
		) od on od.ORDERKEY = o.ORDERKEY
		left join (
			select
				ORDERKEY,
				sum(BOXNUM) as BOXNUM
			from wh2.PICKCONTROL_LABEL
			group by ORDERKEY
		) pl on pl.ORDERKEY = o.ORDERKEY
	where o.[STATUS] >= 78 -- проконтролированы
		and o.ORDERDATE >= @date_from and o.ORDERDATE < @date_to
		and ( @route is NULL or o.[ROUTE] in (select SLICE from dbo.sub_udf_common_split_string(@route,',')) )
		and ( @company is NULL or o.CONSIGNEEKEY in (select [Value] from dbo.split(@company,',')) /* or o.B_COMPANY in (@company) */ )
	group by o.[ROUTE], c.COMPANY
	--order by right('00' + o.[ROUTE], 3), c.COMPANY
	
	select * from dbo.[Split](@route,',')
	select * from dbo.[Split](@company,',')
	
end


