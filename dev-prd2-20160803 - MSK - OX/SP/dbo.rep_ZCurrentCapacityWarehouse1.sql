-- =============================================
-- Author:		Юрчук Жанна
-- Create date: 13.05.2008
-- Description:	Для отчета Текущая загрузка склада (сводный отчет) часть 1, который
-- выводит всю необходимую информацию для принятия управленческих решений
-- =============================================
ALTER PROCEDURE [dbo].[rep_ZCurrentCapacityWarehouse1] 
	@wh VarChar(30)
AS
BEGIN
	set @wh = upper(@wh)
	declare @sql varchar(max)
	set @sql = 'SELECT AREAS.AREAKEY, PICK.PICKTASKS, REPL.REPLTASK, PACK.PACKTASKS
     --, '+@wh+'.CODEDETAIL.DESCRIPTION as AREADESCR
     , SUBSTRING(AREAS.AREAKEY,2,1) AS WHS, SPEEDPICK.VLINES, SPEEDREPL.VLINESREPL
  FROM (SELECT AREAKEY
          FROM '+@wh+'.AREADETAIL WITH (NOLOCK)
          WHERE (AREAKEY LIKE ''U%'')
          GROUP BY AREAKEY
       ) AS AREAS
       LEFT JOIN
       (SELECT AREAKEY
             , CASE WHEN (MINDATE IS NOT NULL AND MINDATE < GETDATE()) 
                    THEN SERIALKEYS * 60/DATEDIFF(N,MINDATE,GETDATE()) 
                    ELSE 0 
                    END AS VLINES
	      FROM (SELECT '+@wh+'.AREADETAIL.AREAKEY
                     , COUNT(DISTINCT '+@wh+'.ORDERDETAIL.SERIALKEY) AS SERIALKEYS
                     , MIN('+@wh+'.ITRN.EFFECTIVEDATE) AS MINDATE
	              FROM '+@wh+'.ITRN (NOLOCK) 
	                   INNER JOIN '+@wh+'.PICKDETAIL (NOLOCK) ON '+@wh+'.PICKDETAIL.PICKDETAILKEY = '+@wh+'.ITRN.SOURCEKEY 
	                   INNER JOIN '+@wh+'.WAVE (NOLOCK) ON '+@wh+'.WAVE.WAVEKEY = '+@wh+'.PICKDETAIL.WAVEKEY
	                   INNER JOIN '+@wh+'.ORDERDETAIL (NOLOCK) ON '+@wh+'.PICKDETAIL.ORDERKEY = '+@wh+'.ORDERDETAIL.ORDERKEY AND '+@wh+'.PICKDETAIL.ORDERLINENUMBER = '+@wh+'.ORDERDETAIL.ORDERLINENUMBER
	                   INNER JOIN '+@wh+'.LOC ON '+@wh+'.ITRN.FROMLOC = '+@wh+'.LOC.LOC
	                   INNER JOIN '+@wh+'.AREADETAIL ON '+@wh+'.AREADETAIL.PUTAWAYZONE = '+@wh+'.LOC.PUTAWAYZONE
	              WHERE (TRANTYPE = ''MV'') AND (SOURCETYPE = ''PICKING'') 
	                AND '+@wh+'.ITRN.EFFECTIVEDATE > DATEADD(N,-60,GETDATE())
	              GROUP BY '+@wh+'.AREADETAIL.AREAKEY
               ) TAB 
       ) AS SPEEDPICK ON  AREAS.AREAKEY = SPEEDPICK.AREAKEY
       LEFT JOIN
       (SELECT AREAKEY
             , CASE WHEN (MINDATE IS NOT NULL AND MINDATE < GETDATE()) 
                    THEN SERIALKEYS * 60/DATEDIFF(N,MINDATE,GETDATE()) 
                    ELSE 0 
                    END AS VLINESREPL
	      FROM (SELECT '+@wh+'.AREADETAIL.AREAKEY, COUNT(DISTINCT '+@wh+'.ITRN.SERIALKEY) AS SERIALKEYS
                     , MIN('+@wh+'.ITRN.EFFECTIVEDATE) AS MINDATE
	              FROM '+@wh+'.ITRN (NOLOCK) 
	                   INNER JOIN '+@wh+'.LOC ON '+@wh+'.ITRN.TOLOC = '+@wh+'.LOC.LOC
	                   INNER JOIN '+@wh+'.AREADETAIL ON '+@wh+'.AREADETAIL.PUTAWAYZONE = '+@wh+'.LOC.PUTAWAYZONE
	              WHERE (TRANTYPE = ''MV'') AND (SOURCETYPE = ''nspRFTRP01'') 
	                AND '+@wh+'.ITRN.EFFECTIVEDATE > DATEADD(N,-60,GETDATE())
	              GROUP BY '+@wh+'.AREADETAIL.AREAKEY
               ) TAB 
       ) AS SPEEDREPL ON  AREAS.AREAKEY = SPEEDREPL.AREAKEY
       LEFT JOIN
       (SELECT '+@wh+'.AREADETAIL.AREAKEY
             , COUNT(DISTINCT '+@wh+'.PICKDETAIL.SERIALKEY) AS PICKTASKS
          FROM '+@wh+'.PICKDETAIL WITH (NOLOCK)
               INNER JOIN '+@wh+'.LOC ON '+@wh+'.PICKDETAIL.LOC = '+@wh+'.LOC.LOC 
               INNER JOIN '+@wh+'.AREADETAIL ON '+@wh+'.LOC.PUTAWAYZONE = '+@wh+'.AREADETAIL.PUTAWAYZONE
          WHERE ('+@wh+'.PICKDETAIL.STATUS = ''1'')
          GROUP BY '+@wh+'.AREADETAIL.AREAKEY
       ) PICK ON AREAS.AREAKEY = PICK.AREAKEY
       LEFT JOIN
       (SELECT '+@wh+'.AREADETAIL.AREAKEY
             , COUNT(DISTINCT '+@wh+'.SKUXLOC.SERIALKEY) AS REPLTASK
          FROM '+@wh+'.ORDERDETAIL  WITH (NOLOCK)
               INNER JOIN '+@wh+'.SKUXLOC  WITH (NOLOCK) ON '+@wh+'.ORDERDETAIL.STORERKEY = '+@wh+'.SKUXLOC.STORERKEY AND '+@wh+'.ORDERDETAIL.SKU = '+@wh+'.SKUXLOC.SKU AND '+@wh+'.SKUXLOC.LOCATIONTYPE = ''PICK'' 
               INNER JOIN '+@wh+'.LOC ON '+@wh+'.SKUXLOC.LOC = '+@wh+'.LOC.LOC 
               INNER JOIN '+@wh+'.ORDERS ON '+@wh+'.ORDERDETAIL.ORDERKEY = '+@wh+'.ORDERS.ORDERKEY
               INNER JOIN '+@wh+'.AREADETAIL ON '+@wh+'.LOC.PUTAWAYZONE = '+@wh+'.AREADETAIL.PUTAWAYZONE
          WHERE (('+@wh+'.ORDERDETAIL.OPENQTY - '+@wh+'.ORDERDETAIL.QTYALLOCATED - '+@wh+'.ORDERDETAIL.QTYPICKED) > 0) 
             AND ('+@wh+'.SKUXLOC.REPLENISHMENTPRIORITY < ''4'') 
             AND ('+@wh+'.ORDERS.STATUS > ''02'')
          GROUP BY '+@wh+'.AREADETAIL.AREAKEY
       ) REPL ON AREAS.AREAKEY = REPL.AREAKEY
       LEFT JOIN
       (SELECT '+@wh+'.AREADETAIL.AREAKEY, COUNT(DISTINCT '+@wh+'.PICKDETAIL.SERIALKEY) AS PACKTASKS
          FROM '+@wh+'.PICKDETAIL WITH (NOLOCK)
               INNER JOIN '+@wh+'.TASKDETAIL ON '+@wh+'.TASKDETAIL.PICKDETAILKEY = '+@wh+'.PICKDETAIL.PICKDETAILKEY
               INNER JOIN '+@wh+'.LOC ON '+@wh+'.TASKDETAIL.FROMLOC = '+@wh+'.LOC.LOC 
               INNER JOIN '+@wh+'.AREADETAIL ON '+@wh+'.LOC.PUTAWAYZONE = '+@wh+'.AREADETAIL.PUTAWAYZONE
          WHERE ('+@wh+'.PICKDETAIL.STATUS = ''5'') and ('+@wh+'.PICKDETAIL.DROPID = '''')
          GROUP BY '+@wh+'.AREADETAIL.AREAKEY
       ) PACK ON AREAS.AREAKEY = PACK.AREAKEY
       --LEFT JOIN '+@wh+'.CODEDETAIL ON '+@wh+'.CODEDETAIL.CODE = AREAS.AREAKEY AND '+@wh+'.CODEDETAIL.LISTNAME = ''AREA''
  WHERE  (PICK.PICKTASKS > 0 OR REPL.REPLTASK > 0)
  ORDER BY SUBSTRING(AREAS.AREAKEY,2,1) , AREAS.AREAKEY'
    exec (@sql)
END

