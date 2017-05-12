-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 25.01.2010 (НОВЭКС)
-- Описание: Получение списка номеров волны из WAVEDETAIL.WAVEKEY
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV12a_WaveRezerv_GetWAVEKEY] 
	@wh varchar(10),
	@datebegin datetime,
	@dateend datetime
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
select distinct WAVEKEY from '+@wh+'.WAVE
where ADDDATE between '''+@bdate+''' and '''+@edate+'''
		and STATUS<>''9''
order by WAVEKEY desc

select WAVEKEY from @tbl'

print(@sql)
exec (@sql)

END

