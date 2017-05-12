CREATE proc [dbo].[p_check_frag_index_db_PRD]
 (@nameDB nchar(10))
as
begin
   declare @i smallint
         , @v_object_name sysname
         , @v_name_ind sysname
         , @count_i smallint
         , @v_schema_name sysname
   create table #t_frag_ind
   ( [object_name] sysname
   , [name] sysname 
   , avg_fragmentation_in_percent float
   , avg_page_space_used_in_percent float)
   ------------------реорганизация--------------
   -- вставка выборки индексов которые надо реорганизовать
   insert into #t_frag_ind
      select object_name([object_id]) [object_name]
           , [name]
           , avg_fragmentation_in_percent
           , avg_page_space_used_in_percent  
        from master.dbo.p_analyze_fragmentation_indexes(@nameDB)
        where (avg_fragmentation_in_percent >= 10
          and avg_fragmentation_in_percent <= 15)
           or (avg_page_space_used_in_percent >= 60
          and  avg_page_space_used_in_percent <= 75)
   -- начало реорганизации
   set @i = 1
   select @count_i = (select count([name]) from #t_frag_ind)
   while @count_i > @i
      begin
         -- берется имя таблицы (объекта)
         select @v_object_name = (select top 1 [object_name]
                                    from #t_frag_ind)
         -- соответствующей ей индекс
         select @v_name_ind = (select top 1 [name]
                                    from #t_frag_ind)
         -- имя схемы к которой таблица пренадлежит
         select @v_schema_name = (select schema_name(schema_id)
                                     from sys.objects
                                     where sys.objects.type = 'U'
                                       and Name = @v_object_name)
         -- запуск реорганизации таблицы  
         exec ('alter index '+@v_name_ind+' on '
                +@v_schema_name+'.'+@v_object_name+' reorganize')
         -- удаление обработанной строчки
         delete from #t_frag_ind
            where [object_name] = @v_object_name
              and [name] = @v_name_ind
         set @i = @i + 1
      end
   --------------------перестроение------------------------------------
   -- вставка выборки индексов которые надо перестроить
   insert into #t_frag_ind
      select object_name([object_id]) [object_name]
           , [name]
           , avg_fragmentation_in_percent
           , avg_page_space_used_in_percent  
        from master.dbo.p_analyze_fragmentation_indexes(@nameDB)
        where (avg_fragmentation_in_percent > 15)
           or (avg_page_space_used_in_percent < 60)
   -- начало перестройки
   set @i = 1
   select @count_i = (select count([name]) from #t_frag_ind)
   while @count_i > @i
      begin
         -- берется имя таблицы (объекта)
         select @v_object_name = (select top 1 [object_name]
                                    from #t_frag_ind)
         -- соответствующей ей индекс
         select @v_name_ind = (select top 1 [name]
                                    from #t_frag_ind)
         -- имя схемы к которой таблица пренадлежит
         select @v_schema_name = (select top 1 schema_name(schema_id)
                                     from sys.objects
                                     where sys.objects.type = 'U'
                                       and Name = @v_object_name)
         -- запуск перестройки таблицы  
         exec ('alter index '+@v_name_ind+' on '
                +@v_schema_name+'.'+@v_object_name+' rebuild')
         -- удаление обработанной строчки
         delete from #t_frag_ind
            where [object_name] = @v_object_name
              and [name] = @v_name_ind
         set @i = @i + 1
      end
   drop table #t_frag_ind
end

