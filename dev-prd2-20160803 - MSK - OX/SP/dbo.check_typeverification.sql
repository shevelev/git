ALTER PROCEDURE [dbo].[check_typeverification]
as
	create table #tmp (
		typeverification int,
		typeverification_name varchar (80))

	print '���� ��������'
	insert into #tmp (typeverification, typeverification_name) values (1,'��� �����������')
	insert into #tmp (typeverification, typeverification_name) values (2,'� �������������')
	insert into #tmp (typeverification, typeverification_name) values (3,'������ S-Market')
	insert into #tmp (typeverification, typeverification_name) values (4,'������ Infor WM')
	select * from #tmp order by typeverification
	drop table #tmp

