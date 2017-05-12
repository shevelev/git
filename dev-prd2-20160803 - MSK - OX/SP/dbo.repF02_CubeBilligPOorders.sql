ALTER PROCEDURE [dbo].[repF02_CubeBilligPOorders] ( /*** =20091118 freez= Ó÷åò îáúåìîâ ñêëàäà 
													ðàñøèðåííûé					(orders, PO) ***/
	@wh varchar(30),
	@storer varchar(15),
	@datebegin datetime,
	@dateend datetime
)

as

create table #result_table (
		O_R varchar(6) not null,
		actDate datetime,
		storerRT varchar(15) not null,
		DescrCompany varchar(45) null,
		docNum varchar(30) not null, 
		externDocNum varchar(30) not null,
		RSumCube float null,
		RSTDGROSSWGT float not null,
		OSumCube float null,
		OSTDGROSSWGT float not null
)

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(10),
		@where varchar(100)


set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(10),@dateend+1,112)
set @where = 'and 1=1'

if @storer is not null
	set @where = 'and po.storerkey='''+@storer+''''


set @sql='
insert into #result_table
select 
		''ÏÓÎ'' O_R,
		rec.editdate actDate,
		po.storerkey storerRT,
		st.Company DescrCompany,
		rec.receiptkey docNum, 
		isnull(po.susr4, po.externpokey) externDocNum,
		sum(pd.qtyreceived*sk.stdcube) RSumCube,
		sum(pd.qtyreceived*sk.STDGROSSWGT) RSTDGROSSWGT,
		0 OSumCube,  
		0 OSTDGROSSWGT
from '+@wh+'.PO po
	join '+@wh+'.receipt rec on po.otherreference=rec.receiptkey
	join '+@wh+'.podetail pd on po.pokey=pd.pokey
	left join '+@wh+'.sku sk on pd.sku=sk.sku and po.storerkey=sk.storerkey
	left join '+@wh+'.storer st on po.storerkey=st.storerkey
where 1=1 '+@where+' 
		and (rec.editdate between '''+@bdate+''' and '''+@edate+''')
		and (po.susr4 not like ''%ÈÍÂÅÍÒÀÐÈÇ%'' or po.susr4 is null)
		and pd.status=11
group by 
		rec.editdate,
		po.storerkey,
		st.Company,
		rec.receiptkey, 
		isnull(po.susr4, po.externpokey)
order by rec.editdate
'

print (@sql)
exec (@sql)

set @sql='
insert into #result_table
select 
		''îðäåð'' O_R,
		MAX(po.editdate) actDate,
		po.storerkey storerRT,
		st.Company DescrCompany,
		po.orderkey docNum, 
		isnull(po.susr4, po.externorderkey) externDocNum,		 
		0 RSumCube,
		0 RSTDGROSSWGT,
		sum(od.shippedqty*sk.stdcube) OSumCube,
		sum(od.shippedqty*sk.STDGROSSWGT) OSTDGROSSWGT

from '+@wh+'.orders po
	join '+@wh+'.orderdetail od on po.orderkey=od.orderkey
	left join '+@wh+'.sku sk on od.sku=sk.sku and po.storerkey=sk.storerkey
	left join '+@wh+'.storer st on po.storerkey=st.storerkey
where 1=1 '+@where+' 
		and po.status>=92
		and (po.editdate between '''+@bdate+''' and '''+@edate+''') 
group by 
		
		po.orderkey, 
		st.Company,
		po.storerkey,
		isnull(po.susr4, po.externorderkey)
		
order by actDate
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
select 
		
		convert(varchar(10), rt.actDate, 104) actDate, 
		rt.storerRT, rt.DescrCompany, rt.O_R, rt.DocNum, rt.externDocNum,
		sum(rt.RSTDGROSSWGT) RSTDGROSSWGT,
		sum(rt.RSumCube) RSumCube, 
		sum(rt.OSTDGROSSWGT) OSTDGROSSWGT,
		sum(rt.OSumCube) OSumCube
		
--		sum(sk.stdcube*ft.qty) CB
--into #tmp
from #result_table rt
--	left join dbo.FT_ostatki FT on rt.storer=ft.storerkey 
--				and convert(varchar(10), rt.actDate, 104)=convert(varchar(10), ft.Date_cn, 104)
--	join wh1.sku sk on ft.storerkey=sk.storerkey and ft.sku=sk.sku
group by convert(varchar(10), rt.actDate, 104), rt.storerRT, rt.DescrCompany, rt.O_R, rt.DocNum, rt.externDocNum
----
--select tmp.actDate, tmp.storer, tmp.RSumCube, tmp.OSumCube, ft.ftc
--from #tmp tmp
--	left join #FT ft on tmp.actDate=ft.actDate and tmp.storer=ft.storerkey

--select *
--from #result_table

--drop table #FT
--drop table #tmp
drop table #result_table

