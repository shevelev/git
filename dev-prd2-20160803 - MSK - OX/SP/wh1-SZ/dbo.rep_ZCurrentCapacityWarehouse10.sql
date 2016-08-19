-- =============================================
-- Author:		Юрчук Жанна
-- Create date: 13.05.2008
-- Description:	Для отчета Текущая загрузка склада (сводный отчет) часть 10, который
-- выводит всю необходимую информацию для принятия управленческих решений
-- =============================================
ALTER PROCEDURE [dbo].[rep_ZCurrentCapacityWarehouse10] 
	@wh VarChar(30)
AS
BEGIN
	set @wh = upper(@wh)
	declare @sql varchar(max)
	set @sql = 'SELECT TAB.WH, TAB.usr_name, TAB.TYPE, CONVERT(varchar(5),MAX(TAB.EDITDATE),108) AS TIME
     , MAX(TAB.LOC) as LOC
     , MAX(CASE WHEN '+@wh+'.RECEIPT.RECEIPTKEY IS NULL THEN '+@wh+'.WAVE.DESCR ELSE '+@wh+'.RECEIPT.CARRIERNAME END) AS WAVEDESCR
  FROM (SELECT ALLTASKS.EDITDATE, ALLTASKS.TYPE, usr_name, ALLTASKS.LOC
             , '''+@wh+''' as WH -- сделать универсальным
             , ALLTASKS.WAVEKEY
          FROM (SELECT TASKS.EDITDATE, TASKS.TYPE, TASKS.ADDWHO, TASKS.LOC, TASKS.WAVEKEY 
                  FROM (SELECT '+@wh+'.ITRN.EDITDATE
                             , CASE WHEN TRANTYPE = ''WD'' AND SOURCETYPE = ''ntrPickDetailUpdate'' THEN ''6. Отгрузка'' 
	                                WHEN TRANTYPE = ''AJ'' THEN '''' 
	                                WHEN TRANTYPE = ''MV'' AND SOURCETYPE = '''' THEN '''' 
	                                WHEN TRANTYPE = ''MV'' AND SOURCETYPE = ''nspRFTRP01'' THEN ''3. Пополнение'' 
	                                WHEN TRANTYPE = ''MV'' AND SOURCETYPE = ''PICKING'' THEN ''4. Отбор'' 
	                                WHEN TRANTYPE = ''DP'' THEN ''1. Приемка'' 
	                                WHEN TRANTYPE = ''MV'' THEN ''2. Перемещение'' 
	                           END AS TYPE
                             , '+@wh+'.ITRN.ADDWHO
                             , CASE WHEN '+@wh+'.ITRN.FROMLOC = '''' OR '+@wh+'.ITRN.FROMLOC = ''PD'' 
                                    THEN '+@wh+'.ITRN.TOLOC 
                                    ELSE '+@wh+'.ITRN.FROMLOC END AS LOC
                             , CASE WHEN '+@wh+'.RECEIPT.RECEIPTKEY IS NOT NULL THEN '+@wh+'.RECEIPT.RECEIPTKEY 
                                    WHEN '+@wh+'.PICKDETAIL.WAVEKEY IS NULL THEN '+@wh+'.WAVEDETAIL.WAVEKEY 
                                    ELSE '+@wh+'.PICKDETAIL.WAVEKEY END AS WAVEKEY
                          FROM '+@wh+'.ITRN  WITH (NOLOCK) LEFT JOIN  '+@wh+'.PICKDETAIL  WITH (NOLOCK) 
                            ON '+@wh+'.ITRN.SOURCEKEY = '+@wh+'.PICKDETAIL.PICKDETAILKEY AND '+@wh+'.ITRN.SOURCETYPE = ''PICKING''
                               LEFT JOIN  '+@wh+'.ORDERS (NOLOCK) 
                            ON SUBSTRING('+@wh+'.ITRN.SOURCEKEY,1,10) = '+@wh+'.ORDERS.ORDERKEY  AND '+@wh+'.ITRN.SOURCETYPE = ''ntrPickDetailUpdate'' 
                               LEFT JOIN  '+@wh+'.WAVEDETAIL (NOLOCK) 
                            ON '+@wh+'.WAVEDETAIL.ORDERKEY = '+@wh+'.ORDERS.ORDERKEY
                               LEFT JOIN '+@wh+'.RECEIPT (NOLOCK) 
                            ON '+@wh+'.ITRN.RECEIPTKEY = '+@wh+'.RECEIPT.RECEIPTKEY AND '+@wh+'.ITRN.TRANTYPE = ''DP'' 
                          WHERE ('+@wh+'.ITRN.EFFECTIVEDATE>=convert(datetime, convert(char(8), GetDate(), 112), 112))
                       ) AS TASKS
                    WHERE TASKS.TYPE <> '''' 
                UNION
                SELECT PACKS.EDITDATE, PACKS.TYPE, PACKS.ADDWHO, PACKS.LOC, PACKS.WAVEKEY
                  FROM (SELECT '+@wh+'.DROPIDDETAIL.ADDDATE AS EDITDATE
                             , ''5. Упаковка'' AS TYPE, '+@wh+'.DROPIDDETAIL.ADDWHO
                             , '+@wh+'.DROPID.DROPLOC AS LOC, '+@wh+'.PICKDETAIL.WAVEKEY 
                          FROM '+@wh+'.DROPIDDETAIL (NOLOCK) LEFT JOIN '+@wh+'.DROPID (NOLOCK) 
                            ON '+@wh+'.DROPID.DROPID = '+@wh+'.DROPIDDETAIL.DROPID
                               LEFT JOIN '+@wh+'.PICKDETAIL (NOLOCK) 
                            ON '+@wh+'.PICKDETAIL.CASEID = '+@wh+'.DROPIDDETAIL.CHILDID
                          WHERE '+@wh+'.DROPID.DROPIDTYPE = 1 
                           AND ('+@wh+'.DROPIDDETAIL.ADDDATE >= convert(datetime, convert(char(8), GetDate(), 112), 112))
                       ) PACKS
                UNION
                SELECT LOADS.EDITDATE, LOADS.TYPE, LOADS.ADDWHO, LOADS.LOC, LOADS.WAVEKEY
                  FROM (SELECT '+@wh+'.DROPIDDETAIL.ADDDATE AS EDITDATE
                             , ''6. Загрузка'' AS TYPE, '+@wh+'.DROPIDDETAIL.ADDWHO
                             , '+@wh+'.DROPID.DROPLOC AS LOC, '+@wh+'.PICKDETAIL.WAVEKEY 
                          FROM '+@wh+'.DROPIDDETAIL (NOLOCK) LEFT JOIN '+@wh+'.DROPID (NOLOCK) 
                            ON '+@wh+'.DROPID.DROPID = '+@wh+'.DROPIDDETAIL.CHILDID
                               LEFT JOIN '+@wh+'.PICKDETAIL (NOLOCK) 
                            ON '+@wh+'.PICKDETAIL.DROPID = '+@wh+'.DROPIDDETAIL.DROPID
                          WHERE '+@wh+'.DROPIDDETAIL.IDTYPE = 4 
                            AND ('+@wh+'.DROPIDDETAIL.ADDDATE >= convert(datetime, convert(char(8), GetDate(), 112), 112))
                       ) LOADS
               ) ALLTASKS
               LEFT JOIN '+@wh+'.LOC (NOLOCK) ON '+@wh+'.LOC.LOC = ALLTASKS.LOC
               LEFT JOIN '+@wh+'.AREADETAIL (NOLOCK) ON '+@wh+'.AREADETAIL.PUTAWAYZONE = '+@wh+'.LOC.PUTAWAYZONE
               INNER JOIN ssaadmin.pl_usr ON ALLTASKS.ADDWHO = ssaadmin.pl_usr.usr_login
          WHERE DATEDIFF(N,ALLTASKS.EDITDATE,GetDate()) < 10
       ) TAB
       LEFT JOIN '+@wh+'.WAVE (NOLOCK) ON '+@wh+'.WAVE.WAVEKEY = TAB.WAVEKEY
       LEFT JOIN '+@wh+'.RECEIPT (NOLOCK) ON '+@wh+'.RECEIPT.RECEIPTKEY = TAB.WAVEKEY AND TAB.TYPE = ''1. Приемка''
  GROUP BY WH, usr_name, TAB.TYPE
  ORDER BY WH, TAB.TYPE, usr_name'
    exec (@sql)
END

