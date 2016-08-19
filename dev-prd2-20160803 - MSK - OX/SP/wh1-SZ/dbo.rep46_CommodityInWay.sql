ALTER PROCEDURE [dbo].[rep46_CommodityInWay](
	@wh varchar(40),
	@sku varchar(10), 
	@skuName varchar(45),
	@ordGroup varchar(20),
	@avtoNum varchar(20),
	@driverFIO varchar(50),
	@shipdate smalldatetime
)as


--declare @sku varchar(10), @ordGroup varchar(20)
--select @ordGroup = 'N%'


declare @sql nvarchar(max)
	-- получаем выборку заказов-DropID по заданным условиям 
	select identity(int,1,1) id, type, ordergroup, od.sku, od.storerkey, pls.tsid,
		dbo.DA_StockScala2Infor(dc_id) whDst, o.orderkey, o.externorderkey, cast(0 as int) asnDelivered,
		cast(null as datetime) delivDate, 
		case when od.status=9 then max(od.editdate) else cast(null as datetime) end shipdate
	into #list
	from wh40.orders o
		join wh40.pickdetail od on od.orderkey=o.orderkey
		join WH40.PackLoadSend pls on pls.serialkey = od.serialkey
	where o.type in (3,21,41)
		and (isnull(@sku,'') = '' or sku like @sku)
		and (isnull(@ordGroup,'') = '' or ordergroup like @ordGroup)
	group by type, ordergroup, od.sku, od.storerkey, pls.tsid, o.orderkey, o.externorderkey, dc_id,od.status
	
	
	-- выбираем уникальные DropID
	select distinct identity(int,1,1)id, tsid, whDst into #drops from #list

	declare @i int, @iMax int, @whproc varchar(10), @extKey varchar(12), @status varchar(10), @delivDate datetime
	select @i=1, @imax = max(id) from #drops


--	 для каждого DropID на складе-получателе выбираем пуо по DropID, 
--	 проверяем его статус, и дату последнего редактирования
	while (@i <= @imax)
	begin
		select @whproc=whDst, @extKey=tsid from #list where id = @i
		if exists (select * from dbo.warehouselist where name = @whproc and enabled=1)
		begin
			set @sql = 'select @status = status, @delivDate=editdate from '+@whproc+'.receipt where externorderkey='''+@extKey+''''
			exec sp_executesql @sql, N'@status varchar(10) out, @delivDate datetime out', 
				@status=@status output, @delivDate=@delivDate output

			-- заносим полученные данные в #list
			update #list set delivDate=@delivDate, asnDelivered= case when  @status='11' then 1 else 0 end
			where tsid=@extKey
		end
		
		set @i=@i+1
	end

	-- выбираем записи из TTNInfo для заказов которые в #list
	select * into #tti from dbo.ttnInfo where objectkey in (select distinct orderkey from #list)
	
	select sku, storerkey, ordergroup, shipdate, avtomark, avtonum, driverFIO, 
		case when not shipdate is null 
			then datediff(mi,shipdate,getdate()) 
			else 0 
		end tm
	into #rs
	from #list l
		join #tti t on objectKey = orderkey
	where asnDelivered=0
	
	select r.*, s.descr skuName,
		cast(floor(tm/60) as varchar(10))hh, cast(tm-floor(tm/60)*60 as varchar(2))mm  
	from #rs r
		join wh40.sku s on r.sku=s.sku and r.storerkey=s.storerkey
	where 1=1 
		and (isnull(@skuName,'') = '' or s.Descr like @skuName)
		and (isnull(@avtoNum,'') = '' or avtonum like @avtoNum)
		and (isnull(@driverFIO,'') = '' or driverFIO like @driverFIO)
		and (@shipdate is null or shipdate >= @shipdate)

	drop table #list
	drop table #drops
	drop table #tti
	drop table #rs

