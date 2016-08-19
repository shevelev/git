
ALTER PROCEDURE dbo.JS_SettingsApply(@pshm sysname = null, 
		@ptbl sysname = null,
		@pLogInsert tinyint = null,
		@pLogUpdate tinyint = null,
		@pLogDelete tinyint = null,
		@prebuildStructure tinyint = null, -- 0 - Таблица создается если ее нет, триггера создаются если их нет, создаются только триггера указанные в buildTriggers
								   -- 1 - пересоздавать таблицу(с потерей данных), пересоздать триггера (необходимо в случае изменения набора полей)
								   --      триггера удалятся все, создадутся только указанные в buildTriggers
								   -- 2 - удалить триггера (триггер удаляются все разом, независимо от параметра buildTriggers)
								   -- 3 - удалить таблицу-журнал и триггера
								   -- 4 - удалить данные в таблице-журнале
								   -- 5 - пересоздать триггера
								   -- прочие значения приравниваются нулю
		@pbuildTriggers tinyint = null,
		@pInsWhere varchar(max)='',@pUpdWhere varchar(max)='',@pDelWhere varchar(max)=''
								-- условия выбора данных из таблиц inserted/deleted. Формат: where <clause>
								-- результатом будет строка в триггере вида 
								-- insert into js_<table> select <fields> from inserted|deleted where <field>=<expression>.
								-- т.е. будет добавлено в конце условие выбора.
								-- для update триггера - условие одинаковое для удаляемой и для вставляемой записей.
		)
as

set nocount on
print 'version 1.1 from 2015/02/25'
declare @id int,
		@shm sysname, 
		@tbl sysname ,
		@LogInsert tinyint,
		@LogUpdate tinyint,
		@LogDelete tinyint,
		@rebuildStructure tinyint, -- 0 - Таблица создается если ее нет, триггера создаются если их нет, создаются только триггера указанные в buildTriggers
								   -- 1 - пересоздавать таблицу(с потерей данных), пересоздать триггера (необходимо в случае изменения набора полей)
								   --      триггера удалятся все, создадутся только указанные в buildTriggers
								   -- 2 - удалить триггера (триггер удаляются все разом, независимо от параметра buildTriggers)
								   -- 3 - удалить таблицу-журнал и триггера
								   -- 4 - удалить данные в таблице-журнале
								   -- 5 - пересоздать триггера
								   -- прочие значения приравниваются нулю
		@buildTriggers tinyint,  -- use bits; 0 - insert, 1 - update, 2- delete. 
								/* Decimal values are:
									-- 0 - no triggers
									-- 1 - Insert
									-- 2 - Update
									-- 3 - Insert, Update
									-- 4 - Delete
									-- 5 - Insert, Delete
									-- 6 - Update, Delete
									-- 7 - Insert, Update, Delete
								*/
		@InsWhere varchar(max), -- условия выбора данных из таблиц inserted/deleted. Формат: <clause>
		@UpdWhere varchar(max), -- результатом будет строка в триггере 
		@DelWhere varchar(max)  -- insert into js_<table> select <fields> from inserted|deleted where <clause>.
								-- <clause> := полностью в той форме, в какой оно пишется в запросах.

set @InsWhere = case when isnull(@pInsWhere,'') != '' then ' where ' else '' end + isnull(@pInsWhere,'')
set @UpdWhere = case when isnull(@pUpdWhere,'') != '' then ' where ' else '' end + isnull(@pUpdWhere,'')
set @DelWhere = case when isnull(@pDelWhere,'') != '' then ' where ' else '' end + isnull(@pDelWhere,'')

										
declare @sql varchar(max)
declare @colList varchar(max)
declare @colsDef varchar(max)
declare @enter varchar(5)
set @enter = char(10)


--#region Внесение данных в таблицу настроек из параметров процедуры
if (not @pshm is null and not @ptbl is null and @@NESTLEVEL = 1)
	if exists (select 1 from dbo.js_Settings where shm=@pshm and tbl = @ptbl)	
	begin
		select @id = ID from dbo.JS_Settings where shm=@pshm and tbl = @ptbl
		update dbo.JS_Settings 
		set [LogInsert] = ISNULL(@pLogInsert,[LogInsert]),[LogUpdate] = ISNULL(@pLogUpdate,[LogUpdate]),[LogDelete] = ISNULL(@pLogDelete,[LogDelete]),
			[rebuildStructure] = ISNULL(@prebuildStructure,[rebuildStructure]),[buildTriggers] = ISNULL(@pbuildTriggers,[buildTriggers])
		where ID=@id
	end
	else
	begin
		INSERT INTO dbo.JS_Settings ([shm],[tbl],[LogInsert],[LogUpdate],[LogDelete],[rebuildStructure],[buildTriggers]) 
		VALUES (@pshm, @ptbl, isnull(@pLogInsert,0), isnull(@pLogUpdate,0), isnull(@pLogDelete,0), isnull(@prebuildStructure,0), isnull(@pbuildTriggers,7))
		set @id = SCOPE_IDENTITY()
	end
else
	set @id = null	
	
--#endregion Внесение данных в таблицу настроек из параметров процедуры

declare @settings table (
	[id] [int] NOT NULL,
	[shm] [sysname] NOT NULL,
	[tbl] [sysname] NOT NULL,
	[LogInsert] [tinyint] NOT NULL,
	[LogUpdate] [tinyint] NOT NULL,
	[LogDelete] [tinyint] NOT NULL,
	[rebuildStructure] [tinyint] NOT NULL,
	[buildTriggers] [tinyint] NOT NULL
)
	
	
--if object_id('tempdb..#settings') is not null drop table #settings
if @@NESTLEVEL = 1
begin
	insert into @settings (id, shm, tbl, LogInsert, LogUpdate, LogDelete, rebuildStructure, buildTriggers)
	--select * into #settings from dbo.js_settings where ID = isnull(@id,0) or @id is null 
	select id, shm, tbl, LogInsert, LogUpdate, LogDelete, rebuildStructure, buildTriggers
	from dbo.js_settings where ID = isnull(@id,0) or @id is null
end
else
begin 
	set @id = 1
	insert into @settings (id, shm, tbl, LogInsert, LogUpdate, LogDelete, rebuildStructure, buildTriggers)
	VALUES (@id, @pshm, @ptbl, isnull(@pLogInsert,0), isnull(@pLogUpdate,0), isnull(@pLogDelete,0), isnull(@prebuildStructure,0), isnull(@pbuildTriggers,7))
end

while exists(select top 1 1 from @settings) 
begin
	set @sql = ''
	select top 1 @id = id, @shm = shm, @tbl = tbl,
		@LogInsert = LogInsert,	@LogUpdate = LogUpdate,	@LogDelete = LogDelete,
		@rebuildStructure = rebuildStructure, @buildTriggers = buildTriggers
	from @settings 


--#region Получение структуры таблицы
	if object_id('tempdb..#defs')is not null drop table #defs
	
	select @shm schemaName, @tbl tablename, sc.name colname, st.name typename, 
			sc.prec, sc.scale, sc.collation, cast(null as varchar(max))colDef--, sc.*, st.*
	into #defs
	from syscolumns sc
		join systypes st on sc.xtype = st.xtype and st.status = 0
	where sc.id = object_id(@shm+'.'+@tbl)
	
	-- формирование описаний полей
	update #defs set coldef = colname+' ' + 	typename + 
		case typename
			when 'varchar' then '(' + cast (prec as varchar) + ')'
			when 'nvarchar' then '(' + cast (prec as varchar) + ')'
			when 'char' then '(' + cast (prec as varchar) + ')'
			when 'nchar' then '(' + cast (prec as varchar) + ')'
			when 'bit' then ''
			when 'float' then ''
			when 'int' then ''
			when 'tibyint' then ''
			when 'decimal'  then '(' + cast (prec as varchar)+','+cast (scale as varchar) + ')'
			when 'datetime' then ''
			when 'smalldatetime' then ''
			else null -- если тип не прописан выше, то описание не создается, поле не логируется
		end
		+ ' null'+
		''--' TODO: сюда дописать collation для символьных типов'
--select * from #defs
	-- удаление колонок для которых нет описания
	delete from #defs where coldef is null
	-- формирование списка колонок в строку для операций insert, select в триггере
	select @collist= (select colname+',' from #defs for xml path(''))
	set @collist = substring(@collist,1,len(@collist)-1)
	--print @collist
	
	
	-- формирование описаний колонок в "одну строку"	
	select @colsDef= (select coldef + ', '	from #defs for xml path(''))
	set @colsDef = substring(@colsDef,1,len(@colsDef)-1)
	--print @colsDef
	
--#endregion Получение структуры таблицы

	-- если задано не известное значение - сбросить в 0
	if @rebuildStructure > 5 set @rebuildStructure = 0
	
--#region Создание/пересоздание структуры таблицы
	
	-- Удаление таблицы-журнала
	if @rebuildStructure in (1,3) and object_id('dbo.JS_'+@tbl) is not null
	begin
		-- отключить все триггера перед удалением таблицы
		exec dbo.JS_SettingsApply @shm,@tbl,0,0,0

		set @sql = 'drop table '+'dbo.JS_'+@tbl+''+@enter+''+@enter
		print @sql
		exec (@sql)
	end
	
	-- создание таблицы-журнала, если ее нет.
	if @rebuildStructure in (0,1) and object_id('dbo.JS_'+@tbl) is null
	begin
		set @sql='CREATE TABLE dbo.JS_'+@tbl + '(' 
		+ '	js_id int identity(1,1) not null,
			dt datetime not null default(getutcdate()),
			op int not null,
			db_user nvarchar(50) not null default(''wmwhse1''),
			sys_user nvarchar(50) not null default (''wmwhse1''),'+@enter
		+ @colsDef 
		+ ')' + @enter + ''+ @enter +
		'
		grant select,insert on dbo.JS_'+@tbl+' to ' + @shm 
		+@enter+''+@enter
		exec (@sql)
		print @sql
	end
	
--#endregion Создание/пересоздание структуры таблицы

--#region Создание шаблонов триггеров

	set @sql = ''
	declare @trTemplate varchar(max), @trjsinsertTemplate varchar(max), @trDropTemplate varchar(200)
	
	set @trDropTemplate = 'drop trigger '+@shm+ '.JS_'+@tbl+'_'
	
	set @trjsinsertTemplate = 'insert into dbo.js_'+@tbl+' (dt, op, db_user, sys_user, '+@collist+')
    select @dt,@P2,CURRENT_USER, SYSTEM_USER,
	'+@collist+'
	from @P3 @P5' 
	
	set @trTemplate = 'CREATE TRIGGER '+@shm+'.JS_'+@tbl+'_@P1 
   ON  '+@shm+'.'+@tbl+' 
   AFTER @P1
AS 
BEGIN
	SET NOCOUNT ON;
	--if @@nestlevel>1 return;
	declare @dt datetime
	set @dt=getutcdate()
	
	@P4

END
'
--#endregion Создание шаблонов триггеров
	
--#region Удаление триггеров
	
	declare @trDropIns varchar(max), @trDropUpd varchar(max), @trDropDel varchar(max)
	
	set @trDropIns = @trDropTemplate+'Insert'+@enter+''+@enter
	set @trDropUpd = @trDropTemplate+'Update'+@enter+''+@enter
	set @trDropDel = @trDropTemplate+'Delete'+@enter+''+@enter

	if (@rebuildStructure in (1,2,3,5))
	begin
		if object_id( @shm+ '.JS_'+@tbl+'_Insert') is not null
		begin
			print @trDropIns
			exec(@trDropIns)
		end
		
		if object_id( @shm+ '.JS_'+@tbl+'_Update') is not null
		begin
			print @trDropUpd
			exec(@trDropUpd)
		end
		
		if object_id( @shm+ '.JS_'+@tbl+'_Delete') is not null
		begin
			print @trDropDel
			exec(@trDropDel)
		end
	
	end
--#endregion Удаление триггеров
	
--#region Создание триггеров

	declare @trIns varchar(max), @trUpd varchar(max), @trDel varchar(max)

	if @rebuildStructure in (0,1,5) and @@NESTLEVEL=1
	begin 
		-- пересоздать триггер на Insert
		if (@buildTriggers & 1 = 1) and object_id( @shm+ '.JS_'+@tbl+'_Insert') is null  
		begin
			set @trIns = @trTemplate
			set @trIns = replace(@trIns,'@P1','Insert') -- задаем тип триггера в названии
			set @trIns = replace(@trIns,'@P4',			-- @P4 - строка вставки данных в js_таблицу
					replace(replace(@trjsinsertTemplate,'@P2','11')	-- @P2 - тип операции
								,'@P3','inserted') +';'+ @enter		-- @P3 - таблица-источник данных
			)
			set @trIns = replace(@trIns,'@P5',@InsWhere) -- @P5 - условие where

			print @trIns
			exec (@trIns)
		end
	
		-- пересоздать триггер на Update
		if (@buildTriggers & 2 = 2) and object_id( @shm+ '.JS_'+@tbl+'_Update') is null
		begin
			
			set @trUpd = @trTemplate
			set @trUpd = replace(@trUpd,'@P1','Update')	-- задаем тип триггера в названии
			set @trUpd = replace(@trUpd,'@P4',			-- @P4 - строка вставки данных в js_таблицу
					replace(replace(@trjsinsertTemplate,'@P2','21')	-- @P2 - тип операции
									,'@P3','deleted') +';'+ @enter	-- @P3 - таблица-источник данных
					+ replace(replace(@trjsinsertTemplate,'@P2','22')	-- @P2 - тип операции
								,'@P3','inserted') +';'+ @enter			-- @P3 - таблица-источник данных
			)
			set @trUpd = replace(@trUpd,'@P5',@UpdWhere) -- @P5 - условие where
			print @trUpd
			exec (@trUpd)
		end
		-- пересоздать триггер на Delete
		if (@buildTriggers & 4 = 4) and object_id( @shm+ '.JS_'+@tbl+'_Delete') is null
		begin
			set @trDel = @trTemplate
			set @trDel = replace(@trDel,'@P1','Delete')	-- задаем тип триггера в названии
			set @trDel = replace(@trDel,'@P4',			-- @P4 - строка вставки данных в js_таблицу
					replace(replace(@trjsinsertTemplate,'@P2','31')	-- @P2 - тип операции
								,'@P3','deleted') +';'+ @enter		-- @P3 - таблица-источник данных
			)
			set @trDel = replace(@trDel,'@P5',@DelWhere) -- @P5 - условие where
			
			print @trDel
			exec (@trDel)
		end
	end
--#endregion Создание триггеров

--#region Чистка данных в таблице
	if @rebuildStructure in (4) and object_id('dbo.JS_'+@tbl) is not null
	begin
		exec dbo.JS_SettingsApply @shm,@tbl,0,0,0
		set @sql = 'truncate table '+'dbo.JS_'+@tbl+''+@enter+''+@enter
		print @sql
		exec (@sql)
		--exec dbo.JS_SettingsApply @shm,@tbl,@LogInsert,@LogUpdate,@LogDelete
	end
--#endregion Чистка данных в таблице

--#region Включение/выключение триггеров

	

	set @sql = ''
	if object_id( @shm+ '.JS_'+@tbl+'_Insert') is not null
	begin
		if @logInsert = 1
			set @sql = @sql+ 'enable '
		else
			set @sql = @sql+ 'disable '
		set  @sql = @sql+ ' trigger ' + @shm+ '.JS_'+@tbl+'_Insert ON  '+ @shm+'.'+@tbl+ ';' +@enter 
	end
	
	if object_id( @shm+ '.JS_'+@tbl+'_Update') is not null
	begin
		if @logUpdate = 1
			set @sql = @sql+ 'enable '
		else
			set @sql = @sql+  'disable '
		set  @sql = @sql+ ' trigger ' + @shm+ '.JS_'+@tbl+'_Update ON  '+ @shm+'.'+@tbl+ ';' +@enter
	end
	
	if object_id( @shm+ '.JS_'+@tbl+'_Delete') is not null
	begin
		if @logDelete = 1
			set @sql = @sql+  'enable '
		else
			set @sql = @sql+  'disable '
		set  @sql = @sql+ ' trigger ' + @shm+ '.JS_'+@tbl+'_Delete ON  '+ @shm+'.'+@tbl+ ';' +@enter
	end

	if @sql !=''
	begin
		print @sql	
		exec (@sql)
	end
--#endregion Включение/выключение триггеров




	--print @@nestlevel
	update dbo.JS_Settings set rebuildStructure = 0 where id=@id
	--print 'a'
	delete from @settings where id = @id
	--print 'b'
end

grant exec on dbo.js_settingsapply to wh1
