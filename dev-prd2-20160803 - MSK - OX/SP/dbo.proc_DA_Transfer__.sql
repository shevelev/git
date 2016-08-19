ALTER PROCEDURE [dbo].[proc_DA_Transfer](
	@wh varchar(10),
	@transmitlogkey varchar (10)
	
)AS

--declare @transmitlogkey varchar (10)
declare @fromlotattribute07 varchar(50)
declare @tolotattribute07 varchar(50)
declare @necond varchar (50) set @necond = 'Некондиция'
declare @osn varchar (50) set @osn = 'Основной'



--set @transmitlogkey = '0005245901'
--select * from wh1.TRANSMITLOG where TRANSMITLOGKEY = @transmitlogkey

-- трансфер на 07 атрибут
select 
		@fromlotattribute07 = isnull(lt.lottable07,''),
		@tolotattribute07 = isnull(td.LOTTABLE07,'')
		from wh1.transmitlog tl
			join wh1.transferdetail td on tl.key1 = td.transferkey
			join wh1.lotattribute lt on lt.lot = td.fromlot
		where tl.tablename = 'transferfinalized' and tl.transmitlogkey = @transmitlogkey
if @fromlotattribute07 != @tolotattribute07
	begin
		print 'трансферт атрибута 07 в брак'
		--получить номер для записи в лог
		exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
		
		--записать в лог событие об отгрузке заказа
		insert wh1.transmitlog (whseid, transmitlogkey, tablename, key1, KEY2, key3, ADDWHO) 
		values ('WH1', @transmitlogkey, 'transferMOVE', '07', case when @fromlotattribute07 != '' then @necond else @osn end, case when @tolotattribute07 != '' then @necond else @osn end, 'dataadapter')	
	end
		
		
--if (@lotattribute07 = 'БРАК' or @lotattribute07 = 'брак' or @lotattribute07 = 'BRAK' or @lotattribute07 = 'brak')
--	begin
--	end
--if (@lotattribute08 = 'БРАК' or @lotattribute08 = 'брак' or @lotattribute08 = 'BRAK' or @lotattribute08 = 'brak')
--	begin
--		print 'трансферт атрибута 08 в брак'
--		--получить номер для записи в лог
--		exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
		
--		--записать в лог событие об отгрузке заказа
--		insert wh1.transmitlog (whseid, transmitlogkey, tablename, KEY1, KEY2, ADDWHO) 
--		values ('WH1', @transmitlogkey, 'transfer', '08', '', 'dataadapter')		
--	end
--105
