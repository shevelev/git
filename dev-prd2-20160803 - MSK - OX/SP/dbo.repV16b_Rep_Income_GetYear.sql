-- =============================================
-- �����:		��������� ��������
-- ������:		������, �.�������
-- ���� ��������: 03.03.2010 (������)
-- ��������: ������� ����� �� ������� (�����)
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV16b_Rep_Income_GetYear] ( 
	@tekdate int
)

as

create table #table_year (
		RN int not null, -- �����
		Label varchar(15) not null, -- �����
		VValue varchar(15) not null -- ��������
)

declare @tdate varchar(10)

insert into #table_year values(1,'2009','2009')
insert into #table_year values(2,'2010','2010')
insert into #table_year values(3,'2011','2011')
insert into #table_year values(4,'2012','2012')
insert into #table_year values(5,'2013','2013')
insert into #table_year values(6,'2014','2014')
insert into #table_year values(7,'2015','2015')

if @tekdate=1 
	begin
		set @tdate=convert(varchar(10),getdate(),112)
		select *
		from #table_year
		where vvalue=substring(@tdate,1,4)
		order by RN
	end
else
	begin
		select *
		from #table_year
		order by RN
	end

drop table #table_year

