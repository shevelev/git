ALTER PROCEDURE [WH1].[plAssignPermissions]
	@NameUser VarChar(15) -- ��� ������������ ������������
  , @ExampleUser VarChar(15) -- ��� ���������� ������������
AS
BEGIN
    begin transaction b1
	SET NOCOUNT ON;
--��������� �������� ���������� ������������ �� ��������� �������
    select  WHSEID
         , PRIORITYTASKTYPE
         , STRATEGYKEY
         , EQUIPMENTPROFILEKEY 
         , LASTCASEIDPICKED 
         , LASTWAVEKEY 
         , TTMSTRATEGYKEY into #tmPr
      from wh1.TASKMANAGERUSER
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
      from wh1.TASKMANAGERUSERDETAIL
      where USERKEY = @ExampleUser
   -- ��������� ��� ��������� �������� � ����������� ������ ������������ �� ��������� ������ �������
   if (@NameUser not in (select USERKEY from wh1.TASKMANAGERUSER)) 
   begin
      insert into wh1.TASKMANAGERUSER (WHSEID
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
      insert into wh1.TASKMANAGERUSERDETAIL (WHSEID
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
       delete from wh1.TASKMANAGERUSER where USERKEY = @NameUser
       delete from wh1.TASKMANAGERUSERDETAIL where USERKEY = @NameUser
       insert into wh1.TASKMANAGERUSER (WHSEID
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
      insert into wh1.TASKMANAGERUSERDETAIL (WHSEID
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

