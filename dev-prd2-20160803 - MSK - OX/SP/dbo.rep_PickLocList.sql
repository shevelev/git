-- ÑÏÐÀÂÎ×ÍÈÊ ÒÎÂÀÐÎÂ --

ALTER PROCEDURE [dbo].[rep_PickLocList]
	@storerkey as varchar(15)='',
	@sku as varchar(60)='',
	@loc as varchar(10)='',
	@section as varchar(1)=''
as  


select sxl.loc, st.company, sxl.sku, s.descr, sxl.qtylocationminimum, sxl.qtylocationlimit
from wh1.skuxloc sxl
join wh1.sku s on (sxl.storerkey=s.storerkey and sxl.sku=s.sku)
join wh1.loc l on (sxl.loc=l.loc)
join wh1.storer st on (sxl.storerkey=st.storerkey)
where 
(sxl.qtylocationminimum>0 and sxl.qtylocationlimit>0 and sxl.allowreplenishfromcasepick=1)
AND
(sxl.loc like '[1-9]___.[0-9].[0-9]')
AND
(l.locationtype='PICK')
AND
(isnull(@section,'')='' or sxl.loc like '[0-9]'+@section+'__.[0-9].[0-9]')
AND
(isnull(@storerkey,'')='' or sxl.storerkey=@storerkey)
AND
(isnull(@sku,'')='' or sxl.sku=@sku)
AND
(isnull(@loc,'')='' or sxl.loc=@loc)
order by sxl.loc, sxl.storerkey, s.descr

