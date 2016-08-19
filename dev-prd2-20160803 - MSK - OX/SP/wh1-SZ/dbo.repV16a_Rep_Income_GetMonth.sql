-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 03.03.2010 (НОВЭКС)
-- Описание: Сводный отчет по доходам (новый)
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV16a_Rep_Income_GetMonth] ( 
	@tekdate int
)

as

create table #table_month (
		RN int not null, -- Номер
		Label varchar(15) not null, -- Метка
		VValue varchar(15) not null -- Описание
)

declare @tdate varchar(10)

insert into #table_month values(1,'январь','01')
insert into #table_month values(2,'февраль','02')
insert into #table_month values(3,'март','03')
insert into #table_month values(4,'апрель','04')
insert into #table_month values(5,'май','05')
insert into #table_month values(6,'июнь','06')
insert into #table_month values(7,'июль','07')
insert into #table_month values(8,'август','08')
insert into #table_month values(9,'сентябрь','09')
insert into #table_month values(10,'октябрь','10')
insert into #table_month values(11,'ноябрь','11')
insert into #table_month values(12,'декабрь','12')

if @tekdate=1 
	begin
		set @tdate=convert(varchar(10),getdate(),112)
		select *
		from #table_month
		where vvalue=substring(@tdate,5,2)
		order by RN
	end
else
	begin
		select *
		from #table_month
		order by RN
	end

drop table #table_month

