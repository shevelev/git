


ALTER PROCEDURE [WH1].[newGLPI] (@keyname varchar(30),@iCount int = 1)
as
begin
	update wh1.NGLPI set keycount = keycount+@icount where keyname=@keyname and adddate=CONVERT(date, GETDATE(), 101)
end


