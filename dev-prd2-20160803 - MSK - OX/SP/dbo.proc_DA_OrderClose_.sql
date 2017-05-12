


-- ПОДТВЕРЖДЕНИЕ ОТГРУЗКИ ЗАКАЗА

ALTER PROCEDURE [dbo].[proc_DA_OrderClose](
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
--declare @skip_0_qty varchar(10)
--declare	@transmitlogkey varchar (10)
--set @transmitlogkey = '0000000760'



CREATE TABLE #result (	
	[externorderkey] varchar(32),
	[orderkey] varchar(32),
	[storerkey] varchar(15),
	[consigneekey] varchar(15),
	[actualshipdate] datetime,
	[type] varchar(10),
	[externlineno] varchar (5),
	[externlineno_2] varchar (30),
	[sku] varchar(10),
	[shippedqty] decimal(22,5),
	[shippingfinished] varchar(30),-- 1-отгрузка завершена, 0-отгрузка незавершена
	[stage] varchar(20),
	[rma] varchar(30)
)

select @orderkey = tl.key1 from wh1.transmitlog tl 
where tl.transmitlogkey = @transmitlogkey

--выбираем строки неотправленных отборов 
select serialkey,orderkey,sku,status,pdudf2,pickdetailkey,orderlinenumber,qty,dropid 
into #tmp
from wh1.pickdetail where orderkey = @orderkey and isnull(pdudf1,'0') != '9' and status >= '8'--in ('1','5','6','8','9')

-- проверям, все ли отборы отгружены
if (exists(select top(1) serialkey from #tmp where status < '9'))
	begin
		-- не все загруженные отборы отгружены - завершаем обработку
		print ' не все отборы отгружены'
	end
else
	begin

		-- все загруженные отборы отгружены - увеличиваем счетчк отгрузок по заказу
		update wh1.orders set susr2 = case when isnull(susr2,'') = '' or susr2 = '' then '1' else cast((cast(susr2 as int) + 1) as varchar(30)) end
			where orderkey = @orderkey

		-- все загруженные отборы отгружены - выдаем файл отгрузки
		print ' все загруженные отборы отгружены'
		-- возвращаем результат датаадаптеру
		insert into #result 
		select 
 			o.externorderkey,
			o.orderkey+'-'+right('000'+o.susr2,3) orderkey,
			o.storerkey,
			o.consigneekey,
			o.editdate,
			o.[type],
			od.externlineno,
			od.susr1,
			od.sku,
			sum(t.qty) shippedqty,
--			o.susr1,
			isnull(o.transportationmode,'0') shippingfinished,
			isnull(od.lottable03,'') stage,
			isnull(od.susr4,'') rma
			from wh1.orders o join wh1.orderdetail od on o.orderkey = od.orderkey
				join #tmp t on t.orderkey = o.orderkey and t.orderlinenumber = od.orderlinenumber -- and t.sku = od.sku and t.storerkey = od.storerkey
			where o.orderkey = @orderkey
			group by o.externorderkey, o.orderkey, o.storerkey, 
				o.consigneekey, /*o.actualshipdate, */o.editdate,
				o.[type], od.externlineno, od.susr1, od.sku, o.susr1, o.susr3, 
				o.susr2,od.lottable03, od.susr4, o.transportationmode

		-- обновляем статусы отправленных строк
		update pd set pd.pdudf1 = '9'
			from wh1.pickdetail pd join #tmp t on pd.serialkey = t.serialkey

--		-- добавляем строки, не отгружаемые в текущей отгрузке
		select 
 			o.externorderkey,
			o.orderkey+'-'+right('000'+o.susr2,3) orderkey,
			o.storerkey,
			o.consigneekey,
			o.editdate,
			o.[type],
			od.externlineno,
			od.susr1 externlineno_2,
			od.sku,
			0 shippedqty,
--			o.susr1 rma,
			isnull(o.transportationmode,'0') shippingfinished,
			isnull(od.lottable03,'') stage,
			isnull(od.susr4,'') rma
				into #result1
			from wh1.orders o join wh1.orderdetail od on o.orderkey = od.orderkey and od.originalqty !=0 and isnull(od.externlineno,'') != ''
			where o.orderkey = @orderkey

			-- удаление отгруженных строк
			delete from r1
				from #result1 r1 join #result r on r1.externlineno = r.externlineno 
--			-- вставка в результат неотгруженных строк
			if ((select count(*) from #result) != 0)
			insert into #result
				select * from #result1
	end

select 'ORDERSHIPPED' filetype, * from #result
drop table #result
drop table #tmp
drop table #result1


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

