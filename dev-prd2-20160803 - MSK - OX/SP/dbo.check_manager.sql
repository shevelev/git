ALTER PROCEDURE [dbo].[check_manager]
as
	create table #tmp (
		id_user varchar (10),
		name_user varchar (80))

	print 'таблица пользователей USER -> #sm_user'
	insert into #tmp 
	selECT * FROM OPENROWSET('MSDASQL','DSN=SMarket;UID=SYSINFOR;PWD=3',
		'select distinct cast(u.id_user as varchar(10)) id_user, u.name_user from users u join users_filials uf on u.id_user = uf.id_user
			where u.is_uvolen = ''F'' and uf.access = ''V'' and uf.filial_index = 99 order by u.id_user')
	insert into #tmp (id_user, name_user) values (null,'<ВСЕ>')
	select * from #tmp order by name_user
	drop table #tmp
