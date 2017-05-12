ALTER PROCEDURE [dbo].[trans] 
AS

--drop table wh1.transfer1
--drop table wh1.transferdetail1
--select * into wh1.TRANSFER from wh1.transfer 
--select * into wh1.TRANSFERDETAIL from wh1.transferdetail

--delete 

--select * from wh1.TRANSFERDETAIL  
--	where transferkey = '0000000767' or transferkey = '0000000768'
	
--select t1.status, tt.status, tt.* from wh1.transferdetail t 
--		join wh1.transferdetail tt on t.fromlot = tt.fromlot and t.toloc = tt.toloc and t.ADDWHO = tt.addwho
--		join wh1.TRANSFER t1 on tt.TRANSFERKEY = t1.transferkey
--		where t.transferKEY = '0000000727'	order by tt.serialkey --and t.status = '9' and t1.status = '9' 

--select * from wh1.TRANSFER join wh1.transferdetail1


--select t.status,td.* from wh1.TRANSFER t join wh1.TRANSFERDETAIL td on t.transferkey = td.transferkey where t.transferkey = '0000000767' or t.transferkey = '0000000768'

declare @transferkey varchar(20)
select  
	td.TRANSFERKEY, 
	td.fromsku, td.fromloc, td.fromlot, 
	td.tosku, td.toloc, td.tolot,
	td.ADDWHO, td.status statusdetail, t.status
into #trans 
from wh1.TRANSFERDETAIL td join wh1.TRANSFER t on t.TRANSFERKEY = td.transferkey --исходная таблица

select * into #transt from #trans where 1=2  -- временная таблица

select * into #transr from #trans where 1=2  --таблица результатов

--select transferkey into #transdel from #trans where 1=2 

while (select COUNT(*) from #trans) != 0
	begin
		--выбор очередной строки трансферта
		select top(1) @transferkey = transferkey from #trans
		
		--вставка во временную таблицу одинаковых значений трансфертов
		insert into #transt
			select tt.* from #trans t 
				join #trans tt on t.fromlot = tt.fromlot and t.toloc = tt.toloc and t.ADDWHO = tt.addwho
			where t.transferKEY = @transferkey

		print'вставка в результирующую таблицу проведенного трансферта'
		insert into #transr
			select * from  #transt t where statusdetail = '9' and status = '9'
			
		if (select COUNT(transferkey) from #transr ) = 0
			begin -- нет проведенного трансферта
				print'вставка в результирующую таблицу уникального трансферта'
				insert into #transr		
				select top(1) * from #transt t order by t.transferkey desc
			end
		
		print'очистка временной таблицы одинаковых значений трансфертов от самого младшего или проведенного трансферта'
		delete tt
			from #transt tt join #transr tr on tt.transferkey = tr.transferkey
		
		print'удаление трансфертов из таблицы wh1.transferdetail'
		delete from td
			from wh1.TRANSFERDETAIL td join #transt tt on tt.transferkey = td.transferkey
		print'удаление трансфертов из таблицы wh1.transfer1'
		delete from td
			from wh1.TRANSFER td join #transt tt on tt.transferkey = td.transferkey
		
		print'очистка временной таблицы одинаковых значений трансфертов'
		delete from #transt 
		
		print'сброс статусов в 0 в деталях трансфертов wh1.transferdetail'
		update td set status = 0
			from wh1.TRANSFERDETAIL td join wh1.TRANSFER t on td.transferkey = t.transferkey
			join #transr tr on td.TRANSFERKEY = tr.TRANSFERKEY
		where t.status = 0
		
		print'очистка временной таблицы младших значений трансфертов'
		delete from #transr	
			
		
		print'удаление обработанных строк трансфертов'
		delete from tt
			from #trans t join #trans tt on t.fromlot = tt.fromlot and t.toloc = tt.toloc and t.ADDWHO = tt.addwho
			where t.transferKEY = @transferkey	
					
	end

--select * from  #transr where status = 0
--select * from #transfer

--drop table #transfer
drop table #trans
drop table #transt
drop table #transr


--select  distinct fromlot, toloc, addwho from wh1.transferdetail
--join #trans tt on t.fromlot = tt.fromlot and t.toloc = tt.toloc and t.ADDWHO = tt.addwho
--where t.transferKEY = @transferkey
