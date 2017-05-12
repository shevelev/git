
ALTER PROCEDURE [wh2].[proc_DA_ReceiptConfirm]
	@wh varchar(30),
	@transmitlogkey varchar (10)

as
--############################################################### ПОДТВЕРЖДЕНИЕ ПУО
set nocount on


declare @receiptkey varchar(10) = null--,@transmitlogkey varchar (10) 
declare --@receiptkey  varchar(15) = null,
		@error int = 0

--set @receiptkey = '0000048296'--'0000048291'--'0000048289'--

select	@receiptkey = key1 
--into	#tl
from	wh2.transmitlog
where	transmitlogkey = @transmitlogkey
	-- and tablename = 'asnclosed'
	and isnull(KEY5,'') !='1'

--select	@receiptkey = t.key1 
--from	#tl t
--	left join #tl tt
--	    on t.transmitlogkey = tt.transmitlogkey
--	    and tt.key5 = '1'
--where	t.transmitlogkey = @transmitlogkey
--	and tt.transmitlogkey is null

print @receiptkey
if @receiptkey is null return

--
/*
 select * from wh2.podetail where pokey in (select pokey from wh2.po where otherreference = '0000045594')
 select * from wh2.receiptdetail where receiptkey = '0000045594'
-- delete from wh2.podetail where pokey in (select pokey from wh2.po where otherreference = '0000045594') and (ALTSKU != '' or altsku is null)
*/
declare @source varchar(100) --set --@source = 'proc_DA_CompositeASNClose'

declare @send_error bit
declare @msg_errdetails varchar(max)
declare @receiptlinenumber varchar(5)
declare @polinenumber varchar(5)
declare @pokey varchar(10)
declare @expokey varchar(20)
declare @bs varchar(3) select @bs = short from wh2.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'
declare @bsanalit varchar(3) select @bsanalit = short from wh2.CODELKUP where LISTNAME='sysvar' and CODE = 'bsanalit'
declare @rqty float, @poqty float
declare @potype varchar(10)

declare @n bigint


CREATE TABLE [#receiptdetail](
	id int identity (1,1) not null,
	sku varchar(50) NULL,
	storerkey varchar(15) NULL,	
	skuqty float null,
	qty float null,
	qtyreceived float NULL,
	QR_BRAK float NULL,
	susr2 varchar(30) NULL, -- серия
	lot varchar(20),
	SCLAD varchar(50),
	SortOrder int
)

CREATE TABLE [#podetail](
	id int identity (1,1) not null,
	--polinenumber varchar(15) NULL,
	pokey varchar(20) null,
	externpokey varchar(20) null,
	sku varchar(50) NULL,
	storerkey varchar(15) NULL,	
	qty float NULL,
	qtyordered float NULL, -- ожидаемое по ЗЗ
	QTYADJUSTED float NULL, -- ожидаемое по строке 
	QTYRECEIVED float NULL, -- принятое Н+Б
	QR_BRAK float NULL, -- принятое Б
	susr2 varchar(30) NULL, -- серия товара
	lot varchar(20),
	SCLAD varchar(50),
	lot02 varchar(50),
	lot04 datetime,
	lot05 datetime
)

create table #skuqty (
	sku varchar(50) NULL,
	storerkey varchar(15) NULL,	
	qty float NULL
)

CREATE TABLE [#OutPOData](
	[WHSEID] [varchar](3) NOT NULL,
	[pokey] [varchar](10) NULL,
	[EXTERNPOKEY] [varchar](20) NULL,
	[POLINENUMBER] [varchar](5) NULL,
	[EXTERNLINENO] [varchar](1) NOT NULL,
	[qtyordered] [float] NULL,
	[QTYRECEIVED] [float] NULL,
	[sku] [varchar](50) NULL,
	[SKUDESCRIPTION] [varchar](60) NULL,
	[STORERKEY] [varchar](15) NULL,
	[SUSR4] [varchar](50) NULL,
	[susr2] [varchar](30) NULL,
	[PACKKEY] [varchar](50) NOT NULL,
	[UOM] [varchar](10) NULL,
	[ALTSKU] [varchar](50) NULL,
	[Lottable02] [varchar](50) NULL,
	[Lottable04] [datetime] NULL,
	[Lottable05] [datetime] NULL
) ON [PRIMARY]


--create table #pokey (
--	pokey varchar(15) NULL
--)


select * into #podetailresult from #podetail


print '0. проверка повторного закрытия ПУО'
	select @receiptkey = tl.key1 from wh2.transmitlog tl where tl.transmitlogkey = @transmitlogkey
	if 0 < (select count(*) from wh2.receipt r where r.receiptkey=@receiptkey and r.susr5='9')
	begin
		--raiserror ('Повторное закрытие ПУО = %s',16,1, @receiptkey)
		set @send_error = 1
		set @msg_errdetails = 'Повторное закрытие ПУО '+ @receiptkey
		goto endproc
	end	

-- выборка приходов
insert into #receiptdetail 
select a.*,
	/* формируем порядок распределения товара со складов */
	case SCLAD when 'SD' then 1--
		when 'BRAKPRIEM' then 2--'BRAKPRIEM'
		when 'OVERPRIEM' then 3--'OVERPRIEM'
		when 'LOSTPRIEM' then 4--'LOSTPRIEM'
		--when 'PRETENZ' then 5--'OVERPRIEM'
		when 'OX_PRIEM' then 6--'OX_PRIEM'  -- Шевелев, 26.08.2016, приблуда к ОХ
		when 'VIRT' then 7--'VIRT' -- Шевелев, 02.12.2016 - ВиртПриходМСК
		else 0--'GENERAL'
	    end as SortOrder	
FROM
(select
	rd.SKU, 
	rd.storerkey,
	0 skuqty,
	sum(rd.QTYRECEIVED) qty,
	sum(rd.QTYRECEIVED) qtyreceived,--sum(case when rd.toloc in ('PRIEM','PRIEM_EA','PRIEM_PL','QC') then rd.QTYRECEIVED else 0 end) qtyreceived, 
	0 QR_BRAK,--sum(case when rd.toloc like 'BRAKPRIEM' then rd.qtyreceived else 0 end) QR_BRAK, 
	rd.LOTTABLE02,rd.TOLOT,
	 case	when s.FREIGHTCLASS = '6' and rd.TOLOC NOT IN ('BRAKPRIEM','LOSTPRIEM','OVERPRIEM','PRETENZ') then 'SD'
			    when rd.TOLOC = 'BRAKPRIEM' then 'BRAKPRIEM'
			    when rd.TOLOC = 'OVERPRIEM' then 'OVERPRIEM'
			    when rd.TOLOC = 'LOSTPRIEM' then 'LOSTPRIEM'
			    when rd.TOLOC = 'PRETENZ' then 'OVERPRIEM'
			    when rd.TOLOC = 'OX_PRIEM' then 'OX_PRIEM'  -- Шевелев, 26.08.2016, приблуда к ОХ
			    when rd.TOLOC = 'VIRT' then 'VIRT' -- Шевелев, 02.12.2016 - ВиртПриходМСК
			    else 'GENERAL'
	    end as SCLAD  
from wh2.RECEIPTDETAIL rd
	join wh2.sku s on rd.SKU=s.sku
where rd.RECEIPTKEY = @receiptkey and rd.qtyexpected = 0 and rd.QTYRECEIVED != 0
group by rd.SKU, rd.STORERKEY, rd.TOLOT, rd.LOTTABLE02,
		case	when s.FREIGHTCLASS = '6' and rd.TOLOC NOT IN ('BRAKPRIEM','LOSTPRIEM','OVERPRIEM','PRETENZ') then 'SD'
			    when rd.TOLOC = 'BRAKPRIEM' then 'BRAKPRIEM'
			    when rd.TOLOC = 'OVERPRIEM' then 'OVERPRIEM'
			    when rd.TOLOC = 'LOSTPRIEM' then 'LOSTPRIEM'
			    when rd.TOLOC = 'PRETENZ' then 'OVERPRIEM'
			    when rd.TOLOC = 'OX_PRIEM' then 'OX_PRIEM'  -- Шевелев, 26.08.2016, приблуда к ОХ
			    when rd.TOLOC = 'VIRT' then 'VIRT' -- Шевелев, 02.12.2016 - ВиртПриходМСК
			    else 'GENERAL'
	    end--, lottable04, lottable05, lottable02
)A
order by SKU, sortorder

--select '#receiptdetail',* from  #receiptdetail ----****

--выборка ожиданий
insert into #podetail
select 
	pd.pokey, 
	pd.EXTERNPOKEY,
	pd.SKU, 
	pd.STORERKEY,
	sum(pd.QTYORDERED) qty, 
	sum(pd.QTYORDERED) QTYORDERED, 
	0 QTYADJUSTED, 
	0 QTYRECEIVED, 
	0 QR_BRAK,
	'',
	'','',LOTTABLE02, LOTTABLE04, LOTTABLE05	
	from wh2.PODETAIL pd 
		join wh2.PO p on p.POKEY = pd.POKEY 
	where p.OTHERREFERENCE = @receiptkey and pd.QTYORDERED>0
	group by pd.SKU, pd.STORERKEY, pd.pokey, pd.EXTERNPOKEY, pd.storerkey,LOTTABLE02, LOTTABLE04, LOTTABLE05
	order by pd.POKEY

--select '#podetail',* from #podetail ----****

-- общее количество товара
insert into #skuqty (sku, storerkey, qty)
select sku, storerkey, SUM(rd.qty) qty from #receiptdetail rd group by rd.sku, rd.storerkey


-- select '#skuqty',* from #skuqty


declare @sku varchar (20), 
		@storerkey varchar (20), 
		@rdid int, 
		@poid int,
		@poqtyordered float,	-- Заказанное кол-во
		@rdqtyreceived float,	-- Принято
		@rdQR_BRAK float,		-- Принято: Брак
		@rdSCLAD varchar(50),			-- СКЛАД
		@skuqty float,
		--@pokey varchar(20),
		@extpokey varchar(30),
		@originalQty float

declare @notfinished int
declare @currPO varchar(10), @lastPO varchar(10)
-- если есть строки с принятым кол-вом начинаем цикл
set @notfinished =  case when exists(select * from #receiptdetail where qtyreceived > 0) then 1 else 0 end;
-- выбираем макс.PO в которое будут падать все излишки
select @lastPO = max(id) from  #podetail

while (@notfinished = 1)
begin 
	--выбор первой строки из принятого количства
	if exists (select top 1 1  from #receiptdetail where qtyreceived > 0)
	    select top 1 @rdid = max(id), @sku = max(sku), @storerkey = max(storerkey), @rdqtyreceived = sum(qtyreceived), 
				--@rdQR_BRAK	= QR_BRAK,
				@rdSCLAD	= max(SCLAD)
			from #receiptdetail where qtyreceived > 0 group by id order by id
	else
	    select @sku = null, @rdqtyreceived = 0, @rdSCLAD = ''
	
	-- если есть строки с не нулевым ожидаемым - выбираем первую
	if not @sku is null
	begin
	    print 'sku from Receipt: ' + @sku
	    select top 1 @currPO = ID from #podetail where sku = @sku and storerkey = @storerkey and qty > 0
	    print 'CurrentPO = ' + isnull(@currPO,'NULL')
	end
	else
	begin
	    select top 1 @currPO = ID, @sku = sku,@storerkey = storerkey  from #podetail where qty > 0
	    print  'sku from PO: ' + @sku
	end
	-- если такой строки нет - то берем последнее использованное PO
	if @currPO is null 
		set @currPO = @lastPO
	
	print 'есть строки с ненулевым ожидаемым количеством'
	--выбор первой строки по товару в зз
	declare @POsku varchar(30)
	--select '#podetail',* from #podetail
	select @poid = ID, @poKey = pokey,@extpokey = externpokey, @poqtyordered = qty, @POsku = sku , @originalQty = qtyordered
	
	from #podetail where ID = @currPO -- sku = @sku and storerkey = @storerkey and qty != 0
--				print 'storerkey '+@storerkey+', sku '+@sku+', qtyordered '+cast(@poqtyordered as varchar(20))

	if @sku != @POsku
	begin
	   set @poqtyordered = 0
	end				
	print	'[	Владелец '+@storerkey
				+ ', ' + char(13) + '	Товар '+@sku
				+ ', ' + char(13) + '	Заказано '+cast(@poqtyordered as varchar(20))
				+ ', ' + char(13) + '	Принято '+cast(@rdqtyreceived as varchar(20))
				--+ ', ' + char(13) + '	qtyreceivedbrack ' + cast( @rdQR_BRAK as varchar(20)) 
				+ ', ' + char(13) + '	@rdSCLAD ' + cast( @rdSCLAD as varchar(20))
				+ char(13) 
				+ ']'
	-- повторяем пока есть принятое И ожидаемое
	declare @raspred decimal(22,5)
	
	if (isnull(@rdqtyreceived,0) > 0 AND isnull(@poqtyordered,0) > 0)
	BEGIN
		-- 1. принятое <= ожидаемое
		declare @susr2 varchar(10)
		
		if @rdqtyreceived <= @poqtyordered
		begin
		    print '1. принятое <= ожидаемое'
			-- распределить все принятое в текущую строку ЗЗ
			set @raspred = @rdqtyreceived   -- поправил, чтобы недостачи не формиловались --Шевелев 14.04.2017
			-- уменьшить ожидаемое на распределенное
			--set @poqtyordered = 0--@poqtyordered - @rdqtyreceived
			set @poqtyordered = @poqtyordered - @rdqtyreceived -- поправил, чтобы недостачи не формиловались --Шевелев 14.04.2017
			-- обнулить принятое
			set @rdqtyreceived = 0
			set @susr2 = '1'
		end
		else -- 2. принятое > ожидаемое
		begin
		    print '2. принятое > ожидаемое'
			-- распределить принятое в кол-ве ожидаемого
			set @raspred = @poqtyordered
			-- уменьшить принятое на распределенное
			set @rdqtyreceived = @rdqtyreceived - @poqtyordered
			-- обнулить ожидаемое
			set @poqtyordered = 0
			set @susr2 = '2'
		end
		-- добавляем строку результата
		insert into #podetailresult (
				sku, 	storerkey, 	 pokey, externpokey, qtyordered, QTYRECEIVED, lot, 	SCLAD,	susr2,	lot02,		lot04,			lot05)
		select rd.sku, rd.storerkey, @pokey, @extpokey, @raspred, 	@raspred, 	 rd.lot, rd.SCLAD, @susr2, la.LOTTABLE02, la.LOTTABLE04, la.LOTTABLE05
		from #receiptdetail rd, wh2.LOTATTRIBUTE la
		where rd.id = @rdid	and la.LOT=rd.lot			
		
		-- корректируем принятое в таблице
		update #receiptdetail set	qtyreceived = @rdqtyreceived 	where id = @rdid
		-- корректируем ожидаемое в таблице
		update #podetail set qty = @poqtyordered where id = @poid
		
		
		
	end			
	else 
	--3. Ожидаемое отсутствует
	IF (isnull(@rdqtyreceived,0) > 0 AND isnull(@poqtyordered,0) <= 0)
	begin
	    print '3. Ожидаемое отсутствует'
		set @raspred = @rdqtyreceived
		set @rdqtyreceived = 0
		set @poqtyordered = 0
		-- добавляем строку результата
		insert into #podetailresult (
				sku, 	storerkey, 	 pokey, externpokey, qtyordered, QTYRECEIVED, lot, 	SCLAD,	susr2,	lot02,		lot04,			lot05)
		select rd.sku, rd.storerkey, @pokey, @extpokey, @poqtyordered, 	@raspred, 	 rd.lot, rd.SCLAD, '3', la.LOTTABLE02, la.LOTTABLE04, la.LOTTABLE05
		from #receiptdetail rd, wh2.LOTATTRIBUTE la
		where rd.id = @rdid	and la.LOT=rd.lot			
		-- корректируем принятое в таблице
		update #receiptdetail set	qtyreceived = @rdqtyreceived 	where id = @rdid
	end
	else
	--4. принятое остутствует
	IF (isnull(@rdqtyreceived,0) = 0 AND isnull(@poqtyordered,0) > 0)	
	begin
	    print '4. принятое остутствует'
		set @raspred = 0
		set @rdqtyreceived = 0
		-- добавляем строку результата
		
		--select @poqtyordered as 'осталось' , @originalQty as 'заказанное'
		
		if (@poqtyordered = @originalQty)
			begin
				insert into #podetailresult (
						sku, 	storerkey, 	 pokey, externpokey, qtyordered, QTYRECEIVED, lot, 	SCLAD,		susr2,	lot02,				lot04,			lot05)
				select rd.sku, rd.storerkey, @pokey, @extpokey, @poqtyordered, 	@raspred, 	 '', 'LOSTPRIEM', '4', 'НедовложенияПост', '19000101 00:00', '19000101 00:00'
				from #podetail rd --, wh2.LOTATTRIBUTE la
				where rd.id = @poid--	and la.LOT=rd.lot
			end		
		-- корректируем ожидаемое в таблице
		update #podetail set qty = 0 where id = @poid
	end
	else
		raiserror ('Ошибка вариантов распределения',16,1)
	
	--set @lastPO = @currPO
	if exists(select top 1 1 from #podetail where qty > 0)
				or exists (select top 1 1 from #receiptdetail where qtyreceived > 0)
		set @notfinished = 1
	else
		set @notfinished = 0
end

--select '#podetailresult',* from #podetailresult ----****

--select '#podetail', * from #podetail
--select '#podetailresul', * from #podetailresult where sku = '38183'
--select * from #receiptdetail

select * from #podetailresult

-- --вставка результатов в ЗЗ
declare @prevCount int
set @prevCount = 0
while (exists(select * from #podetailresult))
	begin
		select distinct top(1) @pokey = pokey from #podetailresult
		
		select @polinenumber = MAX(POLINENUMBER) from wh2.PODETAIL where POKEY = @pokey
		
		print 'po: '+@pokey + '  line: ' + @polinenumber
  
  
		insert into wh2.PODETAIL (WHSEID,pokey,	EXTERNPOKEY,POLINENUMBER,EXTERNLINENO,
			QTYORDERED,-- ожидаемое по ЗЗ			--qtyadjusted, -- ожидаемое по строке
			QTYRECEIVED, -- принятое Н+Б			--Qtyrejected, -- принятое Б
			SKU,SKUDESCRIPTION,STORERKEY,SUSR4,SUSR2,
			PACKKEY,UOM,ALTSKU,Lottable02,LOTTABLE04,LOTTABLE05 )
		output inserted.WHSEID,inserted.pokey,inserted.EXTERNPOKEY,inserted.POLINENUMBER,inserted.EXTERNLINENO,
			inserted.QTYORDERED,-- ожидаемое по ЗЗ	
			inserted.QTYRECEIVED, -- принятое Н+Б
			inserted.SKU,inserted.SKUDESCRIPTION,inserted.STORERKEY,inserted.SUSR4,inserted.SUSR2,
			inserted.PACKKEY,inserted.UOM,inserted.ALTSKU,inserted.Lottable02,inserted.LOTTABLE04,inserted.LOTTABLE05 
		into #OutPOData (WHSEID,pokey,EXTERNPOKEY,POLINENUMBER,EXTERNLINENO,
			QTYORDERED,-- ожидаемое по ЗЗ	
			QTYRECEIVED, -- принятое Н+Б
			SKU,SKUDESCRIPTION,STORERKEY,SUSR4,SUSR2,
			PACKKEY,UOM,ALTSKU,Lottable02,LOTTABLE04,LOTTABLE05)
		
--select @prevCount,@polinenumber
		select 
			--'D' S,
			'wh2' WHSEID,	@pokey pokey,	EXTERNPOKEY,
			right('0000'+cast((row_number()over (partition by pdr.pokey order by pdr.id) /*-@prevCount*/+@polinenumber) as varchar(20)),5) POLINENUMBER,
			'' EXTERNLINENO,
			0, -- qtyordered, --Шевелев 14.04.2017 - убираем вставку qtyOrdered в podetail
			pdr.QTYRECEIVED, --принятое включая брак
			pdr.sku,
			left(s.DESCR,60) SKUDESCRIPTION, -- в wh2.PoDetail - skudescription 60 символов, если будет больше, будет ошибка и файл в аналит не уйдет.
			pdr.STORERKEY,pdr.SCLAD SUSR4,pdr.susr2,s.PACKKEY,s.RFDEFAULTUOM UOM,
			IsNull(r.ALTSKU,s.ALTSKU) as ALTSKU,
			--l.LOTTABLE01,
			pdr.lot02 Lottable02,pdr.LOt04 Lottable04,pdr.LOT05 Lottable05
--into dbo.POdetTest
			from #podetailresult pdr 
				join wh2.sku s on pdr.sku = s.SKU and pdr.storerkey = s.storerkey
				--left join #receiptdetail rd on rd.sku = pdr.sku and rd.storerkey = pdr.storerkey and pdr.lot =  rd.lot --pdr.LOTTABLE02 = rd.LOTTABLE02
				left join wh2.lotattribute l on pdr.lot = l.lot
				
				left join (
			    	    select sku,storerkey,max(ALTSKU) as ALTSKU
			    	    from wh2.RECEIPTDETAIL 
			    	    where RECEIPTKEY = @receiptkey
			    		   and IsNull(ALTSKU,'') <> '' 
			    	    group by sku,storerkey
				)r
					on	pdr.sku = r.SKU and pdr.storerkey = r.storerkey
				
			where pdr.pokey = @pokey
			order by pdr.sku
			--and pdr.sku = '38183'
		set @prevCount = @@rowcount
		delete from #podetailresult where @pokey = pokey
	end
	
	alter table #outPOData add  SELLERNAME varchar(45), BUYERADDRESS4 varchar(45)
	
	update t1 set SELLERNAME =  p.SELLERNAME, BUYERADDRESS4=p.BUYERADDRESS4,SUSR2 = p.SUSR2
	from #outPOData t1 
	join wh2.PO p on t1.pokey = p.pokey
	
	
select --'#OutPOData',
			IDENTITY(int,1,1) idpodet,
			WHSEID,pokey,EXTERNPOKEY,sellername,BUYERADDRESS4,--POLINENUMBER,EXTERNLINENO,
			sum(QTYORDERED)qtyordered,-- ожидаемое по ЗЗ	
			sum(QTYRECEIVED)qtyreceived, -- принятое Н+Б
			SKU,SKUDESCRIPTION,STORERKEY,
			SUSR4,--SUSR2,	PACKKEY,UOM,
			ALTSKU,Lottable02,LOTTABLE04,LOTTABLE05
 into #result
 from #OutPOData
 group by  WHSEID,pokey,EXTERNPOKEY,sellername,BUYERADDRESS4,--POLINENUMBER,EXTERNLINENO,
			SKU,SKUDESCRIPTION,STORERKEY,SUSR4,--SUSR2,PACKKEY,UOM,
			ALTSKU,Lottable02,LOTTABLE04,LOTTABLE05

--print 'выбираем номера ЗЗ для пуо'
	--insert into #pokey select pokey from wh2.PO where OTHERREFERENCE = @receiptkey order by POKEY
	select identity(int,1,1) idpo, pokey into #pokey from wh2.PO where OTHERREFERENCE = @receiptkey order by POKEY
		
		select @potype=POTYPE from wh2.PO where POKEY=@pokey
		
		if @potype not in ('4','5') 
			begin		

				print 'Пытаемся вставить в обменные таблы DAX'	    
				


				select  @n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
				from    [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].INFORINTEGRATIONTABLE_RECEIVED
				
				insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].INFORINTEGRATIONTABLE_RECEIVED
				(DataAReaID, DocID, DocType,INFORDAXSYSTEM, CUSTVENDAC, inventLocationID, Status,daxstatus,ReceivedDate,RecID)
				
				select  'SZ' DataAReaID,EXTERNPOKEY,POTYPE, '1' INFORDAXSYSTEM ,SELLERNAME,SUSR2,  '27' Status,'5' daxstatus, GETDATE() ReceivedDate,
   					@n + tp.idpo as recid
				from    #pokey tp
				join wh2.PO p on tp.POKEY = p.POKEY
				    
				    
				if @@ERROR <> 0
				begin	    
    					print 'Пытаемся вставить в обменные таблы DAX - голова Ошибка'
					--set @error = 1
					goto endproc			

				end

					select  @n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
					from    [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].INFORINTEGRATIONLINE_RECEIVED


						update #result set LOTTABLE02=null where LOTTABLE02='' --Шевелев 24.03.2015
						print 'Пытаемся вставить в обменные таблы DAX - после апдейта'
				print 'тут должен быть селект'
				insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].INFORINTEGRATIONLINE_RECEIVED
					(   DataAReaID, 
						DocID,		
						ItemID,		
						ORDEREDQTYDAX,	
						PICKEDQTYINFOR,	
						BarCodeString,	
						InventLocationID, 
						InventSerialID, 
						PRODDATE,
						InventExpireDate,
						Status,
						daxstatus,
						RecID)

				select 'SZ',
    					EXTERNPOKEY,
    					SKU,
						QTYORDERED,
						QTYRECEIVED,
						Isnull(ALTSKU,'') as ALTSKU,
						case    
							when r.SUSR4 = 'GENERAL' then 'СкладПродаж'
							when r.SUSR4 = 'BRAKPRIEM' then 'ПТВПостащика'
							when r.SUSR4 = 'PRETENZ' then 'ПеревложенияПоставщ'
							when r.SUSR4 = 'LOSTPRIEM' then 'СкладПродаж' --НедовложенияПост
							when r.SUSR4 = 'OVERPRIEM' then 'ПеревложенияПоставщ'
							when r.SUSR4 = 'OX_PRIEM' then 'ОтветХранениеПост' -- Шевелев, 26.08.2016, приблуда к ОХ
							when r.SUSR4 = 'VIRT' then 'ВиртПриход' -- Шевелев, 02.12.2016 - ВиртПриходМСК
							when r.SUSR4 = 'SD' then 'СД'
						end as SUSR4,
						--case    
						--	when  r.SUSR4 = 'GENERAL' then 'Москва'
						--	when  r.SUSR4 = 'BRAKPRIEM' then 'МС_ПТВПостащика'
						--	when  r.SUSR4 = 'PRETENZ' then 'МС_ПеревложенияПост'
						--	when  r.SUSR4 = 'LOSTPRIEM' then 'МС_НедовложенияПост'
						--	when  r.SUSR4 = 'OVERPRIEM' then 'МС_ПеревложенияПост'
						--	when  r.SUSR4 = 'OX_PRIEM' then 'МС_ОтветХран' -- Шевелев, 26.08.2016, приблуда к ОХ
						--	when  r.SUSR4 = 'SD' then 'МС_СД'
						-- end as SUSR4,
						IsNull(LOTTABLE02,'бс') as LOTTABLE02,
						IsNull(LOTTABLE04,'1900-01-01') as LOTTABLE04,
						IsNull(LOTTABLE05,'1900-01-01') as LOTTABLE05,
						'27','5',@n + idpodet as recid	
				from    #result r
				join #pokey p on p.POKEY = r.pokey 
			end
			else
				begin
					print 'выгрузка не положена, документ 4-5'
				end
 
   if @@ERROR <> 0
    begin   	
	    print 'Пытаемся вставить в обменные таблы DAX - детали Ошибка'
	    --set @error = 1
	    goto endproc
    end



print 'обрабатываем поочередно все ЗЗ'
	while 0 < (select count (pokey) from #pokey)
		begin
			select top(1) @pokey = pokey from #pokey
			
			select 
				'RECEIPTCONFIRM' filetype,
				p.STORERKEY storerkey,
				p.OTHERREFERENCE receiptkey,
				p.EXTERNPOKEY externpokey,
				p.POKEY pokey,
				p.POTYPE potype,
				p.SUSR2 susr2,
				p.SUSR3 susr3,
				p.NOTES notes,
				p.SELLERNAME sellername,
				p.VESSEL vessel,
				r.RECEIPTDATE receiptdate,
				r.CLOSEDDATE closedate,
				pd.SKU sku,
				--pd.QTYORDERED qty,
				pd.QTYADJUSTED - pd.QTYRECEIVED QR_BRAK,
				pd.QTYADJUSTED qtyexpected,--оюиаемое
				pd.QTYRECEIVED qtyreceived,--принятое
				--pd.QR_BRAK QR_BRAK,--брак
		--		0 QR_BRAK,
				l.LOTTABLE01 packkey,
				--case when l.LOTTABLE02 = @bs then @bsanalit else l.LOTTABLE02 end attribute02, --замена кода безсерийного товара инфор на код аналита
				convert(varchar(20),l.LOTTABLE04,120) attribute04,
				convert(varchar(20),l.LOTTABLE05,120) attribute05,
				p.BUYERADDRESS4 numberdoc
			from wh2.PO p join wh2.PODETAIL pd on p.POKEY = pd.pokey
				join wh2.RECEIPT r on r.RECEIPTKEY = p.OTHERREFERENCE
				left join wh2.LOTATTRIBUTE l on l.LOT = pd.susr5
			where p.POKEY = @pokey and pd.QTYORDERED = 0
			
			delete from #pokey where POKEY = @pokey
		end
				
-- После успешной выдачи результата дата-адаптеру
print '9.1. обновление susr5 в переданном ПУО'
	update r set r.susr5 = '9' from wh2.receipt r where r.receiptkey = @receiptkey
	update wh2.TRANSMITLOG 	set KEY5 = '1'	where TRANSMITLOGKEY = @transmitlogkey	

print '9.2. обновление статуса ЗЗ'
	update wh2.po set [status] = '11' where otherreference = @receiptkey

	update pod set [status] = '11' 
		from wh2.po po, wh2.podetail pod 
		where po.otherreference = @receiptkey and po.pokey = pod.pokey

endproc:
if @send_error = 1
	begin
		print 'отправляем сообщение об ошибке по почте'
		print @msg_errdetails
		set @source = 'proc_DA_CompositeASNClose'
		insert into DA_InboundErrorsLog (source,msg_errdetails) values (@source,@msg_errdetails)		
		exec app_DA_SendMail @source, @msg_errdetails						
	end

IF OBJECT_ID('tempdb..#receiptdetail') IS NOT NULL DROP TABLE #receiptdetail
IF OBJECT_ID('tempdb..#podetail') IS NOT NULL DROP TABLE #podetail
IF OBJECT_ID('tempdb..#podetailresult') IS NOT NULL DROP TABLE #podetailresult
IF OBJECT_ID('tempdb..#skuqty') IS NOT NULL DROP TABLE #skuqty
IF OBJECT_ID('tempdb..#pokey') IS NOT NULL DROP TABLE #pokey
IF OBJECT_ID('tempdb..#OutPOData') IS NOT NULL DROP TABLE #OutPOData
IF OBJECT_ID('tempdb..#result') IS NOT NULL DROP TABLE #result






