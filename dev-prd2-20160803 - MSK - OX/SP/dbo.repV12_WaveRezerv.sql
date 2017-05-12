-- =============================================
-- �����:		��������� ��������
-- ������:		������, �.�������
-- ���� ��������: 25.01.2010 (������)
-- ��������: ����� �������������������� ������ �� �����
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV12_WaveRezerv] ( 
									
	@wh varchar(30),
	@wave varchar(10)
)

as

create table #table_res1 (
		OrderKey varchar(10) not null, -- � ������
		Storer varchar(15) not null, -- ��� ���������
		Company varchar(45) null, -- ��������
		Sku varchar(50) not null, -- ��� ������
		Descr varchar(60) null, -- �������� ������
		Qty decimal(22,2) not null, -- ���-�� ����������� ������
		QtyR decimal(22,2) not null, -- ���-�� ������������������ ������
		Other varchar(max) null, -- ����������
		Date varchar(11) not null -- ���� ���������� ������
)

create table #table_pick (
		Sku varchar(50) not null, -- ��� ������
		Storer varchar(15) not null, -- ��� ���������
		QtyP decimal(22,2) not null -- ���-�� ������ � ���� ������
)

create table #table_ostatok (
		Sku varchar(50) not null, -- ��� ������
		Storer varchar(15) not null, -- ��� ���������
		QtyO decimal(22,2) not null -- ���-�� ������ �� �������
)

create table #table_ostatokV (
		Sku varchar(50) not null, -- ��� ������
		Storer varchar(15) not null, -- ��� ���������
		QtyO decimal(22,2) not null -- ���-�� ������ �� �������
)

create table #table_srok (
		Storer varchar(15) not null, -- ��������
		Sku varchar(50) not null, -- ��� ������
		Kol decimal(22,0) not null, -- ���-�� ������ �� �������
		Ost int null, -- �������� ���� �� �����
		Date datetime null -- ����� ��
)

create table #table_packkey (
		Storer varchar(15) not null, -- ��� ���������
		Sku varchar(50) not null, -- ��� ������
		Qty decimal(22,2) null, -- ���-�� ����������� ������
		QtyR decimal(22,2) not null, -- ���-�� ������������������ ������
		Lot varchar(10) null, -- ������
		PackKey varchar(50) null, -- ���� ��������
		Other varchar(max) null, -- ����������
)

create table #table_packkey2 (
		Storer varchar(15) not null, -- ��� ���������
		Sku varchar(50) not null, -- ��� ������
		QtyR decimal(22,2) not null, -- ���-�� ������������������ ������
		Other varchar(max) null, -- ����������
)

create table #table_packkey3 (
		Storer varchar(15) not null, -- ��� ���������
		Sku varchar(50) not null, -- ��� ������
		QtyR decimal(22,2) not null, -- ���-�� ������������������ ������
		Other varchar(max) null, -- ����������
)

declare @sql varchar(max)

set @sql='
insert into #table_res1
select 	wd.orderkey OrderKey,
		ord.storerkey Storer,
		st.company Company,
		ord.sku Sku,
		sku.descr Descr,
		ord.originalqty Qty,
		(ord.originalqty-(ord.qtyallocated+ord.qtypicked)) QtyR,
		'''' Other,
		convert(varchar(11),ord.adddate,112) Date
from '+@wh+'.wavedetail as wd
	left join '+@wh+'.orderdetail as ord on wd.orderkey=ord.orderkey
	left join '+@wh+'.storer as st on ord.storerkey=st.storerkey
	left join '+@wh+'.sku as sku on ord.storerkey=sku.storerkey and ord.sku=sku.sku
where wd.wavekey='''+@wave+'''
		and (ord.status=''02'' or ord.status=''09'' or ord.status=''14'' or ord.status=''15'')
		--and ord.originalqty<>(ord.qtyallocated+ord.qtypicked)
order by wd.orderkey, st.company, ord.sku
'
print (@sql)
exec (@sql)

--select  *
--from #table_res1
--order by OrderKey,Company,Sku

set @sql='
insert into #table_pick
select 	distinct(r1.sku) Sku,
		r1.storer Storer,
		sum(lotx.qty) QtyP
from #table_res1 as r1
	left join '+@wh+'.lotxlocxid as lotx on r1.storer=lotx.storerkey and r1.sku=lotx.sku
	left join '+@wh+'.loc as loc on lotx.loc=loc.loc
where loc.locationtype=''PICK''
		and lotx.qty<>0
group by r1.sku, r1.storer
'
print (@sql)
exec (@sql)

--select  *
--from #table_pick
--order by Sku

update rt1 set rt1.Other = '- ������������ ������ � ���� ������; '
	from #table_pick rt2 
		join #table_res1 rt1 on rt2.Storer = rt1.Storer 
							and rt2.Sku=rt1.Sku 
		where rt2.qtyp<rt1.qty

--select  *
--from #table_res1
--order by Sku

set @sql='
insert into #table_ostatok
select 	distinct(rt.sku) Sku,
		rt.storer Storer,
		sum(lotx.qty) QtyO
from #table_res1 as rt
	left join '+@wh+'.lotxlocxid as lotx on rt.storer=lotx.storerkey and rt.sku=lotx.sku
	left join '+@wh+'.loc as loc on lotx.loc=loc.loc
where 	--lotx.qty<>0
		(loc.putawayzone<>''BRAK'' and loc.putawayzone<>''EXP'')
		and lotx.loc not like ''VOZVRAT''
		and lotx.loc not like ''LOST''
		and lotx.loc not like ''VOROTA%''
group by rt.sku, rt.storer
'
print (@sql)
exec (@sql)

--select  *
--from #table_ostatok
--order by Sku

set @sql='
insert into #table_ostatokV
select 	distinct(rt.sku) Sku,
		rt.storer Storer,
		sum(lotx.qty-lotx.qtypicked) QtyO
from #table_res1 as rt
	left join '+@wh+'.lotxlocxid as lotx on rt.storer=lotx.storerkey and rt.sku=lotx.sku
	left join '+@wh+'.loc as loc on lotx.loc=loc.loc
where 	--lotx.qty<>0
		(loc.putawayzone<>''BRAK'' and loc.putawayzone<>''EXP'')
		and lotx.loc like ''VOROTA%''
		and (lotx.qty-lotx.qtypicked)>0
group by rt.sku, rt.storer
'
print (@sql)
exec (@sql)

--select  *
--from #table_ostatokV
--order by Sku

update rt1 set rt1.Other = rt1.Other + '- �� ����������� �����; '
	from #table_ostatokV rt2
		join #table_res1 rt1 on rt2.Storer = rt1.Storer 
							and rt2.Sku=rt1.Sku 
		join #table_ostatok rt3 on rt2.Storer = rt3.Storer 
							and rt2.Sku=rt3.Sku 
		where rt3.qtyo<rt1.qty

--select  *
--from #table_res1
--order by Sku

update rt1 set rt1.QtyO = rt1.QtyO + rt2.QtyO
	from #table_ostatokV rt2 
		join #table_ostatok rt1 on rt2.Storer = rt1.Storer 
							and rt2.Sku=rt1.Sku 

--select  *
--from #table_ostatok
--order by Sku

update rt1 set rt1.Other = rt1.Other + '- �������������� � ��������; '
	from #table_ostatok rt2 
		join #table_res1 rt1 on rt2.Storer = rt1.Storer 
							and rt2.Sku=rt1.Sku 
		where rt2.qtyo<rt1.qty

--select  *
--from #table_res1
--order by Sku

set @sql='
insert into #table_srok
select lotx.storerkey Storer,
		lotx.sku Sku,
		sum(lotx.qty) Kol,
		-cast(lotatr.lottable05-cast(rt.date as datetime) as int) Ost,
		lotatr.lottable05 Date
from  #table_res1 as rt
	left join '+@wh+'.lotxlocxid as lotx on rt.sku=lotx.sku and rt.storer=lotx.storerkey
	left join '+@wh+'.sku as sk on rt.sku=sk.sku and rt.storer=sk.storerkey
	left join '+@wh+'.lotattribute as lotatr on lotx.lot=lotatr.lot
	left join '+@wh+'.loc as loc on lotx.loc=loc.loc
where isnull(lotatr.lottable05,'''')<> ''''
		and sk.lottablevalidationkey=''EXPIRED''
		and lotx.qty>0
		and	cast(lotatr.lottable05-cast(rt.date as datetime) as int)<=0
		and (loc.putawayzone<>''BRAK'' and loc.putawayzone<>''EXP'')
		and lotx.loc not like ''VOZVRAT''
		and lotx.loc not like ''LOST''
group by lotx.storerkey, lotx.sku, lotatr.lottable05, rt.date
'
print (@sql)
exec (@sql)

--select  *
--from #table_srok
--order by Sku

set @sql='
insert into #table_srok
select lotx.storerkey Storer,
		lotx.sku Sku,
		sum(lotx.qty) Kol,
		-cast(dateadd(dy,sk.shelflife,lotatr.lottable04)-cast(rt.date as datetime) as int) Ost,
		dateadd(dy,sk.shelflife,lotatr.lottable04) date
from  #table_res1 as rt
	left join '+@wh+'.lotxlocxid as lotx on rt.sku=lotx.sku and rt.storer=lotx.storerkey
	left join '+@wh+'.sku as sk on rt.sku=sk.sku and rt.storer=sk.storerkey
	left join '+@wh+'.lotattribute as lotatr on lotx.lot=lotatr.lot
	left join '+@wh+'.loc as loc on lotx.loc=loc.loc
where isnull(lotatr.lottable04,'''')<> ''''
		and sk.lottablevalidationkey=''MANUFAC''
		and lotx.qty>0
		and	cast(dateadd(dy,sk.shelflife,lotatr.lottable04)-cast(rt.date as datetime) as int)<=0
		and (loc.putawayzone<>''BRAK'' and loc.putawayzone<>''EXP'')
		and lotx.loc not like ''VOZVRAT''
		and lotx.loc not like ''LOST''
group by lotx.storerkey, lotx.sku, sk.shelflife, lotatr.lottable04, rt.date
'
print (@sql)
exec (@sql)

--select  *
--from #table_srok
--order by Sku

update rt1 set rt1.Other = rt1.Other + '- ������� ������������ �����; '
	from #table_srok rt2 
		join #table_res1 rt1 on rt2.Storer = rt1.Storer 
							and rt2.Sku=rt1.Sku 

--select  *
--from #table_res1
--order by Sku

set @sql='
insert into #table_packkey
select  rt.storer Storer,
		rt.sku Sku,
		lotx.qty Qty,
		rt.qtyr QtyR,
		lotat.lot Lot,
		lotat.lottable01 PackKey,
		null Other
from  #table_res1 as rt
	left join '+@wh+'.sku as sk on rt.sku=sk.sku and rt.storer=sk.storerkey
	left join '+@wh+'.lotxlocxid as lotx on rt.storer=lotx.storerkey and rt.sku=lotx.sku
	left join '+@wh+'.loc as loc on lotx.loc=loc.loc
	left join '+@wh+'.lotattribute as lotat on lotx.storerkey=lotat.storerkey 
												and lotx.sku=lotat.sku
												and lotx.lot=lotat.lot
where   lotx.qty<>0
		and sk.strategykey=''NOVEXCS''
		and (loc.putawayzone<>''BRAK'' and loc.putawayzone<>''EXP'')
		and lotx.loc not like ''VOZVRAT''
		and lotx.loc not like ''LOST''
		and lotx.loc not like ''VOROTA%''
'
print (@sql)
exec (@sql)

--select  *
--from #table_packkey
--order by Sku

set @sql='
insert into #table_packkey
select  rt.storer Storer,
		rt.sku Sku,
		lotx.qty Qty,
		rt.qtyr QtyR,
		lotat.lot Lot,
		lotat.lottable01 PackKey,
		null Other
from  #table_res1 as rt
	left join '+@wh+'.sku as sk on rt.sku=sk.sku and rt.storer=sk.storerkey
	left join '+@wh+'.lotxlocxid as lotx on rt.storer=lotx.storerkey and rt.sku=lotx.sku
	left join '+@wh+'.loc as loc on lotx.loc=loc.loc
	left join '+@wh+'.lotattribute as lotat on lotx.storerkey=lotat.storerkey 
												and lotx.sku=lotat.sku
												and lotx.lot=lotat.lot
where   lotx.qty<>0
		and sk.strategykey=''NOVEXCS''
		and (loc.putawayzone<>''BRAK'' and loc.putawayzone<>''EXP'')
		and lotx.loc like ''VOROTA%''
		and (lotx.qty-lotx.qtypicked)>0
'
print (@sql)
exec (@sql)

--select  *
--from #table_packkey
--order by Sku

update #table_packkey
set	Other = 
	case when (QtyR<>Qty and QtyR<>cast(PackKey as decimal(22,2))) then '�������'
		else 'OK'	
	end

--select  *
--from #table_packkey
--order by Sku

set @sql='
insert into #table_packkey2
select 	distinct(Sku),
		Storer,
		QtyR,
		Other
from #table_packkey
	where Other like ''�������''
'
print (@sql)
exec (@sql)

--select  *
--from #table_packkey2
--order by Sku

set @sql='
insert into #table_packkey3
select 	distinct(Sku),
		Storer,
		QtyR,
		Other
from #table_packkey
	where Other like ''OK''
'
print (@sql)
exec (@sql)

--select  *
--from #table_packkey3
--order by Sku


delete from #table_packkey
where Other like '�������' or Other like 'OK'

set @sql='
insert into #table_packkey
select 	rt1.Sku,
		rt1.Storer,
		null,
		rt1.QtyR,
		rt2.Other,
		null,
		rt1.Other
from #table_packkey2 as rt1
		left join #table_packkey3 as rt2 on rt1.sku=rt2.sku
											and rt1.storer=rt2.storer
											and rt1.QtyR=rt2.QtyR
	where rt1.Other=''�������'' and isnull(rt2.Other,'''')<>''OK''
'
print (@sql)
exec (@sql)

--select  *
--from #table_packkey
--order by Sku


update rt1 set rt1.Other = rt1.Other + '- ������������� �������; '
	from #table_packkey rt2 
		join #table_res1 rt1 on rt2.Storer = rt1.Storer 
							and rt2.Sku=rt1.Sku
							and rt2.QtyR=rt1.QtyR


select  OrderKey,
		Storer,
		Company,
		Sku,
		Descr,
		Qty,
		QtyR,
		Other
from #table_res1
order by Storer, Sku

drop table #table_res1
drop table #table_pick
drop table #table_ostatok
drop table #table_ostatokV
drop table #table_srok
drop table #table_packkey
drop table #table_packkey2
drop table #table_packkey3

