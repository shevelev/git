-- =============================================
-- Author:		Юрчук Жанна
-- Create date: 26.04.2008
-- Description:	Для отчета Время начала работы сотрудников, который предназначен
-- для вывода времени начала работы сотрудников за выбранный день с указанием типа первой операции
-- =============================================
ALTER PROCEDURE [dbo].[rep_ZTimeStartedWorkForEmployee]
	@wh VarChar(30)
  , @startDate VarChar(10)
AS
BEGIN
    set @wh = upper(@wh)
	declare @sql varchar(max)
	set @sql = 'SELECT usr_name, start, TRANTYPE
                  FROM (SELECT usr_name, CONVERT(varchar(5),start,108) as start,
                               CASE	WHEN TRANTYPE = ''WD'' AND SOURCETYPE = ''ntrPickDetailUpdate'' THEN '''' 
	                                WHEN TRANTYPE = ''AJ'' THEN ''Корректировка'' 
	                                WHEN TRANTYPE = ''MV'' AND SOURCETYPE = '''' THEN ''Перемещение'' 
	                                WHEN TRANTYPE = ''MV'' AND SOURCETYPE = ''nspRFTRP01'' THEN ''Пополнение'' 
	                                WHEN TRANTYPE = ''MV'' AND SOURCETYPE = ''PICKING'' THEN ''Отбор'' 
	                                WHEN TRANTYPE = ''DP'' THEN ''Приемка'' 
	                                WHEN TRANTYPE = ''MV'' THEN ''Перемещение'' 
	                                     END AS TRANTYPE
                          FROM (SELECT ssaadmin.pl_usr.usr_name
                                     , '+@wh+'.ITRN.EDITWHO, MIN('+@wh+'.ITRN.EDITDATE) AS start
                                  FROM '+@wh+'.ITRN WITH (NOLOCK)
                                       LEFT OUTER JOIN
                                       ssaadmin.pl_usr ON '+@wh+'.ITRN.EDITWHO = ssaadmin.pl_usr.usr_login
                                  WHERE (CONVERT(varchar(10),'+@wh+'.ITRN.EDITDATE, 104) 
                                         = CONVERT(varchar(10), '''+@startdate+''', 104))
                                  GROUP BY ssaadmin.pl_usr.usr_name, '+@wh+'.ITRN.EDITWHO
                               ) stat
                                LEFT JOIN '+@wh+'.ITRN WITH (NOLOCK) 
                                ON '+@wh+'.ITRN.EDITDATE = stat.start AND '+@wh+'.ITRN.EDITWHO = stat.EDITWHO 
                       ) stats
                  GROUP BY usr_name, start, TRANTYPE
                  ORDER BY  start'
    exec (@sql)	
END

