-- =============================================
-- �����:		��������� ��������
-- ������:		������, �.�������
-- ���� ��������: 03.03.2010 (������)
-- ��������: ������� ����� �� ������� (�����)
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV16a_Rep_Income_GetMonth] ( 
	@tekdate int
)

as

create table #table_month (
		RN int not null, -- �����
		Label varchar(15) not null, -- �����
		VValue varchar(15) not null -- ��������
)

declare @tdate varchar(10)

insert into #table_month values(1,'������','01')
insert into #table_month values(2,'�������','02')
insert into #table_month values(3,'����','03')
insert into #table_month values(4,'������','04')
insert into #table_month values(5,'���','05')
insert into #table_month values(6,'����','06')
insert into #table_month values(7,'����','07')
insert into #table_month values(8,'������','08')
insert into #table_month values(9,'��������','09')
insert into #table_month values(10,'�������','10')
insert into #table_month values(11,'������','11')
insert into #table_month values(12,'�������','12')

if @tekdate=1 
	begin
		set @tdate=convert(varchar(10),getdate(),112)
		select *
		from #table_month
		where vvalue=substring(@tdate,5,2)
		order by RN
	end
else
	begin
		select *
		from #table_month
		order by RN
	end

drop table #table_month

