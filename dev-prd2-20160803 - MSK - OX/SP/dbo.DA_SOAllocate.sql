

ALTER PROCEDURE [dbo].[DA_SOAllocate] --(
	--@wh varchar(10)	= NULL
	@source varchar(500) = null,
	@orderkey1 varchar(20) = ''
--)
as

    declare @src_found int
    set @src_found = 0
    
    if @source = 'wh1'
    begin
	set @src_found = 1
	exec [WH1].[DA_SOAllocate] @source, @orderkey1
    end
    if @source = 'wh2'
    begin
        set @src_found = 2
	exec [WH2].[DA_SOAllocate] @source, @orderkey1
    end
    

    
