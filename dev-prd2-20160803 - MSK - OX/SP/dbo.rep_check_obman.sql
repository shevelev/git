ALTER PROCEDURE [dbo].[rep_check_obman] (
    @ds datetime, -- начальная дата
    @de datetime, -- конечная дата
    @vr int -- выбор обмана. 1=отказы в отборах 2=количество перемещний с паллетного склада. 3=количество перемещений с приемки
)
as
begin

create table #result (
data datetime, --дата общая
username varchar(80), --фио общее
caseid varchar(20), --только для 1 отчета
area varchar(20), --только для 1 отчета
real int, -- 2,3 отчеты
fact int )-- 2,3 отчеты

set @de=DATEADD(day, 1, @de)

if @vr = '1'
	begin
		insert into #result (caseid, username, data, area)
		select cc.caseid, usr.usr_lname+' '+usr.usr_fname, cc.dateadd, cc.area from wh1.caselog cc
			join (select caseid from wh1.caselog
				where dateadd between @ds and @de and caseid !='' --and area='COMPLBAD'
				group by caseid
				having COUNT(caseid)>1 ) c on cc.caseid=c.caseid
			join wh1.PICKDETAIL pd on pd.CASEID=c.caseid
			join ssaadmin.pl_usr usr on cc.userkey=usr.usr_login
				group by cc.caseid, usr.usr_lname+' '+usr.usr_fname,cc.dateadd, cc.area, pd.LOC
				order by 1,3	
	end
	
else if  @vr = '2'
	begin
		insert into #result (username, data, real,fact)
		select usr.usr_lname+' '+usr.usr_fname, c.date, COUNT(c.sku), p.c from (
			select ADDWHO,convert(date,adddate,101) date, SKU, LOT, FROMLOC, FROMID, TOLOC,sum(qty) q
			from wh1.itrn
			where FROMLOC like 'P___._.__' and TRANTYPE='mv'
			and ADDDATE between @ds and @de
			group by ADDWHO,convert(date,adddate,101),SKU, LOT, FROMLOC, FROMID, TOLOC) c
			join (select ADDWHO,convert(date,adddate,101) date, COUNT(*) c
					from wh1.itrn
					where FROMLOC like 'P___._.__' and TRANTYPE='mv' and ADDDATE between @ds and @de
					group by ADDWHO,convert(date,adddate,101)) p on p.ADDWHO=c.ADDWHO and p.date=c.date
			join ssaadmin.pl_usr usr on c.ADDWHO=usr.usr_login
			group by usr.usr_lname+' '+usr.usr_fname, c.date, p.c
			having COUNT(c.sku) <> p.c
			order by 1,2	
	end
	
else if  @vr = '3'
	begin
		insert into #result (username, data, real,fact)
		select usr.usr_lname+' '+usr.usr_fname, c.date, COUNT(c.sku), p.c from (
			select ADDWHO,convert(date,adddate,101) date, SKU, LOT, FROMLOC, FROMID, TOLOC,sum(qty) q
			from wh1.itrn
			where FROMLOC like 'PRIEM%' and TRANTYPE='mv'
			and ADDDATE between @ds and @de
			group by ADDWHO,convert(date,adddate,101),SKU, LOT, FROMLOC, FROMID, TOLOC) c
			join (select ADDWHO,convert(date,adddate,101) date, COUNT(*) c
					from wh1.itrn
					where FROMLOC like 'PRIEM%' and TRANTYPE='mv' and ADDDATE between @ds and @de
					group by ADDWHO,convert(date,adddate,101)) p on p.ADDWHO=c.ADDWHO and p.date=c.date
			join ssaadmin.pl_usr usr on c.ADDWHO=usr.usr_login
			group by usr.usr_lname+' '+usr.usr_fname, c.date, p.c
			having COUNT(c.sku) <> p.c
			order by 1,2	
	end
	
	
	select * from #result
	
end

/*
exec dbo.rep_check_obman '20120701','20120731',2
*/

 

