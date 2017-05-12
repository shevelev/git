-- =============================================
-- �����:		��������� ��������
-- ������:		������, �.�������
-- ���� ��������: 20.07.2010 (������)
-- ��������: ����� ���������� ����� ������� � ���� �� ������� � ��������
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV29_Stat_Str_RO] ( 
	@wh varchar(30),								
	@datebegin datetime,
	@dateend datetime
)
as

create table #table_O(
		Storerkey varchar(15) not null,
		Orderkey varchar(10) not null, -- � ������
		OLNumber varchar(5) not null, -- ������� � ������ �� ��������
		Sku varchar(50) not null, -- ��� ������
		ShtVKorob int not null, -- ��. � �������
		stdcube float not null, -- �����
		QtyKorob decimal(22,5) not null, -- ���-�� ������ � ��������
		QtySht decimal(22,5) not null, -- ���-�� ������ � ��.
		CubeMKorob decimal(22,10) not null, -- ����� � ��������
		CubeMSht decimal(22,6) not null, -- ����� � ��.
		Qty decimal(22,5) not null -- ���-�� ������ � ��.
)
create table #table_R(
		Storerkey varchar(15) not null,
		Receiptkey varchar(10) not null, -- � ���
		RLNumber varchar(5) not null, -- ������� � ������ �� �������
		Sku varchar(50) not null, -- ��� ������
		ShtVKorob int not null, -- ��. � �������
		stdcube float not null, -- �����
		QtyKorob decimal(22,5) not null, -- ���-�� ������ � ��������
		QtySht decimal(22,5) not null, -- ���-�� ������ � ��.
		CubeMKorob decimal(22,10) not null, -- ����� � ��������
		CubeMSht decimal(22,6) not null, -- ����� � ��.
		Qty decimal(22,5) not null -- ���-�� ������ � ��.
)
create table #table_result(
		Storerkey varchar(15) not null,
		Company varchar(45) null,
		Descrip varchar(40) not null, -- �������� ��������
		Number int not null, -- ����� �������� ��� ����������
		StrNumber varchar(50) null, -- ���-�� �������
		CubeMItog decimal(22,6) null, -- ���� �����
		Qty decimal(22,5) not null, -- ���-�� ������ � ��.
		QtyKorob decimal(22,5) not null, -- ���-�� ������ � ��������
		QtySht decimal(22,5) not null -- ���-�� ������ � ��.
)

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(20)

set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(20),dateadd(s,-1,dateadd(day,1,cast(@dateend as datetime))),13)
print (@bdate)
print (@edate)

/**/
set @sql='
insert into #table_O
select  od.storerkey,
		od.orderkey OrderKey,
		od.orderlinenumber OLNumber,
		od.sku Sku,
		PK.casecnt ShtVKorob,
		SK.stdcube stdcube,
		cast(od.shippedqty/PK.casecnt as int) QtyKorob,
		cast(od.shippedqty-cast((od.shippedqty/PK.casecnt)as int)*PK.casecnt as int) QtySht,
		sum((cast((od.shippedqty/PK.casecnt)as int)*PK.casecnt)*SK.stdcube) CubeMKorob,
		sum(cast(od.shippedqty-cast((od.shippedqty/PK.casecnt)as int)*PK.casecnt as int)*SK.stdcube) CubeMSht,
		sum(od.shippedqty) Qty
from '+@wh+'.orderdetail od
left join '+@wh+'.orders o on od.orderkey=o.orderkey
left join '+@wh+'.SKU SK on od.storerkey=SK.storerkey and od.sku=SK.sku
left join '+@wh+'.PACK PK on od.packkey=PK.packkey
where (o.editdate between '''+@bdate+''' and '''+@edate+''')
		and (o.status=''92'' or o.status=''95'')
		and PK.casecnt<>1
		and (od.storerkey=''92'' or od.storerkey=''219'')
group by od.storerkey, od.orderkey, od.orderlinenumber,od.sku,PK.casecnt,SK.stdcube,od.shippedqty
order by od.storerkey, od.orderkey, od.orderlinenumber,od.sku,PK.casecnt,SK.stdcube,od.shippedqty
'

print (@sql)
exec (@sql)

--select *
--from #table_O

/*���� �������� ����� 1*/
set @sql='
insert into #table_O
select  od.storerkey,
		od.orderkey OrderKey,
		od.orderlinenumber OLNumber,
		od.sku Sku,
		PK.casecnt ShtVKorob,
		SK.stdcube stdcube,
		0 QtyKorob,
		od.shippedqty QtySht,
		0 CubeMKorob,
		od.shippedqty*SK.stdcube CubeMSht,
		sum(od.shippedqty) Qty
from '+@wh+'.orderdetail od
left join '+@wh+'.orders o on od.orderkey=o.orderkey
left join '+@wh+'.SKU SK on od.storerkey=SK.storerkey and od.sku=SK.sku
left join '+@wh+'.PACK PK on od.packkey=PK.packkey
where (o.editdate between '''+@bdate+''' and '''+@edate+''')
		and (o.status=''92'' or o.status=''95'')
		and PK.casecnt=1
		and (od.storerkey=''92'' or od.storerkey=''219'')
group by od.storerkey, od.orderkey, od.orderlinenumber,od.sku,PK.casecnt,SK.stdcube,od.shippedqty
order by od.storerkey, od.orderkey, od.orderlinenumber,od.sku,PK.casecnt,SK.stdcube,od.shippedqty
'

print (@sql)
exec (@sql)

----select *
----from #table_O

--select count(OLNumber)
--from #table_O
--where storerkey='219'

/**/
set @sql='
insert into #table_R
select  RD.storerkey,
		RD.receiptkey RECEIPTKEY,
		RD.receiptlinenumber RLNumber,
		RD.sku Sku,
		PK.casecnt ShtVKorob,
		SK.stdcube stdcube,
		cast(rd.qtyexpected/PK.casecnt as int) QtyKorob,
		cast(rd.qtyexpected-cast((rd.qtyexpected/PK.casecnt)as int)*PK.casecnt as int) QtySht,
		sum((cast((rd.qtyexpected/PK.casecnt)as int)*PK.casecnt)*SK.stdcube) CubeMKorob,
		sum(cast(rd.qtyexpected-cast((rd.qtyexpected/PK.casecnt)as int)*PK.casecnt as int)*SK.stdcube) CubeMSht,
		sum(rd.qtyexpected) Qty
from '+@wh+'.RECEIPTDETAIL RD
left join '+@wh+'.receipt as puo on rd.receiptkey = puo.receiptkey
left join '+@wh+'.SKU SK on RD.storerkey=SK.storerkey and RD.sku=SK.sku
left join '+@wh+'.PACK PK on rd.packkey=PK.packkey
where 	(puo.editdate between '''+@bdate+''' and '''+@edate+''')
		and puo.status=''11''
		and PK.casecnt<>1
		and	rd.qtyexpected>0
		and (RD.storerkey=''92'' or RD.storerkey=''219'')
group by RD.storerkey, RD.receiptkey, RD.receiptlinenumber, RD.sku, PK.casecnt, SK.stdcube,rd.qtyexpected
order by RD.storerkey, RD.receiptkey, RD.receiptlinenumber, RD.sku, PK.casecnt, SK.stdcube,rd.qtyexpected
'

print (@sql)
exec (@sql)

--select *
--from #table_R

/*���� �������� ����� 1*/
set @sql='
insert into #table_R
select  RD.storerkey,
		RD.receiptkey RECEIPTKEY,
		RD.receiptlinenumber RLNumber,
		RD.sku Sku,
		PK.casecnt ShtVKorob,
		SK.stdcube stdcube,
		0 QtyKorob,
		rd.qtyexpected QtySht,
		0 CubeMKorob,
		rd.qtyexpected*SK.stdcube CubeMSht,
		sum(rd.qtyexpected) Qty
from '+@wh+'.RECEIPTDETAIL RD
left join '+@wh+'.receipt as puo on rd.receiptkey = puo.receiptkey
left join '+@wh+'.SKU SK on RD.storerkey=SK.storerkey and RD.sku=SK.sku
left join '+@wh+'.PACK PK on rd.packkey=PK.packkey
where 	(puo.editdate between '''+@bdate+''' and '''+@edate+''')
		and puo.status=''11''
		and PK.casecnt=1
		and	rd.qtyexpected>0
		and (RD.storerkey=''92'' or RD.storerkey=''219'')
group by RD.storerkey, RD.receiptkey, RD.receiptlinenumber, RD.sku, PK.casecnt, SK.stdcube,rd.qtyexpected
order by RD.storerkey, RD.receiptkey, RD.receiptlinenumber, RD.sku, PK.casecnt, SK.stdcube,rd.qtyexpected
'

print (@sql)
exec (@sql)

--select *
--from #table_R

--select count(RLNumber)
--from #table_R
--where storerkey='219'

-- ������
set @sql='
insert into #table_result
select  tabR.Storerkey Storerkey,
		st.Company Company,
		''������ ������ �-�� ��������'' Descrip,
		1 Number,
		count(RLNumber) StrNumber,
		sum(CubeMKorob) CubeMItog,
		0 Qty,
		sum(tabR.QtyKorob) QtyKorob,
		0 QtySht
from #table_R tabR
left join '+@wh+'.storer st on tabR.storerkey=st.storerkey
where tabR.storerkey=''219''
		and tabR.QtySht=0
group by tabR.Storerkey, st.Company
'

print (@sql)
exec (@sql)

set @sql='
insert into #table_result
select  tabR.Storerkey Storerkey,
		st.Company Company,
		''������ �������� �-�� ��������'' Descrip,
		2 Number,
		count(RLNumber) StrNumber,
		sum(CubeMKorob+CubeMSht) CubeMItog,
		sum(tabR.Qty) Qty,
		sum(tabR.QtyKorob) QtyKorob,
		sum(tabR.QtySht) QtySht
from #table_R tabR
left join '+@wh+'.storer st on tabR.storerkey=st.storerkey
where tabR.storerkey=''219''
		and tabR.QtySht>0
group by tabR.Storerkey, st.Company
'

print (@sql)
exec (@sql)

set @sql='
insert into #table_result
select  tabO.Storerkey Storerkey,
		st.Company Company,
		''������ ������ �-�� ��������'' Descrip,
		3 Number,
		count(OLNumber) StrNumber,
		sum(CubeMKorob) CubeMItog,
		0 Qty,
		sum(tabO.QtyKorob) QtyKorob,
		0 QtySht
from #table_O tabO
left join '+@wh+'.storer st on tabO.storerkey=st.storerkey
where tabO.storerkey=''219''
		and tabO.QtySht=0
group by tabO.Storerkey, st.Company
'

print (@sql)
exec (@sql)

set @sql='
insert into #table_result
select  tabO.Storerkey Storerkey,
		st.Company Company,
		''������ �������� �-�� ��������'' Descrip,
		4 Number,
		count(OLNumber) StrNumber,
		sum(CubeMKorob+CubeMSht) CubeMItog,
		sum(tabO.Qty) Qty,
		sum(tabO.QtyKorob) QtyKorob,
		sum(tabO.QtySht) QtySht
from #table_O tabO
left join '+@wh+'.storer st on tabO.storerkey=st.storerkey
where tabO.storerkey=''219''
		and tabO.QtySht>0
group by tabO.Storerkey, st.Company
'

print (@sql)
exec (@sql)

-- ���
set @sql='
insert into #table_result
select  tabR.Storerkey Storerkey,
		st.Company Company,
		''������ ������ �-�� ��������'' Descrip,
		1 Number,
		count(RLNumber) StrNumber,
		sum(CubeMKorob) CubeMItog,
		0 Qty,
		sum(tabR.QtyKorob) QtyKorob,
		0 QtySht
from #table_R tabR
left join '+@wh+'.storer st on tabR.storerkey=st.storerkey
where tabR.storerkey=''92''
		and tabR.QtySht=0
group by tabR.Storerkey, st.Company
'

print (@sql)
exec (@sql)

set @sql='
insert into #table_result
select  tabR.Storerkey Storerkey,
		st.Company Company,
		''������ �������� �-�� ��������'' Descrip,
		2 Number,
		count(RLNumber) StrNumber,
		sum(CubeMKorob+CubeMSht) CubeMItog,
		sum(tabR.Qty) Qty,
		sum(tabR.QtyKorob) QtyKorob,
		sum(tabR.QtySht) QtySht
from #table_R tabR
left join '+@wh+'.storer st on tabR.storerkey=st.storerkey
where tabR.storerkey=''92''
		and tabR.QtySht>0
group by tabR.Storerkey, st.Company
'

print (@sql)
exec (@sql)

set @sql='
insert into #table_result
select  tabO.Storerkey Storerkey,
		st.Company Company,
		''������ ������ �-�� ��������'' Descrip,
		3 Number,
		count(OLNumber) StrNumber,
		sum(CubeMKorob) CubeMItog,
		0 Qty,
		sum(tabO.QtyKorob) QtyKorob,
		0 QtySht
from #table_O tabO
left join '+@wh+'.storer st on tabO.storerkey=st.storerkey
where tabO.storerkey=''92''
		and tabO.QtySht=0
group by tabO.Storerkey, st.Company
'

print (@sql)
exec (@sql)

set @sql='
insert into #table_result
select  tabO.Storerkey Storerkey,
		st.Company Company,
		''������ �������� �-�� ��������'' Descrip,
		4 Number,
		count(OLNumber) StrNumber,
		sum(CubeMKorob+CubeMSht) CubeMItog,
		sum(tabO.Qty) Qty,
		sum(tabO.QtyKorob) QtyKorob,
		sum(tabO.QtySht) QtySht
from #table_O tabO
left join '+@wh+'.storer st on tabO.storerkey=st.storerkey
where tabO.storerkey=''92''
		and tabO.QtySht>0
group by tabO.Storerkey, st.Company
'

print (@sql)
exec (@sql)

select *
from #table_result

drop table #table_O
drop table #table_R
drop table #table_result

