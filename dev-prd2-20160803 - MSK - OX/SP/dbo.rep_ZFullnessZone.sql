-- =============================================
-- Author:		Юрчук Жанна
-- Create date: 29.04.2008
-- Description:	Для отчета Заполненность зон, который выводит кол-во заполненных ячеек на тек. дату
-- с разбивкой по участкам и зонам.
-- =============================================
ALTER PROCEDURE [dbo].[rep_ZFullnessZone] 
	@wh VarChar(30)
AS
BEGIN
	set @wh = upper(@wh)
	declare @sql varchar(max)
	set @sql = 'SELECT ALLLOCAREA.AREAKEY, '+@wh+'.PUTAWAYZONE.DESCR
                     , LOCAREA.loccount, ALLLOCAREA.allcount
                     , ALLLOCZONE.PUTAWAYZONE, LOCZONE.loccountzone, ALLLOCZONE.allcountzone
                  FROM (SELECT '+@wh+'.AREADETAIL.AREAKEY, COUNT(DISTINCT '+@wh+'.LOC.LOC) AS allcount
                          FROM '+@wh+'.AREADETAIL LEFT OUTER JOIN '+@wh+'.LOC 
                            ON '+@wh+'.LOC.PUTAWAYZONE = '+@wh+'.AREADETAIL.PUTAWAYZONE 
                          WHERE AREAKEY LIKE ''F%''
                          GROUP BY '+@wh+'.AREADETAIL.AREAKEY 
                          HAVING (COUNT(DISTINCT '+@wh+'.LOC.LOC) > 1) 
                       ) as ALLLOCAREA
                       LEFT JOIN
                       (SELECT '+@wh+'.AREADETAIL.AREAKEY, COUNT(DISTINCT '+@wh+'.LOC.LOC) AS loccount
                          FROM '+@wh+'.LOC LEFT OUTER JOIN
                               '+@wh+'.LOTXLOCXID ON '+@wh+'.LOC.LOC = '+@wh+'.LOTXLOCXID.LOC RIGHT OUTER JOIN
                               '+@wh+'.AREADETAIL ON '+@wh+'.LOC.PUTAWAYZONE = '+@wh+'.AREADETAIL.PUTAWAYZONE
                          WHERE ('+@wh+'.LOTXLOCXID.QTY > 0) AND AREAKEY LIKE ''F%''
                          GROUP BY '+@wh+'.AREADETAIL.AREAKEY
                       ) as LOCAREA 
                    ON LOCAREA.AREAKEY = ALLLOCAREA.AREAKEY
                       LEFT JOIN
                       (SELECT '+@wh+'.AREADETAIL.AREAKEY, '+@wh+'.LOC.PUTAWAYZONE
                             , COUNT(DISTINCT '+@wh+'.LOC.LOC) AS allcountzone
                          FROM '+@wh+'.AREADETAIL LEFT OUTER JOIN
                               '+@wh+'.LOC ON '+@wh+'.LOC.PUTAWAYZONE = '+@wh+'.AREADETAIL.PUTAWAYZONE 
                          WHERE AREAKEY LIKE ''F%''
                          GROUP BY '+@wh+'.AREADETAIL.AREAKEY, '+@wh+'.LOC.PUTAWAYZONE 
                          HAVING (COUNT(DISTINCT '+@wh+'.LOC.LOC) > 1) 
                       ) as ALLLOCZONE ON ALLLOCZONE.AREAKEY = ALLLOCAREA.AREAKEY
                       LEFT JOIN
                       (SELECT '+@wh+'.AREADETAIL.AREAKEY, '+@wh+'.LOC.PUTAWAYZONE
                             , COUNT(DISTINCT '+@wh+'.LOC.LOC) AS loccountzone
                          FROM '+@wh+'.LOC LEFT OUTER JOIN
                               '+@wh+'.LOTXLOCXID ON '+@wh+'.LOC.LOC = '+@wh+'.LOTXLOCXID.LOC RIGHT OUTER JOIN
                               '+@wh+'.AREADETAIL ON '+@wh+'.LOC.PUTAWAYZONE = '+@wh+'.AREADETAIL.PUTAWAYZONE
                          WHERE ('+@wh+'.LOTXLOCXID.QTY > 0) AND AREAKEY LIKE ''F%''
                          GROUP BY '+@wh+'.AREADETAIL.AREAKEY, '+@wh+'.LOC.PUTAWAYZONE
                       ) as LOCZONE 
                    ON LOCZONE.AREAKEY = ALLLOCAREA.AREAKEY AND LOCZONE.PUTAWAYZONE = ALLLOCZONE.PUTAWAYZONE
                       LEFT JOIN '+@wh+'.PUTAWAYZONE 
                    ON '+@wh+'.PUTAWAYZONE.PUTAWAYZONE = ALLLOCZONE.PUTAWAYZONE
                  ORDER BY ALLLOCAREA.AREAKEY'
    exec (@sql)
END

