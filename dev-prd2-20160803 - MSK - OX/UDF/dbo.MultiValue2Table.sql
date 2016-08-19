-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 15.02.2010 (НОВЭКС)
-- Описание: Преобразует Multi выбор в таблицу
--	...
-- =============================================
ALTER FUNCTION [dbo].[MultiValue2Table] 
(
@REGION VARCHAR(max)
)
RETURNS 
@outer TABLE 
(
strin VARCHAR(1000) 
)
AS
BEGIN 

DECLARE @I INT,
		@pozi int,
		@pozf int

SET @I=0
Set @pozi=0
set @pozf=Charindex(',',@Region)

while @Region like'%,%'
	begin
		INSERT into @outer VALUES(substring(@Region,(@pozi),(@pozf)))
		set @region=substring(@Region,(@pozf+1),(len(@Region)-(@pozf)))
		set @pozi=0
		set @Pozf=Charindex(',',@Region)
	end

INSERT into @outer VALUES(@Region)

RETURN 

END

