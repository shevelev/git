ALTER PROCEDURE [dbo].[repF02_CubeBillig_M03] ( /*** =20100216 freez= Ó÷åò îáúåìîâ ñêëàäà (òîâàð BELLA)
																		(orders, PO, receipt) ***/
	@wh varchar(30) ,
	@storer varchar(15),
	@datebegin datetime,
	@dateend datetime,
	@bella int
)

as

create table #result_table (
		O_R varchar(1) not null,
		actDate datetime,
		storer varchar(15) not null,
		docNum varchar(30) not null, 
		externDocNum varchar(30) not null,
		RSumCube float null,
		OSumCube float null
)

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(10)


set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(10),@dateend+1,112)


set @sql='
insert into #result_table
select 
		''R'' O_R,
		rec.editdate actDate,
		po.storerkey storer,
		rec.receiptkey docNum, 
		po.EXTERNPOKEY externDocNum,
		sum(pd.qtyreceived*sk.stdcube) RSumCube,
		0 OSumCube  
from '+@wh+'.PO po
	join '+@wh+'.receipt rec on po.otherreference=rec.receiptkey
	join '+@wh+'.podetail pd on po.pokey=pd.pokey
	left join '+@wh+'.sku sk on pd.sku=sk.sku and po.storerkey=sk.storerkey
where po.storerkey='''+@storer+''' 
		and (rec.editdate between '''+@bdate+''' and '''+@edate+''')
		and (po.susr4 not like ''%ÈÍÂÅÍÒÀÐÈÇ%'' or po.susr4 is null)
		and pd.status=11
group by 
		rec.editdate,
		po.storerkey,
		rec.receiptkey, 
		po.EXTERNPOKEY
order by rec.editdate
'

print (@sql)
exec (@sql)

set @sql='
insert into #result_table
select 
		''O'' O_R,
		MAX(ord.editdate) actDate,
		ord.storerkey storer,
		ord.orderkey docNum, 
		ord.EXTERNORDERKEY externDocNum,		 
		0 RSumCube,
		sum(od.shippedqty*sk.stdcube) OSumCube

from '+@wh+'.orders ord
	join '+@wh+'.orderdetail od on ord.orderkey=od.orderkey
	join '+@wh+'.sku sk on od.sku=sk.sku and ord.storerkey=sk.storerkey
where ord.storerkey='''+@storer+''' 
		and ord.status>=92
		and (ord.editdate between '''+@bdate+''' and '''+@edate+''') 
group by 
		
		ord.orderkey, 
		ord.storerkey,
		ord.EXTERNORDERKEY
		
order by actDate
'

print (@sql)
exec (@sql)

select ft.Date_cn actDate,
		ft.storerkey storerkey,
		sum(ft.qty*sk.stdcube) FTC
into #FT
from dbo.FT_ostatki FT
left join wh1.sku sk on ft.storerkey=sk.storerkey and ft.sku=sk.sku
where ft.storerkey=@storer and (ft.date_cn between dateadd("d",-1,@bdate) and @edate)
group by ft.Date_cn,
		ft.storerkey
order by ft.Date_cn, ft.storerkey

--select *
--from #FT
--
--drop table #FT


--set dateformat dmy  
select convert(varchar(10),rt.actDate,112) actDate, 
		sum(rt.RSumCube) RSumCube, 
		sum(rt.OSumCube) OSumCube,
		rt.storer
into #tmp
from #result_table rt
group by convert(varchar(10),rt.actDate,112), rt.storer

--select rt.actDate, 
--		sum(rt.RSumCube) RSumCube, 
--		sum(rt.OSumCube) OSumCube,
--		rt.storer
--into #tmp
--from #result_table rt
--group by rt.actDate, rt.storer


select convert(varchar(10),ft.actDate,104) actDate, ft.storerkey storer, 
		fto.ftc na_0, 
		isnull(tmp.RSumCube,0) RSumCube, 
		isnull(tmp.OSumCube,0) OSumCube, 
		ft.ftc na_24
from #FT ft
	left join #tmp tmp on ft.actDate=tmp.actDate and ft.storerkey=tmp.storer
	left join #FT fto on ft.actDate=dateadd("d", 1,fto.actDate) and ft.storerkey=fto.storerkey
where (ft.actDate between @bdate and dateadd("d",-1,@edate))
order by ft.actDate


drop table #FT
drop table #tmp
drop table #result_table

