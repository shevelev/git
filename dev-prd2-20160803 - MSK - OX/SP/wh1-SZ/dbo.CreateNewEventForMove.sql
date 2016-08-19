ALTER PROCEDURE [dbo].[CreateNewEventForMove]

AS

DECLARE  @itrn varchar(10),
		 @transmitlogkey varchar(10)

select top 1 @itrn=i.ITRNKEY-- , t.TRANSMITLOGKEY, i.FROMLOC, i.TOLOC
from wh1.ITRN i
left join wh1.TRANSMITLOG t on t.KEY1=i.ITRNKEY and t.TABLENAME='move'
where i.TRANTYPE='MV' and i.ADDDATE> DATEADD(d, -4, getdate())
and t.TRANSMITLOGKEY is null
order by i.ITRNKEY desc

if @itrn > 0
 begin
	print @itrn
		
		exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
            
		insert wh1.transmitlog (whseid, transmitlogkey, tablename, ADDWHO, key1) 
		values ('WH1', @transmitlogkey, 'move',  'infor',@itrn)
		
		exec app_DA_SendMail 'СКРИПТ - Авто Пемерещение: ', @itrn

 end
