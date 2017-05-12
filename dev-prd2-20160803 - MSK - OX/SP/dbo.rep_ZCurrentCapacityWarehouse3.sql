-- =============================================
-- Author:		Юрчук Жанна
-- Create date: 13.05.2008
-- Description:	Для отчета Текущая загрузка склада (сводный отчет) часть 3, который
-- выводит всю необходимую информацию для принятия управленческих решений
-- =============================================
ALTER PROCEDURE [dbo].[rep_ZCurrentCapacityWarehouse3] 
	@wh VarChar(30)
  , @startdate VarChar(10)
AS
BEGIN
	set @wh = upper(@wh)
	declare @sql varchar(max)
	set @sql = 'SELECT O1LINES, O2LINES, O3LINES, OSTLINES, ORDERLINESTODAY
     , TM, CURRMIN, VinMIN, VinMINuser, D, ENDMIN
     , CONVERT(VARCHAR(2),FLOOR(ENDMIN/60)) AS H
     , CONVERT(VARCHAR(2),ENDMIN - FLOOR(ENDMIN/60)*60) AS M
  FROM (SELECT O1LINES, O2LINES, O3LINES, O1LINES - O2LINES AS OSTLINES
             , ORDERLINESTODAY, TM, CURRMIN, ORDERLINESTODAY*60/TM as VinMIN
             , ORDERLINESTODAY*60/TM/USERS as VinMINuser, (O1LINES - O2LINES)*TM/ORDERLINESTODAY as D
             , CURRMIN + (O1LINES - O2LINES)*TM/ORDERLINESTODAY as ENDMIN
          FROM (SELECT ISNULL(O1.ORDERLINENUMBER,0) AS O1LINES
                     , ISNULL(O2.ORDERLINENUMBER,0) AS O2LINES
                     , ISNULL(O3.ORDERLINENUMBER,0) AS O3LINES
                     , TIMES.TM, TIMES.CURRMIN, TODAY.ORDERLINESTODAY, TODAY.USERS
                  FROM (SELECT COUNT(ORDERSLINE.ORDERLINENUMBER) AS ORDERLINENUMBER
                          FROM (SELECT '+@wh+'.ORDERDETAIL.ORDERKEY, '+@wh+'.ORDERDETAIL.ORDERLINENUMBER
                                  FROM '+@wh+'.WAVE WITH (NOLOCK) INNER JOIN '+@wh+'.WAVEDETAIL WITH (NOLOCK) 
                                    ON '+@wh+'.WAVE.WAVEKEY = '+@wh+'.WAVEDETAIL.WAVEKEY 
                                       INNER JOIN '+@wh+'.ORDERDETAIL  WITH (NOLOCK) 
                                    ON '+@wh+'.WAVEDETAIL.ORDERKEY = '+@wh+'.ORDERDETAIL.ORDERKEY
                                  WHERE ('+@wh+'.WAVE.EXTERNALWAVEKEY = CONVERT(varchar(10), convert(datetime, convert(char(8), GetDate(), 112), 112), 103))
                                  GROUP BY '+@wh+'.ORDERDETAIL.ORDERKEY, '+@wh+'.ORDERDETAIL.ORDERLINENUMBER
                               ) ORDERSLINE 
                       ) O1
               LEFT JOIN 
               (SELECT COUNT(ORDERSLINE.ORDERLINENUMBER) AS ORDERLINENUMBER
                  FROM (SELECT '+@wh+'.ORDERDETAIL.ORDERKEY, '+@wh+'.ORDERDETAIL.ORDERLINENUMBER
                          FROM '+@wh+'.WAVE WITH (NOLOCK) INNER JOIN '+@wh+'.WAVEDETAIL  WITH (NOLOCK) 
                            ON '+@wh+'.WAVE.WAVEKEY = '+@wh+'.WAVEDETAIL.WAVEKEY 
                               INNER JOIN '+@wh+'.ORDERDETAIL  WITH (NOLOCK) 
                            ON '+@wh+'.WAVEDETAIL.ORDERKEY = '+@wh+'.ORDERDETAIL.ORDERKEY
                          WHERE ('+@wh+'.WAVE.EXTERNALWAVEKEY = CONVERT(varchar(10), convert(datetime, convert(char(8), GetDate(), 112), 112), 103))
                            AND ('+@wh+'.ORDERDETAIL.OPENQTY <= '+@wh+'.ORDERDETAIL.QTYPICKED) 
                          GROUP BY '+@wh+'.ORDERDETAIL.ORDERKEY, '+@wh+'.ORDERDETAIL.ORDERLINENUMBER
                       ) ORDERSLINE 
               ) O2 ON 1=1
               LEFT JOIN 
               (SELECT COUNT(ORDERSLINE.ORDERLINENUMBER) AS ORDERLINENUMBER
                  FROM (SELECT '+@wh+'.ORDERDETAIL.ORDERKEY, '+@wh+'.ORDERDETAIL.ORDERLINENUMBER
                          FROM '+@wh+'.WAVE WITH (NOLOCK) INNER JOIN '+@wh+'.WAVEDETAIL  WITH (NOLOCK) 
                            ON '+@wh+'.WAVE.WAVEKEY = '+@wh+'.WAVEDETAIL.WAVEKEY 
                               INNER JOIN '+@wh+'.ORDERDETAIL  WITH (NOLOCK) 
                            ON '+@wh+'.WAVEDETAIL.ORDERKEY = '+@wh+'.ORDERDETAIL.ORDERKEY
                               INNER JOIN '+@wh+'.PICKDETAIL  WITH (NOLOCK) 
                            ON '+@wh+'.ORDERDETAIL.ORDERKEY = '+@wh+'.PICKDETAIL.ORDERKEY 
                           AND '+@wh+'.ORDERDETAIL.ORDERLINENUMBER = '+@wh+'.PICKDETAIL.ORDERLINENUMBER
                               INNER JOIN '+@wh+'.ITRN  WITH (NOLOCK)  
                            ON '+@wh+'.ITRN.SOURCEKEY = '+@wh+'.PICKDETAIL.PICKDETAILKEY
                          WHERE ('+@wh+'.WAVE.EXTERNALWAVEKEY <> CONVERT(varchar(10), convert(datetime, convert(char(8), GetDate(), 112), 112), 103)) 
                            AND ('+@wh+'.ITRN.EFFECTIVEDATE >=  convert(DateTime,'''+@startdate+''',104) 
                            AND '+@wh+'.ITRN.EFFECTIVEDATE <  DATEADD(day,1,convert(datetime, convert(char(8), GetDate(), 112), 112)))
                            AND ('+@wh+'.ORDERDETAIL.OPENQTY <= '+@wh+'.ORDERDETAIL.QTYPICKED) 
                          GROUP BY '+@wh+'.ORDERDETAIL.ORDERKEY, '+@wh+'.ORDERDETAIL.ORDERLINENUMBER
                       ) ORDERSLINE 
               ) O3 ON 1=1
               LEFT JOIN
               (SELECT (MAXHOUR + MAXMIN) - (MINHOUR + MINMIN) AS TM, MAXHOUR + MAXMIN AS CURRMIN
                  FROM (SELECT CONVERT(INT,SUBSTRING(TI2.MAXTIME,1,2))*60 AS MAXHOUR
                             , CONVERT(INT,SUBSTRING(TI2.MAXTIME,4,2)) AS MAXMIN
                             , CONVERT(INT,SUBSTRING(TI2.MINTIME,1,2))*60 AS MINHOUR
                             , CONVERT(INT,SUBSTRING(TI2.MINTIME,4,2)) AS MINMIN
                          FROM (SELECT CONVERT(VARCHAR(5),TI.MAXDATE,108) AS MAXTIME
                                     , CONVERT(VARCHAR(5),TI.MINDATE,108) AS MINTIME
                                  FROM (SELECT MIN(EFFECTIVEDATE) AS MINDATE, MAX(EFFECTIVEDATE) AS MAXDATE
                                          FROM '+@wh+'.ITRN WITH (NOLOCK) 
                                          WHERE (TRANTYPE = ''MV'') AND (SOURCETYPE = ''PICKING'') 
                                            AND (CONVERT(varchar(10),'+@wh+'.ITRN.EFFECTIVEDATE,104) = CONVERT(varchar(10), convert(datetime, convert(char(8), GetDate(), 112), 112), 104))
                                       ) TI
                               ) TI2
                       ) TI3
               ) TIMES ON 1=1
               LEFT JOIN
               (SELECT COUNT(DISTINCT ORDERSLINES) AS ORDERLINESTODAY, COUNT(DISTINCT ADDWHO) AS USERS
                  FROM (SELECT '+@wh+'.PICKDETAIL.ORDERKEY + '+@wh+'.PICKDETAIL.ORDERLINENUMBER AS ORDERSLINES, '+@wh+'.ITRN.ADDWHO
                          FROM '+@wh+'.ITRN  WITH (NOLOCK) INNER JOIN '+@wh+'.PICKDETAIL  WITH (NOLOCK) 
                            ON '+@wh+'.ITRN.SOURCEKEY = '+@wh+'.PICKDETAIL.PICKDETAILKEY
                               INNER JOIN '+@wh+'.ORDERDETAIL  WITH (NOLOCK) 
                            ON '+@wh+'.ORDERDETAIL.ORDERKEY = '+@wh+'.PICKDETAIL.ORDERKEY 
                           AND '+@wh+'.ORDERDETAIL.ORDERLINENUMBER = '+@wh+'.PICKDETAIL.ORDERLINENUMBER
                               INNER JOIN '+@wh+'.WAVEDETAIL  WITH (NOLOCK) 
                            ON '+@wh+'.WAVEDETAIL.ORDERKEY = '+@wh+'.ORDERDETAIL.ORDERKEY
                               INNER JOIN '+@wh+'.WAVE  WITH (NOLOCK) ON '+@wh+'.WAVE.WAVEKEY = '+@wh+'.WAVEDETAIL.WAVEKEY
                          WHERE ('+@wh+'.ITRN.SOURCETYPE = ''PICKING'') AND ('+@wh+'.ORDERDETAIL.STATUS >= 55) 
                            AND ('+@wh+'.ITRN.EFFECTIVEDATE > convert(DateTime,'''+@startdate+''',104) AND '+@wh+'.ITRN.EFFECTIVEDATE < DATEADD(day,1,convert(datetime, convert(char(8), GetDate(), 112), 112)))
	                        AND ('+@wh+'.WAVE.EXTERNALWAVEKEY = CONVERT(varchar(10), convert(datetime, convert(char(8), GetDate(), 112), 112), 103))
                          GROUP BY CONVERT(char(10), '+@wh+'.ITRN.EDITDATE, 126), '+@wh+'.PICKDETAIL.ORDERKEY+'+@wh+'.PICKDETAIL.ORDERLINENUMBER, '+@wh+'.ITRN.ADDWHO
                       ) AS PICK
               ) TODAY ON 1=1
               ) DATA
        ) D'
    exec (@sql)
END

