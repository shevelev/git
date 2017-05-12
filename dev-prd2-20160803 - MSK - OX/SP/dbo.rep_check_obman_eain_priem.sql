ALTER PROCEDURE [dbo].[rep_check_obman_eain_priem] (
    @ds datetime, -- начальная дата
    @de datetime -- конечная дата
)
as
begin

set @ds = dbo.udf_get_date_from_datetime(isnull(@ds,getdate()))
set @de = dbo.udf_get_date_from_datetime(isnull(@de,getdate()))
set @de = @de + convert(time,'23:59:59.997')
		
select i.ADDWHO, i.ADDDATE, i.SKU, i.LOT, i.FROMLOC, i.FROMID, i.TOLOC, i.QTY
into #result
from wh1.ITRN i
	join wh1.LOC l on l.LOC=i.toloc
where i.ADDDATE between @ds and @de and i.FROMLOC in ('EA_IN','PRIEM_EA') and l.LOCATIONTYPE='PICK' and i.TRANTYPE='mv'
		
		
select usr.usr_lname+' '+usr.usr_fname username, c.date data, COUNT(c.sku) real, p.c fact 
		
	from	(	select ADDWHO,convert(date,adddate,101) date, SKU, LOT, FROMLOC, FROMID, TOLOC,sum(qty) q
				from #result
				group by ADDWHO,convert(date,adddate,101),SKU, LOT, FROMLOC, FROMID, TOLOC
			) c

	join	(	select ADDWHO,convert(date,adddate,101) date, COUNT(*) c
				from #result
				group by ADDWHO,convert(date,adddate,101)
			) p	on p.ADDWHO=c.ADDWHO and p.date=c.date

	join ssaadmin.pl_usr usr on c.ADDWHO=usr.usr_login

	group by usr.usr_lname+' '+usr.usr_fname, c.date, p.c
	having COUNT(c.sku) <> p.c


drop table #result	
end

/*
exec dbo.rep_check_obman_eain_priem '20120901','20120930','priem_ea'
*/

 						
