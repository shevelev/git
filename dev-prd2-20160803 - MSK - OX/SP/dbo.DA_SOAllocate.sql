ALTER PROCEDURE [dbo].[DA_SOAllocate] --(
	--@wh varchar(10)	= NULL
	@source varchar(500) = null,
	@orderkey1 varchar(20) = ''
--)
as

set nocount on
    create table #outData (orderkey varchar(50), externorderkey varchar(50))
    
    declare @src_found int
    set @src_found = 0
    
    if @source = 'wh1'
    begin
		set @src_found = 1
		if IsNull(@orderkey1,'') = ''
		begin
		    insert into #outData exec [WH1].[DA_SOAllocate_WH1] @source, @orderkey1
		    select orderkey, externorderkey  from #outData
		end
		else
		begin
		    select 1 from wh1.orders where orderkey = @orderkey1
		end;
		
    end
    if @source = 'wh2'
    begin
	set @src_found = 2
	if IsNull(@orderkey1,'') = '' 
	begin
	    insert into #outData exec [WH2].[DA_SOAllocate_WH2] @source, @orderkey1
	    select orderkey, externorderkey  from #outData
	end
	else
		begin
		    select 1 from wh1.orders where orderkey = @orderkey1
		end;
	
    end


