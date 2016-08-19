-- =============================================
-- �����:		��������� ��������
-- ������:		������, �.�������
-- ���� ��������: 17.12.2009 (������)
-- ��������: ����������� ������ � ������ ���������
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV05_Rabota_Personala_Detail] ( 
									
	@wh varchar(30),
	@storer varchar(20),
	@datebegin datetime,
	@dateend datetime,
	@who varchar (20)

)

as
create table #table_oper (
		Storer varchar(15) not null, -- ��������
		Company varchar(45) null,
		Sku varchar(50) not null, -- ��� ������
		CARTONGROUP varchar(10) not null,
		Infor_login varchar(18) not null, -- Login
		FIO varchar(40) null, -- �������, ���
		Type_oper varchar(10) not null, -- �������� (��� ��������)
		Descr_oper varchar(30) null, -- �������� ��������
		Kol int not null, -- ���-�� ��������
		Rub decimal(22,2) not null, -- ������
		Qty decimal (22,5) not null, -- ���-�� ������
		Summ decimal(22,2) not null -- �����
)

create table #table_tariff (
		Storer varchar(15) not null, -- ��������
		Sku varchar(50) not null, -- ��� ������
		Type_oper varchar(10) not null, -- ��� ��������
		Rub decimal(22,2) not null -- ������
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
		st.company Company,
		i.sku Sku,
		sk.CARTONGROUP CARTONGROUP,
		i.addwho Infor_Login,
		u. usr_name FIO, 
		i.trantype Type_oper, 
		i.sourcetype Descr_oper, 
		count(i.serialkey) Kol,
		0,
		sum(i.qty) Qty,
		0
from '+@wh+'.ITRN i 
		join ssaadmin.pl_usr u on i.addwho = u.usr_login
		join '+@wh+'.STORER st on i.storerkey = st.storerkey
		left join '+@wh+'.SKU sk on i.sku=sk.sku and i.storerkey=sk.storerkey
where 1=1 '+case when @storer ='�����' then 'and (i.storerkey=''000000001''
													or i.storerkey=''219''
													or i.storerkey=''5854''
													or i.storerkey=''6845''
													or i.storerkey=''92'')' 
												else 'and i.storerkey='''+@storer+'''' end + '
			and (i.editdate between '''+@bdate+''' and '''+@edate+''')
			and i.addwho = '''+@who+'''
			and i.sourcetype != ''SHORTPICK''
group by i.storerkey, st.company, i.sku, sk.CARTONGROUP, i.addwho, u. usr_name, i.trantype, i.sourcetype
order by i.storerkey, st.company, i.sku, sk.CARTONGROUP, i.addwho, u. usr_name, i.trantype, i.sourcetype
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

/*���������� ������� ��������.
 ����������� ������� � ����� �� ��������*/
update rt1 set rt1.Rub = rt2.Rub,
				rt1.Summ = rt1.Kol * rt2.Rub
	from #table_tariff rt2 
		join #table_oper rt1 on rt2.Storer = rt1.Storer 
							and rt2.Sku=rt1.Sku 
							and rt2.Type_oper=rt1.Type_oper

select Storer,
		Company,
		Sku,
		CARTONGROUP,
		Infor_login,
		FIO,
		Type_oper,
		--Descr_oper,
		Kol,
		Rub,
		Qty,
		Summ
from #table_oper
order by Type_oper, CARTONGROUP, Company, Sku


drop table #table_oper
drop table #table_tariff

