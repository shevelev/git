




ALTER PROCEDURE [rep].[mof_PackListCaseID1] (
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

----------from wh2.orders o join wh2.pickdetail pd on o.orderkey = pd.orderkey
----------join wh2.sku s on pd.sku = s.sku and pd.storerkey = s.storerkey
----------join wh2.pack p on p.packkey = s.packkey
----------left join wh2.storer st on st.storerkey = o.CONSIGNEEKEY
----------join wh2.storer sts on sts.storerkey = o.storerkey
----------join wh2.codelkup ck on ck.code = p.packuom3 and ck.listname = 'PACKAGE'
----------join wh2.loc l on l.loc = pd.loc
----------left join wh2.cartonization c on c.cartontype = pd.CARTONTYPE
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

from wh2.PICKDETAIL pd join wh2.SKU s on pd.SKU = s.sku
join wh2.Storer st on pd.Storerkey = st.storerkey
join wh2.PACK p on p.PACKKEY = s.packkey
join wh2.ORDERS o on o.ORDERKEY = pd.orderkey
join wh2.Storer stc on o.CONSIGNEEKEY = stc.storerkey
join wh2.lotattribute la on pd.LOT = la.lot
where pd.status in ('5','6', '7' ,'8') and 
(pd.orderkey like case when @order != '' then @order else '%' end
and pd.caseid like case when @caseid != '' then @caseid else '%' end)
group by s.descr, pd.sku, st.company, pd.ORDERKEY,pd.caseid, p.casecnt, o.CONSIGNEEKEY, stc.company, o.route, o.externorderkey, o.door,  la.LOTTABLE02

