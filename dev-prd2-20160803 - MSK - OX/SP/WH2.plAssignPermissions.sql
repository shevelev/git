ALTER PROCEDURE [WH2].[plAssignPermissions]
	@NameUser VarChar(15) -- имя проверяемого пользователя
  , @ExampleUser VarChar(15) -- имя эталонного пользователя
AS
BEGIN
    begin transaction b1
	SET NOCOUNT ON;
--выгружаем значения эталонного пользователя во временные таблицы
    select  WHSEID
         , PRIORITYTASKTYPE
         , STRATEGYKEY
         , EQUIPMENTPROFILEKEY 
         , LASTCASEIDPICKED 
         , LASTWAVEKEY 
         , TTMSTRATEGYKEY into #tmPr
      from WH2.TASKMANAGERUSER
      where USERKEY = @ExampleUser
    select WHSEID
         , USERLINENUMBER
         , PERMISSIONTYPE
         , AREAKEY 
         , PERMISSION
         , DESCR
         , ALLOWCASE
         , ALLOWIPS
         , ALLOWPALLET
         , ALLOWPIECE into #tmPrDetail
      from WH2.TASKMANAGERUSERDETAIL
      where USERKEY = @ExampleUser
   -- добавляем или обновляем значения с проверяемым именем пользователя из временных таблиц обратно
   if (@NameUser not in (select USERKEY from WH2.TASKMANAGERUSER)) 
   begin
      insert into WH2.TASKMANAGERUSER (WHSEID
            , USERKEY
            , PRIORITYTASKTYPE
            , STRATEGYKEY
            , EQUIPMENTPROFILEKEY 
            , LASTCASEIDPICKED 
            , LASTWAVEKEY 
            , TTMSTRATEGYKEY)
         select tm.WHSEID
              , @NameUser
              , tm.PRIORITYTASKTYPE
              , tm.STRATEGYKEY
              , tm.EQUIPMENTPROFILEKEY 
              , tm.LASTCASEIDPICKED 
              , tm.LASTWAVEKEY 
              , tm.TTMSTRATEGYKEY
            from #tmPr tm
      insert into WH2.TASKMANAGERUSERDETAIL (WHSEID
                                            , USERKEY
                                            , USERLINENUMBER
                                            , PERMISSIONTYPE
                                            , AREAKEY 
                                            , PERMISSION
                                            , DESCR
                                            , ALLOWCASE
                                            , ALLOWIPS
                                            , ALLOWPALLET
                                            , ALLOWPIECE)
       select tmD.WHSEID
             , @NameUser
             , tmD.USERLINENUMBER
             , tmD.PERMISSIONTYPE
             , tmD.AREAKEY 
             , tmD.PERMISSION
             , tmD.DESCR
             , tmD.ALLOWCASE
             , tmD.ALLOWIPS
             , tmD.ALLOWPALLET
             , tmD.ALLOWPIECE 
          from #tmPrDetail tmD
   end
   else 
     begin 
       delete from WH2.TASKMANAGERUSER where USERKEY = @NameUser
       delete from WH2.TASKMANAGERUSERDETAIL where USERKEY = @NameUser
       insert into WH2.TASKMANAGERUSER (WHSEID
            , USERKEY
            , PRIORITYTASKTYPE
            , STRATEGYKEY
            , EQUIPMENTPROFILEKEY 
            , LASTCASEIDPICKED 
            , LASTWAVEKEY 
            , TTMSTRATEGYKEY)
         select tm.WHSEID
              , @NameUser
              , tm.PRIORITYTASKTYPE
              , tm.STRATEGYKEY
              , tm.EQUIPMENTPROFILEKEY 
              , tm.LASTCASEIDPICKED 
              , tm.LASTWAVEKEY 
              , tm.TTMSTRATEGYKEY
            from #tmPr tm
      insert into WH2.TASKMANAGERUSERDETAIL (WHSEID
                                            , USERKEY
                                            , USERLINENUMBER
                                            , PERMISSIONTYPE
                                            , AREAKEY 
                                            , PERMISSION
                                            , DESCR
                                            , ALLOWCASE
                                            , ALLOWIPS
                                            , ALLOWPALLET
                                            , ALLOWPIECE)
       select tmD.WHSEID
             , @NameUser
             , tmD.USERLINENUMBER
             , tmD.PERMISSIONTYPE
             , tmD.AREAKEY 
             , tmD.PERMISSION
             , tmD.DESCR
             , tmD.ALLOWCASE
             , tmD.ALLOWIPS
             , tmD.ALLOWPALLET
             , tmD.ALLOWPIECE 
          from #tmPrDetail tmD
     end
   drop table #tmPr
   drop table #tmPrDetail
   commit transaction b1
END


