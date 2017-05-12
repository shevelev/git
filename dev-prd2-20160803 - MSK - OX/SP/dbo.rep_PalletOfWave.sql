-- =============================================
-- Author:		Сандаков В.В.
-- Create date: 23.06.08
-- Description:	Отчет по волнам
-- =============================================
ALTER PROCEDURE [dbo].[rep_PalletOfWave]
	@wh varchar(10),
	@wave varchar(20)
AS

declare @sql varchar(max)

----для проверки
--declare @wave varchar(20)
--declare @wh varchar(10)
--set @wh = 'wh40'
--set @wave = '0000000438'

set @sql = 'select wd.WAVEKEY, wd.ORDERKEY, pd.SKU, s.descr, count(distinct (pd.PDUDF1)) summa
from '+@wh+'.WAVEDETAIL wd
join '+@wh+'.PICKDETAIL pd on pd.orderkey = wd.orderkey
join '+@wh+'.SKU s on s.sku = pd.sku
where (wd.WAVEKEY = '+@wave+' ) and (pd.status < 8) and (pd.PDUDF1 is not null) and (PDUDF1 <> '''')
group by wd.WAVEKEY, wd.ORDERKEY, pd.SKU, s.descr '

exec (@sql)

