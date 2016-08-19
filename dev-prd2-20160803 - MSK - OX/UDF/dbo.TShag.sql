-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 05.05.2010 (НОВЭКС)
-- Описание: Создает таблицу с тариффами с начального по шагам
--	...
-- =============================================
ALTER FUNCTION [dbo].[TShag] 
(
@minZ decimal(22,2),
@shag int,
@znach decimal(22,2),
@proc int,
@kolstr int
)
RETURNS 
@outer TABLE 
(
strD varchar(15) not null,
minZ decimal(22,2) not null,
maxZ decimal(22,2) not null,
Itog decimal(22,2)
)
AS
BEGIN 

DECLARE @I INT,
		@Ch2 decimal(22,2),
		@maxZ decimal(22,2)

SET @I=0
--Set @Ch2=0.1
Set @maxZ=@minZ+@shag

while @I<@kolstr
	begin
		INSERT into @outer VALUES(cast(@minZ as varchar(10))+' - '+ cast(@maxZ as varchar(10)),@minZ,@maxZ,@znach)
		set @minZ=@maxZ
		--set @minZ=@maxZ+@Ch2
		set @maxZ=@maxZ+@shag
		set @znach=(@znach*@proc)/100
		set @I=@I+1
	end

RETURN 

END

