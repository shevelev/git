-- =============================================
-- Author:		Юрчук Жанна
-- Create date: 29.04.2008
-- Description:	Для отчета Интенсивность работы сотрудников,  который
-- позволяет вывести общую интенсивность работы определенных сотрудников за выбранный день
-- =============================================
ALTER PROCEDURE [dbo].[rep_ZIntensityWorkEmployees] 
	@wh VarChar(30)
  , @day VarChar(10)
  , @users VarChar(100)
AS
BEGIN
   	set @wh = upper(@wh)
	declare @sql varchar(max)
	set @sql = 'select ssaadmin.pl_usr.usr_name as editwho, iq.rdate
                     , iq.rhour, count(iq.SERIALKEY) as tasks
                  from (SELECT TASKS.EDITDATE, TASKS.EDITWHO
                             , TASKS.SERIALKEY, TASKS.rdate, TASKS.rhour
                          FROM (SELECT '+@wh+'.ITRN.EDITDATE, '+@wh+'.ITRN.EDITWHO, '+@wh+'.ITRN.SERIALKEY
                                     , convert(nvarchar(10), '+@wh+'.ITRN.editdate, 104) as rdate
                                     , convert(smallint, convert(nvarchar(2), '+@wh+'.ITRN.editdate, 108)) as rhour
                                     , CASE WHEN TRANTYPE = ''WD'' AND SOURCETYPE = ''ntrPickDetailUpdate'' THEN '''' 
	                                        WHEN TRANTYPE = ''AJ'' THEN '''' 
	                                        WHEN TRANTYPE = ''MV'' AND SOURCETYPE = '''' THEN '''' 
	                                        WHEN TRANTYPE = ''MV'' AND SOURCETYPE = ''nspRFTRP01'' THEN ''Пополнение'' 
	                                        WHEN TRANTYPE = ''MV'' AND SOURCETYPE = ''PICKING'' THEN ''Отбор'' 
	                                        WHEN TRANTYPE = ''DP'' THEN ''Приемка'' 
	                                        WHEN TRANTYPE = ''MV'' THEN ''Перемещение'' 
	                                   END AS TYPE
                                  FROM '+@wh+'.ITRN WITH (NOLOCK) 
                               ) AS TASKS
                          WHERE TASKS.TYPE <> ''''
                       ) as iq
                       LEFT JOIN
                       ssaadmin.pl_usr ON iq.EDITWHO = ssaadmin.pl_usr.usr_login
                  where (iq.rdate = convert(nvarchar(10), '''+@day+''', 104))
                    and (ssaadmin.pl_usr.usr_name in('''+@users+'''))
                  group by iq.rdate, iq.rhour, ssaadmin.pl_usr.usr_name
                  order by ssaadmin.pl_usr.usr_name, iq.rdate, iq.rhour'
    exec (@sql)
END

