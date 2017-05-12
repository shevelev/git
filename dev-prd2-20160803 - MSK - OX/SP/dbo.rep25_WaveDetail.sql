ALTER PROCEDURE [dbo].[rep25_WaveDetail](
	@wh varchar(10),
	@wave varchar(10)
)

as

--declare
--	@wh varchar(10),
--	@wave varchar(10)
--select @wh = 'wh1', @wave = '0000000438'

	declare @sql nvarchar(max)

	declare @Vavg decimal(10,5)
	set @Vavg = 1.2*0.8*1.6

	select wavekey, orderkey into #waves from wh1.wavedetail where 1=2
--	alter table #waves drop column serialkey
	set @sql = 'insert #waves select wavekey, orderkey from '+@wh+'.wavedetail where wavekey = '''+@wave+''''
	exec(@sql)
--select * from #waves
	select orderkey,  status, door into #orders from wh1.orders where 1=2
	set @sql = 'insert #orders select orderkey,  status, door
			from '+@wh+'.orders where orderkey in (select orderkey from #waves)'
	exec(@sql)
	select orderkey,  qty, status, sku, storerkey, packkey,dropid into #picks from wh1.pickdetail where 1=2
	set @sql = 'insert #picks select orderkey,  qty, status, sku, storerkey, packkey,dropid
		from '+@wh+'.pickdetail where orderkey in (select  orderkey from #waves)'
	exec(@sql)

	declare @status int
	set @status = 5

	select orderkey,
		sum(p.qty*stdcube) Volume,
		sum(p.qty*stdgrosswgt)  GrossWGT,
		ceiling(sum(p.qty/case when isnull(pallet,0)=0 then 1 else pallet end)) plEstimatePack,
		ceiling(sum((p.qty*stdcube)/@Vavg)) plEstimateVol,
		sum(case when status = @status then 1 else 0 end) pkCompleted--,
		--sum(case when status < @status then 1 else 0 end) plIncompleted
	into #PlCounts 
	from #picks p 
			join wh1.sku s on p.sku = s.sku and p.storerkey=s.storerkey
			join wh1.pack pk on pk.packkey = p.packkey
	where 1=2
	group by orderkey
	
	--set identity_insert #picks on
	set @sql = 'insert into #PlCounts select orderkey,
		sum(p.qty*stdcube) Volume,
		sum(p.qty*stdgrosswgt)  GrossWGT,
		ceiling(sum(p.qty/case when isnull(pallet,0)=0 then 1 else pallet end)) plEstimatePack,
		ceiling(sum((p.qty*stdcube)/@Vavg)) plEstimateVol,
		sum(case when status = @status then 1 else 0 end) pkCompleted--,
		--sum(case when status < @status then 1 else 0 end) plIncompleted
	 
	from #picks p 
			join '+@wh+'.sku s on p.sku = s.sku and p.storerkey=s.storerkey
			join '+@wh+'.pack pk on pk.packkey = p.packkey
	group by orderkey'
	exec sp_executesql @sql, N'@status int, @Vavg decimal(10,5)',
			 @status=@status, @Vavg = @Vavg


	select orderkey, count(distinct dropid)plCount into #plCounts2 from #picks group by orderkey

	select orderkey, 0 CompletedPosCount, 
		0 posCount
		into #posCompleted
		from wh1.orderdetail where 1=2
	--set identity_insert #posCompleted on

	set @status = 68
	set @sql = 'insert into #posCompleted select orderkey, sum(case when status>=@status then 1 else 0 end)CompletedPosCount, 
		count(orderlinenumber) posCount
		
		from '+@wh+'.orderdetail where orderkey in  (select  orderkey from #waves)
		group by orderkey'
	exec sp_executesql @sql, N'@status int', @status=@status

	
	set @sql = 'select o.orderkey, oss.description status, door, grosswgt, 
				volume, posCount, plEstimateVol, plEstimatePack, 
		completedPosCount, pkCompleted, completedPosCount*100/posCount  percentCompleted 
	from #orders o
		left join #plCounts t1 on o.orderkey=t1.orderkey
		left join #posCompleted pc on o.orderkey = pc.orderkey
		left join '+@wh+'.orderstatussetup oss on oss.code = o.status'
	exec (@sql)
--select * from wh1.orderstatussetup


drop table #waves
drop table #orders
drop table #picks
drop table #plCounts
drop table #plCounts2
drop table #posCompleted

