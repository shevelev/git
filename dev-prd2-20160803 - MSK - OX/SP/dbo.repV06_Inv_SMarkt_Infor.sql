-- =============================================
-- �����:		��������� ��������
-- ������:		������, �.�������
-- ���� ��������: 19.12.2009 (������)
-- ��������: ������� �������������� ���������� � S-Market � ����������� � Infor
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV06_Inv_SMarkt_Infor] ( 
									
	@wh varchar(30),
	@storer varchar(20),
	@datebegin datetime,
	@dateend datetime

)

as

create table #tp (
		whseid varchar(10) not null, -- �����
		batchkey varchar(50) null, -- � ��������� Infor
		storer varchar(15) null, -- ��������
		sku varchar(50) null, -- ��� ������
		descr varchar(60) null,
		loc varchar(10) null, -- ������
		editdate varchar(10) null, -- ����
		deltaqty decimal(22,2) null, -- �������
		kol int not null, -- ���-�� ����������
		kol_itrn int null -- ���-�� � Infor
)

create table #tp_itrn (
		whseid varchar(10) not null, -- �����
		storer varchar(15) null, -- ��������
		sku varchar(50) null, -- ��� ������
		loc varchar(10) null, -- ������
		editdate varchar(10) null, -- ����
		qty decimal(22,2) null -- �������
)

create table #tp_itrn2 (
		whseid varchar(10) not null, -- �����
		storer varchar(15) null, -- ��������
		sku varchar(50) null, -- ��� ������
		loc varchar(10) null, -- ������
		editdate varchar(10) null, -- ����
		qty decimal(22,2) null, -- �������
		kol_itrn int not null  -- ���-�� � Infor
)

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(10)

set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(10),@dateend+1,112)

/*����� ���������� � ���������� ���������� � S-Market*/
set @sql='
insert into #tp
select da.whseid whseid,
		da.batchkey batchkey,
		da.storerkey storerkey,
		da.sku sku,
		null,
		da.loc loc,
		convert(varchar(10),da.editdate,112) editdate,
		da.deltaqty deltaqty,
		count(*) kol,
		0
from dbo.DA_Adjustment da
		
	where 1=1 '+case when @storer ='�����' then 'and (da.storerkey=''000000001''
													or da.storerkey=''219''
													or da.storerkey=''5854''
													or da.storerkey=''6845''
													or da.storerkey=''92'')' 
												else 'and da.storerkey='''+@storer+'''' end + '
			and (da.editdate between '''+@bdate+''' and '''+@edate+''')
			and da.whseid = '''+@wh+'''
group by whseid, batchkey, storerkey, sku, loc, editdate, deltaqty
having count(*)>1
'
print (@sql)
exec (@sql)

--select *
--from #tp
--order by sku

/*������� �������������� �� Itrn*/
set @sql='
insert into #tp_itrn
select i.whseid whseid,
		i.storerkey storer,
		i.sku sku,
		i.toloc loc,
		convert(varchar(10),i.editdate,112) editdate,
		i.qty qty
from '+@wh+'.ITRN i
	where i.trantype=''AJ''
		and i.sourcetype=''ntrAdjustmentDetailAdd''
group by whseid, storerkey, sku, toloc, editdate, qty
'
print (@sql)
exec (@sql)

--select *
--from #tp_itrn
--order by sku

/*����� ���������� � �������������� �� Itrn*/
set @sql='
insert into #tp_itrn2
select i.whseid whseid,
		i.storer storer,
		i.sku sku,
		i.loc loc,
		convert(varchar(10),i.editdate,112) editdate,
		i.qty qty,
		count(*) kol_itrn
from #tp_itrn i
group by whseid, storer, sku, loc, editdate, qty
--having count(*)>1
'
print (@sql)
exec (@sql)

--select *
--from #tp_itrn2
--order by sku


/*����������� ������� ����� �����������*/
update rt1 set rt1.kol_itrn = rt2.kol_itrn
	from #tp_itrn2 rt2
		left join #tp rt1 on rt2.whseid = rt1.whseid
							and rt2.storer = rt1.storer
							and rt2.sku = rt1.sku 
							and rt2.loc = rt1.loc
							and rt2.editdate = rt1.editdate
							and rt2.qty = rt1.deltaqty

set @sql='
update tp set tp.descr = sk.descr,
				tp.storer = st.company
	from '+@wh+'.sku sk
		left join #tp tp on sk.storerkey = tp.storer
							and sk.sku = tp.sku 
		left join '+@wh+'.storer st on sk.storerkey = st.storerkey

'
print (@sql)
exec (@sql)

select *
from #tp
--order by sku

drop table #tp
drop table #tp_itrn
drop table #tp_itrn2

