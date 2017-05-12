-- =============================================
-- Author:		Юрчук Жанна
-- Create date: 13.05.2008
-- Description:	Для отчета Текущая загрузка склада (сводный отчет) часть 2, который
-- выводит всю необходимую информацию для принятия управленческих решений
-- =============================================
ALTER PROCEDURE [dbo].[rep_ZCurrentCapacityWarehouse2] 
	@wh VarChar(30)
AS
BEGIN
	set @wh = upper(@wh)
	declare @sql varchar(max)
	set @sql = 'select iq.type, iq.rhour, count(iq.SERIALKEY) as tasks
from (SELECT TASKS.EDITDATE, TASKS.TYPE, TASKS.SERIALKEY, TASKS.rdate
           , substring(TASKS.rhour,1,3) + convert(varchar(2),floor(cast(substring(TASKS.rhour,4,2) as int)/30)*3)+''0'' as rhour
        FROM (SELECT '+@wh+'.ITRN.EDITDATE, '+@wh+'.ITRN.SERIALKEY
                   , convert(nvarchar(10), '+@wh+'.ITRN.EFFECTIVEDATE, 104) as rdate
                   , convert(varchar(5), convert(nvarchar(5), '+@wh+'.ITRN.editdate, 108)) as rhour
                   , CASE WHEN TRANTYPE = ''WD'' AND SOURCETYPE = ''ntrPickDetailUpdate'' THEN '''' 
	                      WHEN TRANTYPE = ''AJ'' THEN '''' 
	                      WHEN TRANTYPE = ''MV'' AND SOURCETYPE = '''' THEN '''' 
	                      WHEN TRANTYPE = ''MV'' AND SOURCETYPE = ''nspRFTRP01'' THEN ''Пополнение'' 
	                      WHEN TRANTYPE = ''MV'' AND SOURCETYPE = ''PICKING'' THEN ''Отбор'' 
	                      WHEN TRANTYPE = ''DP'' THEN ''Приемка'' 
	                      WHEN TRANTYPE = ''MV'' THEN ''Перемещение'' 
	                      END AS TYPE
                FROM '+@wh+'.ITRN  WITH (NOLOCK)
                WHERE ('+@wh+'.ITRN.EFFECTIVEDATE >= convert(datetime, convert(char(8), GetDate(), 112), 112))
             ) AS TASKS
        WHERE TASKS.TYPE <> '''' 
     UNION
     SELECT LOADS.EDITDATE, LOADS.TYPE, LOADS.SERIALKEY, LOADS.rdate
          , substring(LOADS.rhour,1,3) + convert(varchar(2),floor(cast(substring(LOADS.rhour,4,2) as int)/30)*3)+''0'' as rhour
       FROM (SELECT '+@wh+'.DROPIDDETAIL.ADDDATE AS EDITDATE, '+@wh+'.DROPIDDETAIL.SERIALKEY
                  , convert(nvarchar(10), '+@wh+'.DROPIDDETAIL.ADDDATE, 104) as rdate
                  , convert(varchar(5), convert(nvarchar(5), '+@wh+'.DROPIDDETAIL.ADDDATE, 108)) as rhour
                  , ''Загрузка'' AS TYPE 
               FROM '+@wh+'.DROPIDDETAIL (NOLOCK) 
               WHERE '+@wh+'.DROPIDDETAIL.IDTYPE=4 
                AND ('+@wh+'.DROPIDDETAIL.ADDDATE >= convert(datetime, convert(char(8), GetDate(), 112), 112))
            ) LOADS
     ) as iq
  group by iq.type, iq.rdate, iq.rhour
  order by iq.type, iq.rhour'
    exec (@sql)
END

