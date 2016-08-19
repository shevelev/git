-- =============================================
-- Author:		Юрчук Жанна
-- Create date: 29.04.2008
-- Description:	Для отчета Максимальные показатели по типам задач,
-- который выводит за выбранный период максимальное кол-во выполненных задач
-- по типам с расшифровкой сотрудника, дня и часа, когда это было зафиксировано
-- =============================================
ALTER PROCEDURE [dbo].[rep_ZMaximumIndexesForTypeTasks] 
	@wh VarChar(30)
  , @startdate VarChar(10)
  , @enddate VarChar(10)
AS
BEGIN
	set @wh = upper(@wh)
	declare @sql varchar(max)
	set @sql = 'SELECT RT.TYPE, RT.tasks, TAB.DD, TAB.RHOUR, TAB.USRNAME
                  FROM (SELECT TYPE, max(tasks) AS tasks
                          FROM (SELECT rhour,dd,TYPE, usrname, count(SERIALKEY) as tasks
                                  FROM (SELECT iq.TYPE , iq.usrname, SERIALKEY
                                             , convert(smallint, convert(nvarchar(2), iq.EDITDATE, 108)) as rhour
                                             , convert(varchar(10), iq.EDITDATE, 104) as dd
                                          FROM (SELECT EDITWHO, TRANTYPE, SOURCETYPE, EDITDATE, SERIALKEY
                                                     , CASE WHEN TRANTYPE = ''WD'' AND SOURCETYPE = ''ntrPickDetailUpdate'' THEN '''' 
	                                                        WHEN TRANTYPE = ''AJ'' THEN '''' 
	                                                        WHEN TRANTYPE = ''MV'' AND SOURCETYPE = '''' THEN '''' 
	                                                        WHEN TRANTYPE = ''MV'' AND SOURCETYPE = ''nspRFTRP01'' THEN ''Пополнение'' 
	                                                        WHEN TRANTYPE = ''MV'' AND SOURCETYPE = ''PICKING'' THEN ''Отбор'' 
	                                                        WHEN TRANTYPE = ''DP'' THEN ''Приемка'' 
	                                                        WHEN TRANTYPE = ''MV'' THEN ''Перемещение'' 
	                                                   END AS TYPE
                                                     , convert(nvarchar(10), editdate, 104) as rdate
                                                     , ssaadmin.pl_usr.usr_name as usrname
                                                  FROM '+@wh+'.ITRN WITH (NOLOCK)
                                                       LEFT JOIN ssaadmin.pl_usr 
                                                    ON '+@wh+'.ITRN.EDITWHO = ssaadmin.pl_usr.usr_login
                                                  WHERE '+@wh+'.ITRN.EFFECTIVEDATE >= CONVERT(DATETIME,  '''+@startdate+''' , 104) 
                                                   AND ('+@wh+'.ITRN.EFFECTIVEDATE <= CONVERT(DATETIME,  '''+@enddate+''' , 104) 
                                                    OR '''+@enddate+''' IS NULL)
                                               ) as iq
                                          WHERE iq.TYPE <> ''''
                                       ) Data 
                                  GROUP BY rhour,dd,TYPE,usrname
                               ) TAB
                          GROUP BY TYPE
                       ) RT
                       LEFT JOIN
                      (SELECT rhour, dd, TYPE, usrname, count(SERIALKEY) as tasks
                         FROM (SELECT iq.TYPE , iq.usrname, SERIALKEY
                                    , convert(smallint, convert(nvarchar(2), iq.EDITDATE, 108)) as rhour
                                    , convert(varchar(10), iq.EDITDATE, 104) as dd
                                 FROM (SELECT EDITWHO, TRANTYPE, SOURCETYPE, EDITDATE, SERIALKEY
                                            , CASE WHEN TRANTYPE = ''WD'' AND SOURCETYPE = ''ntrPickDetailUpdate'' THEN '''' 
	                                               WHEN TRANTYPE = ''AJ'' THEN '''' 
	                                               WHEN TRANTYPE = ''MV'' AND SOURCETYPE = '''' THEN '''' 
	                                               WHEN TRANTYPE = ''MV'' AND SOURCETYPE = ''nspRFTRP01'' THEN ''Пополнение'' 
	                                               WHEN TRANTYPE = ''MV'' AND SOURCETYPE = ''PICKING'' THEN ''Отбор'' 
	                                               WHEN TRANTYPE = ''DP'' THEN ''Приемка'' 
	                                               WHEN TRANTYPE = ''MV'' THEN ''Перемещение'' 
	                                          END AS TYPE
                                            , convert(nvarchar(10), editdate, 104) as rdate
                                            , ssaadmin.pl_usr.usr_name as usrname
                                         FROM '+@wh+'.ITRN WITH (NOLOCK)
                                              LEFT JOIN ssaadmin.pl_usr 
                                           ON '+@wh+'.ITRN.EDITWHO = ssaadmin.pl_usr.usr_login
                                         WHERE '+@wh+'.ITRN.EFFECTIVEDATE >= CONVERT(DATETIME,  '''+@startdate+''' , 104) 
                                           AND ('+@wh+'.ITRN.EFFECTIVEDATE <= CONVERT(DATETIME,  '''+@enddate+''' , 104) 
                                            OR '''+@enddate+''' IS NULL) 
                                      ) as iq
                                 WHERE iq.TYPE <> ''''
                              ) Data 
                         GROUP BY rhour,dd,TYPE,usrname
                      ) TAB 
                   ON RT.TYPE = TAB.TYPE AND RT.tasks = TAB.tasks'
    exec (@sql)
END

