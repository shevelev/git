/*
 * Статистика по заказам №3 (по объему)
 */
ALTER PROCEDURE [rep].[mof_Statistics_receipts]
	@date_from datetime = NULL,
	@date_to datetime = NULL
as
begin
	set NOCOUNT on
	
	select
		@date_from = cast(round(cast(@date_from as real), 0, 1) as smalldatetime),
		@date_to = cast(round(cast(@date_to as real), 0, 1) as smalldatetime) + 1

	select
		isnull(c.[DESCRIPTION],'???') as FREIGHTCLASS,
		s.SKU,
		s.DESCR,
		pd.SUSR2,
		sum(pd.QTYRECEIVED) as QTYRECEIVED,
		sum(s.STDGROSSWGT * pd.QTYRECEIVED) as STDGROSSWGT,
		sum(s.STDCUBE * pd.QTYRECEIVED) as STDCUBE
	from wh2.PODETAIL pd
		join wh2.PO p on p.POKEY = pd.POKEY
		join wh2.SKU s
			left join wh2.CODELKUP c on c.CODE = s.FREIGHTCLASS and c.LISTNAME = 'FREIGHTCLS'
		on s.STORERKEY = pd.STORERKEY and s.SKU = pd.SKU
	where pd.WHSEID = 'dbo'
		and p.PODATE >= @date_from and p.PODATE < @date_to
		and pd.QTYRECEIVED > 0
	group by
		c.[DESCRIPTION],
		s.SKU,
		s.DESCR,
		pd.SUSR2

	--order by p.POKEY desc, p.POLINENUMBER

end

