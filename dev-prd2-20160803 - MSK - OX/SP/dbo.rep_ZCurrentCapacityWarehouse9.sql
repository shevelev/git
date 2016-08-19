-- Author:		Юрчук Жанна
-- Create date: 13.05.2008
-- Description:	Для отчета Текущая загрузка склада (сводный отчет) часть 9, который
-- выводит всю необходимую информацию для принятия управленческих решений
-- =============================================
ALTER PROCEDURE [dbo].[rep_ZCurrentCapacityWarehouse9] 
	@wh VarChar(30)
  , @startdate VarChar(10)
AS
BEGIN
	set @wh = upper(@wh)
	declare @sql varchar(max)
	set @sql = 'select usr_name,  iq.rhour, count(iq.SERIALKEY) as tasks
  from (SELECT TASKS.EDITDATE, TASKS.EDITWHO, TASKS.SERIALKEY, TASKS.rdate
             , substring(TASKS.rhour,1,2)  as rhour
          FROM (SELECT '+@wh+'.ITRN.EDITDATE, '+@wh+'.ITRN.SERIALKEY
                     , convert(nvarchar(10), '+@wh+'.ITRN.EFFECTIVEDATE, 104) as rdate
                     , convert(varchar(5), convert(nvarchar(5), '+@wh+'.ITRN.editdate, 108)) as rhour
                     , '+@wh+'.ITRN.EDITWHO
                  FROM '+@wh+'.ITRN  WITH (NOLOCK)
                  WHERE TRANTYPE = ''MV'' AND SOURCETYPE = ''PICKING'' 
                    and (('+@wh+'.ITRN.EFFECTIVEDATE >= convert(DateTime,'''+@startdate+''',104)) 
                    AND (convert(nvarchar(10), '+@wh+'.ITRN.EFFECTIVEDATE, 104)  = convert(nvarchar(10), convert(datetime, convert(char(8), GetDate(), 112), 112), 104)))
               ) AS TASKS
       ) as iq
       INNER JOIN ssaadmin.pl_usr ON iq.EDITWHO = ssaadmin.pl_usr.usr_login
  group by usr_name, iq.rdate, iq.rhour
  order by usr_name, iq.rhour'
    exec (@sql)
END

