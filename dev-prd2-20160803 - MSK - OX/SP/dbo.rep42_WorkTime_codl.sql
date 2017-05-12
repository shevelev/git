ALTER PROCEDURE [dbo].[rep42_WorkTime_codl](
	@wh varchar(10)
)AS

	declare @sql varchar(max)

	create table #res1 (
		code varchar(10) COLLATE Cyrillic_General_CI_AS DEFAULT (''),
		description varchar(250) COLLATE Cyrillic_General_CI_AS DEFAULT (''))
insert into #res1 (code, description) values (null,'все')
set @sql = 'insert into #res1 select code, description from '+@wh+'.CODELKUP where listname = ''itrntype'''
	exec (@sql)

select * from #res1
	drop table #res1
--select * from ssaadmin.pl_usr

