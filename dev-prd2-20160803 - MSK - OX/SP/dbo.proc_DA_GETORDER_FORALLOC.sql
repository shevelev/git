ALTER PROCEDURE [dbo].[proc_DA_GETORDER_FORALLOC]
	@source varchar(500) = null,
	@orderkey varchar(10) = ''
as

declare @allowUpdate int
declare @send_error bit
declare @msg_errdetails varchar(max)
declare @msg_errdetails1 varchar(max),
	@msg_errdetails2 varchar(max)
declare @enter varchar(10),
	@load char(1)    

set @send_error = 0
set @msg_errdetails = ''
set @msg_errdetails2 = ''
set @enter = char(10)+char(13)					


BEGIN TRY
	
	
		
	
		if IsNull(@orderkey,'') = ''
		begin
        	
		    select  top 1
			    ORDERKEY, EXTERNORDERKEY
		    from    wh1.ORDERS
		    where   STATUS = '02'			    
		    order by PRIORITY
        	
		end
		else
		begin
        	
		    select  COUNT(*) as [sign]
		    from    wh1.ORDERS
		    where   STATUS = '17'
			    and ORDERKEY = @orderkey
        	
		end
		
	

	
	
END TRY

BEGIN CATCH
	declare @error_message nvarchar(4000)
	declare @error_severity int
	declare @error_state int
	
	set @error_message  = ERROR_MESSAGE()
	set @error_severity = ERROR_SEVERITY()
	set @error_state    = ERROR_STATE()

	set @send_error = 0
	raiserror (@error_message, @error_severity, @error_state)
END CATCH


IF OBJECT_ID('tempdb..#q') IS NOT NULL DROP TABLE #q
