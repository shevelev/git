-- =============================================
-- Author:		Юрчук Жанна
-- Create date: 13.05.2008
-- Description:	Для отчета Текущая загрузка склада (сводный отчет) часть 5, который
-- выводит всю необходимую информацию для принятия управленческих решений
-- =============================================
ALTER PROCEDURE [dbo].[rep_ZCurrentCapacityWarehouse5] 
	@wh VarChar(30)
AS
BEGIN
	set @wh = upper(@wh)
	declare @sql varchar(max)
	set @sql = 'SELECT usr_name, SUM(DISTINCT COUNTTASK) AS COUNTTASK, MAX(MASMAXTIME) AS MASMAXTIME
     , DATEDIFF(n,MAX(EFFECTIVEDATE),GetDate()) AS PAUSE
  FROM (SELECT usr_name, MAX(EFFECTIVEDATE) as EFFECTIVEDATE, COUNT(DISTINCT SERIALKEY) AS COUNTTASK
             , CONVERT(varchar(5),MAX(EFFECTIVEDATE),108) AS MASMAXTIME
          FROM '+@wh+'.ITRN WITH (NOLOCK) INNER JOIN ssaadmin.pl_usr 
            ON '+@wh+'.ITRN.ADDWHO = ssaadmin.pl_usr.usr_login
               INNER JOIN ssaadmin.pl_grp_usr 
            on ssaadmin.pl_grp_usr.usr_key = ssaadmin.pl_usr.usr_key 
           --and ssaadmin.pl_grp_usr.grp_key <> 5
          WHERE EFFECTIVEDATE >= convert(datetime,  convert(char(8), GetDate(), 112), 112) 
            AND (SOURCETYPE = ''nspRFTRP01'' OR SOURCETYPE = ''PICKING'' 
             OR TRANTYPE = ''DP'' OR TRANTYPE = ''WD'' OR TRANTYPE = ''MV'') 
          GROUP BY usr_name
        UNION
        SELECT usr_name, MAX(ADDDATE) as EFFECTIVEDATE, COUNT(DISTINCT SERIALKEY) AS COUNTTASK
             , CONVERT(varchar(5),MAX(ADDDATE),108) AS MASMAXTIME
          FROM '+@wh+'.DROPIDDETAIL WITH (NOLOCK) INNER JOIN ssaadmin.pl_usr 
            ON '+@wh+'.DROPIDDETAIL.ADDWHO = ssaadmin.pl_usr.usr_login
          WHERE ADDDATE > = convert(datetime, convert(char(8), GetDate(), 112), 112) 
          GROUP BY usr_name
       ) TAB
  GROUP BY usr_name
  HAVING SUM(DISTINCT COUNTTASK) > 10 and  DATEDIFF(n,MAX(EFFECTIVEDATE),GetDate()) > 20'
    exec (@sql)
END

