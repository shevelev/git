ALTER PROCEDURE [dbo].[DA_TEST] 
AS

set xact_abort off

BEGIN TRY

begin tran
 insert da_adjustment (whseid) values ('wh1')
 raiserror ('---------------',16,1)
commit tran

END TRY
BEGIN CATCH
	ROLLBACK TRAN
END CATCH

