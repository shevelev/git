ALTER PROCEDURE [dbo].[check_typedocument]
as
	create table #tmp (
		typedocument int,
		typedocument_name varchar (80))

	print '���� ����������'
	insert into #tmp (typedocument, typedocument_name) values (0,'�������')
	insert into #tmp (typedocument, typedocument_name) values (1,'������')
	insert into #tmp (typedocument, typedocument_name) values (3,'���������')
	insert into #tmp (typedocument, typedocument_name) values (4,'�����������')
	select * from #tmp order by typedocument
	drop table #tmp

