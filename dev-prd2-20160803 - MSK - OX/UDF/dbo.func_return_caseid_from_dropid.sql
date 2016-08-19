-- =============================================
-- Author:		Dr.MoPo3ilo
-- Create date: 2009-01-27
-- Description:	Возвращает caseid из dropid
-- =============================================
ALTER FUNCTION [dbo].[func_return_caseid_from_dropid](@dropid varchar(15))
RETURNS 
@restbl TABLE 
(
  idx integer,
  caseid varchar(15)
)
AS
BEGIN
  declare @droptbl table(dropid varchar(15))
	declare @idx integer
	set @idx=0
	
	insert into @restbl
	select distinct @idx,CHILDID from WH1.DROPIDDETAIL
	where DROPID=@dropid
	
	insert into @droptbl
	select caseid from @restbl
	where caseid in (select DROPID from WH1.DROPIDDETAIL)
	
	delete from @restbl
	where caseid in (select dropid from @droptbl)
	
	set @idx=@idx+1

	while exists (select * from @droptbl)
	begin
	  insert into @restbl
	  select distinct @idx,CHILDID from WH1.DROPIDDETAIL
	  where DROPID in (select dropid from @droptbl)
	  
	  delete from @droptbl
	  
	  insert into @droptbl
	  select caseid from @restbl
	  where  caseid in (select DROPID from WH1.DROPIDDETAIL)
	  
	  delete from @restbl
	  where caseid in (select dropid from @droptbl)
  	
	  set @idx=@idx+1
	end
	
	RETURN 
END

