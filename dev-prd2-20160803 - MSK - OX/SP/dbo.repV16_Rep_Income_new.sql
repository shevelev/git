-- =============================================
-- �����:		��������� ��������
-- ������:		������, �.�������
-- ���� ��������: 03.03.2010 (������)
-- ��������: ������� ����� �� ������� (�����)
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV16_Rep_Income_new] ( 
	@wh varchar(30),	
	@month varchar(2),
	@year varchar(4),							
	--@datebegin datetime,
	--@dateend datetime,
	@B219 float,
	@B92 float,
	@tekdate int
)

as

create table #table_Storer (
		Storerkey varchar(15) not null, -- ��������
		Company varchar(45) not null -- �������� ���������
)

create table #table_DocLinesCount (
		Storer varchar(15) not null, -- ��������
		Company varchar(45) not null, -- �������� ���������
		CountOrder int not null, -- ���-�� ����������
		CountOrderLine int not null, -- ���-�� ����� � ����������
		ReceiptLinesCount int not null, -- ���-�� ����� � ���������� �� �������
		OQTY decimal(22,5) not null, -- ����� ���-�� ����������� ������
		SQTY decimal(22,5) not null, -- ����� ���-�� ������������ ������
		SumOQTY decimal(22,5) not null, -- ���� �� ����� ���-�� ����������� ������
		SumSQTY decimal(22,5) not null, -- ���� �� ����� ���-�� ������������ ������
		PercentSum decimal(22,5) not null, -- ���������� ����������� �� ����
		PercentQty decimal(22,5) not null -- ���������� ����������� �� ���-��
)

create table #table_Trans (
		Storer varchar(15) not null, -- ��������
		Company varchar(45) not null, -- �������� ���������
		SummaTrans decimal(22,2) not null -- ����� ��������		
)

create table #table_Pallete (
		Storer varchar(15) not null, -- ��������
		Company varchar(45) not null, -- �������� ���������
		SummaPal decimal(22,2) not null -- ����� ��������������		
)

create table #table_Paket (
		Storer varchar(15) not null, -- ��������
		Company varchar(45) not null, -- �������� ���������
		SummaPak decimal(22,2) not null -- ���-�� ������� ����������		
)

create table #table_volume_ro (
		O_R varchar(1) not null,
		actDate datetime,
		storer varchar(15) not null,
		docNum varchar(30) not null, 
		externDocNum varchar(30) not null,
		RSumCube float null,
		OSumCube float null
)

create table #table_volume_ft (
		actDate datetime,
		storer varchar(15) not null,
		FTC float null
)

create table #table_volume_tmp (
		actDate datetime,
		RSumCube float null,
		OSumCube float null,
		storer varchar(15) not null,
)

create table #table_volume_res (
		actDate varchar(15),
		storer varchar(15) not null,
		na_0 float not null, 
		RSumCube float null,
		OSumCube float null,
		na_24 float not null
)

create table #table_volume (
		actDate varchar(15),
		storer varchar(15) not null,
		na_0 float not null, 
		RSumCube float null,
		OSumCube float null,
		na_24 float not null,
		P400 float not null
)

create table #result_table (
		Storer varchar(15) not null, -- ��������
		Company varchar(45) not null, -- �������� ���������
		Operation varchar(45) not null, -- ��� ��������
		Number int not null, -- ����� �������� ��� ����������
		Ed varchar(45) not null, -- ������� ���������
		--Expense float null, -- ������
		--Arrival float null, -- ������
		Total float null, -- �����
		Tariff varchar(10) not null, -- �����
		TotalRub decimal(22,2) null -- ����� � ���.
)

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(20),
		@tdate varchar(10),
		@edateStart varchar(10),
		@kolday decimal(22,2),
		@kolt decimal(22,2)

--set @bdate=convert(varchar(10),@datebegin,112)
--set @edate=convert(varchar(10),@dateend+1,112)
--set @edateStart=convert(varchar(10),@dateend,112)
if @tekdate=1 
	begin
		set @tdate=convert(varchar(10),getdate(),112)
		set @bdate=substring(@tdate,1,6)+'01'
		set @edate=convert(varchar(20),dateadd(s,-1,dateadd(day,1,cast((@tdate)as datetime))),13)
		set @edateStart=@tdate--convert(varchar(10),cast(@tdate as datetime)-1,112)
		set @kolt=(datediff(day,cast(@bdate as datetime),dateadd(day,1,cast(@tdate as datetime))))
	end
else
	begin
		set @bdate=@year+@month+'01'
		--set @edate=convert(varchar(10),dateadd(month,1,cast((@year+@month+'01')as datetime)),112)
		set @edate=convert(varchar(20),dateadd(s,-1,dateadd(month,1,cast((@bdate)as datetime))),13)
		set @edateStart=convert(varchar(10),dateadd(month,1,cast((@bdate)as datetime))-1,112)
		set @kolt=(datediff(day,cast(@bdate as datetime),dateadd(month,1,cast(@bdate as datetime))))
	end

set @kolday=(datediff(day,cast(@bdate as datetime),dateadd(month,1,cast(@bdate as datetime))))

print('@tdate '+@tdate)
print('@bdate '+@bdate)
print('@edate '+@edate)
print('@edateStart '+@edateStart)
print(@kolt)
print(@kolday)

set @sql='
insert into #table_Storer
select 	storer.storerkey Storerkey,
		storer.company Company
from '+@wh+'.STORER storer
where storer.type=''1''
'
print (@sql)
exec (@sql)

--select *
--from #table_Storer

/*���������� ����� ��� ������ � ���������*/
-- 
set @sql='
insert into #table_DocLinesCount
exec dbo.repV13_DocLinesCount '''+@wh+''','''+@bdate+''','''+@edateStart+'''
'
print (@sql)
exec (@sql)

--select *
--from #table_DocLinesCount

--
set @sql='
insert into #table_Trans
select 	storer.storerkey Storer,
		storer.company Company,
		sum(cast(isnull(tasn.udf2,0)as decimal(22,2))) SummaTrans
from '+@wh+'.TRANSASN tasn
left join #table_Storer storer on tasn.customerkey=storer.storerkey
where tasn.adddate between '''+@bdate+''' and '''+@edate+'''
group by storer.storerkey, storer.company
'
--where '+case when @tekdate=0 
--					then 'tasn.adddate between '''+@bdate+''' and '''+@edate+''''
--					else 'tasn.adddate between '''+@bdate+''' and '''+@tdate+''''
--		end+'

print (@sql)
exec (@sql)

--select *
--from #table_Trans

--
set @sql='
insert into #table_Pallete
select  storer.storerkey Storer,
		storer.company Company,
		sum(cast(isnull(ord.CONTAINERQTY,0)as decimal(22,2))) SummaPal
from '+@wh+'.orders ord
left join #table_Storer storer on ord.storerkey=storer.storerkey
where ord.DELIVERYDATE2 between '''+@bdate+''' and  '''+@edate+'''
		and (ord.status=''92'' or ord.status=''95'')
group by  storer.storerkey, storer.company
'
--'+case when @tekdate=0 
--					then 'ord.DELIVERYDATE2 between '''+@bdate+''' and  '''+@edate+''''
--					else 'ord.DELIVERYDATE2 between '''+@bdate+''' and  '''+@tdate+''''
--		end+'
print (@sql)
exec (@sql)

--select *
--from #table_Pallete

--
set @sql='
insert into #table_Paket
select  storer.storerkey Storer,
		storer.company Company,
		count(ord.orderkey) SummaPak
from '+@wh+'.orders ord
left join #table_Storer storer on ord.storerkey=storer.storerkey
where ord.DELIVERYDATE2 between '''+@bdate+''' and  '''+@edate+'''
		and (ord.status=''92'' or ord.status=''95'')
		and (ord.susr2 not like ''��������� �����������''
				and ord.susr2 not like ''������� �����''
				and ord.susr2 not like ''������� ������ ����������''
				and ord.susr2 not like ''�������������� (���������)''
				and ord.susr2 not like ''������������ ������''
				and ord.susr2 not like ''���������� 2-�� ���%''
				and ord.susr2 not like ''��������''
				and ord.susr2 not like ''�������� �������'')
group by  storer.storerkey, storer.company
'
--'+case when @tekdate=0 
--					then 'ord.DELIVERYDATE2 between '''+@bdate+''' and  '''+@edate+''''
--					else 'ord.DELIVERYDATE2 between '''+@bdate+''' and  '''+@tdate+''''
--		end+'
print (@sql)
exec (@sql)

--select *
--from #table_Paket

/*--��������
insert into #result_table
select  tDLC.Storer Storer,
		tDLC.Company Company,
		'������' Operation,
		1 Number,
		'��.' Ed,
		tDLC.CountOrder Expense,
		tDLC.ReceiptLinesCount Arrival,
		(tDLC.CountOrder+tDLC.ReceiptLinesCount) Total,
		'10 ���.' Tariff,
		(tDLC.CountOrder+tDLC.ReceiptLinesCount)*10 TotalRub
from #table_DocLinesCount tDLC
		where tDLC.Storer='219' or tDLC.Storer='92'*/
--
insert into #result_table
select  tDLC.Storer Storer,
		tDLC.Company Company,
		'������ ������' Operation,
		1 Number,
		'��.' Ed,
		--tDLC.CountOrder Expense,
		--tDLC.ReceiptLinesCount Arrival,
		tDLC.CountOrder Total,
		'' Tariff,
		null TotalRub
from #table_DocLinesCount tDLC
		where tDLC.Storer='219' or tDLC.Storer='92'

--
insert into #result_table
select  tDLC.Storer Storer,
		tDLC.Company Company,
		'������ ������' Operation,
		2 Number,
		'��.' Ed,
		--tDLC.CountOrder Expense,
		--tDLC.ReceiptLinesCount Arrival,
		tDLC.ReceiptLinesCount Total,
		'' Tariff,
		null TotalRub
from #table_DocLinesCount tDLC
		where tDLC.Storer='219' or tDLC.Storer='92'

--
insert into #result_table
select  tDLC.Storer Storer,
		tDLC.Company Company,
		'������ �����' Operation,
		3 Number,
		'��.' Ed,
		--tDLC.CountOrder Expense,
		--tDLC.ReceiptLinesCount Arrival,
		(tDLC.CountOrder+tDLC.ReceiptLinesCount) Total,
		'10 ���.' Tariff,
		(tDLC.CountOrder+tDLC.ReceiptLinesCount)*10 TotalRub
from #table_DocLinesCount tDLC
		where tDLC.Storer='219' or tDLC.Storer='92'

--select *
--from #result_table

--
insert into #result_table
select  tT.Storer Storer,
		tT.Company Company,
		'�������' Operation,
		4 Number,
		'���.' Ed,
		--null Expense,
		--tT.SummaTrans Arrival,
		tT.SummaTrans Total,
		'1%' Tariff,
		(tT.SummaTrans*1)/100 TotalRub
from #table_Trans tT
		where tT.Storer='219' or tT.Storer='92'

--select *
--from #result_table

--
insert into #result_table
select  tP.Storer Storer,
		tP.Company Company,
		'��������������' Operation,
		5 Number,
		'��.' Ed,
		--null Expense,
		--tP.SummaPal Arrival,
		tP.SummaPal Total,
		'40 ���.' Tariff,
		tP.SummaPal*40 TotalRub
from #table_Pallete tP
		where tP.Storer='219' or tP.Storer='92'


--select *
--from #result_table

--
insert into #result_table
select  tPak.Storer Storer,
		tPak.Company Company,
		'����� ����������' Operation,
		6 Number,
		'��.' Ed,
		--null Expense,
		--tP.SummaPal Arrival,
		tPak.SummaPak Total,
		'45 ���.' Tariff,
		tPak.SummaPak*45 TotalRub
from #table_Paket tPak
		where tPak.Storer='219' or tPak.Storer='92'


--select *
--from #result_table

insert into #result_table
select  tS.Storerkey Storer,
		tS.Company Company,
		'�������� �������' Operation,
		7 Number,
		'��.' Ed,
		--null Expense,
		--null Arrival,
		sum(fto.Qty) Total,
		cast(cast(300/@kolday as decimal(22,2)) as varchar(10))+' ���.' Tariff,
		(300/@kolday)*sum(fto.Qty) TotalRub
from #table_Storer tS
left join adminsPRD1.dbo.FT_ostatki fto on tS.storerkey=fto.storerkey
		where tS.Storerkey='219' 
				and fto.sku like 'REKLAM%'
				and (fto.date_CN between ''+@bdate+'' and  ''+@edateStart+'' ) 
group by tS.Storerkey, tS.Company

--select *
--from #result_table

--
insert into #result_table
select  tS.Storerkey Storer,
		tS.Company Company,
		'�������� �������' Operation,
		7 Number,
		'��.' Ed,
		--null Expense,
		--null Arrival,
		sum(fto.Qty) Total,
		cast(cast(300/@kolday as decimal(22,2)) as varchar(10))+' ���.' Tariff,
		(300/@kolday)*sum(fto.Qty) TotalRub
from #table_Storer tS
left join adminsPRD1.dbo.FT_ostatki fto on tS.storerkey=fto.storerkey
		where tS.Storerkey='92'
				and fto.sku like 'REKLAM%'
				and (fto.date_CN between ''+@bdate+'' and  ''+@edateStart+'' ) 
group by tS.Storerkey, tS.Company

--select *
--from #result_table

--
insert into #result_table
select  tS.Storerkey Storer,
		tS.Company Company,
		'����, �������, ������������' Operation,
		8 Number,
		'��.' Ed,
		--null Expense,
		--null Arrival,
		null Total,
		'' Tariff,
		@B219 TotalRub
from #table_Storer tS
		where tS.Storerkey='219'

--select *
--from #result_table

--
insert into #result_table
select  tS.Storerkey Storer,
		tS.Company Company,
		'����, �������, ������������' Operation,
		8 Number,
		'��.' Ed,
		--null Expense,
		--null Arrival,
		null Total,
		'' Tariff,
		@B92 TotalRub
from #table_Storer tS
		where tS.Storerkey='92'

--select *
--from #result_table

--
insert into #result_table
select  tS.Storerkey Storer,
		tS.Company Company,
		'�������� ����������' Operation,
		9 Number,
		'��.' Ed,
		--null Expense,
		--null Arrival,
		null Total,
		'0,26 ���.' Tariff,
		null TotalRub
from #table_Storer tS
		where tS.Storerkey='219' or tS.Storerkey='92'

--select *
--from #result_table

--
insert into #result_table
select  tS.Storerkey Storer,
		tS.Company Company,
		'�������� ��������' Operation,
		10 Number,
		'��.' Ed,
		--null Expense,
		--null Arrival,
		null Total,
		'0,4 ���.' Tariff,
		null TotalRub
from #table_Storer tS
		where tS.Storerkey='219' or tS.Storerkey='92'

--select *
--from #result_table

/*���������� ����� ��� �.����� � ����*/
-- 
set @sql='
insert into #table_volume_ro
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
where (po.storerkey=''000000001'' or po.storerkey=''6845'')
		and (rec.editdate between '''+@bdate+''' and '''+@edate+''')
		and (po.susr4 not like ''%����������%'' or po.susr4 is null)
		and pd.status=11
group by 
		rec.editdate,
		po.storerkey,
		rec.receiptkey, 
		po.EXTERNPOKEY
order by rec.editdate
'
--'+case when @tekdate=0 
--					then 'and (rec.editdate between '''+@bdate+''' and '''+@edate+''')'
--					else 'and (rec.editdate between '''+@bdate+''' and '''+@tdate+''')'
--		end+'
print (@sql)
exec (@sql)

--select *
--from #table_volume_ro

--
set @sql='
insert into #table_volume_ro
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
where (ord.storerkey=''000000001'' or ord.storerkey=''6845'')
		and ord.status>=92
		and (ord.editdate between '''+@bdate+''' and '''+@edate+''') 		
group by 
		ord.orderkey, 
		ord.storerkey,
		ord.EXTERNORDERKEY
		
order by actDate
'
--'+case when @tekdate=0 
--					then 'and (ord.editdate between '''+@bdate+''' and '''+@edate+''') '
--					else 'and (ord.editdate between '''+@bdate+''' and '''+@tdate+''') '
--		end+'
print (@sql)
exec (@sql)

--select *
--from #table_volume_ro

--
set @sql='
insert into #table_volume_ft
select ft.Date_cn actDate,
		ft.storerkey storer,
		sum(ft.qty*sk.stdcube) FTC
from adminsPRD1.dbo.FT_ostatki FT
left join '+@wh+'.sku sk on ft.storerkey=sk.storerkey and ft.sku=sk.sku
where (ft.storerkey=''000000001'' or ft.storerkey=''6845'') 
		and (ft.date_cn between dateadd("d",-1,'''+@bdate+''') and dateadd("d",1,'''+@edate+'''))
group by ft.Date_cn,
		ft.storerkey
order by ft.Date_cn, ft.storerkey
'
--'+case when @tekdate=0 
--					then 'and (ft.date_cn between dateadd("d",-1,'''+@bdate+''') and '''+@edate+''')'
--					else 'and (ft.date_cn between dateadd("d",-1,'''+@bdate+''') and '''+@tdate+''')'
--		end+'
print (@sql)
exec (@sql)

--select *
--from #table_volume_ft


set @sql='
insert into #table_volume_tmp
select convert(varchar(10),rt.actDate,112) actDate, 
		sum(rt.RSumCube) RSumCube, 
		sum(rt.OSumCube) OSumCube,
		rt.storer
from #table_volume_ro rt
group by convert(varchar(10),rt.actDate,112), rt.storer
'

print (@sql)
exec (@sql)

--select *
--from #table_volume_tmp

--
set @sql='
insert into #table_volume_res
select convert(varchar(10),ft.actDate,104) actDate, 
		ft.storer storer, 
		fto.ftc na_0, 
		isnull(tmp.RSumCube,0) RSumCube, 
		isnull(tmp.OSumCube,0) OSumCube, 
		ft.ftc na_24
from #table_volume_ft ft
	left join #table_volume_tmp tmp on ft.actDate=tmp.actDate and ft.storer=tmp.storer
	left join #table_volume_ft fto on ft.actDate=dateadd("d", 1,fto.actDate) and ft.storer=fto.storer
where (ft.actDate between '''+@bdate+''' and '''+@edate+''')
order by ft.actDate
'
--'+case when @tekdate=0 
--					then '(ft.actDate between '''+@bdate+''' and dateadd("d",-1,'''+@edate+'''))'
--					else '(ft.actDate between '''+@bdate+''' and dateadd("d",-1,'''+@tdate+'''))'
--		end+'
print (@sql)
exec (@sql)

--select *
--from #table_volume_res

--
insert into #result_table
select  tS.Storerkey Storer,
		tS.Company Company,
		'�������� �������������� ������' Operation,
		1 Number,
		'�3' Ed,
		--null Expense,
		--null Arrival,
		(400/@kolday)*@kolt Total,
		'300 ���.' Tariff,
		((400/@kolday)*@kolt)*300 TotalRub
from #table_Storer tS
		where tS.Storerkey='000000001'

--select *
--from #result_table

-- 
insert into #table_volume
select 	tv_res.actDate actDate,
		tv_res.storer storer,
		tv_res.na_0 na_0,
		tv_res.RSumCube RSumCube,
		tv_res.OSumCube OSumCube,
		tv_res.na_24 na_24,
		(tv_res.na_24-400) P400
from #table_volume_res tv_res

--select *
--from #table_volume

-- 
update rt set rt.P400 = 0
	from #table_volume rt
		where rt.P400<0

--select *
--from #table_volume

-- 
insert into #result_table
select  tV.Storer Storer,
		storer.Company Company,
		'���������� ��������� ������ ��������' Operation,
		2 Number,
		'�3' Ed,
		--null Expense,
		--null Arrival,
		sum(tV.P400) Total,
		cast(cast(340/@kolday as decimal(22,2)) as varchar(10))+' ���.' Tariff,
		sum(tV.P400)*cast(340/@kolday as decimal(22,2)) TotalRub
from #table_volume tV
left join #table_Storer storer on tV.storer=storer.storerkey
where tV.storer='000000001'
group by tV.Storer, storer.Company

--select *
--from #result_table

/*-- ��������
--insert into #result_table
--select  tV.Storer Storer,
--		storer.Company Company,
--		'����-�����' Operation,
--		'�3' Ed,
--		sum(tV.OSumCube) Expense,
--		sum(tV.RSumCube) Arrival,
--		(sum(tV.OSumCube)+sum(tV.RSumCube)) Total,
--		'120 ���.' Tariff,
--		(sum(tV.OSumCube)+sum(tV.RSumCube))*120 TotalRub
--from #table_volume tV
--left join #table_Storer storer on tV.storer=storer.storerkey
--where tV.storer='000000001'
--group by tV.Storer, storer.Company*/

--
insert into #result_table
select  tV.Storer Storer,
		storer.Company Company,
		'����' Operation,
		3 Number,
		'�3' Ed,
		--sum(tV.OSumCube) Expense,
		--sum(tV.RSumCube) Arrival,
		sum(tV.RSumCube) Total,
		'' Tariff,
		null TotalRub
from #table_volume tV
left join #table_Storer storer on tV.storer=storer.storerkey
where tV.storer='000000001'
group by tV.Storer, storer.Company

--
insert into #result_table
select  tV.Storer Storer,
		storer.Company Company,
		'�����' Operation,
		4 Number,
		'�3' Ed,
		--sum(tV.OSumCube) Expense,
		--sum(tV.RSumCube) Arrival,
		sum(tV.OSumCube) Total,
		'' Tariff,
		null TotalRub
from #table_volume tV
left join #table_Storer storer on tV.storer=storer.storerkey
where tV.storer='000000001'
group by tV.Storer, storer.Company

--
insert into #result_table
select  tV.Storer Storer,
		storer.Company Company,
		'����-����� �����' Operation,
		5 Number,
		'�3' Ed,
		--sum(tV.OSumCube) Expense,
		--sum(tV.RSumCube) Arrival,
		(sum(tV.OSumCube)+sum(tV.RSumCube)) Total,
		'120 ���.' Tariff,
		(sum(tV.OSumCube)+sum(tV.RSumCube))*120 TotalRub
from #table_volume tV
left join #table_Storer storer on tV.storer=storer.storerkey
where tV.storer='000000001'
group by tV.Storer, storer.Company

--select *
--from #result_table

-- 
insert into #result_table
select  tV.Storer Storer,
		storer.Company Company,
		'�������� ������' Operation,
		1 Number,
		'�3' Ed,
		--null Expense,
		--null Arrival,
		sum(tV.na_24) Total,
		cast(cast(360/@kolday as decimal(22,2)) as varchar(10))+' ���.' Tariff,
		sum(tV.na_24)*cast(360/@kolday as decimal(22,2)) TotalRub
from #table_volume_res tV
left join #table_Storer storer on tV.storer=storer.storerkey
where tV.storer='6845'
group by tV.Storer, storer.Company

--select *
--from #result_table

/*-- ��������
insert into #result_table
select  tV.Storer Storer,
		storer.Company Company,
		'����-�����' Operation,
		'�3' Ed,
		sum(tV.OSumCube) Expense,
		sum(tV.RSumCube) Arrival,
		(sum(tV.OSumCube)+sum(tV.RSumCube)) Total,
		'120 ���.' Tariff,
		(sum(tV.OSumCube)+sum(tV.RSumCube))*120 TotalRub
from #table_volume_res tV
left join #table_Storer storer on tV.storer=storer.storerkey
where tV.storer='6845'
group by tV.Storer, storer.Company*/

--
insert into #result_table
select  tV.Storer Storer,
		storer.Company Company,
		'����' Operation,
		2 Number,
		'�3' Ed,
		--sum(tV.OSumCube) Expense,
		--sum(tV.RSumCube) Arrival,
		sum(tV.RSumCube) Total,
		'' Tariff,
		null TotalRub
from #table_volume_res tV
left join #table_Storer storer on tV.storer=storer.storerkey
where tV.storer='6845'
group by tV.Storer, storer.Company

--
insert into #result_table
select  tV.Storer Storer,
		storer.Company Company,
		'�����' Operation,
		3 Number,
		'�3' Ed,
		--sum(tV.OSumCube) Expense,
		--sum(tV.RSumCube) Arrival,
		sum(tV.OSumCube) Total,
		'' Tariff,
		null TotalRub
from #table_volume_res tV
left join #table_Storer storer on tV.storer=storer.storerkey
where tV.storer='6845'
group by tV.Storer, storer.Company

--
insert into #result_table
select  tV.Storer Storer,
		storer.Company Company,
		'����-����� �����' Operation,
		4 Number,
		'�3' Ed,
		--sum(tV.OSumCube) Expense,
		--sum(tV.RSumCube) Arrival,
		(sum(tV.OSumCube)+sum(tV.RSumCube)) Total,
		'120 ���.' Tariff,
		(sum(tV.OSumCube)+sum(tV.RSumCube))*120 TotalRub
from #table_volume_res tV
left join #table_Storer storer on tV.storer=storer.storerkey
where tV.storer='6845'
group by tV.Storer, storer.Company

--select *
--from #result_table

/*���������� ����� ��� ����������������*/
insert into #table_Storer 
Values('0','����������������')

--
insert into #result_table
select  tS.Storerkey Storer,
		tS.Company Company,
		'��������' Operation,
		1 Number,
		'��' Ed,
		--null Expense,
		--null Arrival,
		null Total,
		'' Tariff,
		null TotalRub
from #table_Storer tS
		where tS.Storerkey='0'

select *
from #result_table
order by company, number


drop table #table_Storer
drop table #table_DocLinesCount
drop table #table_Trans
drop table #table_Pallete
drop table #table_Paket
drop table #table_volume_ro
drop table #table_volume_ft
drop table #table_volume_tmp
drop table #table_volume_res
drop table #table_volume
drop table #result_table

