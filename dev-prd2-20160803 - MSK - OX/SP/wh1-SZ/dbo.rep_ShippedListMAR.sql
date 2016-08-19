/****** Object:  StoredProcedure [dbo].[rep_ShippedListMAR]    Script Date: 03/24/2011 15:14:50 ******/
ALTER PROCEDURE [dbo].[rep_ShippedListMAR] (
	@mar varchar(12)
)
AS



select  count(distinct pd.caseid)caseCount,pd.caseid, oss.DESCRIPTION ,lh.door, lod.SHIPMENTORDERID,pd.DROPID, st.company,ord.EXTERNORDERKEY,lh.DEPARTURETIME, lh.ROUTE, dr.droploc
from wh1.loadhdr lh
join wh1.loadstop ls on lh.LOADID=ls.LOADID
join wh1.LOADORDERDETAIL lod on ls.LOADSTOPID=lod.LOADSTOPID
left join wh1.pickdetail pd on pd.ORDERKEY=lod.SHIPMENTORDERID
left join wh1.DROPID dr on dr.DROPID=pd.dropid
join WH1.STORER AS st ON lod.CUSTOMER = st.STORERKEY
left join wh1.ORDERS ord on ord.ORDERKEY=lod.SHIPMENTORDERID
join wh1.ORDERSTATUSSETUP oss on ord.STATUS=oss.code
where lh.ROUTE=@mar and lh.STATUS!='9' and ord.status!='95'--and ord.status in ('52','53','55','57','61','68','88')

group by   pd.caseid,oss.DESCRIPTION , lh.door, lod.SHIPMENTORDERID,pd.DROPID,st.company,ord.EXTERNORDERKEY,lh.DEPARTURETIME, lh.ROUTE, dr.droploc



