

ALTER PROCEDURE [rep].[Act_of_acceptance](
--DECLARE
	@pk varchar(15)--='0000039958'
	--'0000030596'
	--'0000030573'
	--'0000030560'
	--'0000030575' BRAKPRIEM
	)
AS

declare @receiptkey varchar(10) = null--,@transmitlogkey varchar (10) 
--declare @error int = 0

--declare @ext2pokey varchar(10)

--set @ext2pokey='0000053125'

select @receiptkey = OTHERREFERENCE from wh1.po where POKEY=@pk

print @receiptkey

if @receiptkey is null return

declare @source varchar(100) --set --@source = 'proc_DA_CompositeASNClose'
declare @send_error bit
declare @msg_errdetails varchar(max)
declare @receiptlinenumber varchar(5)
declare @polinenumber varchar(5)
declare @pokey varchar(10)
declare @expokey varchar(20)
declare @bs varchar(3) select @bs = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'
declare @bsanalit varchar(3) select @bsanalit = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bsanalit'
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
	susr2 varchar(30) NULL, -- �����
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
	qtyordered float NULL, -- ��������� �� ��
	QTYADJUSTED float NULL, -- ��������� �� ������ 
	QTYRECEIVED float NULL, -- �������� �+�
	QR_BRAK float NULL, -- �������� �
	susr2 varchar(30) NULL, -- ����� ������
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


-- ������� ��������
insert into #receiptdetail 
select a.*,
	/* ��������� ������� ������������� ������ �� ������� */
	case SCLAD when 'SD' then 1--
		when 'BRAKPRIEM' then 2--'BRAKPRIEM'
		when 'OVERPRIEM' then 3--'OVERPRIEM'
		when 'LOSTPRIEM' then 4--'LOSTPRIEM'
		--when 'PRETENZ' then 5--'OVERPRIEM'
		when 'OX_PRIEM' then 6--'OX_PRIEM'  -- �������, 26.08.2016, �������� � ��
		when 'VIRT' then 7--'VIRT' -- �������, 02.12.2016 - �������������
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
			    when rd.TOLOC = 'OX_PRIEM' then 'OX_PRIEM'  -- �������, 26.08.2016, �������� � ��
			    when rd.TOLOC = 'VIRT' then 'VIRT' -- �������, 02.12.2016 - �������������
			    else 'GENERAL'
	    end as SCLAD  
from wh1.RECEIPTDETAIL rd
	join wh1.sku s on rd.SKU=s.sku
where rd.RECEIPTKEY = @receiptkey and rd.qtyexpected = 0 and rd.QTYRECEIVED != 0
group by rd.SKU, rd.STORERKEY, rd.TOLOT, rd.LOTTABLE02,
		case	when s.FREIGHTCLASS = '6' and rd.TOLOC NOT IN ('BRAKPRIEM','LOSTPRIEM','OVERPRIEM','PRETENZ') then 'SD'
			    when rd.TOLOC = 'BRAKPRIEM' then 'BRAKPRIEM'
			    when rd.TOLOC = 'OVERPRIEM' then 'OVERPRIEM'
			    when rd.TOLOC = 'LOSTPRIEM' then 'LOSTPRIEM'
			    when rd.TOLOC = 'PRETENZ' then 'OVERPRIEM'
			    when rd.TOLOC = 'OX_PRIEM' then 'OX_PRIEM'  -- �������, 26.08.2016, �������� � ��
			    when rd.TOLOC = 'VIRT' then 'VIRT' -- �������, 02.12.2016 - �������������
			    else 'GENERAL'
	    end--, lottable04, lottable05, lottable02
)A
order by SKU, sortorder

--select '#receiptdetail',* from  #receiptdetail ----****

--������� ��������
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
	from wh1.PODETAIL pd 
		join wh1.PO p on p.POKEY = pd.POKEY 
	where p.OTHERREFERENCE = @receiptkey and pd.QTYORDERED>0
	group by pd.SKU, pd.STORERKEY, pd.pokey, pd.EXTERNPOKEY, pd.storerkey,LOTTABLE02, LOTTABLE04, LOTTABLE05
	order by pd.POKEY

--select '#podetail',* from #podetail ----****

-- ����� ���������� ������
insert into #skuqty (sku, storerkey, qty)
select sku, storerkey, SUM(rd.qty) qty from #receiptdetail rd group by rd.sku, rd.storerkey


-- select '#skuqty',* from #skuqty


declare @sku varchar (20), 
		@storerkey varchar (20), 
		@rdid int, 
		@poid int,
		@poqtyordered float,	-- ���������� ���-��
		@rdqtyreceived float,	-- �������
		@rdQR_BRAK float,		-- �������: ����
		@rdSCLAD varchar(50),			-- �����
		@skuqty float,
		--@pokey varchar(20),
		@extpokey varchar(30),
		@originalQty float

declare @notfinished int
declare @currPO varchar(10), @lastPO varchar(10)
-- ���� ���� ������ � �������� ���-��� �������� ����
set @notfinished =  case when exists(select * from #receiptdetail where qtyreceived > 0) then 1 else 0 end;
-- �������� ����.PO � ������� ����� ������ ��� �������
select @lastPO = max(id) from  #podetail

while (@notfinished = 1)
begin 
	--����� ������ ������ �� ��������� ���������
	if exists (select top 1 1  from #receiptdetail where qtyreceived > 0)
	    select top 1 @rdid = max(id), @sku = max(sku), @storerkey = max(storerkey), @rdqtyreceived = sum(qtyreceived), 
				--@rdQR_BRAK	= QR_BRAK,
				@rdSCLAD	= max(SCLAD)
			from #receiptdetail where qtyreceived > 0 group by id order by id
	else
	    select @sku = null, @rdqtyreceived = 0, @rdSCLAD = ''
	
	-- ���� ���� ������ � �� ������� ��������� - �������� ������
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
	-- ���� ����� ������ ��� - �� ����� ��������� �������������� PO
	if @currPO is null 
		set @currPO = @lastPO
	
	print '���� ������ � ��������� ��������� �����������'
	--����� ������ ������ �� ������ � ��
	declare @POsku varchar(30)
	--select '#podetail',* from #podetail
	select @poid = ID, @poKey = pokey,@extpokey = externpokey, @poqtyordered = qty, @POsku = sku , @originalQty = qtyordered
	
	from #podetail where ID = @currPO -- sku = @sku and storerkey = @storerkey and qty != 0
--				print 'storerkey '+@storerkey+', sku '+@sku+', qtyordered '+cast(@poqtyordered as varchar(20))

	if @sku != @POsku
	begin
	   set @poqtyordered = 0
	end				
	print	'[	�������� '+@storerkey
				+ ', ' + char(13) + '	����� '+@sku
				+ ', ' + char(13) + '	�������� '+cast(@poqtyordered as varchar(20))
				+ ', ' + char(13) + '	������� '+cast(@rdqtyreceived as varchar(20))
				--+ ', ' + char(13) + '	qtyreceivedbrack ' + cast( @rdQR_BRAK as varchar(20)) 
				+ ', ' + char(13) + '	@rdSCLAD ' + cast( @rdSCLAD as varchar(20))
				+ char(13) 
				+ ']'
	-- ��������� ���� ���� �������� � ���������
	declare @raspred decimal(22,5)
	
	if (isnull(@rdqtyreceived,0) > 0 AND isnull(@poqtyordered,0) > 0)
	BEGIN
		-- 1. �������� <= ���������
		declare @susr2 varchar(10)
		
		if @rdqtyreceived <= @poqtyordered
		begin
		    print '1. �������� <= ���������'
			-- ������������ ��� �������� � ������� ������ ��
			set @raspred = @rdqtyreceived   -- ��������, ����� ��������� �� ������������� --������� 14.04.2017
			-- ��������� ��������� �� ��������������
			--set @poqtyordered = 0--@poqtyordered - @rdqtyreceived
			set @poqtyordered = @poqtyordered - @rdqtyreceived -- ��������, ����� ��������� �� ������������� --������� 14.04.2017
			-- �������� ��������
			set @rdqtyreceived = 0
			set @susr2 = '1'
		end
		else -- 2. �������� > ���������
		begin
		    print '2. �������� > ���������'
			-- ������������ �������� � ���-�� ����������
			set @raspred = @poqtyordered
			-- ��������� �������� �� ��������������
			set @rdqtyreceived = @rdqtyreceived - @poqtyordered
			-- �������� ���������
			set @poqtyordered = 0
			set @susr2 = '2'
		end
		-- ��������� ������ ����������
		insert into #podetailresult (
				sku, 	storerkey, 	 pokey, externpokey, qtyordered, QTYRECEIVED, lot, 	SCLAD,	susr2,	lot02,		lot04,			lot05)
		select rd.sku, rd.storerkey, @pokey, @extpokey, @raspred, 	@raspred, 	 rd.lot, rd.SCLAD, @susr2, la.LOTTABLE02, la.LOTTABLE04, la.LOTTABLE05
		from #receiptdetail rd, wh1.LOTATTRIBUTE la
		where rd.id = @rdid	and la.LOT=rd.lot			
		
		-- ������������ �������� � �������
		update #receiptdetail set	qtyreceived = @rdqtyreceived 	where id = @rdid
		-- ������������ ��������� � �������
		update #podetail set qty = @poqtyordered where id = @poid
		
		
		
	end			
	else 
	--3. ��������� �����������
	IF (isnull(@rdqtyreceived,0) > 0 AND isnull(@poqtyordered,0) <= 0)
	begin
	    print '3. ��������� �����������'
		set @raspred = @rdqtyreceived
		set @rdqtyreceived = 0
		set @poqtyordered = 0
		-- ��������� ������ ����������
		insert into #podetailresult (
				sku, 	storerkey, 	 pokey, externpokey, qtyordered, QTYRECEIVED, lot, 	SCLAD,	susr2,	lot02,		lot04,			lot05)
		select rd.sku, rd.storerkey, @pokey, @extpokey, @poqtyordered, 	@raspred, 	 rd.lot, rd.SCLAD, '3', la.LOTTABLE02, la.LOTTABLE04, la.LOTTABLE05
		from #receiptdetail rd, wh1.LOTATTRIBUTE la
		where rd.id = @rdid	and la.LOT=rd.lot			
		-- ������������ �������� � �������
		update #receiptdetail set	qtyreceived = @rdqtyreceived 	where id = @rdid
	end
	else
	--4. �������� �����������
	IF (isnull(@rdqtyreceived,0) = 0 AND isnull(@poqtyordered,0) > 0)	
	begin
	    print '4. �������� �����������'
		set @raspred = 0
		set @rdqtyreceived = 0
		-- ��������� ������ ����������
		
		--select @poqtyordered as '��������' , @originalQty as '����������'
		
		if (@poqtyordered = @originalQty)
			begin
				insert into #podetailresult (
						sku, 	storerkey, 	 pokey, externpokey, qtyordered, QTYRECEIVED, lot, 	SCLAD,		susr2,	lot02,				lot04,			lot05)
				select rd.sku, rd.storerkey, @pokey, @extpokey, @poqtyordered, 	@raspred, 	 '', 'LOSTPRIEM', '4', '', null, null
				from #podetail rd --, wh1.LOTATTRIBUTE la
				where rd.id = @poid--	and la.LOT=rd.lot
			end		
		else
			begin
				insert into #podetailresult (
						sku, 	storerkey, 	 pokey, externpokey, qtyordered, QTYRECEIVED, lot, 	SCLAD,		susr2,	lot02,				lot04,			lot05)
				select rd.sku, rd.storerkey, @pokey, @extpokey, @poqtyordered, 	@raspred, 	 '', 'LOSTPRIEM', '99', '', null, null--'����������������', '19000101 00:00', '19000101 00:00'
				from #podetail rd --, wh1.LOTATTRIBUTE la
				where rd.id = @poid--	and la.LOT=rd.lot
			end	
		-- ������������ ��������� � �������
		update #podetail set qty = 0 where id = @poid
	end
	else
		raiserror ('������ ��������� �������������',16,1)
	
	--set @lastPO = @currPO
	if exists(select top 1 1 from #podetail where qty > 0)
				or exists (select top 1 1 from #receiptdetail where qtyreceived > 0)
		set @notfinished = 1
	else
		set @notfinished = 0
end

--select * from #podetailresult

-- --������� ����������� � ��
declare @prevCount int
set @prevCount = 0
while (exists(select * from #podetailresult))
	begin
		select distinct top(1) @pokey = pokey from #podetailresult
		
		select @polinenumber = MAX(POLINENUMBER) from wh1.PODETAIL where POKEY = @pokey
		
		print 'po: '+@pokey + '  line: ' + @polinenumber
  
  
		insert into #OutPOData (WHSEID,pokey,EXTERNPOKEY,POLINENUMBER,EXTERNLINENO,
			QTYORDERED,-- ��������� �� ��	
			QTYRECEIVED, -- �������� �+�
			SKU,SKUDESCRIPTION,STORERKEY,SUSR4,SUSR2,
			PACKKEY,UOM,ALTSKU,Lottable02,LOTTABLE04,LOTTABLE05)
		
		select 
			--'D' S,
			'WH1' WHSEID,	@pokey pokey,	EXTERNPOKEY,
			right('0000'+cast((row_number()over (partition by pdr.pokey order by pdr.id) /*-@prevCount*/+@polinenumber) as varchar(20)),5) POLINENUMBER,
			'' EXTERNLINENO,
			qtyordered, --0, -- qtyordered, --������� 14.04.2017 - ������� ������� qtyOrdered � podetail
			pdr.QTYRECEIVED, --�������� ������� ����
			pdr.sku,
			left(s.DESCR,60) SKUDESCRIPTION, -- � wh1.PoDetail - skudescription 60 ��������, ���� ����� ������, ����� ������ � ���� � ������ �� �����.
			pdr.STORERKEY,pdr.SCLAD SUSR4,pdr.susr2,s.PACKKEY,s.RFDEFAULTUOM UOM,
			IsNull(r.ALTSKU,s.ALTSKU) as ALTSKU,
			--l.LOTTABLE01,
			pdr.lot02 Lottable02,pdr.LOt04 Lottable04,pdr.LOT05 Lottable05
			from #podetailresult pdr 
				join wh1.sku s on pdr.sku = s.SKU and pdr.storerkey = s.storerkey
				--left join #receiptdetail rd on rd.sku = pdr.sku and rd.storerkey = pdr.storerkey and pdr.lot =  rd.lot --pdr.LOTTABLE02 = rd.LOTTABLE02
				left join wh1.lotattribute l on pdr.lot = l.lot
				
				left join (
			    	    select sku,storerkey,max(ALTSKU) as ALTSKU
			    	    from wh1.RECEIPTDETAIL 
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
	join wh1.PO p on t1.pokey = p.pokey
	
	
select --'#OutPOData',
			IDENTITY(int,1,1) idpodet,
			WHSEID,pokey,EXTERNPOKEY,sellername,BUYERADDRESS4,--POLINENUMBER,EXTERNLINENO,
			sum(QTYORDERED)qtyordered,-- ��������� �� ��	
			sum(QTYRECEIVED)qtyreceived, -- �������� �+�
			SKU,SKUDESCRIPTION,STORERKEY,
			SUSR4,--SUSR2,	PACKKEY,UOM,
			ALTSKU,Lottable02,LOTTABLE04,LOTTABLE05
 into #result
 from #OutPOData
 where pokey=@pk
 group by  WHSEID,pokey,EXTERNPOKEY,sellername,BUYERADDRESS4,--POLINENUMBER,EXTERNLINENO,
			SKU,SKUDESCRIPTION,STORERKEY,SUSR4,--SUSR2,PACKKEY,UOM,
			ALTSKU,Lottable02,LOTTABLE04,LOTTABLE05

	select identity(int,1,1) idpo, pokey into #pokey from wh1.PO where OTHERREFERENCE = @receiptkey order by POKEY
	update #result set LOTTABLE02=null where LOTTABLE02='' --������� 24.03.2015
	
	
	--select '#result', * from #result-- where pokey=@ext2pokey


------------------------------------------------


--DECLARE @pk varchar(10)--='0000039958'

--set @pk=@ext2pokey

/*
	�����: �������� ���
	�����: ������� �.�.
	����: 25.02.2015
	�����������: 10.03.2015 -- ���������� �� ���� ����������
	�����������: 16.04.2015 -- ��������� ���=0, �� ���������.
*/
CREATE TABLE [#rt](
	[SKU] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[SKUGROUP] [nvarchar](20) COLLATE Cyrillic_General_CI_AS NULL,	
	[DESCR] [nvarchar](300) COLLATE Cyrillic_General_CI_AS NULL, --�������� ������
	[EXTN] [nvarchar](15) COLLATE Cyrillic_General_CI_AS NULL,
	[POKEY] [nvarchar](20) COLLATE Cyrillic_General_CI_AS NULL,		
	[CompanyName] [nvarchar](100) COLLATE Cyrillic_General_CI_AS NULL,	
	[LOTTABLE01] [nvarchar](40) COLLATE Cyrillic_General_CI_AS NULL,
	[LOTTABLE02] [nvarchar](40) COLLATE Cyrillic_General_CI_AS NULL,	
	[LOTTABLE04] date,
	[LOTTABLE05] date,
	[EFFECTIVEDATE] date,	
	[ud] [nvarchar](15) COLLATE Cyrillic_General_CI_AS NULL,		
	[FGr] [nvarchar](20) COLLATE Cyrillic_General_CI_AS NULL,		
	[nak] [nvarchar](150) COLLATE Cyrillic_General_CI_AS NULL,
	[dat] [nvarchar](15) COLLATE Cyrillic_General_CI_AS NULL,				
	[busr2] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[zak] int, --���������� ���-��
	[otgr]int, --�������� ���-��
	[brak] int, --����
	[lostpriem] int, --���������
	[overpriem] int, --�������
	[editdate] date) --�������������� ���������
	
	
CREATE TABLE [#ozhid] (
	[SKU] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[LOTTABLE02] [nvarchar](40) COLLATE Cyrillic_General_CI_AS NULL,	
	[LOTTABLE04] date,
	[LOTTABLE05] date,
	[zak] int --���������� ���-��
)

CREATE TABLE [#prin] (
	[SKU] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[LOTTABLE02] [nvarchar](40) COLLATE Cyrillic_General_CI_AS NULL,	
	[LOTTABLE04] date,
	[LOTTABLE05] date,
	[otgr] int, --�������� ���-��
	[zak] int -- ����������
)

CREATE TABLE [#prinBRLO] (
	[SKU] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[LOTTABLE02] [nvarchar](40) COLLATE Cyrillic_General_CI_AS NULL,	
	[LOTTABLE04] date,
	[LOTTABLE05] date,
	[otgr] int, --�������� ���-��
	[zak] int, -- ����������
	[st] int, -- ������ .
	[susr4] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL
)

declare @td varchar(1) -- ��� ��������� (0)-��� ���������, (1-5) � ����������.

select @td=potype from wh1.po where POKEY=@pk

--if @td>=0
--begin
--	/* ���������, �� ��� ���������, ��� ��������� */
--	insert into #ozhid (SKU, zak)
--	select pd.SKU, pd.QTYORDERED
--	from wh1.PODETAIL pd
--	where pd.POKEY=@pk  and QTYORDERED>0
--end

if @td>=0
	begin
		---������� ����
		insert into #prin (sku,LOTTABLE02,LOTTABLE04,LOTTABLE05,zak,otgr)
		select SKU, LOTTABLE02,LOTTABLE04, LOTTABLE05, qtyordered, qtyreceived--sum(QTYRECEIVED) qty
		from #result
		where SUSR4 in ('GENERAL','SD') and POKEY=@pk 
		group by SKU, LOTTABLE02,LOTTABLE04, LOTTABLE05,qtyordered, qtyreceived
		
		---������� ��������
		insert into #prinBRLO(sku,LOTTABLE02,LOTTABLE04,LOTTABLE05,zak,otgr,st,susr4)
		select SKU, LOTTABLE02,LOTTABLE04, LOTTABLE05,  qtyordered, qtyreceived, /*sum(QTYRECEIVED) qty, */'5',SUSR4
		from #result
		where SUSR4 in ('LOSTPRIEM','BRAKPRIEM','OVERPRIEM','PRETENZ') and POKEY=@pk 
		group by SKU, LOTTABLE02,LOTTABLE04, LOTTABLE05,  qtyordered, qtyreceived, SUSR4
	
	end
	
	--select '#prinBRLO',* from #prinBRLO

if @td>=0
	begin
		insert into #rt (sku, zak,otgr, LOTTABLE02, lottable04, lottable05)
		select SKU, zak,otgr, LOTTABLE02, LOTTABLE04, LOTTABLE05 from #prin
	end


--/* ����� �����-��������-�������� */
	update brlo
	set st=10
	from #prinBRLO brlo
	join #prin pr on pr.SKU=brlo.SKU and pr.LOTTABLE02=brlo.LOTTABLE02 and pr.LOTTABLE05=brlo.LOTTABLE05 and pr.LOTTABLE04=brlo.LOTTABLE04 
	
	--select '#prinBRLO',* from #prinBRLO
	
	if (select COUNT(*) from #prinBRLO where st=5) >0
		begin
	--	print 'add �������'
		 --------=========== ��������� ���� ============-------------
		insert into #rt (sku, zak,otgr, LOTTABLE02, lottable04, lottable05, brak)
		select SKU, zak,otgr, LOTTABLE02, LOTTABLE04, LOTTABLE05, otgr from #prinBRLO
		where st=5 and susr4='BRAKPRIEM'
		
	--	--------=========== ��������� LOST ============-------------
		insert into #rt (sku, zak,otgr, LOTTABLE02, lottable04, lottable05,  lostpriem)
		select SKU, zak,0, LOTTABLE02, LOTTABLE04, LOTTABLE05, zak from #prinBRLO
		where st=5 and susr4='LOSTPRIEM'
		
	--	--------=========== ��������� ������� ============-------------
		insert into #rt (sku,zak,otgr, LOTTABLE02, lottable04, lottable05,  overpriem)
		select SKU,0, otgr, LOTTABLE02, LOTTABLE04, LOTTABLE05,  otgr from #prinBRLO
		where st=5 and susr4='OVERPRIEM'
		
		--------=========== ��������� �������(��������) ============-------------
		insert into #rt (sku, zak,otgr, LOTTABLE02, lottable04, lottable05,  overpriem)
		select SKU, 0,otgr, LOTTABLE02, LOTTABLE04, LOTTABLE05,  otgr from #prinBRLO
		where st=5 and susr4='PRETENZ'
		
	end					
	

if (select COUNT(*) from #prinBRLO where st=10) >0
	begin
--		--print '����������� �������'
		update pr       --------=========== LostPriem ============-------------
		set pr.lostpriem = brlo.otgr, pr.zak=pr.zak+brlo.otgr
		from #rt pr
		join #prinBRLO brlo on pr.SKU=brlo.SKU and pr.LOTTABLE02=brlo.LOTTABLE02 and pr.LOTTABLE05=brlo.LOTTABLE05 and pr.LOTTABLE04=brlo.LOTTABLE04  
		where brlo.susr4='LOSTPRIEM' and brlo.st=10
	 
		update pr       --------=========== BrakPriem ============-------------
		set pr.brak = brlo.otgr, pr.zak=pr.zak+brlo.otgr, pr.otgr=pr.otgr+brlo.otgr
		from #rt pr
		join #prinBRLO brlo on pr.SKU=brlo.SKU and pr.LOTTABLE02=brlo.LOTTABLE02 and pr.LOTTABLE05=brlo.LOTTABLE05 and pr.LOTTABLE04=brlo.LOTTABLE04  
		where brlo.susr4='BRAKPRIEM' and brlo.st=10
 	
		update pr       --------=========== OVERPRIEM ============-------------
		set pr.overpriem  = brlo.otgr, pr.otgr=pr.otgr+brlo.otgr
		from #rt pr
		join #prinBRLO brlo on pr.SKU=brlo.SKU and pr.LOTTABLE02=brlo.LOTTABLE02 and pr.LOTTABLE05=brlo.LOTTABLE05 and pr.LOTTABLE04=brlo.LOTTABLE04 
		where brlo.susr4='OVERPRIEM' and brlo.st=10

	end		

		update r       --------=========== ������� ============-------------
		set overpriem = otgr-isnull(zak,0)
		from #rt r
		where otgr>isnull(zak,0)
				

update r       --------=========== ������������ �\� ��� ������������ ������ ============-------------
set LOTTABLE02 = '�\�'
from #rt r
where LOTTABLE02=''

/* ���������� �� �������� ������ */

update r
	set r.DESCR=case when s.NOTES1 is NULL then s.DESCR else s.NOTES1 end,
		r.busr2=s.BUSR2,
		r.ud=s.BUSR3,
		r.SKUGROUP=s.SKUGROUP,
		r.FGr= case when (s.SKUGROUP2 = '�����������������') or (s.FREIGHTCLASS = '6') 			then '�����������������'			else '1 �����'		end
	from #rt r
	join wh1.sku s on r.SKU=s.sku

--/* ���������� �� ����� PO */
update r
	set r.EXTN=po.EXTERNPOKEY, --������� �����
		r.POKEY=po.POKEY, --����� ��
		r.nak=isnull(nullif(left(po.BUYERADDRESS4, len(po.BUYERADDRESS4) - charindex(' ',reverse(po.BUYERADDRESS4))),''),
		substring(po.BUYERSREFERENCE, 0, charindex(' ', po.BUYERSREFERENCE))), --� ���������
		r.dat=isnull(nullif(ltrim(right(po.BUYERADDRESS4, charindex(' ',reverse(po.BUYERADDRESS4)))),''),
		substring(po.BUYERSREFERENCE,charindex(' ', po.BUYERSREFERENCE) + 1,len(po.BUYERSREFERENCE))), --���� ���������
		r.EFFECTIVEDATE=po.EFFECTIVEDATE,
		r.CompanyName=st.CompanyName,
		r.editdate=po.EDITDATE
	from #rt r
	join wh1.po po on po.POKEY=@pk
	left join wh1.storer st on po.SELLERNAME = st.storerkey	
	
	
	
select * from #rt order by sku
-------------------------------------------------
IF OBJECT_ID('tempdb..#ozhid') IS NOT NULL DROP TABLE #ozhid
IF OBJECT_ID('tempdb..#prin') IS NOT NULL DROP TABLE #prin
IF OBJECT_ID('tempdb..#rt') IS NOT NULL DROP TABLE #rt
IF OBJECT_ID('tempdb..#prinBRLO') IS NOT NULL DROP TABLE #prinBRLO

IF OBJECT_ID('tempdb..#receiptdetail') IS NOT NULL DROP TABLE #receiptdetail
IF OBJECT_ID('tempdb..#podetail') IS NOT NULL DROP TABLE #podetail
IF OBJECT_ID('tempdb..#podetailresult') IS NOT NULL DROP TABLE #podetailresult
IF OBJECT_ID('tempdb..#skuqty') IS NOT NULL DROP TABLE #skuqty
IF OBJECT_ID('tempdb..#pokey') IS NOT NULL DROP TABLE #pokey
IF OBJECT_ID('tempdb..#OutPOData') IS NOT NULL DROP TABLE #OutPOData
IF OBJECT_ID('tempdb..#result') IS NOT NULL DROP TABLE #result






