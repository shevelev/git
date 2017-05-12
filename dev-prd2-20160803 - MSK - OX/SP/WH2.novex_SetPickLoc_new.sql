-- =============================================
-- �����:		������� �����
-- ������:		������, �.�������
-- ���� ��������: 19.08.2009 (������)
-- ��������: ���������� ����� ������
--	������ ��������� ������������ ���������� ����� �������� ������ ���
--	���������� ������.
--	...
-- =============================================
ALTER PROCEDURE [WH2].[novex_SetPickLoc_new] 
	@Storer as varchar(15),
	@SkuName as varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--##############################################################################

declare	@zone		varchar(10),
		@SkuPrefix	varchar(50),
		@needLoc	int,
		@abc		varchar(5),
		@newLot		varchar(10),
		@pLOC		varchar(10)

--declare @Storer varchar(15), @SkuName varchar(60)
--select @Storer='219',@SkuName='10223'

print '>>>novex_SetPickLoc  ��������� ������ ���������� ��� ������ Storer='+isnull(@Storer,'<NULL>')+' Sku='+isnull(@SkuName,'<NULL>')

print '������� ������ ������� ������������ ����� ������'
	select 			l.LOC,
					l.LOGICALLOCATION,
					l.CUBICCAPACITY,
					cast(0 as float)		SKUCOUNT,
					cast('C' as varchar(5)) ABC,
					l.loclevel,
					cast(0 as int)		SKUSTDCOUNT,
					cast('' as varchar(10)) LOCindex
	into #processingLocs
	from WH2.loc l
	where 1=0

	select * into #selectedLocs from #processingLocs where 1=0
	select * into #PREselectedLocs from #processingLocs where 1=0


print '1.0 ��������� ����� �� ��������� ������ ����������'
select @needLoc=WH2.novex_checkNeedSetPickLoc(@Storer,@SkuName)

if (@needLoc>0)
begin 
	print '...��� ������ ��������� ��������� '+cast(@needLoc as varchar)+' ������ ������'
	print '...���������� ��������� ������'	
	select	@zone=left(s.putawayzone,len(s.putawayzone)-2)+'EA',
			@abc=isnull(s.abc,'C'),
--����� ��������������� ����� ����������� "�������" �������. ���������� 1/3 �� �������� ������.
--� ����������, ������ � �������� ������� � �������� �� ����������� � ���� ������.
			@SkuPrefix=left(s.descr,round(len(s.descr)/3,0))
	from WH2.sku s 
	where (s.storerkey=@Storer and s.sku=@SkuName)

	-------------------------------------------------------------------------------
	print '2.0 ����� �������� ��������� ����� � ��������� ���� �� ������� ��������'
	print '...�������� ������ ����� ��������������� ����'
	print '...������ � ������� ����� ����� ������ X ����������� �� ������������'
	insert into #processingLocs
	select 			l.LOC,
					l.LOGICALLOCATION,
					l.CUBICCAPACITY,
					cast(0 as float)		SKUCOUNT,
					cast('C' as varchar(5)) ABC,
					case 
					 when isnull(l.loclevel,0)>0 then l.loclevel
												 else 1
					end	loclevel,
					isnull(Z.PZLEVEL,0)	SKUSTDCOUNT,
					''					LOCindex
	from WH2.loc l
		join WH2.PUTAWAYZONE Z on (l.PUTAWAYZONE=Z.PUTAWAYZONE)
		left join WH2.SKUXLOC sxl on (l.loc=sxl.loc)
		left join WH2.SKU s on (sxl.storerkey=s.storerkey and sxl.sku=s.sku)
	where 
	l.putawayzone = @zone						-- ����� � ��������� ����
	and
	(l.locationtype='PICK')						-- ������ ������ �������� ������
	and
	(l.locationflag='NONE' and l.status='OK')	-- ������ ������ � �������� ���������
	and
	(l.loc like '[1-9]___.[1-9].[1-9]')			-- ������ ���������� ������
	group by		l.LOC,
					l.LOGICALLOCATION,
					l.CUBICCAPACITY,
					case 
					 when isnull(l.loclevel,0)>0 then l.loclevel
												 else 1
					end,
					isnull(Z.PZLEVEL,0)
	having max(isnull(s.abc,'C'))<>'X'			-- ��������� ������ � ������� ������ X

	print '...������������ � ���������� ���������� �������, ������� ������ ������ ��������� ������� ������'
	print '...��� ������ � ������ ������� ������� ��� 2, ��� ������ B � C ��� 1, ��� ������ D - 1'
	update #processingLocs
	set	SKUCOUNT=isnull((select sum(case when s.abc='A' then 2 when s.abc='D' then 1 else 1 end) 
					from WH2.skuxloc sxl join WH2.sku s on (sxl.storerkey=s.storerkey and sxl.sku=s.sku)
					where  sxl.loc=#processingLocs.loc and
					((sxl.allowreplenishfromcasepick=1 or sxl.allowreplenishfrombulk=1))
				  ),0)
	print '...����������, ����� ������� ������ ��������������� ����� ������� ������ ������'
	update #processingLocs
	set	ABC=isnull((select min(isnull(s.abc,'C')) from WH2.skuxloc sxl 
											join WH2.sku s on (sxl.storerkey=s.storerkey and sxl.sku=s.sku)
					where  sxl.loc=#processingLocs.loc and
					(sxl.allowreplenishfromcasepick=1 or sxl.allowreplenishfrombulk=1)
			),@abc)
--select * from #processingLocs

	print '...��������� ������ ��� ���������� ����� ������'
	insert into #PREselectedLocs
		select pl.LOC,pl.LOGICALLOCATION,pl.CUBICCAPACITY,pl.SKUCOUNT,pl.ABC,pl.loclevel,pl.SKUSTDCOUNT,
			--������ ������� ��� ���������� �����
			case pl.SKUSTDCOUNT
			-----------------------------------------------------------------------------------------
			--���������� ���������� ������� � ������ ����� 1 �����=1 �����
			when 1 then
				case	
						--������ ������ D (���������� � ����� ������ 2 ������, �������� 2)
						--����������:  ���������� ���� 3 [1-D/C/B/A, 0]
						--����������:  ���� 1-2 [1-D/C/B/A, 0]
						when isnull(@abc,'C')='D' then 
								case 
									when pl.loclevel>=3 and pl.skucount=1 then '000'
									when pl.loclevel>=3 and pl.skucount=0 then '010'
									when pl.loclevel<=2 and pl.skucount=1 then '020'
									when pl.loclevel<=2 and pl.skucount=0 then '030'
									else 'ZZZ' --������ �� �����������
									--else replicate('0',3-len(cast((pl.skucount+2)*10 as varchar(3)))) + cast((pl.skucount+2)*10 as varchar(3))
								end	
								+ (char(ascii('Z')-ascii(left(pl.abc,1))+ascii('A')))
						--������ ������ A (����������: 1 �����=1 �����, �������� 1)
						--����������:  [0-D/C/B/A]
						when isnull(@abc,'C')='A' then 
								--replicate('0',3-len(cast(pl.skucount*10 as varchar(3)))) + cast(pl.skucount*10 as varchar(3))
								case 
									when pl.loclevel<=2 and pl.skucount=0 then '000'
									else 'ZZZ' --������ �� �����������
								end	
								+ (char(ascii('Z')-ascii(left(pl.abc,1))+ascii('A')))
						--�������� ����� ������, ������ B � � (����������: 1 �����=1 �����, �������� 2)
						--����������:  [0-D/C/B/A, 1-D/C/B/A]
						else
								case 
									when pl.loclevel<=2 and pl.skucount=0 then '000'
									when pl.loclevel<=2 and pl.skucount=1 then '010'
									when pl.loclevel>=3 and pl.skucount=0 then '020'
									when pl.loclevel>=3 and pl.skucount=1 then '030'
									else 'ZZZ' --������ �� �����������
									--else replicate('0',3-len(cast((pl.skucount+2)*10 as varchar(3)))) + cast((pl.skucount+2)*10 as varchar(3))
								end	
								+ (char(ascii('Z')-ascii(left(pl.abc,1))+ascii('A')))
				end			
			-----------------------------------------------------------------------------------------
			--���������� ���������� ������� � ������ ����� 1 �����=2 ������
			when 2 then  
				case	
						--������ ������ A ��� B (����������: 1 �����=1 �����, �������� 1 �����)
						--����������:  ���� 1-2 [0-D/C/B/A]
						--����������:  ���� 3 � ���� ������ ����������
						when isnull(@abc,'C')='A' or isnull(@abc,'C')='B' then 
							case 
							 when pl.loclevel<=2 and pl.skucount=0 then '000'
							 else 'ZZZ' --������ �� �����������
							end
							+ 
							(char(ascii('Z')-ascii(left(pl.abc,1))+ascii('A')))
						--������ ������ D (����������: 1 ������ 2 ������, �������� 3 ������)
						--����������:  ���������� ���� 3 [1-D/C/B/A, 0, 2-D/C/B/A]
						--����������:  ���� 1-2 [1-D/C/B/A, 0, 2-D/C/B/A]
						when isnull(@abc,'C')='D' then 
								case 
									when pl.loclevel>=3 and pl.skucount=1 then '000'
									when pl.loclevel>=3 and pl.skucount=0 then '010'
									when pl.loclevel>=3 and pl.skucount=2 then '020'
									when pl.loclevel<=2 and pl.skucount=1 then '030'
									when pl.loclevel<=2 and pl.skucount=0 then '040'
									when pl.loclevel<=2 and pl.skucount=2 then '050'
									else 'ZZZ' --������ �� �����������
								end	
								+ (char(ascii('Z')-ascii(left(pl.abc,1))+ascii('A')))
						--�������� ����� ������, ������ � (����������: 1 �����=2 ������, �������� 3)
						--����������:  ���� 1-2 [1-C/D/B/A, 0, 2-C/D/B/A]
						--����������:  ���� 3	[0, 1-C/D/B/A]
						else
								case 
									when pl.loclevel<=2 and pl.skucount=1 then '000'
									when pl.loclevel<=2 and pl.skucount=0 then '010'
									when pl.loclevel<=2 and pl.skucount=2 then '020'
									when pl.loclevel>=3 and pl.skucount=0 then '030'
									when pl.loclevel>=3 and pl.skucount=1 then '040'
									else 'ZZZ' --������ �� �����������
								end	
								+
								case pl.abc
									when 'B' then 'Y'
									when 'A' then 'Z'
									else pl.abc
								end	
				end			
			-----------------------------------------------------------------------------------------
			--���������� ���������� ������� � ������ ������� ������ 1 �����=3 ������
			else --
				case isnull(@abc,'C')
						when 'A' then --������ ������ A (����������: 1 �����=1 �����, �������� 2)
								--����������:  ���� 1-2 [0-D/C/B/A, 1-D/C/B/A, 2-D/C/B/A]
								--����������:  ���� 3 � ���� ������ ����������
								case 
									when pl.loclevel<=2 and pl.skucount=0 then '000'
									when pl.loclevel<=2 and pl.skucount=1 then '010'
									when pl.loclevel<=2 and pl.skucount=2 then '020'
									else 'ZZZ' --������ �� �����������
								end	
								+ 
								(char(ascii('Z')-ascii(left(pl.abc,1))+ascii('A')))

						when 'B' then --������ ������ B (����������: 1 �����=2 ������, �������� 3)
								--����������:  ���� 1-2 [1-B/C/D/A, 0, 2]
								--����������:  ���� 3   [1-B/C/D/A, 0]
								case 
									when pl.loclevel<=2 and pl.skucount=1 then '000'
									when pl.loclevel<=2 and pl.skucount=0 then '010'
									when pl.loclevel<=2 and pl.skucount=2 then '020'
									when pl.loclevel>=3 and pl.skucount=1 then '030'
									when pl.loclevel>=3 and pl.skucount=0 then '040'
									else 'ZZZ' --������ �� �����������
								end	
								+
								case pl.abc
									when 'A' then 'Z'
									else pl.abc
								end

						when 'D' then --������ ������ D (����������: 1 ������ 4 ������, �������� 4)
								--����������:  ���������� ���� 3 [1-D/C/B/A, 2, 0]
								--����������:  ���� 1-2 [2-D/C/B/A, 1, 3, 0]
								case 
									when pl.loclevel>=3 and pl.skucount=1 then '000'
									when pl.loclevel>=3 and pl.skucount=2 then '010'
									when pl.loclevel>=3 and pl.skucount=0 then '020'
									when pl.loclevel<=2 and pl.skucount=2 then '030'
									when pl.loclevel<=2 and pl.skucount=1 then '040'
									when pl.loclevel<=2 and pl.skucount=3 then '050'
									when pl.loclevel<=2 and pl.skucount=0 then '060'
									else 'ZZZ' --������ �� �����������
								end	
								+ (char(ascii('Z')-ascii(left(pl.abc,1))+ascii('A')))

						else	
								--����������:  ���������� ���� 1-2 [2-C/D/B/A, 1, 0]
								--����������:  ���� 3 [1-D/C/B/A, 0]
								case 
									when pl.loclevel<=2 and pl.skucount=2 then '000'
									when pl.loclevel<=2 and pl.skucount=1 then '010'
									when pl.loclevel<=2 and pl.skucount=0 then '020'
									when pl.loclevel>=3 and pl.skucount=1 then '030'
									when pl.loclevel>=3 and pl.skucount=0 then '040'
									else 'ZZZ' --������ �� �����������
								end	
								+
								case pl.abc
									when 'B' then 'Y'
									when 'A' then 'Z'
									else pl.abc
								end	
				end
			end	LOCindex
		from #processingLocs pl
		where pl.loc not in	(
					select pl2.loc
					from #processingLocs pl2
						join WH2.skuxloc sxl on (pl2.loc=sxl.loc)
						join WH2.sku s on (sxl.storerkey=s.storerkey and sxl.sku=s.sku)
					where
						s.descr like @SkuPrefix+'%'
						and ((sxl.allowreplenishfromcasepick=1 or sxl.allowreplenishfrombulk=1) 
								and (sxl.qtylocationminimum>0 and sxl.qtylocationlimit>0))
					group by pl2.loc
					)

--	select * from #PREselectedLocs
--	order by LOCindex, pl.logicallocation

	delete from #PREselectedLocs where LOCindex like 'ZZZ%'

	if (@needLoc=1)
	begin
		print '...�������� ���� �������� ���������� ������'
		if isnull(@abc,'C')='D'
		begin
			insert into #selectedLocs
			select top 1 *
			from #PREselectedLocs
			order by LOCindex, CUBICCAPACITY, LOGICALLOCATION desc
		end
		else begin
			insert into #selectedLocs
			select top 1 *
			from #PREselectedLocs
			order by LOCindex, CUBICCAPACITY desc, LOGICALLOCATION
		end
	end
	else
	begin
		print '...�������� ��� �������� ���������� ������'
		if isnull(@abc,'C')='D'
		begin
			insert into #selectedLocs
			select top 2 *
			from #PREselectedLocs
			order by LOCindex, CUBICCAPACITY, LOGICALLOCATION desc
		end
		else begin
			insert into #selectedLocs
			select top 2 *
			from #PREselectedLocs
			order by LOCindex, CUBICCAPACITY desc, LOGICALLOCATION
		end
	end

--	select * from #processingLocs
--	select * from #selectedLocs 
--	truncate table #selectedLocs

	print '...���������, ���� ����������, ������ �������� ������ ������ � skuxloc (��� ��������� ���������� ����������)'
	insert into WH2.skuxloc
		 (WHSEID,STORERKEY,		SKU,   LOC,LOCATIONTYPE,qtylocationminimum,qtylocationlimit,replenishmentuom,allowreplenishfromcasepick,allowreplenishfrombulk,REPLENISHMENTPRIORITY, ADDWHO)
	select 'WH2',  @Storer,@SkuName,sl.LOC,		 'PICK',				 0,				  0,			 '2',						  1,				     1,					 '4','novex_SetPickLoc'
	from #selectedLocs sl
		left join WH2.skuxloc sxl on (sl.loc=sxl.loc and sxl.storerkey=@Storer and sxl.sku=@SkuName)
	where sxl.loc is null
	print '...���� ������ � SKUXLOC �� ������ ��� ����, �� �� ���� ���������� ����������, �� ����������� ������ ���������� �� ����������� � ���������� ��������'
	update sxl
	set	replenishmentuom='2',
		allowreplenishfromcasepick=1,
		allowreplenishfrombulk=1
	from WH2.skuxloc sxl join #selectedLocs sl   on (sl.loc=sxl.loc)
	where (sxl.storerkey=@Storer and sxl.sku=@SkuName)

	print '...������������ � ��������� ������ ���������� ��� ���� ��������� �����'
	----- ��� ������� ��������� ��������� ��������� ����� ������ �� 10% ��� ������ �������������� �������
	----- �.�. � ������ � ����� ������� ��������� ����� - 90%, � ����� - 80%, � ����� 70% � �.�. //��. (1-(sc.skucount+...)/10)
	DECLARE LOCATIONSLIST CURSOR STATIC FOR 
	SELECT LOC FROM #selectedLocs

	OPEN LOCATIONSLIST
	FETCH NEXT FROM LOCATIONSLIST INTO @pLOC

	WHILE @@FETCH_STATUS = 0
	BEGIN
		exec WH2.novex_RecalcLoc @pLOC
		FETCH NEXT FROM LOCATIONSLIST INTO @pLOC
	END

	CLOSE LOCATIONSLIST
	DEALLOCATE LOCATIONSLIST


	print '...���� ���������� ��������� � LOTxLOCxID ������ ��������������� ����������� �������'
	--�������� ������, ������� �������� � LOTxLOCxID
	select storerkey, sku, min(lot) lot
	into #LLD2
	from WH2.lot lot
	where
	(lot.storerkey=@Storer and lot.sku=@SkuName)
	group by storerkey, sku 

	--���� ����� �����, �� ������� ������ ������
	if (select count(*) from #LLD2)=0
	begin
	print '......����� �����, ������� ������ ������'
		exec dbo.DA_GetNewKey 'WH2', 'LOT', @newLot OUTPUT --�������� ����� ����� ������
		insert into WH2.lotattribute
			(	whseid,	lot,	storerkey,	sku,		addwho,				editwho)
		select	'WH2',	@newLot,@Storer,	@SkuName,	'novex_SetPickLoc',	'novex_SetPickLoc'
		insert into WH2.lot
			(	whseid,	lot,	storerkey,	sku,		addwho,				editwho)
		select	'WH2',	@newLot,@Storer,	@SkuName,	'novex_SetPickLoc',	'novex_SetPickLoc'

		insert into #LLD2
			(	storerkey,	sku,		lot)
		select @Storer,		@SkuName,	@newLot
	end

	print '...������� ������ ��� ���������� � LOTxLOCxID'
	--select * from #selectedLocs
	select 'WH2' whseid, lld2.lot, sxl.loc, @Storer storerkey, @SkuName sku
	into #newLLD
	from #selectedLocs sxl
		left join WH2.lotxlocxid lld on (sxl.loc=lld.loc and lld.storerkey=@Storer and lld.sku=@SkuName)
		join #LLD2 lld2 on (lld2.storerkey=@Storer and lld2.sku=@SkuName)
	where
		(lld.loc is null)	--������ ���������� ������ ������ � ��� �������, ����� � LOTxLOCxID ��� ��������������� ������� 

	--��������� ������ � LOTxLOCxID
	insert into WH2.lotxlocxid
		(whseid,lot,loc,storerkey,sku)
	select whseid,lot,loc,storerkey ,sku
	from #newLLD

--drop table #processingLocs
--drop table #selectedLocs
end
else
begin
	if @needLoc=0	print '��� ������� ������ ��� ������� ����������� ������ ������'
			else	print '����� �������� � ���� ��������, �� ��������� ���������� ����� ������'
end

select * from #selectedLocs


END

