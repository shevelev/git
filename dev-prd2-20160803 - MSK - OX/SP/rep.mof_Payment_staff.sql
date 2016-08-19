ALTER PROCEDURE [rep].[mof_Payment_staff] ( /*** =20091101 freez= Учет работы персонала склада 
																		(orders, receipt, taskdetail, itrn) ***/
	@wh varchar(30),
	@datebegin datetime,
	@dateend datetime
)
as

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(10)


set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(10),@dateend+1,112)

select 
	tskd.userkey usr,
	cast(ord.orderkey as varchar(30)) numDoc,
	count(od.orderlinenumber) linenum,
	sum(od.shippedqty) qty,
	sum(sk.stdcube) Scube,
	isnull(td.rate, 0) rub,
	td.base base,
	case td.base 
			when 'R' then isnull(td.rate, 0)*count(od.orderlinenumber) 
			when 'C' then isnull(td.rate, 0)*sum(sk.stdcube)
	end payR

into #tmpOrders
	 
from wh2.orders ord
	left join wh2.orderdetail od on ord.orderkey=od.orderkey
	left join wh2.sku sk on od.sku=sk.sku and ord.storerkey=sk.storerkey
	left join wh2.tariffdetail td on sk.busr3=td.descrip or sk.busr2=td.descrip or sk.busr1=td.descrip
	join wh2.taskdetail tskD on ord.orderkey=tskd.orderkey and od.sku=tskd.sku and ord.storerkey=tskd.storerkey and tskd.status='9'

	
where 1=2
group by 
		tskd.userkey,
		isnull(td.rate, 0),
		td.base,
		ord.orderkey


--set dateformat dmy
set @sql ='

insert into #tmpOrders
select 
	tskd.userkey usr, 
	(ord.orderkey+''_O'') numDoc,
	count(od.orderlinenumber) linenum,
	sum(od.shippedqty) qty,
	sum(sk.stdcube) Scube,
	isnull(td.rate, 0) rub,
	td.base base,
	case td.base 
			when ''R'' then isnull(td.rate, 0)*count(od.orderlinenumber) 
			when ''C'' then isnull(td.rate, 0)*sum(sk.stdcube)
	end payR
	 
from '+@wh+'.orders ord
	left join '+@wh+'.orderdetail od on ord.orderkey=od.orderkey
	left join '+@wh+'.sku sk on od.sku=sk.sku and ord.storerkey=sk.storerkey
	left join '+@wh+'.tariffdetail td on sk.busr3=td.descrip or sk.busr2=td.descrip or sk.busr1=td.descrip
	join '+@wh+'.taskdetail tskD on ord.orderkey=tskd.orderkey and od.sku=tskd.sku and ord.storerkey=tskd.storerkey and tskd.status=''9''
	
where 
	(ord.orderdate between '''+@bdate+''' and '''+@edate+''') 
	and ord.status>88
group by 
		tskd.userkey,
		isnull(td.rate, 0),
		td.base,
		(ord.orderkey+''_O'')
order by (ord.orderkey+''_O'')	
'

print @sql
exec (@sql)


set @sql='
insert into #tmpOrders
select 
	itrn.addwho usr, 
	(rec.receiptkey+''_R'') numDoc,
	count(rd.receiptlinenumber) linenum,
	sum(rd.qtyreceived) qty,
	sum(sk.stdcube) Scube,
	isnull(td.rate, 0) rub,
	td.base base,
	case td.base 
			when ''R'' then isnull(td.rate, 0)*count(rd.receiptlinenumber)
			when ''C'' then isnull(td.rate, 0)*sum(sk.stdcube)
	end payR
from '+@wh+'.receipt rec
	left join '+@wh+'.receiptdetail rd on rec.receiptkey=rd.receiptkey
	left join '+@wh+'.sku sk on rd.sku=sk.sku and rec.storerkey=sk.storerkey
	left join '+@wh+'.tariffdetail td on sk.busr3=td.descrip or sk.busr2=td.descrip 
	join '+@wh+'.itrn itrn on rec.receiptkey=itrn.receiptkey and rd.sku=itrn.sku 
	
where 
	(rec.receiptdate between '''+@bdate+''' and '''+@edate+''')
group by 
		itrn.addwho,
		isnull(td.rate, 0),
		td.base,
		(rec.receiptkey+''_R'') 
order by (rec.receiptkey+''_R'')

'

print @sql
exec (@sql)


select  usr,
		isnull(UsrFull.usr_name,' ') as usr_name,
		numDoc,
		linenum,
		qty,
		Scube,
		rub,
		base,
		payR
from #tmpOrders tmp
left join ssaadmin.pl_usr UsrFull on tmp.usr=UsrFull.usr_login

drop table #tmpOrders

