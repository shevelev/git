ALTER PROCEDURE [dbo].[rep53_PLNZO] (
	/*   Погрузочный лист (поручение экспедитору) */
	@nzo varchar(15)
)AS


SELECT     ls.STOP, lod.SHIPMENTORDERID, lod.TRANSSHIPCONTAINERID, lod.OUTUNITS, lod.OUTUNITCUBE, lod.OUTUNITWEIGHT, lod.EXTERNALSHIPMENTID, 
                      lod.EXTERNALORDERID, lod.TOTALCOST, lod.TOTALVALUE, lod.OHTYPE, lod.FLOWORDERID, lod.CASEID, lod.TRANSASNKEY, lod.ADDDATE, lod.ADDWHO, 
                      lod.EDITDATE, lod.EDITWHO, lod.WHSEID, st.COMPANY, st2.COMPANY AS Expr1, lh.loadid, pd.dropid, dbo.getean128(lh.loadid) bcLOADID, lh.ROUTE, lh.DOOR, ck.DESCRIPTION ckdesc, 
                      lh.DEPARTURETIME, lh.CARRIERID, lh.TRAILERID, lh.TOTALCUBE, lh.TOTALWEIGHT, lh.TOTALUNITS, lh.EXTERNALID, st2.ADDRESS1
into #test1
FROM         WH1.LOADSTOP AS ls INNER JOIN
                      WH1.LOADORDERDETAIL AS lod ON ls.LOADSTOPID = lod.LOADSTOPID INNER JOIN
                      WH1.STORER AS st ON lod.STORER = st.STORERKEY INNER JOIN
                      WH1.STORER AS st2 ON lod.CUSTOMER = st2.STORERKEY INNER JOIN
                      WH1.LOADHDR lh ON ls.LOADID = lh.LOADID INNER JOIN
                      WH1.CODELKUP ck ON lh.STATUS = ck.CODE and ck.LISTNAME = 'loadstatus'
                      join wh1.pickdetail pd on pd.ORDERKEY=lod.SHIPMENTORDERID
WHERE     (ls.LOADID = @nzo) 

select sum(s.STDGROSSWGT*od.SHIPPEDQTY) ves, sum(s.STDCUBE*od.SHIPPEDQTY) obem, od.orderkey
into #test2
from wh1.orderdetail od
left join wh1.SKU s on s.SKU = od.sku
where ORDERKEY in (select o.orderkey from wh1.ORDERS o where o.LOADID=@nzo)
group by  od.orderkey

select * from #test1 t1
join #test2 t2 on t1.SHIPMENTORDERID=t2.ORDERKEY

drop table #test1
drop table #test2


