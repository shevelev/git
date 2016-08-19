/*
ѕолучение строки @number единиц времени @datepart
ќпорна€ дата событи€ - дл€ более точного подсчета разр€дов. »меет смысл только дл€ @destination = 4
*/
ALTER FUNCTION dbo.udf_common_get_datepart_suffix (
	@datepart varchar(10), -- как в функции DATEADD
	@number int, -- количество единиц времени
	@event_date datetime, -- необ€зательно - опорна€ дата событи€ (до которого осталось @number @datepart'ов)
	@destination tinyint -- 1 Ц только суффикс, 2 Ц число и суффикс, 3 Ц строка и суффикс, 4 Ц с группировкой по старшим разр€дам
)
RETURNS varchar(200)
AS
BEGIN
	
	declare @DATEPARTS table (
		DATEPART_ID tinyint NOT NULL,
		PARENT_DATEPART_ID tinyint NULL,
		GENDER tinyint NOT NULL,
		FORM_1 varchar(50) NOT NULL,
		FORM_2 varchar(50) NOT NULL,
		FORM_3 varchar(50) NOT NULL
	)
	
	insert into @DATEPARTS values (1, NULL, 1, 'год',     'года',     'лет'       )
	insert into @DATEPARTS values (2,  1,   1, 'квартал', 'квартала', 'кварталов' )
	insert into @DATEPARTS values (3,  1,   1, 'мес€ц',   'мес€ца',   'мес€цев'   )
	insert into @DATEPARTS values (4,  1,   2, 'недел€',  'недели',   'недель'    )
	insert into @DATEPARTS values (5,  3,   1, 'день',    'дн€',      'дней'      )
	insert into @DATEPARTS values (6,  5,   1, 'час',     'часа',     'часов'     )
	insert into @DATEPARTS values (7,  6,   2, 'минута',  'минуты',   'минут'     )
	insert into @DATEPARTS values (8,  7,   2, 'секунда', 'секунды',  'секунд'    )
	
	declare
		@base_date datetime, -- базова€ дата (сейчас)
		@test_date datetime, -- тестова€ дата (оказываетс€, datediff считает ќ„≈Ќ№ грубо)
		@datepart_id tinyint
	
	if @datepart in ('year','yy','yyyy') select @datepart_id = 1, @base_date = dateadd(yy,-@number,@event_date)
	if @datepart in ('quarter','qq','q') select @datepart_id = 2, @base_date = dateadd(qq,-@number,@event_date)
	if @datepart in ('month','mm','m')   select @datepart_id = 3, @base_date = dateadd(mm,-@number,@event_date)
	if @datepart in ('week','wk','ww')   select @datepart_id = 4, @base_date = dateadd(wk,-@number,@event_date)
	if @datepart in ('day','dd','d')     select @datepart_id = 5, @base_date = dateadd(dd,-@number,@event_date)
	if @datepart in ('hour','hh')        select @datepart_id = 6, @base_date = dateadd(hh,-@number,@event_date)
	if @datepart in ('minute','mi','n')  select @datepart_id = 7, @base_date = dateadd(mi,-@number,@event_date)
	if @datepart in ('second','ss','s')  select @datepart_id = 8, @base_date = dateadd(ss,-@number,@event_date)
	
	if @datepart_id is NULL
	or @destination not in (1,2,3,4)
		return NULL
	
	--if @number = 0
	--	return 'сейчас'
	
	
	if @event_date is NULL
		select
			@base_date = getdate(),
			@event_date = dbo.sub_udf_common_dateadd(@datepart_id,@number,@base_date)
	
	-- дл€ @destination in (3,4) и не указанном количестве дальше выйдет пуста€ строка. ѕоэтому делаем подмену.
	if @number = 0 and @destination in (3,4)
		return dbo.udf_common_get_datepart_suffix(@datepart, @number, NULL, 2)
	
	
	if @number < 0
		select
			@number = -@number,
			@test_date = @event_date,
			@event_date = @base_date,
			@base_date = @test_date
	
	
	-- -- 8< -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	
	declare
		@last_digits tinyint,
		@i int,
		@gender tinyint,
		@form_1 varchar(20),
		@form_2 varchar(20),
		@form_3 varchar(20),
		@suffix varchar(20),
		@datepart_with_suffix varchar(200);
	
	declare c cursor local fast_forward read_only for
		with tree ( DATEPART_ID, PARENT_DATEPART_ID ) as (
			select d.DATEPART_ID, d.PARENT_DATEPART_ID
			from @DATEPARTS d
			where d.DATEPART_ID = @datepart_id
			union all
			select d.DATEPART_ID, d.PARENT_DATEPART_ID
			from @DATEPARTS d
				join tree t on d.DATEPART_ID = t.PARENT_DATEPART_ID
			where @destination = 4 -- старшие разр€ды только по требованию
		)
		select d.DATEPART_ID, d.GENDER, d.FORM_1, d.FORM_2, d.FORM_3
		from tree t
			join @DATEPARTS d on t.DATEPART_ID = d.DATEPART_ID
		order by d.DATEPART_ID
	
	open c
	
	while 1=1
	begin
		fetch from c into @datepart_id, @gender, @form_1, @form_2, @form_3
		if @@FETCH_STATUS <> 0 break
		
		set @i = dbo.sub_udf_common_datediff(@datepart_id,@base_date,@event_date)
		
		set @test_date = dbo.sub_udf_common_dateadd(@datepart_id,@i,@base_date)
		
		if @test_date > @event_date
			-- datediff промахнулс€ !!! >:]
			select @i = @i - 1
		
		if @i >= 0
		begin
			
			set @base_date = dbo.sub_udf_common_dateadd(@datepart_id,@i,@base_date)
			
			set @last_digits = @i % 100;
			
			if @last_digits between 10 and 19
				set @suffix = @form_3;
			else
			begin
				set @last_digits = @i % 10;
				set @suffix = case
								when @last_digits = 1 then @form_1
								when @last_digits between 2 and 4 then @form_2
								else @form_3 
							end;
			end
			
			
			set @datepart_with_suffix = ltrim(isnull(@datepart_with_suffix + ' ','')
					+ case @destination
							when 1 then @suffix
							when 2 then convert(varchar(12),@i) + ' ' + @suffix
							when 3 then isnull(dbo.udf_common_get_number_as_string(nullif(@i,0),@gender) + ' ' + @suffix,'')
							when 4 then isnull(convert(varchar(12),nullif(@i,0)) + ' ' + @suffix,'')
						end
				)
		end
		
	end
	
	close c
	deallocate c
	
	return @datepart_with_suffix;
END

