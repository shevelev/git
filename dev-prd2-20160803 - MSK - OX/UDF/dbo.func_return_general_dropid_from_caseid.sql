-- =============================================
-- Author:		Dr.MoPo3ilo
-- Create date: 2009-01-27
-- Description:	Возвращает самый верхний dropid из caseid
-- =============================================
ALTER FUNCTION [dbo].[func_return_general_dropid_from_caseid] (@caseid varchar(15))
RETURNS varchar(15)
AS
BEGIN
	DECLARE @dropid varchar(15)

	select top 1 @dropid = dropid from func_return_dropid_from_caseid(@caseid)
	order by idx desc

	RETURN @dropid

END

