-- =============================================
-- �����:		��������� ��������
-- ������:		������, �.�������
-- ���� ��������: 03.03.2010 (������)
-- ��������: ����� ��������
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV25a_FOT_Get_Tariff] ( 
	@Tmin decimal(22,2),
	@Proc int,
	@shag int
)
as 

create table #tab_Tarrif (
		strD varchar(15) not null, -- �������
		MinSO decimal(22,1) not null, -- ����������� ��������
		MaxSO decimal(22,1) not null, -- ������������ ��������
		TRub decimal(22,2) not null -- ������
)

insert into #tab_Tarrif
select *
from [dbo].[TShag](0,@shag,@Tmin,@Proc,15)

select *
from #tab_Tarrif

