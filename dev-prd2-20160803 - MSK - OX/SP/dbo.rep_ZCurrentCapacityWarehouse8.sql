-- Author:		Юрчук Жанна
-- Create date: 13.05.2008
-- Description:	Для отчета Текущая загрузка склада (сводный отчет) часть 8, который
-- выводит всю необходимую информацию для принятия управленческих решений
-- =============================================
ALTER PROCEDURE [dbo].[rep_ZCurrentCapacityWarehouse8] 
	@wh VarChar(30)
AS
BEGIN
	set @wh = upper(@wh)
	declare @sql varchar(max)
	set @sql = 'SELECT CAST(CONVERT(VARCHAR(10),MAX(EFFECTIVEDATE),103) as DATETIME) AS MAXDATE, MAX(EFFECTIVEDATE) AS MAXTIME 
                  FROM '+@wh+'.ITRN (NOLOCK)'
    exec (@sql)
END

