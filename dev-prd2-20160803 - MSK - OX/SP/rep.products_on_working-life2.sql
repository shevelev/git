-- =============================================
-- �����:		��������� ��������
-- ������:		������, �.�������
-- ���� ��������: 21.01.2010 (������)
-- ��������: ����� ����� �� ������ �������� ���
--	...
-- =============================================
ALTER PROCEDURE [rep].[products_on_working-life2] ( 
									
	@wh varchar(30),
	@storer varchar(15),
	@asn varchar(15),
	@day int
)

as

create table #table_result (
		Sku varchar(50) not null, -- ��� ������
		Descr varchar(60) null, -- �������� ������
		Qty decimal(22,0) not null, -- ���-�� ������
		NumberPal varchar(18) null, -- � �������
		Date datetime not null, -- ���� �������
		Proizved datetime null, -- ����������
		GodDo datetime null, -- ����� ��
		KolDay int null, -- ���-�� ���� ��������
		SrokGod datetime null -- ���� ��������
)

declare @sql varchar(max)

set @sql='
insert into #table_result
select 	rd.sku Sku,
		sk.descr Descr,
		rd.qtyreceived Qty,
		rd.toid NumberPal,
		convert(datetime,convert(varchar(11),r.receiptdate,112)) Date,
		rd.lottable04 Proizved,
		null GodDo,
		sk.shelflife KolDay,
		dateadd(dy,sk.shelflife,rd.lottable04) SrokGod
from '+@wh+'.RECEIPTDETAIL as rd
	left join '+@wh+'.sku as sk on rd.sku=sk.sku and rd.storerkey=sk.storerkey
	left join '+@wh+'.RECEIPT as r on rd.receiptkey=r.receiptkey
where rd.receiptkey='''+@asn+'''
		and rd.storerkey='''+@storer+'''
		and sk.lottablevalidationkey=''MANUFAC''
		and rd.qtyreceived<>0
'
print (@sql)
exec (@sql)

--select *
--from #table_result

set @sql='
insert into #table_result
select 	rd.sku Sku,
		sk.descr Descr,
		rd.qtyreceived Qty,
		rd.toid NumberPal,
		convert(datetime,convert(varchar(11),r.receiptdate,112)) Date,
		null Proizved,
		rd.lottable05 GodDo,
		null KolDay,
		rd.lottable05 SrokGod
from '+@wh+'.RECEIPTDETAIL as rd
	left join '+@wh+'.sku as sk on rd.sku=sk.sku and rd.storerkey=sk.storerkey
	left join '+@wh+'.RECEIPT as r on rd.receiptkey=r.receiptkey
where rd.receiptkey='''+@asn+'''
		and rd.storerkey='''+@storer+'''
		and sk.lottablevalidationkey=''EXPIRED''
		and rd.qtyreceived<>0
'
print (@sql)
exec (@sql)

select  *
from #table_result
where cast(SrokGod - Date as int)<=@day
order by sku

drop table #table_result

