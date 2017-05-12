-- =============================================
-- �����:		��������� ��������
-- ������:		������, �.�������
-- ���� ��������: 09.12.2009 (������)
-- ��������: ����� ������ � ������ ���������
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV05_Rabota_Personala] ( 
									
	@wh varchar(30),
	@storer varchar(20),
	@datebegin datetime,
	@dateend datetime,
	@who varchar (20)

)

as
create table #table_oper (
		Storer varchar(15) not null, -- ��������
		Sku varchar(50) not null, -- ��� ������
		Infor_login varchar(18) not null, -- Login
		Type_oper varchar(10) not null, -- �������� (��� ��������)
		Descr_oper varchar(30) null, -- �������� ��������
		Kol int not null, -- ���-�� ��������
		Rub decimal(22,2) not null, -- ������
		Summ decimal(22,2) not null -- �����
)

create table #table_tariff (
		Storer varchar(15) not null, -- ��������
		Sku varchar(50) not null, -- ��� ������
		Type_oper varchar(10) not null, -- ��� ��������
		Rub decimal(22,2) not null -- ������
)

create table #table_priem (
		Infor_login varchar(18) not null, -- Login
		Priem_kol int null, -- ���-�� �������� �� �������
		Summ decimal(22,2) null -- �����
)

create table #table_razm (
		Infor_login varchar(18) not null, -- Login
		Razm_kol int null, -- ���-�� �������� �� ����������
		Summ decimal(22,2) null -- �����
)

create table #table_perem (
		Infor_login varchar(18) not null, -- Login
		Perem_kol int null, -- ���-�� �������� �� �����������
		Summ decimal(22,2) null -- �����
)

create table #table_popol (
		Infor_login varchar(18) not null, -- Login
		Popol_kol int null, -- ���-�� �������� �� ����������
		Summ decimal(22,2) null -- �����
)

create table #table_korrekt (
		Infor_login varchar(18) not null, -- Login
		Korrekt_kol int null, -- ���-�� �������� �� �������������
		Summ decimal(22,2) null -- �����
)

create table #table_otbor (
		Infor_login varchar(18) not null, -- Login
		Otbor_kol int null, -- ���-�� �������� �� ������
		Summ decimal(22,2) null -- �����
)

create table #result_table (
		Infor_login varchar(18) null, -- Login
		FIO varchar(40) null, -- �������, ���
		Priem int null, -- �������
		Razm int null, -- ����������
		Perem int null, -- �����������
		Popol int null, -- ����������
		Korrekt int null, -- �������������
		Otbor int null, -- �����
		Summ decimal(22,2) null -- �����
)

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(10)

set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(10),@dateend+1,112)

/*�������� ������� ��������
� ������ ������� ���������� ������ � ���, ����� �������� �������� ��� ��� ���� ������������
..����������� ������ ITRN � PL_USR (�� ���� ������������� ������� ���� � ����� �����),
��� ��������� ������� � ����� ������������
*/
set @sql='
insert into #table_oper
select  i.storerkey Storer,
		i.sku Sku,
		i.addwho Infor_Login, 
		i.trantype Type_oper, 
		i.sourcetype Descr_oper, 
		count(serialkey) Kol,
		0,
		0
from '+@wh+'.ITRN i 
where 1=1 '+case when @storer ='�����' then 'and (i.storerkey=''000000001''
													or i.storerkey=''219''
													or i.storerkey=''5854''
													or i.storerkey=''6845''
													or i.storerkey=''92'')' 
												else 'and i.storerkey='''+@storer+'''' end + '
			and (i.editdate between '''+@bdate+''' and '''+@edate+''')
			'+case when @who is null then '' else 'and i.addwho = '''+@who+'''' end + '
			and i.sourcetype != ''SHORTPICK''
group by i.storerkey, i.sku, i.addwho, i.trantype, i.sourcetype
order by i.storerkey, i.sku, i.addwho, i.trantype, i.sourcetype
'

print (@sql)
exec (@sql)


/*���������� ������� ��������.
 ����������� ���� ��������*/
update #table_oper 
set	Type_oper = 
	case Type_oper
		--when 'WD' then '6'--'��������'
		when 'AJ' then
			case Descr_oper 
				when 'ntrAdjustmentDetailAdd' then '4'--'�������������'
				when 'ntrAdjustmentDetailUnreceive' then '6'--'-����������� ��������'
				else '6'--'-����������� ��������'
			end
		when 'DP' then
			case Descr_oper 
				when 'ntrReceiptDetailAdd' then '1'--'�������'
				when 'ntrTransferDetailAdd' then '6'--'-����������� ��������'
				else '6'--'-����������� ��������'
			end
		when 'MV' then 
			case Descr_oper 
				when 'NSPRFPA02' then '2'--'����������'
				when 'NSPRFRL01' then '3'--'�����������'
				when 'nspRFTRP01' then '5'--'����������'
				when 'ntrTaskDetailUpdate' then '2'--'����������'
				when 'PICKING' then 'HO'
				when '' then '3'--'�����������'
				else '6'--'-����������� ��������'
			end
			else '6'--'-����������� ��������'
		end

--select *
--from #table_oper

/*�������� ������� ������
� ������ ������� ���������� ������ �� ������� �� ��� ��������
..����������� ������ SKU � TARIFFDETAIL (�� �������� ������)
*/
set @sql='
insert into #table_tariff
select  sk.storerkey Storer,
		sk.sku Sku,
		isnull(td.chargetype,'' '') Type_oper,
		isnull(td.rate, 0) Rub
from '+@wh+'.sku sk
	left join '+@wh+'.tariffdetail td on sk.busr3=td.descrip 
											or sk.busr2=td.descrip 
											or sk.busr1=td.descrip
	where 1=1 '+case when @storer ='�����' then 'and (sk.storerkey=''000000001''
													or sk.storerkey=''219''
													or sk.storerkey=''5854''
													or sk.storerkey=''6845''
													or sk.storerkey=''92'')' 
												else 'and sk.storerkey='''+@storer+'''' end + '

order by sk.storerkey, sk.sku
'

print (@sql)
exec (@sql)

--select *
--from #table_tariff
--�������� �� ������� �������
--select tab_t.Storer,
--		tab_t.Sku,
--		tab_t.Type_oper,
--		tab_t.Rub,
--		sk.skugroup2
--from #table_tariff tab_t
--left join wh1.sku sk on tab_t.storer=sk.storerkey and tab_t.sku=sk.sku
--where tab_t.Type_oper=''

/*���������� ������� ��������.
 ����������� ������� � ����� �� ��������*/
update rt1 set rt1.Rub = rt2.Rub,
				rt1.Summ = rt1.Kol * rt2.Rub
	from #table_tariff rt2 
		join #table_oper rt1 on rt2.Storer = rt1.Storer 
							and rt2.Sku=rt1.Sku 
							and rt2.Type_oper=rt1.Type_oper

--select *
--from #table_oper

--�������� �� ������� �������
--select tab_op.Storer,
--		tab_op.Sku,
--		tab_op.Infor_Login, 
--		tab_op.Type_oper, 
--		tab_op.Descr_oper, 
--		tab_op.Kol,
--		tab_op.Rub,
--		tab_op.Summ,
--		sk.Skugroup2		
--from #table_oper tab_op
--left join wh1.sku sk on tab_op.storer=sk.storerkey and tab_op.sku=sk.sku
--where tab_op.Type_oper='HO'
--		and tab_op.rub=0


/*�������� ������ ���������� �� ���������
..
*/
insert into #table_priem
select TabO.Infor_login Infor_login,
		Sum(TabO.kol) Priem_kol,
		Sum(TabO.Summ) Summ
from #table_oper TabO
	where TabO.Type_oper='1'
group by TabO.Infor_login
order by TabO.Infor_login

--select *
--from #table_priem

insert into #table_razm
select TabO.Infor_login Infor_login,
		Sum(TabO.kol) Razm_kol,
		Sum(TabO.Summ) Summ
from #table_oper TabO
	where TabO.Type_oper='2'
group by TabO.Infor_login
order by TabO.Infor_login

--select *
--from #table_razm

insert into #table_perem
select TabO.Infor_login Infor_login,
		Sum(TabO.kol) Perem_kol,
		Sum(TabO.Summ) Summ
from #table_oper TabO
	where TabO.Type_oper='3'
group by TabO.Infor_login
order by TabO.Infor_login

--select *
--from #table_perem

insert into #table_popol
select TabO.Infor_login Infor_login,
		Sum(TabO.kol) Popol_kol,
		Sum(TabO.Summ) Summ
from #table_oper TabO
	where TabO.Type_oper='5'
group by TabO.Infor_login
order by TabO.Infor_login

--select *
--from #table_popol

insert into #table_korrekt
select TabO.Infor_login Infor_login,
		Sum(TabO.kol) Korrekt_kol,
		Sum(TabO.Summ) Summ
from #table_oper TabO
	where TabO.Type_oper='4'
group by TabO.Infor_login
order by TabO.Infor_login

--select *
--from #table_korrekt

insert into #table_otbor
select TabO.Infor_login Infor_login,
		Sum(TabO.kol) Otbor_kol,
		Sum(TabO.Summ) Summ
from #table_oper TabO
	where TabO.Type_oper='HO'
group by TabO.Infor_login
order by TabO.Infor_login

--select *
--from #table_otbor

/*�������� �������������� �������
..
*/

insert into #result_table
select u.usr_login Infor_login,
		u.usr_name FIO,
		isnull(TabPri.Priem_kol,0) Priem,
		isnull(TabRaz.Razm_kol,0) Razm,
		isnull(TabPer.Perem_kol,0) Perem,
		isnull(TabPop.Popol_kol,0) Popol,
		isnull(TabKor.Korrekt_kol,0) Korrekt,
		isnull(TabOtb.Otbor_kol,0) Otbor,
		(isnull(TabPri.Summ,0) + isnull(TabRaz.Summ,0)
			+ isnull(TabPer.Summ,0) + isnull(TabPop.Summ,0)
			+ isnull(TabKor.Summ,0) + isnull(TabOtb.Summ,0)) Summ
from ssaadmin.pl_usr u
		left join #table_priem TabPri on u.usr_login=TabPri.Infor_login
		left join #table_razm TabRaz on u.usr_login=TabRaz.Infor_login
		left join #table_perem TabPer on u.usr_login=TabPer.Infor_login
		left join #table_popol TabPop on u.usr_login=TabPop.Infor_login
		left join #table_korrekt TabKor on u.usr_login=TabKor.Infor_login
		left join #table_otbor TabOtb on u.usr_login=TabOtb.Infor_login


/*���������� �������������� �������.
 �������� ������������� ��� ��������*/
delete from #result_table 
where Priem = 0
		and	Razm = 0
		and	Perem = 0
		and	Popol = 0
		and Korrekt = 0
		and	Otbor = 0

select Infor_login,
		FIO,
		Priem,
		Razm,
		Perem,
		Popol,
		Korrekt,
		Otbor,
		Summ
from #result_table
order by FIO

drop table #table_oper
drop table #table_tariff
drop table #table_priem
drop table #table_razm
drop table #table_perem
drop table #table_popol
drop table #table_korrekt
drop table #table_otbor
drop table #result_table

