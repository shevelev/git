


-- ������������� �������� ������

ALTER PROCEDURE [dbo].[proc_DA_OrderClose](
	@wh varchar(10),
	@transmitlogkey varchar (10)
)AS


--
--SET NOCOUNT ON
--
--if @wh <> 'wh1'
--begin
--	raiserror('������������ ����� %s',16,1,@wh)
--	return
--end
--
declare	@orderkey varchar (10) -- ����� ������
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
	[shippingfinished] varchar(30),-- 1-�������� ���������, 0-�������� �����������
	[stage] varchar(20),
	[rma] varchar(30)
)

select @orderkey = tl.key1 from wh1.transmitlog tl 
where tl.transmitlogkey = @transmitlogkey

--�������� ������ �������������� ������� 
select serialkey,orderkey,sku,status,pdudf2,pickdetailkey,orderlinenumber,qty,dropid 
into #tmp
from wh1.pickdetail where orderkey = @orderkey and isnull(pdudf1,'0') != '9' and status >= '8'--in ('1','5','6','8','9')

-- ��������, ��� �� ������ ���������
if (exists(select top(1) serialkey from #tmp where status < '9'))
	begin
		-- �� ��� ����������� ������ ��������� - ��������� ���������
		print ' �� ��� ������ ���������'
	end
else
	begin

		-- ��� ����������� ������ ��������� - ����������� ������ �������� �� ������
		update wh1.orders set susr2 = case when isnull(susr2,'') = '' or susr2 = '' then '1' else cast((cast(susr2 as int) + 1) as varchar(30)) end
			where orderkey = @orderkey

		-- ��� ����������� ������ ��������� - ������ ���� ��������
		print ' ��� ����������� ������ ���������'
		-- ���������� ��������� ������������
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

		-- ��������� ������� ������������ �����
		update pd set pd.pdudf1 = '9'
			from wh1.pickdetail pd join #tmp t on pd.serialkey = t.serialkey

--		-- ��������� ������, �� ����������� � ������� ��������
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

			-- �������� ����������� �����
			delete from r1
				from #result1 r1 join #result r on r1.externlineno = r.externlineno 
--			-- ������� � ��������� ������������� �����
			if ((select count(*) from #result) != 0)
			insert into #result
				select * from #result1
	end

select 'ORDERSHIPPED' filetype, * from #result
drop table #result
drop table #tmp
drop table #result1


--status pickdetail
--	0 - ��������������
--	1 - �������
--	5 - �������
--	6 - ��������
--	8 - ��������
--	9 - ��������

--
--
--

