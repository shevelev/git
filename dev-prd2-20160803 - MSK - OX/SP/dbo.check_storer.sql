ALTER PROCEDURE [dbo].[check_storer]
as
	create table #tmp (
		storer int,
		storer_name varchar (80))

	print 'владельцы'
	insert into #tmp 
	SELECT * FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3','select tc.id_th_classif, tc.name 
									from th_classif tc 
									where tc.id_th_classif = 92 or tc.id_th_classif = 219') 
	insert into #tmp (storer, storer_name) values (null,'<ВСЕ>')
	select * from #tmp order by storer
	drop table #tmp

