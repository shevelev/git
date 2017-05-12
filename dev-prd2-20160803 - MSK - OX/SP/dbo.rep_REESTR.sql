ALTER PROCEDURE [dbo].[rep_REESTR] 
(	@dateLow	datetime='20090101',
	@dateHigh	datetime='20090101',
	@status		varchar(1)='5',		--'5' - отобран, '9' - отгружен
	@storer		varchar(15)='' )

as
--declare @dateLow	datetime,
--		@dateHigh	datetime,
--		@status		varchar(1)

--select	@dateLow	='20091026',
--		@dateHigh	='20091026',
--		@status		='5'

select 
o.orderkey					INFORNumber,
o.susr4						SMDocNumber,
o.EXTERNORDERKEY,
o.orderdate					SMdate,
o.editdate					ShipDate,
o.C_Company,
isnull(st.Company,'')		B_Company,
pd.storerkey,
pd.sku,
sum(pd.qty)					qty,
od.unitprice,
o.susr2					susr2
into #step1
from
wh1.pickdetail pd
join wh1.orders o on (pd.orderkey=o.orderkey)
join wh1.orderdetail od on (pd.orderkey=od.orderkey and pd.orderlinenumber=od.orderlinenumber)
left join wh1.storer st on (o.B_COMPANY=st.storerkey)
where
pd.storerkey=@storer
and pd.editdate between @dateLow and dateadd(day,1,@dateHigh)
and pd.status>=@status
group by 
o.orderkey,
o.susr4,
o.EXTERNORDERKEY,
o.orderdate,
o.editdate,
o.C_Company,
isnull(st.Company,''),
pd.storerkey,
pd.sku,
od.unitprice,
o.susr2

--select * from #step1
--drop table #step1

select 
INFORNumber,
SMDocNumber,
EXTERNORDERKEY,
SMdate,
ShipDate,
C_Company,
B_Company,
sum(round(qty*unitprice,2))			SUMMA,
susr2
from #step1
group by
INFORNumber,
SMDocNumber,
EXTERNORDERKEY,
SMdate,
ShipDate,
C_Company,
B_Company,
susr2
order by ShipDate,SMdate,EXTERNORDERKEY

