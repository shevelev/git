

ALTER PROCEDURE [rep].[A_Otgruzka] (
    @ord varchar(10)
)
as
begin

declare @caseid varchar(12), @caseid2 varchar(12), @dropid varchar(12)
declare @maxlevels int, @iLevel int -- счетчик уровней
set @maxLevels = 10

create table #rez (caseid varchar(12), childid varchar(12),dropid varchar(12), addwho varchar(20), adddate datetime)

select distinct pd.CASEID, pd.dropid into #orders from wh1.PICKDETAIL pd where ORDERKEY=@ord

while exists(select top 1 * from #orders)
	begin
		set @iLevel=1
	
		select @caseid=caseid from #orders
		insert into #rez
		select @caseid, childid, dropid,  addwho, adddate  from wh1.DROPIDDETAIL where CHILDID=@caseid

			while @iLevel <= @maxLevels
				begin
	print @ilevel
	select  @caseid2=dropid, @dropid=childid from #rez 
		insert into #rez
	select @caseid, childid, dropid, addwho, adddate from wh1.DROPIDDETAIL where CHILDID=@caseid2 and dropid!=@dropid
	set @iLevel=@iLevel+1
	
				end

delete #orders where CASEID=@caseid
	end

select r.caseid, r.childid, r.dropid, u.usr_lname+' '+u.usr_fname addwho,r.adddate 
from #rez r
	join ssaadmin.pl_usr u on u.usr_login=r.addwho
drop table #orders
drop table #rez

end 
/*
exec rep_A_Otgruzka 0000233662
*/

 

