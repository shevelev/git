/*************************************************************************/
/*                  UsdPhrase function for MSSQL2000                     */
/*                   Gleb Oufimtsev (dnkvpb@nm.ru)                       */
/*                       http://www.gvu.newmail.ru                       */
/*                          Moscow  Russia  2001                         */
/*************************************************************************/
ALTER FUNCTION [dbo].[UsdPhrase] (@Value money)
returns varchar(255)
as
begin
  declare @dpart bigint, @dattr tinyint, @cpart tinyint, @cattr tinyint
  set @dpart=floor(@Value)     set @dattr=@dpart%100
  if @dattr>19 set @dattr=@dattr%10
  set @cpart=(@Value-@dpart)*100
  if @cpart>19 set @cattr=@cpart%10 else set @cattr=@cpart
  return dbo.NumPhrase(floor(@Value),1)+' המככאנ'
           +case when @dattr=1 then '' when @dattr in (2,3,4) then 'א' else
'מג' end
           +' ÑØÀ '+right('0'+cast(@cpart as varchar(2)),2)+' צוםע'
           +case when @cattr=1 then '' when @cattr in (2,3,4) then 'א' else
'מג' end
end

