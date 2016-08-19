ALTER PROCEDURE [dbo].[rep_AssignLocComplectToOrder](
		@wh varchar(10),
		@loc varchar(10),
		@orderkey varchar(12),
		@delflag int
)
--with encryption
as

--	declare @wh varchar(10),
--		@loc varchar(10),
--		@orderkey varchar(12),
--		@delflag int
--	select @wh='wh40', @loc='U.04C', @orderkey='0000000422', @delflag=0
		
		declare @sql varchar(max)
		
		set @sql = 'update '+@wh+'.orders 
			set door=''' + case when @delflag=1 then '' else @loc end + ''' 
			where orderkey = '''+@orderkey+''''
		exec (@sql)

