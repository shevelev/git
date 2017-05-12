


-- ПОДТВЕРЖДЕНИЕ УПАКОВКИ ЗАКАЗА

ALTER PROCEDURE [dbo].[proc_DA_OrderPacked](
	@wh varchar(10),
	@transmitlogkey varchar (10)
)AS


--
--SET NOCOUNT ON
--
--if @wh <> 'wh1'
--begin
--	raiserror('Недопустимая схема %s',16,1,@wh)
--	return
--end
--
declare	@orderkey varchar (10) -- номер заказа
declare @source varchar(50) 

declare @send_error bit
declare @msg_errdetails varchar(max)

--declare @skip_0_qty varchar(10)
--declare	@transmitlogkey varchar (10)
--set @transmitlogkey = '0000000760'

declare @bs varchar(3) select @bs = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'
declare @bsanalit varchar(3) select @bsanalit = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bsanalit'



CREATE TABLE #result (	
	[orderkey] varchar(32),
	[storerkey] varchar(15),--
	[externorderkey] varchar(32),--
	[type] varchar(10),--
	[susr1] varchar(30),--
	[susr2] varchar(30),--
	[susr3] varchar(30),--
	[susr4] varchar(30),--
	--[susr5] varchar(30),--
	[sku] varchar(10),--
	[packkey] varchar(50),--
	[attribute02] varchar(50),--
	[attribute04] datetime null,--
	[attribute05] datetime null,--
	[openqty] decimal(22,5), --
	packedqty decimal(22,5), --
	[packdate] datetime
	--[consigneekey] varchar(15),
	--[actualshipdate] datetime,
	--[externlineno] varchar (5),
	--[externlineno_2] varchar (30),
	--[shippedqty] decimal(22,5),
	--[shippingfinished] varchar(30),-- 1-отгрузка завершена, 0-отгрузка незавершена
	--[stage] varchar(20),
	--[rma] varchar(30),
	
)

select @orderkey = tl.key1 from wh1.transmitlog tl 
where tl.transmitlogkey = @transmitlogkey

if (select count(*) from wh1.orders where ORDERKEY = @orderkey and susr2 >= '6') != 0
	begin
		print 'повторная упаковка заказа'
		set @send_error = 1
		set @msg_errdetails = 'Повторная упаковка Заказа на отгрузку '+ @orderkey
		goto endproc
	end

--выбираем строки невыгруженных упакованных отборов 
select serialkey, orderkey, sku, status, pdudf2, pickdetailkey, orderlinenumber, qty, dropid 
into #tmp
from wh1.pickdetail 
where orderkey = @orderkey and isnull(pdudf1,'0') != '6' and status >= '6'--in ('1','5','6','8','9')

-- проверям, все ли отборы упакованы
if (exists(select top(1) serialkey from #tmp where status < '6'))
	begin
		-- не все загруженные отборы отгружены - завершаем обработку
		print 'не все отборы упакованы'
	end
else
	begin
		-- возвращаем результат датаадаптеру
		insert into #result 
		select 
			--t.dropid as orderkey,--o.orderkey,--+'-'+right('000'+o.susr2,3) orderkey,
			o.ORDERKEY,
			o.storerkey,
 			o.externorderkey,
			--o.consigneekey,
			o.[type],
			od.susr1,
			od.susr2,
			od.susr3,
			od.susr4,
			--od.susr5,
			od.sku,
			od.packkey,
			--case when od.LOTTABLE02 = @bs then @bsanalit else od.LOTTABLE02 end,
			case when od.LOTTABLE02 = '' then @bsanalit else od.LOTTABLE02 end,
					
			convert(varchar(20),od.LOTTABLE04,120),
			convert(varchar(20),od.LOTTABLE05,120),
			od.ORIGINALQTY,
			od.QTYPICKED, --od.openqty
			convert(varchar(20),o.editdate,120)
			--od.externlineno,
			--sum(t.qty) packedqty,
			--isnull(o.transportationmode,'0') shippingfinished,
			--isnull(od.lottable03,'') stage,
			--isnull(od.susr4,'') rma
		from wh1.orders o 
			join wh1.orderdetail od on o.orderkey = od.orderkey
--			join #tmp t on t.orderkey = o.orderkey and t.orderlinenumber = od.orderlinenumber -- and t.sku = od.sku and t.storerkey = od.storerkey
		where o.orderkey = @orderkey
		--group by o.externorderkey, o.orderkey, o.storerkey, 
		--		o.consigneekey, /*o.actualshipdate, */o.editdate,
		--		o.[type], od.externlineno, od.susr1, od.sku, o.susr1, o.susr3, 
		--		o.susr2, od.lottable03, od.susr4, o.transportationmode, t.dropid

		-- обновляем статусы отправленных строк
		--update pd set pd.pdudf1 = '6'
		--	from wh1.pickdetail pd join #tmp t on pd.serialkey = t.serialkey
		update pd set pd.pdudf1 = '6'
			from wh1.pickdetail pd where pd.ORDERKEY = @orderkey
		update wh1.orders set SUSR2 = '6' where ORDERKEY = @orderkey and SUSR2 != '9'


--		-- добавляем строки, не отгружаемые в текущей отгрузке
		--select 
 	--		o.externorderkey,
		--	o.orderkey,--+'-'+right('000'+o.susr2,3) orderkey,
		--	o.storerkey,
		--	o.consigneekey,
		--	o.editdate,
		--	o.[type],
		--	od.externlineno,
		--	od.susr1 externlineno_2,
		--	od.sku,
		--	0 shippedqty,
		--	isnull(o.transportationmode,'0') shippingfinished,
		--	isnull(od.lottable03,'') stage,
		--	isnull(od.susr4,'') rma
		--		into #result1
		--	from 
		--		wh1.orders o join wh1.orderdetail od on o.orderkey = od.orderkey and od.originalqty !=0 and isnull(od.externlineno,'') != ''
		--	where o.orderkey = @orderkey

			-- удаление отгруженных строк
--			delete from r1
--				from #result1 r1 join #result r on r1.externlineno = r.externlineno 
----			-- вставка в результат неотгруженных строк
--			if ((select count(*) from #result) != 0)
--			insert into #result
--			select * from #result1
			

	end

select 'ORDERPACKED' filetype, * from #result
drop table #result
drop table #tmp
--drop table #result1

endproc:
if @send_error = 1
	begin
		print 'отправляем сообщение о повторной упаковке заказа'
		print @msg_errdetails
		set @source = 'proc_DA_OrderPacked'
		insert into DA_InboundErrorsLog (source,msg_errdetails) values (@source,@msg_errdetails)		
		exec app_DA_SendMail @source, @msg_errdetails
	end

--status pickdetail
--	0 - зарезервирован
--	1 - запущен
--	5 - отобран
--	6 - упакован
--	8 - загружен
--	9 - отгружен

--
--
--


