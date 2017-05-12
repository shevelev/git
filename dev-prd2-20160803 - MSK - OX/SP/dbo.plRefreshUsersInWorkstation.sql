ALTER PROCEDURE [dbo].[plRefreshUsersInWorkstation]
   @grp_name VarChar(25) = 'all' 	
AS
BEGIN
	begin transaction
    declare @kol smallint
          , @i smallint
          , @NameUser VarChar(15)
          , @AtalonUser VarChar(15)
    select identity(int,1,1) id, grp_name, atusr_name, usr_login, usr_name
    into #tmp
      from dbo.plAtln_usr inner join ssaadmin.pl_grp_usr
        on dbo.plAtln_usr.grp_key = ssaadmin.pl_grp_usr.grp_key
           inner join ssaadmin.pl_usr
        on ssaadmin.pl_grp_usr.usr_key = ssaadmin.pl_usr.usr_key
      where dbo.plAtln_usr.atusr_key <> ssaadmin.pl_grp_usr.usr_key
        and (dbo.plAtln_usr.grp_name = @grp_name or @grp_name = 'all')
    select @kol = (select count(*) from #tmp)
    set @i = 1
    while @i <= @kol
      begin
        select @NameUser =usr_login
             , @AtalonUser = atusr_name 
          from #tmp 
          where id = @i
        exec [WH40].[plAssignPermissions] @NameUser, @AtalonUser
        set @i = @i + 1 
      end
    drop table #tmp
    commit transaction
END

