-- =============================================
-- �����:		��������� ��������
-- ������:		������, �.�������
-- ���� ��������: 01.02.2010 (������)
-- ��������: ������������ ������ ����������
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV13_DocLinesCount] ( 
	@wh varchar(30),								
	@datebegin datetime,
	@dateend datetime

)

as
create table #table_order (
		Storer varchar(15) not null, -- ��������
		Orderkey varchar(10) not null, -- ����� ������
		OrderLine varchar(5) not null, -- ������� � ������
		OQTY decimal(22,5) not null, -- ���-�� ����������� ������
		SQTY decimal(22,5) not null, -- ���-�� ������������ ������
		Price float not null, -- ���� �� �����
)

create table #table_itog (
		Storer varchar(15) not null, -- ��������
		Company varchar(45) not null, -- �������� ���������
		CountOrder int not null, -- ���-�� ����������
		CountOrderLine int not null, -- ���-�� ����� � ����������
		OQTY decimal(22,5) not null, -- ����� ���-�� ����������� ������
		SQTY decimal(22,5) not null, -- ����� ���-�� ������������ ������
		SumOQTY decimal(22,5) not null, -- ���� �� ����� ���-�� ����������� ������
		SumSQTY decimal(22,5) not null, -- ���� �� ����� ���-�� ������������ ������
		PercentSum decimal(22,5) not null, -- ���������� ����������� �� ����
		PercentQty decimal(22,5) not null -- ���������� ����������� �� ���-��
)

create table #table_receipt (
		Storer varchar(15) not null, -- ��������
		Company varchar(45) not null, -- �������� ���������
		ReceiptLinesCount decimal(22,5) not null -- ���-�� ����� � ���������� �� �������
)

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(10)

set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(10),@dateend+1,112)

-- ������������ ���-�� ������������ � ������������ ������
set @sql='
insert into #table_order
select  od.storerkey Storer,
		od.orderkey OrderKey,
		od.orderlinenumber OrderLine,
		sum(od.originalqty) OQTY,
		sum(od.shippedqty) SQTY,
		sum(od.unitprice) Price
from '+@wh+'.orderdetail od
left join '+@wh+'.orders o on od.orderkey=o.orderkey
where (o.editdate between '''+@bdate+''' and '''+@edate+''')
		--and od.orderkey=''0000001439''
		--and od.storerkey=''92''
		and (o.status=''92'' or o.status=''95'')
group by od.storerkey, od.orderkey, od.orderlinenumber
order by od.storerkey, od.orderkey, od.orderlinenumber
'
print (@sql)
exec (@sql)

--select *
--from #table_order

-- ��������� ������� �������
set @sql='
insert into #table_itog
select  tor.storer Storer,
		st.company Company,
		count(tor.OrderKey) CountOrder,
		count(tor.OrderLine) CountOrderLine,
		sum(tor.OQTY) OQTY,
		sum(tor.SQTY) SQTY,
		sum(tor.OQTY*tor.Price) SumOQTY,
		sum(tor.SQTY*tor.Price) SumSQTY,
		(sum(tor.SQTY*tor.Price)/sum(tor.OQTY*tor.Price)) PercentSum,
		(sum(tor.SQTY)/sum(tor.OQTY)) PercentQty
from #table_order as tor
left join '+@wh+'.storer as st on tor.storer = st.storerkey
where tor.storer<>''000000001''
group by tor.storer, st.company
order by tor.storer, st.company
'
print (@sql)
exec (@sql)

set @sql='
insert into #table_itog
select  tor.storer Storer,
		st.company Company,
		count(tor.OrderKey) CountOrder,
		count(tor.OrderLine) CountOrderLine,
		sum(tor.OQTY) OQTY,
		sum(tor.SQTY) SQTY,
		sum(tor.OQTY) SumOQTY,
		sum(tor.SQTY) SumSQTY,
		(sum(tor.SQTY)/sum(tor.OQTY)) PercentSum,
		(sum(tor.SQTY)/sum(tor.OQTY)) PercentQty
from #table_order as tor
left join '+@wh+'.storer as st on tor.storer = st.storerkey
where tor.storer=''000000001''
group by tor.storer, st.company
order by tor.storer, st.company
'
print (@sql)
exec (@sql)


--select *
--from #table_itog

-- ������������ ������� �������
set @sql='
insert into #table_receipt
select  rd.storerkey Storer, 
		st.company Company,
		count(rd.receiptkey) ReceiptLinesCount
from '+@wh+'.receiptdetail rd
left join '+@wh+'.storer as st on rd.storerkey = st.storerkey
left join '+@wh+'.receipt as puo on rd.receiptkey = puo.receiptkey
where	(puo.editdate between '''+@bdate+''' and '''+@edate+''')
		and	rd.qtyexpected>0
		and puo.status=''11''
group by rd.storerkey, st.company
'
print (@sql)
exec (@sql)

--select *
--from #table_receipt

select
case when LC1.storer is null then LC2.storer else LC1.storer end STORER,
case when LC1.company is null then LC2.company else LC1.company end COMPANY,
isnull(LC1.CountOrder,0)	    CountOrder,
isnull(LC1.CountOrderLine,0)    CountOrderLine,
isnull(LC2.ReceiptLinesCount,0)	ReceiptLinesCount,
isnull(LC1.OQTY,0)				OQTY,
isnull(LC1.SQTY,0)				SQTY,
isnull(LC1.SumOQTY,0)			SumOQTY,
isnull(LC1.SumSQTY,0)		    SumSQTY,
isnull(LC1.PercentSum,0)		PercentSum,
isnull(LC1.PercentQty,0)		PercentQty
from #table_itog LC1
	full outer join #table_receipt LC2 on (LC1.storer=LC2.storer)
order by LC1.storer

drop table #table_order
drop table #table_itog
drop table #table_receipt

