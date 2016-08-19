ALTER PROCEDURE [dbo].[check_typeverification]
as
	create table #tmp (
		typeverification int,
		typeverification_name varchar (80))

	print 'типы проверки'
	insert into #tmp (typeverification, typeverification_name) values (1,'без расхождений')
	insert into #tmp (typeverification, typeverification_name) values (2,'с расхождениями')
	insert into #tmp (typeverification, typeverification_name) values (3,'только S-Market')
	insert into #tmp (typeverification, typeverification_name) values (4,'только Infor WM')
	select * from #tmp order by typeverification
	drop table #tmp

