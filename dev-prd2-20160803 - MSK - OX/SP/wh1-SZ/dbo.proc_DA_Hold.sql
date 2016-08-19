
-- БЛОКИРОВКА ЗАПАСОВ из АНАЛИТа в Infor WM --
ALTER PROCEDURE [dbo].[proc_DA_Hold]
	@source varchar(500) = null
as  


declare @allowUpdate int
declare @send_error bit
declare @msg_errdetails varchar(max)
declare @msg_errdetails1 varchar(max)
declare @enter varchar(10) 
declare @storerkey varchar(15)
declare @sku varchar(15)
declare @externreceiptkey varchar(20)
declare @id int
declare @receiptkey varchar (15)
declare @stage_count int


declare @transferkey varchar(15) --Логироваие в трансферкей
declare @lottable08 varchar(15) set @lottable08 = 'блокировка ФСН'
declare @lottable03 varchar(15) set @lottable03 = 'нет сертификата'
declare @tolottable08 varchar(15)  -- новый8
declare @tolottable03 varchar(15)  -- новый3
declare @tolottable07 varchar(15)  -- старый брак
declare @tolottable01 varchar(15) -- упаковка
declare @newLot		varchar(10), @Storer varchar(10),	@SkuName varchar(10), @oldLot varchar(10) -- новый лот, владелец, товар


set @send_error = 0
set @msg_errdetails = ''
set @enter = char(10)+char(13)

create table #tmp(
	sk int IDENTITY(1,1),
	--whseid varchar (10) null,
	lot	varchar (15) null,
	newlot varchar (15) null,
	--loc varchar (15) null,
	--id varchar (15) null,
	storerkey varchar (15) null,
	sku varchar (15) null,
	--qty float null,
	lottable01 varchar (15) null,
	lottable02 varchar (15) null,
	lottable03 varchar (15) null,
	lottable04 datetime,
	lottable05 datetime,
	--lottable06 varchar (15) null,
	lottable07 varchar (15) null,
	lottable08 varchar (15) null,
	--lottable09 varchar (15) null,
	--lottable10 varchar (15) null,
	holdtype int,
	holdset varchar(1)--,
	--orderkey varchar(10)
	)

CREATE TABLE #DA_Hold(
	[id] int,
	[storerkey] [varchar](50) NULL,
	[sku] [varchar](50) NULL,
	[packkey] [varchar](50) NULL,
	[attribute02] [varchar](50) NULL,
	[attribute04] [varchar](50) NULL,
	[attribute05] [varchar](50) NULL,
	[holdtype] [int] NULL,
	[holdset] [varchar](50) NULL
) 

	while (exists (select id from da_hold))
	--while (exists (select id from da_hold where id=3212))
		begin
			print ' выбираем запись из обменной таблицы da_Hold'
		insert into DA_InboundErrorsLog (source,msg_errdetails) values ('test','выбираем запись из обменной таблицы da_Hold')
			insert into #da_hold (id, sku, storerkey, packkey,attribute02, attribute04, attribute05, holdtype, holdset)
			select top(1) id, sku, storerkey, packkey,attribute02, attribute04, attribute05, holdtype, holdset  from da_hold order by id desc

insert into DA_InboundErrorsLog (source,msg_errdetails) values ('test','обновление NULL значений')
			print ' обновление NULL значений'
			update #da_hold set
				storerkey = isnull(storerkey,''),
				sku = isnull(sku,''),
				packkey = isnull(packkey,''),
				attribute02 = isnull(attribute02,''),
				attribute04 = isnull(right(left(attribute04,5),2)+right(LEFT(attribute04,3),1)+left(attribute04,2)+right(LEFT(attribute04,3),1)+right(attribute04,2),''),
				--attribute04 = isnull(CAST(attribute04 AS datetime),''),
				--attribute05 = isnull(CAST(attribute05 AS datetime),''),
				attribute05 = isnull(right(left(attribute05,5),2)+right(LEFT(attribute05,3),1)+left(attribute05,2)+right(LEFT(attribute05,3),1)+right(attribute05,2),''),
				[holdtype] = isnull([holdtype],''),
				holdset = isnull(holdset,'')

set @msg_errdetails1 =''
insert into DA_InboundErrorsLog (source,msg_errdetails) values ('test','проверка входных данных')
			print ' проверка входных данных'
			select 
				@msg_errdetails1 = @msg_errdetails1 --storerkey EMPTY
					+case when ltrim(rtrim(r.storerkey)) = ''
						then 'HOLD. STORERkey=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --storerkey in STORER
					+case when (not exists(select s.* from wh1.storer s where s.storerkey = r.storerkey))
						then 'HOLD. STORERkey='+r.storerkey+' отсутвует в справочнике STORER.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --sku empty
					+case when ltrim(rtrim(r.sku)) = ''
						then 'HOLD. SKU=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --sku+storerkey in SKU
					+case when (not exists(select s.* from wh1.sku s where s.sku = r.sku and s.storerkey = r.storerkey))
						then 'HOLD. SKU='+r.sku+' отсутвует в справочнике SKU.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --packkey empty
					+case when ltrim(rtrim(r.packkey)) = ''
						then 'HOLD. packkey=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --attribute02 empty
					+case when ltrim(rtrim(r.attribute02)) = ''
						then 'HOLD. attribute02=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --attribute04 empty
					+case when ltrim(rtrim(r.attribute04)) = ''
						then 'HOLD. attribute04=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --attribute05 empty
					+case when ltrim(rtrim(r.attribute05)) = ''
						then 'HOLD. attribute05=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --holdtype empty
					+case when ltrim(rtrim(r.holdtype)) = ''
						then 'HOLD. HOLDType=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --holdtype !=3 & !=8
					+case when ltrim(rtrim(r.holdtype)) != '3' and ltrim(rtrim(r.holdtype)) != '8'
						then 'HOLD. неверный HOLDType !=3 & !=8.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --holdset empty
					+case when ltrim(rtrim(r.holdset)) = ''
						then 'HOLD. holdset=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --holdset !=0 & !=1
					+case when ltrim(rtrim(r.holdset)) != '0' and ltrim(rtrim(r.holdset)) != '1'
						then 'HOLD. неверный holdset !=0 & !=1.'+@enter
						else ''
					end					
			from #da_hold r

update #DA_Hold set attribute02='' where attribute02='бс'

if (@msg_errdetails1 = '')
	begin
					print 'выбираем партии товаров соответвующих заданным условиям'
insert into DA_InboundErrorsLog (source,msg_errdetails) values ('test','выбираем партии товаров соответвующих заданным условиям')
	insert into #tmp
						(lot,
						storerkey,
						sku,
						lottable01,
						lottable02,
						lottable03,
						lottable04,
						lottable05,
						lottable07,
						lottable08,
						holdset,
						holdtype)		
select distinct	
						la.LOT, 
						la.STORERKEY, 
						la.SKU, 
						la.LOTTABLE01,
						la.LOTTABLE02,
						la.LOTTABLE03, 
						la.LOTTABLE04,
						la.LOTTABLE05,
						la.LOTTABLE07,
						la.LOTTABLE08,
						dh.holdset, 
						dh.holdtype
						from wh1.LOTATTRIBUTE la   
							join #DA_Hold dh on 
									dh.sku = la.SKU 
									and la.STORERKEY = dh.storerkey 
									and la.LOTTABLE02 = dh.attribute02
									and ( la.LOTTABLE04 = dh.attribute04 or (la.LOTTABLE04 is NULL and dh.attribute04 is NULL) ) -- дата производства
									and ( la.LOTTABLE05 = dh.attribute05 or (la.LOTTABLE05 is NULL and dh.attribute05 is NULL )) -- срок годности
							

					

if @@ROWCOUNT != 0
			begin

print 'на остатках есть товар удовлетворяющий условиям'
							print 'вставляем записи в таблицу логгирования трансфертов'
							insert into wh1.transferlog 
								(sku, storerkey, lot, fromlottable03, tolottable03, fromlottable08, tolottable08)
							select t.sku, t.storerkey, t.lot, t.lottable03,
								case when t.holdtype = '3' then case when t.holdset = '1' then @lottable03 else 'OK' end else t.LOTTABLE03 end,
								t.lottable08,
								case when t.holdtype = '8' then case when t.holdset = '1' then @lottable08 else 'OK' end else t.LOTTABLE08 end
								from #tmp t

--select * from #tmp 
-----------------start while-------------						
while (select COUNT(*) from #tmp) != 0
	begin
select top 1 @oldLot=lot from #tmp

set @newLot=''
set @tolottable03=''
set @tolottable08=''
set @tolottable07=''
set @tolottable01=''

	select	@tolottable03 = case when t.holdtype = '3' then case when t.holdset = '1' then  @lottable03 else 'OK' end  else t.LOTTABLE03 end,
			@tolottable08 = case when t.holdtype = '8' then case when t.holdset = '1' then @lottable08 else 'OK' end else t.LOTTABLE08 end,
			@tolottable07 = t.lottable07,
			@tolottable01 = t.lottable01
			from wh1.lotattribute lli 
			join #tmp t on lli.lot = t.lot
			where lli.LOT=@oldLot
			
			select @newLot=la.LOT							
							from wh1.LOTATTRIBUTE la
							join #tmp dh on la.LOTTABLE02=dh.lottable02  
												and ( la.LOTTABLE04 = dh.lottable04 or la.LOTTABLE04 is NULL and dh.lottable04 is NULL ) -- дата производства
												and ( la.LOTTABLE05 = dh.lottable05 or la.LOTTABLE05 is NULL and dh.lottable05 is NULL ) -- срок годности
												--la.LOTTABLE04=dh.lottable04 and 
												--la.LOTTABLE05=dh.lottable05 and
												and la.STORERKEY=dh.storerkey and
												la.sku=dh.sku 												
							where la.LOTTABLE03=@tolottable03 and la.LOTTABLE08=@tolottable08 and la.LOTTABLE07=@tolottable07 and la.LOTTABLE01=@tolottable01
							

insert into DA_InboundErrorsLog (source,msg_errdetails) values ('test','поиск партии'+@newLot)
if @newLot='' 
	begin
		print 'создаем партию'
insert into DA_InboundErrorsLog (source,msg_errdetails) values ('test','создаем партию')											
		exec dbo.DA_GetNewKey 'wh1', 'LOT', @newLot OUTPUT --получаем номер новой партии
		
		print 'Создаем партию в лотатрибутах'
		insert into wh1.lotattribute
			(	whseid,	lot,	storerkey,		sku,	addwho,	editwho, LOTTABLE01, LOTTABLE02, LOTTABLE04, LOTTABLE05, LOTTABLE03, LOTTABLE08, LOTTABLE07)
		select	'WH1',	@newLot,dh.storerkey,	dh.sku,	'test',	'test', @tolottable01, dh.attribute02, dh.attribute04, dh.attribute05, @tolottable03, @tolottable08, @tolottable07
		from #DA_Hold dh
		join wh1.LOTATTRIBUTE la on dh.sku=la.SKU and la.LOT=@oldLot
		
		print 'Создаем партию в лот'
		insert into wh1.lot
			(	whseid,	lot,	storerkey,	sku,		addwho,				editwho)
		select	'WH1',	@newLot,dh.storerkey,	dh.sku,	'test',	'test'
		from #DA_Hold dh
		
		print 'новая партия создана: '+@newLot
		insert into DA_InboundErrorsLog (source,msg_errdetails) values ('test','создаем партию'+@newLot)											
	end
						
		print 'Старая партия '+  @oldLot + ' Новая партия->' + @newLot					
if (@newLot<>@oldLot)
	begin
----------переброска остатков------------			
			print 'переброска остатков '+  @oldLot + '->' + @newLot
--insert into DA_InboundErrorsLog (source,msg_errdetails) values ('test','переброска остатков')														
			update NEW set NEW.QTY=NEW.QTY+OLD.QTY, new.QTYALLOCATED=new.QTYALLOCATED+old.QTYALLOCATED, new.QTYPICKED=new.QTYPICKED+old.QTYPICKED
				from wh1.lot NEW 
					join wh1.lot OLD on OLD.lot = @oldLot and NEW.SKU=OLD.SKU
				where NEW.LOT=@newLot
			
			print 'Обновляем лот в нули по старому лоту'
			update wh1.lot set QTY=0, QTYALLOCATED=0, QTYPICKED=0 where LOT=@oldLot
			
			print 'Обновляем лотхлокх новой партией где старая'
			update wh1.lotxlocxid set LOT=@newLot where LOT=@oldLot
			
---------/переброска остатков------------	
	end				
		
	
			
delete from #tmp where lot=@oldLot

	end
-----------------end while-------------		
			end							
						
	else
			begin
						select 'ничего нет'
			end							
		
			

	end
else
	begin
		set @msg_errdetails = 'Нет товаров удовлетворяющих условиям.'+@enter
		set @send_error = 1
	end
			
				
				
			print 'удаляем обработанную строку из обменной таблицы'
			delete from dh 
				from da_hold dh join #da_hold tdh on dh.id = tdh.id
	end	
	
								
drop table #da_hold 			
drop table #tmp	
