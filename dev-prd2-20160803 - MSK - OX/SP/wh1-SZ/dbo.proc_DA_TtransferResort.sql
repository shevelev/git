ALTER PROCEDURE [dbo].[proc_DA_TtransferResort](
	@wh varchar(10),
	@transmitlogkey varchar (10)
	
)AS

--declare @transmitlogkey varchar (10)
declare @fromlotattribute07 varchar(50)
declare @tolotattribute07 varchar(50)
declare @transferkey varchar (50)
--3    __Сильнодействующие
--1    1 Склад
--22    Забраковка
--30    Некондиция
--35    Потери
--4    Сертификация
declare @bs varchar(3) select @bs = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'
declare @bsanalit varchar(3) select @bsanalit = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bsanalit'


--set @transmitlogkey = '0005245901'
select @transferkey = KEY1 from wh1.TRANSMITLOG where TRANSMITLOGKEY = @transmitlogkey

-- трансфер на 07 атрибут
select 'transfer' filetype,
		td.TOSTORERKEY STORERKEY,
		td.tosku SKU,
		td.frompackkey FROMPACKKEY,
		case when lt.lottable02 = @bs then @bsanalit else lt.LOTTABLE02 end fromattribute02,
		lt.lottable04 fromattribute04,
		lt.lottable05 fromattribute05,
		case l.PUTAWAYZONE
			when '1' then '30'
			when '2' then '3'
			when '3' then '1'
			when '4' then '22'
			when '5' then '35'
			when '6' then '4'
			else '1'
			end	sklad,
		td.topackkey TOPACKKEY,
		case when td.lottable02 = @bs then @bsanalit else td.LOTTABLE02 end toattrbute02,
		td.lottable04 toattribute04,
		td.lottable05 toattribute05,
		td.toqty qty
		from wh1.transferdetail td 
			join wh1.lotattribute lt on lt.lot = td.fromlot
			join wh1.loc l on l.LOC = td.FROMLOC
		where td.TRANSFERKEY = @transferkey
		
		
--if @fromlotattribute07 != @tolotattribute07
--	begin
--		print 'трансферт атрибута 07 в брак'
--		--получить номер для записи в лог
--		exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
		
--		--записать в лог событие об отгрузке заказа
--		insert wh1.transmitlog (whseid, transmitlogkey, tablename, key1, KEY2, key3, key4, ADDWHO) 
--		values ('WH1', @transmitlogkey, 'transferMOVE', @transferkey, '07', case when @fromlotattribute07 != '' then @necond else @osn end, case when @tolotattribute07 != '' then @necond else @osn end, 'dataadapter')	
--	end
		
		
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
