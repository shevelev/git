ALTER PROCEDURE [dbo].[SZ_MVTask] 
AS

	insert into DA_InboundErrorsLog (source,msg_errdetails) 
	values ('SZ_MVTask','входные данные: ')

	exec [WH1].[SZ_MVTask] 
--	exec [WH2].[SZ_MVTask] 

