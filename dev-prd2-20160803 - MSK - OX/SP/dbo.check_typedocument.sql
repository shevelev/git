ALTER PROCEDURE [dbo].[check_typedocument]
as
	create table #tmp (
		typedocument int,
		typedocument_name varchar (80))

	print 'типы документов'
	insert into #tmp (typedocument, typedocument_name) values (0,'Приемка')
	insert into #tmp (typedocument, typedocument_name) values (1,'Расход')
	insert into #tmp (typedocument, typedocument_name) values (3,'Пересчеты')
	insert into #tmp (typedocument, typedocument_name) values (4,'Перемещения')
	select * from #tmp order by typedocument
	drop table #tmp

