ALTER PROCEDURE [dbo].[CreateNewEventForTransfer]

AS

DECLARE  @itrn varchar(10),
		 @transmitlogkey varchar(10)

select top 1 @itrn=t.TRANSFERKEY-- , t.TRANSMITLOGKEY, i.FROMLOC, i.TOLOC
from wh1.TRANSFER t
left join wh1.TRANSMITLOG tm on t.TRANSFERKEY=tm.KEY1 and tm.TABLENAME='transferfinalized'
where t.ADDDATE> DATEADD(d, -4, getdate()) and tm.TRANSMITLOGKEY is null
order by t.TRANSFERKEY desc

if @itrn > 0
 begin
	print @itrn
		
		exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
            
		insert wh1.transmitlog (whseid, transmitlogkey, tablename, ADDWHO, key1) 
		values ('WH1', @transmitlogkey, 'transferfinalized',  'infor',@itrn)
		
		exec app_DA_SendMail 'ÑÊĞÈÏÒ - Àâòî Òğàíñôåğò: ', @itrn
 end
