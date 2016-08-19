ALTER PROCEDURE [rep].[Physical_features_of_product] (
	@st varchar(10) = NULL,
    @sku varchar(20) = NULL,
    @descr varchar(100) = NULL,
    @ostatki varchar(20)
)
as
begin
	
	--if @st is null set @st='001'

	if @ostatki <> '1' -- на NULL не сработает, но это не важно
		set @ostatki = NULL
	
	
	select
		s.SKU,
		s.NOTES1,
		lx.LOC,
		lx.QTY,
		nullif(s.STDGROSSWGT,0) as STDGROSSWGT,
		nullif(s.STDCUBE,0) as STDCUBE,
		--(s.STDGROSSWGT*1000) / (s.STDCUBE*1000000) PLOT
		s.STDGROSSWGT / nullif(s.STDCUBE,0) / 1000 as PLOT
	from wh1.SKU s
		left join wh1.LOTxLOCxID lx on lx.SKU = s.SKU and lx.QTY > 0 and s.STORERKEY=lx.STORERKEY
	where (@ostatki is NULL or lx.SERIALKEY is NOT NULL)
		and (@sku is NULL or s.SKU = @sku)
		and (@descr is NULL or s.NOTES1 like '%' + @descr + '%')
		and s.STORERKEY=@st
	order by 7 desc
		
end

/*
exec dbo.rep_sku_qty_vgh null,null,null
*/

 

