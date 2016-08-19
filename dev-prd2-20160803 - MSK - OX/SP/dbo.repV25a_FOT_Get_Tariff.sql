-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 03.03.2010 (НОВЭКС)
-- Описание: Вывод тариффов
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV25a_FOT_Get_Tariff] ( 
	@Tmin decimal(22,2),
	@Proc int,
	@shag int
)
as 

create table #tab_Tarrif (
		strD varchar(15) not null, -- Строчка
		MinSO decimal(22,1) not null, -- Минимальное значение
		MaxSO decimal(22,1) not null, -- Максимальное значение
		TRub decimal(22,2) not null -- Тарифф
)

insert into #tab_Tarrif
select *
from [dbo].[TShag](0,@shag,@Tmin,@Proc,15)

select *
from #tab_Tarrif

