ALTER PROCEDURE [rep].[Move_with_pl] (
    @ds datetime, -- ��������� ����
    @de datetime -- �������� ����
)
as
begin


set @ds = dbo.udf_get_date_from_datetime(isnull(@ds,getdate()))
set @de = dbo.udf_get_date_from_datetime(isnull(@de,getdate()))
set @de = @de + convert(time,'23:59:59.997')
		
		select usr.usr_lname+' '+usr.usr_fname username, c.date data, COUNT(c.sku) real, p.c fact from (
			select ADDWHO,convert(date,adddate,101) date, SKU, LOT, FROMLOC, FROMID, TOLOC,sum(qty) q
			from wh1.itrn
			where FROMLOC like 'P___._.__'  and SOURCETYPE!='PICKING'
			and ADDDATE between @ds and @de
			group by ADDWHO,convert(date,adddate,101),SKU, LOT, FROMLOC, FROMID, TOLOC) c
			join (select ADDWHO,convert(date,adddate,101) date, COUNT(*) c
					from wh1.itrn
					where FROMLOC like 'P___._.__'  and SOURCETYPE!='PICKING'
					and ADDDATE between @ds and @de
					group by ADDWHO,convert(date,adddate,101)) p on p.ADDWHO=c.ADDWHO and p.date=c.date
			join ssaadmin.pl_usr usr on c.ADDWHO=usr.usr_login
			group by usr.usr_lname+' '+usr.usr_fname, c.date, p.c
			having COUNT(c.sku) <> p.c
			
	
end

/*
exec dbo.rep_check_obman_pl '20120801','20120830'
*/







 
	
