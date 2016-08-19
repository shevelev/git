ALTER PROCEDURE [dbo].[rep42_WorkTime](
	@wh varchar(10), 
	@date smalldatetime,
	@worker_n varchar (40),
	@worker_l varchar (40),
	@code varchar (10),
	@codef varchar (10)
)AS


--declare @wh varchar(10), @date smalldatetime
--select @date = convert(varchar(10),dateadd(dy,-1,getdate()),112),
--		@wh = 'wh1'

	declare @sql varchar(max)

--min(adddate), max(adddate)
	select addwho, min(itrnkey) minKey, max(itrnkey) maxKey, count(itrnkey) countKeys 
	into #itrn from wh1.itrn i
	where 1=2 
	group by addwho
	
	set @sql='insert into #itrn	
		select addwho, min(itrnkey) minKey, max(itrnkey) maxKey, count(itrnkey) countKeys 
			from '+@wh+'.itrn i
		where i.adddate between '''+convert(varchar(10),@date,112)+'''
			and dateadd(dy,1,'''+convert(varchar(10),@date,112)+''')
		group by addwho'
	exec (@sql)


	select t.addwho, i1.adddate minDate, i1.trantype firstOp, i2.adddate maxDate, i2.trantype lastOp, 
		datediff(mi,i1.adddate,i2.adddate)diff
	into #Res1 
	from #itrn t 
		join wh1.itrn i1 on t.minkey=i1.itrnkey
		join wh1.itrn i2 on t.maxkey=i2.itrnkey
	where 1=2
	set @sql='insert into #Res1 	
		select t.addwho, i1.adddate minDate, i1.trantype firstOp, i2.adddate maxDate, i2.trantype lastOp, 
			datediff(mi,i1.adddate,i2.adddate)diff
		from #itrn t 
			join '+@wh+'.itrn i1 on t.minkey=i1.itrnkey
			join '+@wh+'.itrn i2 on t.maxkey=i2.itrnkey'
	exec (@sql)

	--select * from #Res1

	set @sql = 'select usr_name, r.*, ck1.description first, ck2.description last, 
		cast(floor(diff/60) as varchar(10))hh, cast(diff - (floor(diff/60)*60)as varchar(2)) mm
	from #res1 r
	 join '+@wh+'.codelkup ck1 on ck1.code = r.firstop and ck1.listname = ''itrntype''
	 join '+@wh+'.codelkup ck2 on ck2.code = r.lastop and ck2.listname = ''itrntype''
	 join ssaadmin.pl_usr usr on usr_login=r.addwho 
	 where 1=1 '+ 
case when @worker_n is null then '' else ' and usr.usr_name like '''+@worker_n+'''' end +
case when @worker_l is null then '' else ' and usr.usr_login like '''+@worker_l+'''' end +

case when isnull(@codef,'') = '' and isnull(@code,'') = ''  then '' else
	case when isnull(@code,'') = '' or isnull(@codef,'') = '' then
		case when isnull(@code,'') = '' then '' else ' and ck1.code like '''+@code+'''' end +
		case when isnull(@codef,'') = '' then '' else ' and ck2.code like '''+@codef+'''' end 
	else
		' and (ck2.code like '''+@codef+''' or ck1.code like '''+@code+''')' 
	end 
end +
 ' order by 1,diff'
	exec (@sql)
--select @sql
	drop table #itrn
	drop table #res1
--select * from ssaadmin.pl_usr

