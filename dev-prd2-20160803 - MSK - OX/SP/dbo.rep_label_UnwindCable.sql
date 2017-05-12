-- =============================================
-- Author:		Сандаков В.В.
-- Create date: 06.07.08
-- Description:	отчет для этикетки по отмотанному кабелю
-- =============================================
ALTER PROCEDURE [dbo].[rep_label_UnwindCable] (@orderkey varchar(20))

AS

--declare @orderkey varchar(20)
--set @orderkey = '0000006147'

select pd.PICKDETAILKEY, pd.ORDERKEY, pd.SKU, dbo.GetEAN128(pd.SKU) EAN128, pd.STORERKEY, s.LOTTABLEVALIDATIONKEY, o.EXTERNORDERKEY, pd.CASEID, dbo.GetEAN128(pd.CASEID) case1,
	s.DESCR, o.CONSIGNEEKEY, o.C_COMPANY, pd.QTY, pd.STATUS, pd.EDITDATE, pd.loc, dbo.GetEAN128(pd.loc) loc1,
	o.DOOR, l.LOTTABLE03, loc.PUTAWAYZONE, o.ordergroup, pd.ID,s.susr4, isnull(s.susr4, case when s.LOTTABLEVALIDATIONKEY = '02' then 'М' else 'ШТ' end) susr,
	case when isnull(od.susr5,'')='' then 0 else 1 end susr5 
into #temp
from WH40.PICKDETAIL pd
join WH40.SKU s on pd.STORERKEY = s.STORERKEY and s.SKU = pd.SKU
join WH40.ORDERS o on o.ORDERKEY = pd.ORDERKEY
 join WH40.ORDERDETAIL od on pd.ORDERKEY = od.ORDERKEY and pd.orderlinenumber = od.ORDERLINENUMBER
join WH40.LOTATTRIBUTE l on l.LOT = pd.LOT
join WH40.LOC loc on pd.LOC=loc.LOC
where 1=1
	and pd.ORDERKEY = @orderkey
	and loc.loc like '07%'/*(s.LOTTABLEVALIDATIONKEY = '02' or loc.PUTAWAYZONE in ('OCTATKI7','OTMOTKA7', 'BARABAN7','ELKA7'))*/
	and pd.STATUS < 5 		
--select * from #temp

select distinct t.PICKDETAILKEY, t.ORDERKEY, t.SKU, t.EAN128, t.STORERKEY, t.LOTTABLEVALIDATIONKEY, t.EXTERNORDERKEY, t.CASEID, t.case1, t.DESCR,
	t.CONSIGNEEKEY, t.C_COMPANY, t.QTY, t.STATUS, t.EDITDATE, st.VAT, t.loc, t.loc1, t.DOOR, t.LOTTABLE03, t.PUTAWAYZONE, t.ordergroup, t.ID, t.susr4, t.susr, t.susr5
into #result
from #temp t
join WH40.STORER st on st.STORERKEY = t.CONSIGNEEKEY

select * from #result

drop table #temp
drop table #result

