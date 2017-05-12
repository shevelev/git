ALTER PROCEDURE [dbo].[Up_pick1] 
	@orderkey varchar (15), -- номер заказа
    @wh varchar(30)
AS


declare 
	@sql varchar(max),
	@volume decimal(22,5),
    @o int


set nocount on

create table #f
(f varchar(15))

create table #v
(v decimal(22,5))

create table #caseid
(caseid varchar(20),
 CARTONGROUP varchar(10),
 scube decimal(22,5),
 checked int,
 loctype varchar(10) )

set @sql='insert into #v (v) SELECT c.cube from '+@wh+'.CARTONIZATION c where CARTONIZATIONGROUP=''PALLET'''
exec(@sql)

select @volume=v from #v
select @volume=isnull(@volume,1.5)
 

Set @sql='insert into #f (f) select distinct orderkey from '+@wh+'.pickdetail where STATUS>=''5'' and orderkey='''+@orderkey+''''
exec(@sql)

set @o=0
select @o=count(*) from #f


if @o=0
begin
    set @sql=
     ' insert into #caseid (caseid,CARTONGROUP,scube,checked, loctype) '
      +'(Select 
           distinct p.CASEID as caseid, p.CARTONGROUP as CARTONGROUP, sum(s.STDCUBE*p.QTY),0, 
           case when l.LOCATIONTYPE=''CASE'' or l.LOCATIONTYPE=''PICK'' then ''uni'' 
                when l.LOCATIONTYPE=''OTHER'' then ''OTHER'' end as loctype
       from '
        +@wh+'.pickdetail p join '
        +@wh+'.orderdetail i on p.orderkey = i.orderkey and p.orderlinenumber = i.orderlinenumber join '
        +@wh+'.sku s on i.sku=s.sku join '
        +@wh+'.StrategyxSKU st  on st.skugroup=s.skugroup and st.skugroup2=s.skugroup2 and st.abc=s.abc and '
        +' st.layer=''1'' and  st.volumegroup=''1'' and st.packheightgroup=''1''  join '
        +@wh+'.loc l on p.loc=l.loc join '
        +' (select  CARTONGROUP, typeLoc   from 
		(Select 
		   distinct count(p.caseid) as caseid, p.CARTONGROUP as CARTONGROUP, 
           case when l.LOCATIONTYPE=''CASE'' or l.LOCATIONTYPE=''PICK'' then ''uni'' 
                when l.LOCATIONTYPE=''OTHER'' then ''OTHER'' end as typeLoc 
		from '
		+@wh+'.pickdetail p join '
		+@wh+'.orderdetail i on p.orderkey = i.orderkey and p.orderlinenumber = i.orderlinenumber join '
		+@wh+'.sku s on i.sku=s.sku join '
		+@wh+'.StrategyxSKU st on st.skugroup=s.skugroup and st.skugroup2=s.skugroup2 and st.abc=s.abc and '
        +' st.layer=''1'' and  st.volumegroup=''1'' and st.packheightgroup=''1'' join '
        +@wh+'.loc l on p.loc=l.loc '
		+'where '
		+'  st.packtype=''N'' and '
		+'  p.CARTONTYPE is null and '
        +'  l.LOCATIONTYPE in (''CASE'',''PICK'',''OTHER'') and '
		+'  i.orderkey ='''+@orderkey+'''' 
		+' group by p.CARTONGROUP,
                   case when l.LOCATIONTYPE=''CASE'' or l.LOCATIONTYPE=''PICK'' then ''uni'' 
                        when l.LOCATIONTYPE=''OTHER'' then ''OTHER'' end '
		+'having count(p.caseid)>1 ) s ) '
		+'g on g.CARTONGROUP=p.CARTONGROUP and g.typeloc=(case when l.LOCATIONTYPE=''CASE'' or l.LOCATIONTYPE=''PICK'' then ''uni'' 
                when l.LOCATIONTYPE=''OTHER'' then ''OTHER'' end) '
        +'where '
        +'  st.packtype=''N'' and '
        +'  p.CARTONTYPE is null and '
        +'  l.LOCATIONTYPE in (''CASE'',''PICK'',''OTHER'') and '
        +'  i.orderkey ='''+@orderkey+'''' 
        +'  group by p.CASEID,p.CARTONGROUP, 
                     case when l.LOCATIONTYPE=''CASE'' or l.LOCATIONTYPE=''PICK'' then ''uni'' 
                     when l.LOCATIONTYPE=''OTHER'' then ''OTHER'' end '
        +'  having sum(s.STDCUBE*p.QTY)< '+convert(varchar(100),@volume) + ') '

     exec(@sql)

-- обработка коробок по группам       
     SET @SQL=
       'declare 
          @CASEID varchar(20), 
		  @UnionCaseId varchar(20),
          @CARTONGROUP varchar(10),
          @CARTONGROUP_Pre varchar(10),
          @CUBE decimal(22,5),
		  @UnionCube decimal(22,5),
		  @RemCube decimal(22,5),
          @checked int,
          @EndRep int,
		  @EndWhile int,
          @loctype varchar(10)
		  
      set @EndRep=0
      While @EndRep=0 
		begin
		  set @caseid=null
		  select top 1 @caseid=caseid, @cartongroup=CARTONGROUP, @cube=scube, @loctype=loctype
		  from #caseid
		  where checked=0
			order by scube desc '
		  
		+ ' if @caseid is not null 
			begin'
		+ '  update #caseid set checked=1 where caseid=@caseid and @cartongroup=CARTONGROUP and @loctype=loctype '
		+ '  select @RemCube= '+convert(varchar(100),@volume)+ ' -@cube'
		+ '  set @EndWhile=0'
		+ '  while @RemCube>0 and @EndWhile=0 '
		+ '  begin '
		+ '    set @UnionCaseId=null'
		+ '    select top 1 @UnionCaseId=caseid, @UnionCube=scube
			   from #caseid 
			   where CARTONGROUP = @cartongroup and scube<=@RemCube and caseid<>@caseid and checked=0 and @loctype=loctype
			   order by scube desc
			   if @UnionCaseId is not null
		       begin
			     set @RemCube=@RemCube-@UnionCube
			     update #caseid set checked=1 where caseid=@UnionCaseId and CARTONGROUP = @cartongroup and @loctype=loctype	'
        + '      update t set t.caseid=@caseid '
        + '      from '+@wh+'.pickdetail p join '
                       +@wh+'.taskdetail t on t.sourcekey = p.pickdetailkey '
        +'       where p.caseid=@UnionCaseId and p.orderkey='''+@orderkey +''''
--        +'      insert into '+@wh+'.ORDERSTATUSHISTORY '
--        +'       (WHSEID,ORDERKEY,ORDERTYPE,ADDDATE,COMMENTS,ORDERLINENUMBER,STATUS,ADDWHO) ' 
--        +'       select '''+@wh+''','''+@orderkey+''',''SO'',getdate(),''sku=''+p.sku+''_qty qty=''+convert(varchar(10),p.qty)+''_caseid ''+@UnionCaseId+''>''+@caseid,''nul'',''nul'',p.ADDWHO'
--        +'       from '+@wh+'.pickdetail p where caseid=@UnionCaseId and orderkey='''+@orderkey +''''
        +'       select '''+@wh+''' WHSEID,'''+@orderkey+''' ORDERKEY,''SO'' ORDERTYPE,'
		+'			getdate() ADDDATE,'
		+'			''sku=''+p.sku+''_qty qty=''+convert(varchar(10),p.qty)+''_caseid ''+@UnionCaseId+''>''+@caseid COMMENTS,''nul'' ORDERLINENUMBER,''nul'' STATUS,p.ADDWHO ADDWHO'
        +'       into #tempOSHistory'
        +'       from '+@wh+'.pickdetail p where caseid=@UnionCaseId and orderkey='''+@orderkey +''''
        +'      insert into '+@wh+'.ORDERSTATUSHISTORY '
        +'       (WHSEID,ORDERKEY,ORDERTYPE,ADDDATE,COMMENTS,ORDERLINENUMBER,STATUS,ADDWHO) ' 
        +'       select * '
        +'       from #tempOSHistory '
        +'       drop table #tempOSHistory '
--
		+ '	     update '+@wh+'.pickdetail set caseid=@caseid where caseid=@UnionCaseId and orderkey='''+@orderkey +''''
		+ '    end'
		+ '    else set @EndWhile=1 '
		+ '  end'
		+'  end '
		+'else set @EndRep=1 '
      +'END '

--print @sql
exec (@sql)


-- обновление поля, отображаемого на экране терминала, с количеством коробок и штук дл отбора. 
set @sql=
--'update t set t.message03 = 
--left (
--case when s.susr2 is null then '''' else left(s.susr2,4) + '':'' end +
--case when floor(p.qty / pc.casecnt) = 0 then '''' else convert(varchar(18),floor(p.qty / pc.casecnt)) + ''к. '' end
--+ 
--case when p.qty - floor(p.qty / pc.casecnt) * pc.casecnt = 0 then '''' else convert(varchar(10), p.qty - floor(p.qty / pc.casecnt) * pc.casecnt) + ''шт.'' end
--, 20)
--from '
--+@wh+'.pickdetail p join '
--+@wh+'.orderdetail i on p.orderkey = i.orderkey and p.orderlinenumber = i.orderlinenumber join ' 
--+@wh+'.taskdetail t on t.sourcekey = p.pickdetailkey join '
--+@wh+'.pack pc on pc.packkey = i.packkey join '
--+@wh+'.orders o on o.orderkey = i.orderkey left join '
--+@wh+'.storer s on s.storerkey = o.b_company '
--+'where i.orderkey ='''+ @orderkey +''''
'select t.taskdetailkey, 
left (
case when s.susr3 is null then '''' else left(s.susr2,4) + '':'' end +
case when floor(p.qty / pc.casecnt) = 0 then '''' else convert(varchar(18),floor(p.qty / pc.casecnt)) + ''к. '' end
+ 
case when p.qty - floor(p.qty / pc.casecnt) * pc.casecnt = 0 then '''' else convert(varchar(10), p.qty - floor(p.qty / pc.casecnt) * pc.casecnt) + ''шт.'' end
, 20) msg3
into #tempMSG3
from '
+@wh+'.pickdetail p join '
+@wh+'.taskdetail t on p.pickdetailkey = t.sourcekey join '
+@wh+'.orderdetail i on (p.orderkey = i.orderkey and p.orderlinenumber = i.orderlinenumber) join ' 
+@wh+'.pack pc on i.packkey = pc.packkey join '
+@wh+'.orders o on i.orderkey = o.orderkey left join '
+@wh+'.storer s on o.b_company = s.storerkey '
+ 'where i.orderkey ='''+ @orderkey +''''
+ ' update t set t.message03 = #tempMSG3.msg3'
+ ' from #tempMSG3 left join '+@wh+'.taskdetail t on #tempMSG3.taskdetailkey = t.taskdetailkey '
+ 'drop table #tempMSG3'
exec(@sql) 
end

