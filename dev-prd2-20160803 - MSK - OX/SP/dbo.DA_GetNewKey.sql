


ALTER PROCEDURE [dbo].[DA_GetNewKey] (@wh varchar(10), @keyname varchar(30), @sNewID varchar(10) output, @iCount int = 1)
--returns varchar(10)
as
begin
	declare @newID int--, @var1 int
	declare @sql nvarchar(max)
	set @sql = 'update '+@wh+'.ncounter set @var1=keycount, keycount = keycount+'+CAST(@icount as varchar)+' where keyname like ''' +@keyname+ ''''
	exec sp_executesql @sql, N'@var1 int output', @var1 = @newID output
	set @snewID = replicate ('0',10-len(cast(@newID as varchar)))+cast(@newID as varchar)
end


