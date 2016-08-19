-- =============================================
-- Автор:		Тын Максим
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 27/01/2010 (НОВЭКС)
-- Описание: Биллинг кол-ва и времени отбора товара.
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repF04_timeBillingPick](
	

	@userkey varchar(18),
	@datebegin datetime,
	@dateend datetime
)
AS
		

select td.caseid, (sk.cartongroup) carton, sum(td.qty*sk.stdcube) skcube, min(td.starttime) starttime, max(td.endtime) endtime
	, convert(varchar(10), max(td.endtime) - min(td.starttime),108) timeid, count(distinct td.orderlinenumber) line
from wh1.taskdetail td
	join wh1.sku sk on td.storerkey=sk.storerkey and td.sku=sk.sku
where 
	td.userkey=@userkey and td.tasktype='PK' and (td.starttime between @datebegin and @dateend+1)

group by td.caseid, sk.cartongroup

order by td.caseid desc


--select *
--from wh1.taskdetail td
--where	td.userkey='dubovcova'

