


ALTER PROCEDURE [rep].[GetNewMarkID] (@wh varchar(10)='dbo', @MarkName varchar(30), @count varchar(10)=1)
as
	declare @ID int,			-- текущее значение счетчика
			@prefix varchar(10),	-- префикс в ШК этикетки
			@newID varchar(10), -- текущее значение счетчика в строковом виде
			@countC int, -- количество этикеток
			@headin varchar (50), -- текст заголовка этикетки
			@t int, -- неиспользуется
			@const_maxLenOfID int -- максимальная длина ID. константа. всегда равно 10
	create table #ArrayLabel (id varchar(127), header varchar(50))


	-- задаем число символов в ID. По умолчанию должно быть 10
	set @const_maxLenOfID = 10
set @t=0;
	while (@count > 0 ) -- количество этикеток
		begin
			select @countC = count_copy, @headin = head	from dbo.MarkersCounter where name like @MarkName -- считывание количества копий каждой этикетки

			update dbo.MarkersCounter set @ID = counter, -- текущее значение счетчика
										@prefix = prefix, -- префикс
										counter = counter+1 -- увеличение на единицу счетчика
				where (whseid like @wh)		-- ключ разделения 
					and (name like @MarkName)	-- имя этикетки

			set @newID = cast(@ID as varchar(10)) -- преобразование текущего значения счетчика в строковый тип

			declare @ln as int, -- длина в символах текущего значения счетчика
					@lp int	-- длина префикса для ШК этикетки

			-- вычисление длины значащей части ID и префикса
			select @ln = len(@newID), @lp = len(@prefix) 
			
			-- преобразование к 10разрядному виду с учетом длин префикса и значащей части ID
			set @newID = @prefix+replicate ('0',@const_maxLenOfID-@ln-@lp)+@newID 

			while (@countC > 0) -- количество копий этикеток
				begin
					insert into #ArrayLabel (id, header) values (@newID,@headin)
					set @countC = @countC - 1;
				end
			set @count = @count - 1;
		end
		--select top 1 @outValue = ID from #ArrayLabel

select dbo.GetEAN128(id), header, id as numb from #ArrayLabel -- вывод результата
drop table #ArrayLabel


