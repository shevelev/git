ALTER PROCEDURE [dbo].[repF02_CubeBillig] ( /*** =20091101 freez= Ó÷åò îáúåìîâ ñêëàäà 
																		(orders, PO) ***/
	@wh varchar(30),
	@storer varchar(15),
	@datebegin datetime,
	@dateend datetime
)

as

create table #result_table (
		O_R varchar(1) not null,
		actDate datetime,
		storer varchar(15) not null,
		docNum varchar(30) not null, 
		externDocNum varchar(30) not null,
		RSumCube float null,
		RSTDGROSSWGT float not null,
		OSumCube float null,
		OSTDGROSSWGT float not null
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
		po.effectivedate actDate,
		po.storerkey storer,
		po.pokey docNum, 
		po.EXTERNPOKEY externDocNum,
		sum(pd.qtyreceived*sk.stdcube) RSumCube,
		sum(pd.qtyreceived*sk.STDGROSSWGT) RSTDGROSSWGT,
		0 OSumCube,  
		0 OSTDGROSSWGT
from '+@wh+'.PO po
	join '+@wh+'.podetail pd on po.pokey=pd.pokey
	left join '+@wh+'.sku sk on pd.sku=sk.sku and po.storerkey=sk.storerkey
where po.storerkey='''+@storer+''' 
		and (po.effectivedate between '''+@bdate+''' and '''+@edate+''')
		and (po.susr4 not like ''%ÈÍÂÅÍÒÀÐÈÇ%'' or po.susr4 is null)
		and pd.status=11
group by 
		po.effectivedate,
		po.storerkey,
		po.pokey, 
		po.EXTERNPOKEY
order by po.effectivedate
'

print (@sql)
exec (@sql)

set @sql='
insert into #result_table
select 
		''O'' O_R,
		ord.ACTUALSHIPDATE actDate,
		ord.storerkey storer,
		ord.orderkey docNum, 
		ord.EXTERNORDERKEY externDocNum,		 
		0 RSumCube,
		0 RSTDGROSSWGT,
		sum(od.shippedqty*sk.stdcube) OSumCube,
		sum(od.shippedqty*sk.STDGROSSWGT) OSTDGROSSWGT

from '+@wh+'.orders ord
	join '+@wh+'.orderdetail od on ord.orderkey=od.orderkey
	join '+@wh+'.sku sk on od.sku=sk.sku and ord.storerkey=sk.storerkey
where ord.storerkey='''+@storer+''' 
		and ord.status>=92
		and (ord.ACTUALSHIPDATE between '''+@bdate+''' and '''+@edate+''') 
group by 
		
		ord.orderkey, 
		ord.storerkey,
		ord.EXTERNORDERKEY,
		ord.ACTUALSHIPDATE
order by ord.ACTUALSHIPDATE
'

print (@sql)
exec (@sql)

--select convert(varchar(10), ft.Date_cn, 104) actDate,
--		ft.storerkey storerkey,
--		sum(ft.qty*sk.stdcube) FTC
--into #FT
--from dbo.FT_ostatki FT
--left join wh1.sku sk on ft.storerkey=sk.storerkey and ft.sku=sk.sku
--group by convert(varchar(10), ft.Date_cn, 104),
--		ft.storerkey
--order by convert(varchar(10), ft.Date_cn, 104), ft.storerkey

--select *
--from #FT
--
--drop table #FT


set dateformat dmy  
select convert(varchar(10), rt.actDate, 104) actDate, 
		sum(rt.RSumCube) RSumCube, 
		sum(rt.OSumCube) OSumCube,
		rt.storer
--		sum(sk.stdcube*ft.qty) CB
--into #tmp
from #result_table rt
--	left join dbo.FT_ostatki FT on rt.storer=ft.storerkey 
--				and convert(varchar(10), rt.actDate, 104)=convert(varchar(10), ft.Date_cn, 104)
--	join wh1.sku sk on ft.storerkey=sk.storerkey and ft.sku=sk.sku
group by convert(varchar(10), rt.actDate, 104), rt.storer
----
--select tmp.actDate, tmp.storer, tmp.RSumCube, tmp.OSumCube, ft.ftc
--from #tmp tmp
--	left join #FT ft on tmp.actDate=ft.actDate and tmp.storer=ft.storerkey

--select *
--from #result_table

--drop table #FT
--drop table #tmp
drop table #result_table

