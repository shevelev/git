ALTER PROCEDURE [dbo].[rep_check_summa_eain_priem] (
    @ds datetime, -- начальная дата
    @de datetime -- конечная дата
)
as
begin

set @ds = dbo.udf_get_date_from_datetime(isnull(@ds,getdate()))
set @de = dbo.udf_get_date_from_datetime(isnull(@de,getdate()))
set @de = @de + convert(time,'23:59:59.997')
		
select usr.usr_lname+' '+usr.usr_fname username, convert(date,i.adddate,101) date, i.SKU, s.NOTES1,i.FROMLOC, i.TOLOC, i.QTY, i.lot
from wh1.ITRN i
	join wh1.LOC l on l.LOC=i.toloc
	join ssaadmin.pl_usr usr on i.ADDWHO=usr.usr_login
	join wh1.SKU s on s.SKU=i.sku
where i.ADDDATE between @ds and @de  and i.FROMLOC in ('EA_IN','PRIEM_EA') and l.LOCATIONTYPE='PICK' and i.TRANTYPE='mv'



end

/*
exec dbo.rep_check_summa_eain_priem '20120901','20120930'
*/

 						
