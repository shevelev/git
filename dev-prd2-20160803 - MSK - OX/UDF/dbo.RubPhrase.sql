ALTER FUNCTION [dbo].[RubPhrase] (@Value1 money)
returns varchar(255)
as
begin
  declare @Value money
  set @Value=abs(@Value1)
  declare @rpart bigint, @rattr tinyint,  @cpart tinyint, @cattr tinyint
  set @rpart=floor(@Value)     set @rattr=@rpart%100
  if @rattr>19 set @rattr=@rattr%10
  set @cpart=(@Value-@rpart)*100
  if @cpart>19 set @cattr=@cpart%10 else set @cattr=@cpart
  return case when @Value1<0 then 'МИНУС ' else '' end +
	dbo.NumPhrase(@rpart,1)+' рубл'
           +case when @rattr=1 then 'ь' when @rattr in (2,3,4) then 'я' else
'ей' end+' '
           +right('0'+cast(@cpart as varchar(2)),2)+' копе'
           +case when @cattr=1 then 'йка' when @cattr in (2,3,4) then 'йки'
else 'ек' end
end

