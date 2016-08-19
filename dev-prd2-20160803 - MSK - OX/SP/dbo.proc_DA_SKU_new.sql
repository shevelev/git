-- ���������� ������� --

ALTER PROCEDURE [dbo].[proc_DA_SKU_new]
	@source varchar(500) = null
as  

BEGIN TRY

declare @allowUpdate int
declare @id int
declare @storerkey varchar(15)
declare @sku varchar(10)
declare @skugroup varchar(10)
declare @skugroup2 varchar(30)

update DA_SKU set 
	descr   = isnull(descr,''),
	busr1   = substring(isnull(busr1,''),1,30),
	busr2   = substring(isnull(busr2,''),1,30),
	busr3   = substring(isnull(busr3,''),1,30),
	busr4   = substring(isnull(busr4,''),1,30),
	country = substring(isnull(country,''),1,30),
	sert    = substring(isnull(sert, ''),1,50)

update DA_SKU set busr_non_empty = 
		case 
			when isnull(busr4,'') != '' then busr4 
			when isnull(busr3,'') != '' then busr3 
			when isnull(busr2,'') != '' then busr2
			else busr1
		end

print '1. ���������� ����������� ���������� �������'	
	select @allowUpdate = allowUpdate from dbo.DA_MessageTypes where MessageKey = 'SkuCard'

print '2. �������� ������� ������'

print '2.1. �������� ����������� ����� storerkey � sku'
if 0<(select count(id) from DA_SKU where (storerkey is null or rtrim(storerkey) = '')) 
	raiserror ('�� ������ ��� ���������',16,1)

if 0<(select count(id) from DA_SKU where (sku is null or rtrim(sku) = '')) 
	raiserror ('�� ������ ��� ������',16,2)

print '2.2. �������� ������� ��������� � ����������� storer'
	select @storerkey=null, @sku=null
	select top 1 @storerkey = d.storerkey, @sku = d.sku from DA_SKU d
	where 0=(select count(*) from wh1.storer s where d.storerkey=s.storerkey)
	if @storerkey is not null
		raiserror ('�������� ������ ����������� � ����������� (STORERKEY=%s, SKU=%s)',16,3,@storerkey,@sku)

print '2.3. �������� ������� ���������� ��� allowUpdate=0'
if(@allowUpdate = 0)
begin
	select @id=null, @storerkey=null, @sku=null
	select top 1 @id = d.id, @storerkey = d.storerkey, @sku = d.sku from DA_SKU d
	where 0<(select count(*) from wh1.sku s where d.sku = s.sku and d.storerkey = s.storerkey)
	if(@id is not null)
		raiserror ('���������� ������� ��������� (STORERKEY=%s,SKU=%s)',16,4,@storerkey,@sku)
end

print '2.4. �������� ����� ��������'
-- 0- ���� ����� �������� �� �������(�� ���������)
-- 1- ���� ����� �������� �� ���� ������������
-- 2- ���� ����� �������� �� ���� ��������� ����� ��������
update DA_SKU set SHELFLIFECODETYPE=0 
where (SHELFLIFECODETYPE not in (0,1,2)) or (SHELFLIFECODETYPE is null)

print '2.5. �������� �������� �������� ���������'
-- 0- ������� �����(�� ���������)
-- 1- �������� ������ � ��������� ��������
update DA_SKU set CASEONLY=0 where (CASEONLY not in (0,1)) or (CASEONLY is null)

print '2.6. �������� ������ �������� stdgrosswgt'
	update DA_SKU set stdgrosswgt = 0 where stdgrosswgt is null or stdgrosswgt <= 0

print '2.7. �������� �������� casecnt'
	select @id=null, @storerkey=null, @sku=null
	select top 1 @id=id, @storerkey=storerkey, @sku=sku from DA_SKU where casecnt is null or casecnt <= 0
	if @id is not null 
		raiserror ('�� ��������� ���� casecnt (STORERKEY=%s, SKU=%s)',16,5,@storerkey,@sku)

print '2.8. �������� �� ������������ ���� skugroup � skugroup2'
	select @id=null, @storerkey=null, @sku=null, @skugroup=null, @skugroup2=null
	select top 1 @id=d.id, @storerkey=d.storerkey, @sku=d.sku, @skugroup=d.skugroup, @skugroup2=d.busr_non_empty 
    from DA_SKU d left join wh1.strategyxsku s on 
		--���� � strategyxsku ������� �� 6 �����
		(d.skugroup=s.skugroup and d.busr_non_empty= s.skugroup2 and s.packheightgroup=1 and s.layer=1 and s.abc='A' and s.volumegroup=1)
	where (s.skugroup is null) or (s.skugroup2 is null)

	if @id is not null 
		raiserror ('��������� ��������� ����������� � ����������� strategyxsku (STORERKEY=%s, SKU=%s, SKUGROUP=%s, SKUGROUP2=%s)',16,6,@storerkey,@sku,@skugroup,@skugroup2)

print '2.9. ������� ������������� ������ �������� � pack'

-- ������ ������� �������� 01/02/2011
--  >>�������������� ����������� ���������� �� 27 ������� ��� ��� �� ���������
/*
--���������� 16.11.2009 ������� �����\ ��� �������� ��������� ���������� �������� "�����" �� 27 �������
--��� ����� ��� �������������� ������� ������ ������ � ������� ������.	
--	insert wh1.pack (WHSEID,PACKKEY,  PACKDESCR,PACKUOM1,  CASECNT,REPLENISHUOM1,REPLENISHZONE1,CARTONIZEUOM1,REPLENISHUOM2,REPLENISHZONE2,CARTONIZEUOM2,PACKUOM3,QTY,REPLENISHUOM3,REPLENISHZONE3,CARTONIZEUOM3)
--	select distinct   'WH1',t.casecnt,t.casecnt,    'CS',t.casecnt,          'N',        'CASE',   s.packtype,          'N',        'PICK',          'N',    'EA',  1,          'Y',        'PICK',          'Y'

--	insert wh1.pack (WHSEID,PACKKEY,  PACKDESCR,PACKUOM1,  CASECNT,REPLENISHUOM1,REPLENISHZONE1,CARTONIZEUOM1,REPLENISHUOM2,REPLENISHZONE2,CARTONIZEUOM2,PACKUOM3,QTY,REPLENISHUOM3,REPLENISHZONE3,CARTONIZEUOM3, packuom2,			   innerpack,cartonizespecialip)
--	select distinct   'WH1',t.casecnt,t.casecnt,    'CS',t.casecnt,          'N',        'CASE',   s.packtype,          'N',        'PICK',          'N',    'EA',  1,          'Y',        'PICK',          'Y',     'PC',round(t.casecnt*27,0),			    '2'
--	from DA_SKU t						--���� � strategyxsku ������� �� 6 �����	
--		inner join wh1.strategyxsku s on (t.skugroup=s.skugroup and t.busr_non_empty = s.skugroup2 and 
--								s.packheightgroup=1 and s.layer=1 and s.abc='A' and s.volumegroup=1)
--		left join wh1.pack p on p.packkey=cast (t.casecnt as varchar(50))
--	where p.packkey is null
*/
-- VC 31/01/2011 �������� ���������� �������� � ������
	-- ������� ������� � ������������ ����������
	select cast(round(isnull(casecnt,1),0) as int)casecnt,
			cast(round(isnull(innercnt,1),0) as int)innercnt,
			cast(round(isnull(palletcnt,1),0) as int)palletcnt,
			convert(varchar(50),'') packkey,
			sku,
			storerkey
	into #newPacks
	from DA_SKU t	
	
	-- ��������� ���� � ���� innerpack x casecnt x palletcnt (��� ��������)
	update #newPacks set packkey = convert(varchar, innerpack)+'x'+convert(varchar, casecnt)+'x'+convert(varchar, palletcnt)

	-- ��������� ���� � �������� �������
	update t set t.packkey = np.packkey
		from DA_SKU t 
			join #newpacks np on np.sku=t.sku and np.storerkey=t.storerkey

	-- ������� �� ������ ����� ������ ��, ������� ��� ���� � ����
	delete from #newPacks where packkey in (select packkey from WH1.PACK)

	-- ������� ������������� � ����
	insert wh1.pack (WHSEID,	PACKKEY,	PACKDESCR,	cartonizespecialip,
		QTY,		PACKUOM3,	REPLENISHUOM3,	CARTONIZEUOM3,	REPLENISHZONE3, -- �����
		innerpack,	PACKUOM2,	REPLENISHUOM2,	CARTONIZEUOM2,	REPLENISHZONE2, -- �����. ��������
		CASECNT,	PACKUOM1,	REPLENISHUOM1,	CARTONIZEUOM1,	REPLENISHZONE1, -- �����
		PALLET,		PACKUOM4,	REPLENISHUOM4,	CARTONIZEUOM4,	REPLENISHZONE4 -- �������
		)
	select distinct   'WH1',	packkey,	packkey,    '2',
	/*	���-��	     ��	         ���������	    ���������������	    ����     */
       ---------------------------------------------------------------------
			1,      'EA',			'Y',			'Y',			'PICK', 
        innercnt,	'IP',			'N',			'N',			'PICK',
		casecnt,	'CS',			'N',			'Y',			'CASE',
		palletcnt,	'PL',			'N',			'N',			'OTHER'
	from #newPacks 
/* end changes of 01/02/2011 */

while 1 = 1
begin
	--������� �������� ������ ������ (����������� id)
	set @id=null

	select top 1 @id = id, @storerkey = storerkey, @sku = sku--, 
		 from DA_SKU order by id asc
	if @id is null break

	if exists (select * from wh1.sku where storerkey = @storerkey and sku = @sku)
	begin
		print '3. ��������� ������������ �����'
		--�� ��������� stdcube, packkey, stdgrosswgt, stdnetwgt
		update s set 
		s.descr=substring(t.descr,1,60),
		s.notes1=t.descr,
		s.manufacturersku=t.sert,
		s.busr9 = t.sertdate,
		s.skugroup=t.skugroup,
		s.skugroup2=t.busr_non_empty,
		s.busr1=t.busr1, s.busr2=t.busr2, s.busr3=t.busr3, s.busr4=t.busr4,
		s.busr10 = t.country,
		s.susr4=t.susr4,
		s.shelflife=t.shelflife,
		s.shelflifeindicator=case when t.shelflifecodetype='0' then 'N' else 'Y' end,
		s.shelflifecodetype=case when t.shelflifecodetype='1' then 'M' else 'E' end,
		s.putawayzone = x.putawayzone,
		s.lottablevalidationkey = case when t.shelflifecodetype='1' then 'MANUFAC' when t.shelflifecodetype='2' then 'EXPIRED' else 'STD' end,
		s.strategykey = x.strategykey,
		s.putawaystrategykey = x.putawaystrategykey,
		s.datecodedays = x.datecodedays,
		s.cartongroup = x.cartongroup,
		s.rotateby = case when t.shelflifecodetype='1' then 'Lottable04' else 'Lottable05' end,
		/* VC 01/02/2011 */
		s.packkey = t.packkey,
		s.RFdefaultpack = t.packkey
		/*****************/
		from wh1.sku s 
			inner join DA_SKU t on (t.id = @id and s.storerkey = t.storerkey and s.sku = t.sku)
			inner join wh1.strategyxsku x on (t.skugroup=x.skugroup and t.busr_non_empty=x.skugroup2 and 
						x.packheightgroup=1 and x.layer=1 and x.abc='A' and x.volumegroup=1)

	end	
	else
	begin
		print '3. ��������� ����� �����'
		insert into wh1.sku
			(storerkey, sku, descr, notes1, manufacturersku, busr9, skugroup, skugroup2, 
			 stdcube, busr1, busr2, busr3, busr4, busr10, susr4, stdgrosswgt, stdnetwgt, 
			 shelflife, shelflifeindicator, shelflifecodetype, packkey, rfdefaultpack,			 
			 lottablevalidationkey, 
			 putawayzone, strategykey, putawaystrategykey, datecodedays, cartongroup,
			 returnsloc, putawayloc, onreceiptcopypackkey, abc,
			 rotateby,
			 lottable01label,lottable02label,lottable03label,lottable04label,lottable05label,lottable06label,lottable07label,lottable08label,lottable09label,lottable10label)
			select d.storerkey, d.sku, substring(d.descr,1,60), d.descr, d.sert, d.sertdate, d.skugroup, d.busr_non_empty,
					d.stdcube, d.busr1, d.busr2, d.busr3, d.busr4, d.country, d.susr4, d.stdgrosswgt, d.stdgrosswgt,
					d.shelflife,
					case when d.shelflifecodetype='0' then 'N' else 'Y' end,
					case when d.shelflifecodetype='1' then 'M' else 'E' end,
					/* VC 01/02/2011 */
					--d.casecnt, d.casecnt,
					d.packkey, d.packkey,
					/*********/
					case when d.shelflifecodetype='1' then 'MANUFAC' when d.shelflifecodetype='2' then 'EXPIRED' else 'STD' end,
					x.putawayzone, x.strategykey, x.putawaystrategykey, x.datecodedays, x.cartongroup,
					'VOROTA16','NEW', '1', 'C',
					case when d.shelflifecodetype='1' then 'Lottable04' else 'Lottable05' end,
					'��������','','','���� ������������','����� ��','','','','',''
			from DA_SKU d, wh1.strategyxsku x where d.id = @id and
				(d.skugroup=x.skugroup and d.busr_non_empty=x.skugroup2 and x.packheightgroup=1 and x.layer=1 and x.abc='A' and x.volumegroup=1)
	end
    
	delete DA_SKU where id = @id
end

END TRY
BEGIN CATCH
	declare @error_message nvarchar(4000)
	declare @error_severity int
	declare @error_state int
	
	set @error_message  = ERROR_MESSAGE()
	set @error_severity = ERROR_SEVERITY()
	set @error_state    = ERROR_STATE()

	raiserror (@error_message, @error_severity, @error_state)
END CATCH

