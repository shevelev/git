ALTER PROCEDURE [dbo].[rep41_TimeInWarmZone](
	@wh varchar(10), @dt1 smalldatetime, @dt2 smalldatetime,
	@id varchar(10), @sku varchar(10), @skuName varchar(45), @whoAdd varchar(50), @whomoveout varchar(50)
)as 
--declare @wh varchar(10), @dt1 smalldatetime, @dt2 smalldatetime,
--	@id varchar(10), @sku varchar(10), @skuName varchar(45), @whoAdd varchar(50), @whomoveout varchar(50)
--select @wh='wh40', @dt1 = '20080701'--, @dt2 = '20080704'

declare @sql varchar(max)

set @dt2 = dateadd(d,1,@dt2)
	-- €чейки зоны теплого отстойника
	select loc into #locs from wh40.loc where 1=2
	set @sql = 'insert into #locs select loc from '+@wh+'.loc where putawayzone like ''BARABAN7'''
	exec(@sql)
	
	-- перемещени€ в €чейку
	create table #toLoc (
		tm int,
		serialkey int,
		adddate datetime,
		fromID varchar(30)  collate Cyrillic_General_CI_AS,
		addwho varchar(30) collate Cyrillic_General_CI_AS,
		sku varchar(30) collate Cyrillic_General_CI_AS,
		storerkey varchar(30) collate Cyrillic_General_CI_AS,
		fromloc varchar(30) collate Cyrillic_General_CI_AS,
		toloc varchar(30) collate Cyrillic_General_CI_AS,
		toID varchar(30) collate Cyrillic_General_CI_AS)

--	select datediff(mi,adddate,getdate())tm, * into #toLoc 
--	from wh40.itrn where 1=2
	set @sql = 'insert into #toLoc select datediff(mi,adddate,getdate())tm,
		serialkey, adddate, fromID, addwho, sku, storerkey, 
				fromloc, toloc, toid 
	from '+@wh+'.itrn where toloc in (select loc from #locs) and trantype = ''MV'''
	exec (@sql)

	-- перемещени€ из €чейки
	create table #fromLoc (
		serialkey int,
		adddate datetime,
		fromID varchar(30) collate Cyrillic_General_CI_AS,
		addwho varchar(30) collate Cyrillic_General_CI_AS,
		sku varchar(30) collate Cyrillic_General_CI_AS,
		storerkey varchar(30) collate Cyrillic_General_CI_AS,
		fromloc varchar(30) collate Cyrillic_General_CI_AS,
		toloc varchar(30) collate Cyrillic_General_CI_AS,
		toID varchar(30) collate Cyrillic_General_CI_AS)
	
--	select serialkey, adddate, fromID, addwho, sku, storerkey, fromloc, toloc, toid
--	into #fromLoc from wh40.itrn where 1=2
	
	set @sql = 'insert into #fromLoc select serialkey, adddate, fromID, addwho, sku, storerkey, 
				fromloc, toloc, toid
			from '+@wh+'.itrn where fromloc in (select loc from #locs) and toloc in (select loc from #locs) 
		and trantype = ''MV''
		and fromID != '''''
	exec(@sql)
	
	select min( fl.serialkey)sk, fl.fromid, fl.sku, fl.storerkey, min(fl.adddate )dt
	into #tmp
	from #fromLoc fl
		join #toloc tl on tl.toID=fl.fromID and tl.adddate < fl.adddate 
			and tl.sku=fl.sku and tl.storerkey=fl.storerkey and fl.fromloc=tl.toloc
	group by fl.fromid, fl.sku, fl.storerkey
	
	
--	select * from #toloc
	
	select tl.adddate, tl.addwho, tm, tl.toid, tl.sku, tl.storerkey, fl.adddate outdate, fl.addwho outwho 
	into #res
	from #toloc tl
		left join ( select fl.* from #fromLoc fl 
		 join #tmp t on fl.serialkey = t.sk) fl on tl.sku=fl.sku and tl.storerkey=fl.storerkey 
			and tl.toID=fl.fromID  and fl.fromloc=tl.toloc and tl.adddate < fl.adddate 
	order by tl.sku, tl.toid
	
	select r.*,s.descr skuName, u1.usr_name inName, u2.usr_name outName,
		cast(floor(tm/60) as varchar(10))hh, cast((tm-floor(tm/60)*60)as varchar(2)) mm
	from #res r
		join wh40.sku s on s.sku=r.sku and s.storerkey = r.storerkey
		left join ssaadmin.pl_usr u1 on u1.usr_login = r.addwho
		left join ssaadmin.pl_usr u2 on u2.usr_login = r.outwho
	where 1=1
		and (@dt1 is null or (r.adddate >= @dt1 or outdate >= @dt1))
		and (@dt2 is null or (r.adddate < @dt2 or outdate < @dt2))
		and (isnull(@id,'')='' or toid = @id)
		and (isnull(@sku,'')='' or r.sku = @sku)
		and (isnull(@skuName,'')='' or s.descr like @skuName)
		and (isnull(@whoAdd,'')='' or u1.usr_name like @whoAdd)
		and (isnull(@whomoveout,'')='' or u2.usr_name like @whomoveout)
		
		
--	@dt1 smalldatetime, @dt2 smalldatetime,
--	@id varchar(10), @sku varchar(10), @skuName varchar(45), @whoAdd varchar(50), @whomoveout varchar(50)
	
drop table #tmp
drop table #res
drop table #toLoc
drop table #fromLoc
drop table #locs

