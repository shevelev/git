-- =============================================
-- Author:		<������� �.�.>
-- Create date: <������ 2008>
-- Description:	<������� ���������� �������� ��������� ParamName �� ������ 
--               ListName �� ������� CODELKUP>
-- =============================================
ALTER FUNCTION [WH2].[GetFromCODELKUP]
(	@ListName varchar(10),
	@ParamName varchar(10)
)


RETURNS varchar(250)
AS
Begin
	RETURN (select [DESCRIPTION]
			from CODELKUP
			where LISTNAME=@ListName and CODE=@ParamName)
End

