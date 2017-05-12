-- Cписок свободного остатка товаров в чужих ячейках отбора
-- Проект: НОВЭКС, Барнаул, 05/11/2009, Смехнов Антон,

ALTER PROCEDURE [dbo].[rep_MoveForeingSKU]
	@VolumeLimit as float=0.03,
	@section as varchar=''
as  

select loc, storerkey, sku, qty, qtylocationminimum, qtylocationlimit,allowreplenishfromcasepick into #SXL from wh1.skuxloc
select loc, storerkey, sku, lot, qty, qtypicked, qtyallocated into #LLD from wh1.lotxlocxid

select sxl.loc FromLoc, st.company, sxl.sku, lld.lot, (lld.qty-lld.qtypicked-lld.qtyallocated) QTY,  sxl2.loc ToLoc, s.descr,  s.stdcube*(lld.qty-lld.qtypicked-lld.qtyallocated) Volume
from #SXL sxl
join #SXL sxl2 on (sxl.storerkey=sxl2.storerkey and sxl.sku=sxl2.sku)						--где товар должен лежать
join #LLD lld on (sxl.loc=lld.loc and sxl.storerkey=lld.storerkey and sxl.sku=lld.sku)	--остаток по текущей ячейке
join wh1.sku s on (sxl.storerkey=s.storerkey and sxl.sku=s.sku)
join wh1.loc l on (sxl.loc=l.loc)
join wh1.storer st on (sxl.storerkey=st.storerkey)
where 
(sxl.qtylocationminimum=0 or sxl.qtylocationlimit=0 or sxl.allowreplenishfromcasepick=0)
AND
(lld.qty>0)
AND
(sxl2.qtylocationminimum>0 and sxl2.qtylocationlimit>0 and sxl2.allowreplenishfromcasepick=1)
AND
(sxl.loc like '[1-9]___.[1-9].[1-9]')
AND
(l.locationtype='PICK')
AND
(sxl.storerkey<>'000000001')
AND
s.stdcube*(lld.qty-lld.qtypicked-lld.qtyallocated)>@VolumeLimit
AND
(isnull(@section,'')='' or sxl.loc like '[1-9]'+@section+'__.[1-9].[1-9]')
order by sxl.loc, sxl.storerkey, sxl.sku

