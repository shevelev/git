-- =============================================
-- Author:		Dr.MoPo3ilo
-- Create date: 2009-01-27
-- Description:	Возвращает dropid из caseid
-- =============================================
ALTER FUNCTION [dbo].[func_return_dropid_from_caseid] (@caseid varchar(15))
RETURNS 
@restbl TABLE 
(
	idx integer, 
	dropid varchar(15)
)
AS
BEGIN
	
	declare @idx integer
	set @idx=0
	
	insert into @restbl
	select distinct @idx,DROPID from WH1.DROPIDDETAIL
	where CHILDID=@caseid
	
	while exists (select * from WH1.DROPIDDETAIL
	  where CHILDID in (select dropid from @restbl
	    where idx=@idx))
	begin
	  insert into @restbl
	  select distinct (@idx+1),DROPID from WH1.DROPIDDETAIL
	  where CHILDID in (select dropid from @restbl
	    where idx=@idx)
	  set @idx=@idx+1
	end
	
	RETURN 
END

