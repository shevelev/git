-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 15.02.2010 (НОВЭКС)
-- Описание: Получение списка номеров волны из WAVEDETAIL.WAVEKEY
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV15a_WaveTime_GetWAVEKEY] 
	@wh varchar(10),
	@datebegin datetime,
	@dateend datetime,
	@statwave varchar(5)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(10)

set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(10),@dateend+1,112)

set @sql='
set dateformat dmy
declare @tbl table (WAVEKEY varchar(10))
insert into @tbl
select distinct(wd.wavekey)
from '+@wh+'.WAVEDETAIL wd
left join '+@wh+'.wave w on wd.wavekey=w.wavekey
where  orderkey in (select ord.orderkey
					from '+@wh+'.orders ord
					left join '+@wh+'.orderdetail ordet on ord.orderkey=ordet.orderkey
					where (ord.status=''02'' or ord.status=''14''
						  or ord.status=''17'' or ord.status=''19''
						  or ord.status=''52'')
						  and ord.requestedshipdate between '''+@bdate+''' and '''+@edate+'''
						  and ordet.status<>''55''
					)
		and '+  case when @statwave='0' then 'w.status<>''9'''
					else
						case when @statwave='1' then 'w.status=''0'''
								else 'w.status=''5'''
						end
				end+'		

select WAVEKEY from @tbl'

print(@sql)
exec (@sql)

END

