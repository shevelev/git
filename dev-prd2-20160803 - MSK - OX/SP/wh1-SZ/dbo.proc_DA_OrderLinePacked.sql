


-- ПОДТВЕРЖДЕНИЕ УПАКОВКИ СТРОКИ ЗАКАЗА

ALTER PROCEDURE [dbo].[proc_DA_OrderLinePacked](
	@wh varchar(10),
	@transmitlogkey varchar (10)
)AS

--declare @transmitlogkey varchar (10), @wh varchar(10)
--set @transmitlogkey = '0005245860' set @wh = 'WH1'

	declare @ordkey varchar(10)
	
	select @ordkey = key1
	from wh1.transmitlog
	where transmitlogkey = @transmitlogkey and whseid = @wh
	print @ordkey
	--Проверим все ли существующие отборы упакованы
	if( not exists(select top(1) serialkey
		from wh1.pickdetail	
		where orderkey = @ordkey and [status] < '6' and qty <> 0)
	)
	begin
		print' все отборы упакованы - генерируем событие упаковка'
		--select top(1) serialkey from wh1.transmitlog where tablename = 'customerorderpacked' and key1 = @ordkey and whseid = @wh 
		if( not exists(select top(1) serialkey from wh1.transmitlog where tablename = 'customerorderpacked' and key1 = @ordkey and whseid = @wh ) )
		begin
			select @transmitlogkey = MAX(transmitlogkey) from wh1.TRANSMITLOG
		
			INSERT INTO [PRD1].[WH1].[TRANSMITLOG]
				   ([WHSEID]
				   ,[TRANSMITLOGKEY]
				   ,[TABLENAME]
				   ,[KEY1]
				   ,[KEY2]
				   ,[KEY3]
				   ,[KEY4]
				   ,[KEY5]
				   ,[TRANSMITFLAG]
				   ,[TRANSMITFLAG2]
				   ,[TRANSMITFLAG3]
				   ,[TRANSMITFLAG4]
				   ,[TRANSMITFLAG5]
				   ,[TRANSMITFLAG6]
				   ,[TRANSMITFLAG7]
				   ,[TRANSMITFLAG8]
				   ,[TRANSMITFLAG9]
				   ,[TRANSMITBATCH]
				   ,[EVENTSTATUS]
				   ,[EVENTFAILURECOUNT]
				   ,[EVENTCATEGORY]
				   ,[MESSAGE]
				   ,[ADDDATE]
				   ,[ADDWHO]
				   ,[EDITDATE]
				   ,[EDITWHO]
				   ,[error])
			 select
				   @wh
				   ,right('0000000000' + cast(@transmitlogkey + 1 as varchar(10)), 10)
				   ,'customerorderpacked'
				   ,@ordkey
				   ,''
				   ,''
				   ,''
				   ,''
				   ,0
				   ,NULL
				   ,NULL
				   ,NULL
				   ,NULL
				   ,NULL
				   ,NULL
				   ,NULL
				   ,NULL
				   ,''
				   ,0
				   ,0
				   ,'E'
				   ,''
				   ,GetDate()
				   ,'DAdapter'
				   ,GetDate()
				   ,'DAdapter'
				   ,NULL
			from [PRD1].[WH1].[TRANSMITLOG]
			where transmitlogkey = @transmitlogkey and whseid = @wh
		end
	end

--select 'customerorderlinepacked' as filetype
