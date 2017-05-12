-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[VEDOMOST_NVX]
	-- Add the parameters for the stored procedure here
	@CARTONGROUP varchar(50)='',
	@SECTION varchar(50)='',
	@SKUGROUP2 varchar(50)='',
	@SM_Group1 varchar(50)='',
	@SM_Group2 varchar(50)='',
	@SM_Group3 varchar(50)=''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

select
dbo.GetEAN128(s.SKU) barcode,
s.SKU, max(s.descr) DESCR, 
cast(isnull(max(s.susr1),'0') as float) U_F, cast(isnull(max(s.susr2),'0') as float) U_N,
cast(0 as float) FAKT_F, cast(0 as float) FAKT_N,
cast(0 as float) NED_FVV, cast(0 as float) NED_NVX,
cast(0 as float) NED_TOTAL,
max(s.CARTONGROUP) CARTONGROUP, 
max(s.skugroup) SECTION, max(s.skugroup2) SKUGROUP2,
max(s.busr1) SM_Group1, max(s.busr2) SM_Group2, max(s.busr3) SM_Group3, max(s.busr4) SM_Group4,
max(isnull(pod.unitprice,0)) PRICE,
--cast(0 as float) PRICE,
cast(0 as float) SUMMA
into #VEDOMOST
from wh1.sku s
left join wh1.podetail pod on (s.sku=pod.sku and s.storerkey=pod.storerkey)
where --(s.susr1>'' or s.susr2>'') and 
(pod.pokey='0000000168' or pod.pokey is null) and
(s.storerkey='92' or s.storerkey='219')
and
(
	(isnull(s.CARTONGROUP,'')=@CARTONGROUP or @CARTONGROUP='') 
	and	
	(isnull(s.SKUGROUP,'')=@SECTION or @SECTION='')
	and
	(isnull(s.SKUGROUP2,'')=@SKUGROUP2 or @SKUGROUP2='')
	and
	(isnull(s.busr1,'')=@SM_Group1 or @SM_Group1='')
	and
	(isnull(s.busr2,'')=@SM_Group2 or @SM_Group2='')
	and
	(isnull(s.busr3,'')=@SM_Group3 or @SM_Group3='')
)
group by s.sku

select lld.SKU, sum(lld.qty) fact_FVV 
into #fact_FVV
from wh1.lotxlocxid lld
where lld.storerkey='92' and lld.qty>0
group by lld.storerkey, lld.sku

select lld.SKU, sum(lld.qty) fact_NVX 
into #fact_NVX
from wh1.lotxlocxid lld
where lld.storerkey='219' and lld.qty>0
group by lld.storerkey, lld.sku

update V
set	V.FAKT_F=ROUND(isnull(FVV.fact_FVV,0),0),
	V.FAKT_N=ROUND(isnull(NVX.fact_NVX,0),0),
	V.NED_FVV=ROUND(isnull(FVV.fact_FVV,0)-V.U_F,0),		
	V.NED_NVX=ROUND(isnull(NVX.fact_NVX,0)-V.U_N,0),
	V.NED_TOTAL=ROUND((isnull(FVV.fact_FVV,0)+isnull(NVX.fact_NVX,0))  -  (V.U_F+V.U_N),0),
	V.SUMMA=ROUND(((isnull(FVV.fact_FVV,0)+isnull(NVX.fact_NVX,0))  -  (V.U_F+V.U_N))*V.PRICE,0)
from #VEDOMOST V
left join #fact_FVV FVV on (V.SKU=FVV.SKU)
left join #fact_NVX NVX on (V.SKU=NVX.SKU)

select * 
--into table01 
from #VEDOMOST
where (NED_FVV<>0 or NED_NVX<>0)
order by abs(SUMMA) DESC

END

