




ALTER PROCEDURE [rep].[PackListCaseID1] (
/* 06 ”паковочный лист на €щик */
	@wh varchar(30),
	@order varchar(10),
	@caseid varchar(20)=null
)
--with encryption
as


----------select --pd.CARTONTYPE, 
------------distinct
----------pd.id, 
----------o.adddate, 
----------pd.loc, 
----------pd.lot,
----------s.descr,
----------ck.description, 
----------o.deliverydate, 
----------o.door, 
----------o.externorderkey, 
----------sts.company company_storer, 
----------o.CONSIGNEEKEY, 
------------o.DeliveryAdr,
----------o.orderkey,
----------o.susr4,
----------st.company company_consign,
----------st.vat clientINN,
----------st.storerkey,


---------- pd.caseid, 

----------isnull(c.CARTONDESCRIPTION,'') CARTONDESCRIPTION,
----------cast(case when (pd.id <> '') then 'ѕаллета' else 'ящик' end as varchar(15)) CaseDescr,
---------- dbo.getean128(pd.caseid) caseid1, 
----------pd.sku, 
---------- dbo.getean128(pd.sku) bcsku, 
----------sum(pd.qty),
----------sum(p.casecnt) cs, 
----------sum(case when p.casecnt = 0 then 0 else floor(pd.qty/p.casecnt) end) casecnt,
----------sum(pd.qty - case when p.casecnt = 0 then 0 else floor (pd.qty/p.casecnt)*p.casecnt end) uomcnt,
----------l.logicallocation, o.ROUTE

----------from wh1.orders o join wh1.pickdetail pd on o.orderkey = pd.orderkey
----------join wh1.sku s on pd.sku = s.sku and pd.storerkey = s.storerkey
----------join wh1.pack p on p.packkey = s.packkey
----------left join wh1.storer st on st.storerkey = o.CONSIGNEEKEY
----------join wh1.storer sts on sts.storerkey = o.storerkey
----------join wh1.codelkup ck on ck.code = p.packuom3 and ck.listname = 'PACKAGE'
----------join wh1.loc l on l.loc = pd.loc
----------left join wh1.cartonization c on c.cartontype = pd.CARTONTYPE
----------where pd.status in ('5','6', '7' ,'8') and 
----------(pd.orderkey like case when @order != '' then @order else '%' end
----------and pd.caseid like case when @caseid != '' then @caseid else '%' end)
----------group by pd.id, 
----------o.adddate, 
----------pd.loc, 
----------pd.lot,
----------s.descr,
----------ck.description, 
----------o.deliverydate, 
----------o.door, 
----------o.externorderkey, 
----------sts.company, 
----------o.CONSIGNEEKEY, 
------------o.DeliveryAdr,
----------o.orderkey,
----------o.susr4,
----------st.company,
----------st.vat,
----------st.storerkey,
----------pd.caseid, 
----------isnull(c.CARTONDESCRIPTION,''),
----------pd.id,
----------pd.caseid, 
----------pd.sku, 
----------pd.sku, 
----------p.casecnt, 
----------l.logicallocation, o.ROUTE
----------order by l.logicallocation




select 
st.company c1,
SUM(pd.qty), 'шт' uom, s.DESCR, pd.sku, pd.ORDERKEY, pd.caseid, p.casecnt, stc.company c2, o.route,o.externorderkey, o.door, la.LOTTABLE02, '' logicallocation

from wh1.PICKDETAIL pd join wh1.SKU s on pd.SKU = s.sku
join wh1.Storer st on pd.Storerkey = st.storerkey
join wh1.PACK p on p.PACKKEY = s.packkey
join wh1.ORDERS o on o.ORDERKEY = pd.orderkey and o.STORERKEY=pd.STORERKEY
join wh1.Storer stc on o.CONSIGNEEKEY = stc.storerkey
join wh1.lotattribute la on pd.LOT = la.lot and pd.STORERKEY=la.STORERKEY
where pd.status in ('5','6', '7' ,'8') and 
(pd.orderkey like case when @order != '' then @order else '%' end
and pd.caseid like case when @caseid != '' then @caseid else '%' end)
group by s.descr, pd.sku, st.company, pd.ORDERKEY,pd.caseid, p.casecnt, o.CONSIGNEEKEY, stc.company, o.route, o.externorderkey, o.door,  la.LOTTABLE02
