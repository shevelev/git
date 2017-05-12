-- =============================================
-- Author:		Юрчук Жанна
-- Create date: 13.05.2008
-- Description:	Для отчета Текущая загрузка склада (сводный отчет) часть 4, который
-- выводит всю необходимую информацию для принятия управленческих решений
-- =============================================
ALTER PROCEDURE [dbo].[rep_ZCurrentCapacityWarehouse4] 
	@wh VarChar(30)
  , @startdate VarChar(10)
  , @enddate VarChar(10)
AS
BEGIN
	set @wh = upper(@wh)
	declare @sql varchar(max)
	set @sql = 'SELECT PICKS.DATA, ISNULL(PICKS.ORDERLINES,0) AS LINESPICKED
     , ISNULL(SHIPS.ORDERLINES,0) AS LINESSHIPED, ISNULL(SHIPS.CUBE,0) AS CUBE
     , SHIPS.CONSIGNEE, PICKS.HOURS, PICKS.LINESHOUR
     , ISNULL(ERRORSHIPS.ERRORLINES,0) AS ERRORLINES
     , DP.DPCUBE, ISNULL(REPL.REPLTASK,0) AS REPLTASK
     , PICKUSER.ORDERLINES*60/PICKUSER.TM/PICKUSER.USERS AS TASKUSER
  FROM (SELECT DATA, ORDERLINES, MINDATE, MAXDATE
             , DATEDIFF(MINUTE,MINDATE,MAXDATE)/60 as HOURS
             , CASE WHEN DATEDIFF(MINUTE,MINDATE,MAXDATE) = 0 
                    THEN 0 
                    ELSE (ORDERLINES*60/DATEDIFF(MINUTE,MINDATE,MAXDATE)) 
                    END AS LINESHOUR
          FROM (SELECT PICK.DATA, COUNT(PICK.ORDERLINENUMBER) AS ORDERLINES
                     , MIN(MINDATE) AS MINDATE, MAX(MAXDATE) AS MAXDATE
                  FROM (SELECT CONVERT(varchar(10), '+@wh+'.ITRN.EFFECTIVEDATE, 102) AS DATA
                             , '+@wh+'.PICKDETAIL.ORDERKEY, '+@wh+'.PICKDETAIL.ORDERLINENUMBER
                             , MIN('+@wh+'.ITRN.EFFECTIVEDATE) AS MINDATE, MAX('+@wh+'.ITRN.EFFECTIVEDATE) AS MAXDATE
                          FROM '+@wh+'.ITRN  WITH (NOLOCK) INNER JOIN '+@wh+'.PICKDETAIL  WITH (NOLOCK) 
                            ON '+@wh+'.ITRN.SOURCEKEY = '+@wh+'.PICKDETAIL.PICKDETAILKEY
                               LEFT JOIN '+@wh+'.ORDERDETAIL  WITH (NOLOCK) 
                            ON '+@wh+'.ORDERDETAIL.ORDERKEY = '+@wh+'.PICKDETAIL.ORDERKEY 
                           AND '+@wh+'.ORDERDETAIL.ORDERLINENUMBER = '+@wh+'.PICKDETAIL.ORDERLINENUMBER
                          WHERE ('+@wh+'.ITRN.SOURCETYPE = ''PICKING'') AND ('+@wh+'.ORDERDETAIL.STATUS >= 55)
	                        '+CASE WHEN @startdate is not NULL THEN 'and ('+@wh+'.ITRN.EFFECTIVEDATE >= convert(DateTime,'''+@startdate+''',104))'
                                                               ELSE '' END+'
	                        '+CASE WHEN @enddate is not NULL THEN 'and ('+@wh+'.ITRN.EFFECTIVEDATE < DATEADD(DAY,1, convert(DateTime,'''+@enddate+''',104)))'
                                                             ELSE ' ' END + '
                          GROUP BY CONVERT(varchar(10), '+@wh+'.ITRN.EFFECTIVEDATE, 102)
                                 , '+@wh+'.PICKDETAIL.ORDERKEY, '+@wh+'.PICKDETAIL.ORDERLINENUMBER
                       ) AS PICK 
                  GROUP BY PICK.DATA
               ) TAB
       ) PICKS
       LEFT JOIN
       (SELECT CONVERT(varchar(10),'+@wh+'.ORDERDETAIL.EDITDATE,102) as DATA
             , COUNT('+@wh+'.ORDERDETAIL.ORDERLINENUMBER) AS ORDERLINES
             , SUM('+@wh+'.ORDERDETAIL.SHIPPEDQTY * '+@wh+'.SKU.STDCUBE) AS CUBE
             , COUNT(DISTINCT '+@wh+'.ORDERS.CONSIGNEEKEY) AS CONSIGNEE
          FROM '+@wh+'.ORDERDETAIL WITH (NOLOCK) INNER JOIN '+@wh+'.SKU WITH (NOLOCK) 
            ON '+@wh+'.ORDERDETAIL.SKU = '+@wh+'.SKU.SKU
               INNER JOIN '+@wh+'.ORDERS WITH (NOLOCK) 
            ON '+@wh+'.ORDERS.ORDERKEY = '+@wh+'.ORDERDETAIL.ORDERKEY
          WHERE '+@wh+'.ORDERDETAIL.status = 95 AND '+@wh+'.ORDERS.STATUS = 95
	       and ('+@wh+'.ORDERDETAIL.EDITDATE >=  convert(DateTime,'''+@startdate+''',104)) 
	       and (CONVERT(varchar(10),  '+@wh+'.ORDERDETAIL.EDITDATE,  102) <= '''+@enddate+''')
          GROUP BY CONVERT(varchar(10),'+@wh+'.ORDERDETAIL.EDITDATE,102)
       ) SHIPS ON SHIPS.DATA = PICKS.DATA
       LEFT JOIN
       (SELECT CONVERT(varchar(10),'+@wh+'.ORDERDETAIL.EDITDATE,102) as DATA
             , COUNT('+@wh+'.ORDERDETAIL.ORDERLINENUMBER) AS ERRORLINES
          FROM '+@wh+'.ORDERDETAIL WITH (NOLOCK) INNER JOIN '+@wh+'.ORDERS WITH (NOLOCK) 
            ON '+@wh+'.ORDERS.ORDERKEY = '+@wh+'.ORDERDETAIL.ORDERKEY
          WHERE '+@wh+'.ORDERDETAIL.status = 95 AND '+@wh+'.ORDERS.STATUS = 95 
            and '+@wh+'.ORDERDETAIL.ORIGINALQTY > '+@wh+'.ORDERDETAIL.SHIPPEDQTY
	        and ('+@wh+'.ORDERDETAIL.EDITDATE >=  convert(DateTime,'''+@startdate+''',104))
	        and (CONVERT(varchar(10),  '+@wh+'.ORDERDETAIL.EDITDATE,  102) <= '''+@enddate+''')
          GROUP BY CONVERT(varchar(10),'+@wh+'.ORDERDETAIL.EDITDATE,102)
       ) ERRORSHIPS ON ERRORSHIPS.DATA = PICKS.DATA
       LEFT JOIN
       (SELECT CONVERT(varchar(10),'+@wh+'.ITRN.EFFECTIVEDATE,102) as DATA
             , SUM('+@wh+'.ITRN.QTY*'+@wh+'.SKU.STDCUBE) AS DPCUBE
          FROM '+@wh+'.ITRN (NOLOCK) INNER JOIN '+@wh+'.SKU (NOLOCK) 
            ON '+@wh+'.ITRN.SKU = '+@wh+'.SKU.SKU
          WHERE ('+@wh+'.ITRN.EFFECTIVEDATE >= convert(DateTime,'''+@startdate+''',104))
		    AND ('+@wh+'.ITRN.TRANTYPE = ''DP'')
          GROUP BY CONVERT(varchar(10),'+@wh+'.ITRN.EFFECTIVEDATE,102)
       ) DP ON DP. DATA = PICKS.DATA
       LEFT JOIN
       (select DATA, sum(task) as REPLTASK
          from (select convert(varchar(10),effectivedate,102) as DATA
                     , toloc, count(serialkey) as task 
                  from '+@wh+'.itrn (nolock) 
                  where sourcetype = ''nspRFTRP01'' 
                    and effectivedate >= convert(DateTime,'''+@startdate+''',104) and effectivedate < dateadd(day,1,convert(DateTime,'''+@enddate+''',104)) 
                    and toloc <> ''PD''
                  group by convert(varchar(10),effectivedate,102), toloc
                  having (count(serialkey) > 1) 
               ) tab
          group by DATA
       ) AS REPL ON REPL.DATA = PICKS.DATA
       LEFT JOIN
       (SELECT PICK.DATA, COUNT(DISTINCT PICK.ORDERKEY + PICK.ORDERLINENUMBER) AS ORDERLINES
             , DATEDIFF(n,MIN(MINDATE),MAX(MAXDATE)) AS TM, COUNT(DISTINCT PICK.ADDWHO) AS USERS
          FROM (SELECT CONVERT(varchar(10), '+@wh+'.ITRN.EFFECTIVEDATE, 102) AS DATA
                     , '+@wh+'.PICKDETAIL.ORDERKEY, '+@wh+'.PICKDETAIL.ORDERLINENUMBER
                     , MIN('+@wh+'.ITRN.EFFECTIVEDATE) AS MINDATE, MAX('+@wh+'.ITRN.EFFECTIVEDATE) AS MAXDATE
                     , '+@wh+'.ITRN.ADDWHO
                  FROM '+@wh+'.ITRN  WITH (NOLOCK) INNER JOIN '+@wh+'.PICKDETAIL  WITH (NOLOCK) 
                    ON '+@wh+'.ITRN.SOURCEKEY = '+@wh+'.PICKDETAIL.PICKDETAILKEY
                       LEFT JOIN '+@wh+'.LOC ON '+@wh+'.ITRN.FROMLOC = '+@wh+'.LOC.LOC
                       LEFT JOIN '+@wh+'.ORDERDETAIL  WITH (NOLOCK) 
                    ON '+@wh+'.ORDERDETAIL.ORDERKEY = '+@wh+'.PICKDETAIL.ORDERKEY 
                   AND '+@wh+'.ORDERDETAIL.ORDERLINENUMBER = '+@wh+'.PICKDETAIL.ORDERLINENUMBER
                  WHERE ('+@wh+'.ITRN.SOURCETYPE = ''PICKING'') AND ('+@wh+'.ORDERDETAIL.STATUS >= 55)
	                and ('+@wh+'.ITRN.EFFECTIVEDATE >= convert(DateTime,'''+@startdate+''',104))
	                and ('+@wh+'.ITRN.EFFECTIVEDATE < DATEADD(DAY,1, convert(DateTime,'''+@startdate+''',104)))
	                and '+@wh+'.LOC.LOCLEVEL = 1
                  GROUP BY CONVERT(varchar(10), '+@wh+'.ITRN.EFFECTIVEDATE, 102)
                         , '+@wh+'.ITRN.ADDWHO, '+@wh+'.PICKDETAIL.ORDERKEY, '+@wh+'.PICKDETAIL.ORDERLINENUMBER
               ) AS PICK 
          GROUP BY PICK.DATA
       ) PICKUSER ON PICKUSER.DATA = PICKS.DATA
  ORDER BY PICKS.DATA'
    exec (@sql)
END

