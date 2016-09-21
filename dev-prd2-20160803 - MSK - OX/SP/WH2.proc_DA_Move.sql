
/***************************************************************************************************/

ALTER PROCEDURE [WH2].[proc_DA_Move](
	@wh varchar(10),
	@transmitlogkey varchar (10)
)AS

--SET NOCOUNT ON

--declare @osn varchar(50) set @osn = '1'
--declare @lost varchar(50) set @lost = '35'
--declare @tamg varchar(50) set @tamg = '4'

--declare @bs varchar(3) select @bs = short from WH2.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'
--declare @bsanalit varchar(3) select @bsanalit = short from WH2.CODELKUP where LISTNAME='sysvar' and CODE = 'bsanalit'

--3    __Сильнодействующие
--1    1 Склад
--22    Забраковка
--30    Некондиция
--35    Потери
--4    Сертификация


declare @mess01 varchar(max),
	@mess02 varchar(max),
--	@mastersystem varchar(10) = null
	@mastersystem int -- 0 
	
create table #resulthead (
	--serkey int IDENTITY(1,1),
	dataareaid VARCHAR(5),
	inventjournalnameid varchar(20),
	transdate datetime,
	inventjournalid varchar(30),
	inventjournaltype varchar(3),
--	mastersystem varchar(10) -- поправил с 5 до 10
	mastersystem int -- поправил с 5 до 10
	)	

CREATE TABLE #resultdetail(
	dataareaid VARCHAR(5),
	inventjournalid varchar(30),
	transdate datetime,
	[sku] varchar(50) NULL,
	manufacturedatafrom datetime,
	manufacturedatato datetime,
	inventexpiredate datetime,
	corrinventexpiredate datetime,
	[orderedqty] numeric(22,5),		
	inventlocationid varchar(20),
	corrinventlocationid varchar(20),
	inventbatchid varchar(40),
	corrinventbatchid varchar(40),
	inventserialid varchar(40),
	corrinventserialid varchar(40),
--	mastersystem varchar(10) -- поправил с 5 до 10
	mastersystem int -- поправил с 5 до 10
)

create table #resultall (
	dataareaid VARCHAR(5),
	inventjournalnameid varchar(20),
	transdate datetime,
	inventjournalid varchar(30),
	inventjournaltype varchar(3),
--	mastersystem varchar(10), -- поправил с 5 до 10
	mastersystem int, -- поправил с 5 до 10
	[sku] varchar(50) NULL,
	manufacturedatafrom datetime,
	manufacturedatato datetime,
	inventexpiredate datetime,
	corrinventexpiredate datetime,
	[orderedqty] numeric(22,5),		
	inventlocationid varchar(20),
	corrinventlocationid varchar(20),
	inventbatchid varchar(40),
	corrinventbatchid varchar(40),
	inventserialid varchar(40),
	corrinventserialid varchar(40)
	
	)

select	loc,l.PUTAWAYZONE
into	#lo
from	WH2.LOC l


--select *
--into	#task
--from	WH2.TASKDETAIL t
--where	t.TASKTYPE = 'MV'


select	'SZ' as dataareaid,
	'1' as inventjournalnameid,
	getdate() as transdate,
	--'' as inventjournalid,
	2 as inventjournaltype,
	--'' as journalposted,
--	'Infor' as mastersystem,
	1 as mastersystem,
	--'' as processingstatus,
	'5' as status,
	i.SKU,
	--'' as linenum,
	--'' as barcodestring,
	--'' as blockingreason,
	IsNull(i.LOTTABLE04,cast('19000101' as DATETIME)) as manufacturedatafrom,
	IsNull(i.LOTTABLE04,cast('19000101' as DATETIME)) as manufacturedatato,
	IsNull(i.LOTTABLE05,cast('19000101' as DATETIME)) as inventexpiredate,
	IsNull(i.LOTTABLE05,cast('19000101' as DATETIME)) as corrinventexpiredate,  
	i.QTY as orderedqty,
	w2.sklad as inventlocationid,
	w.sklad as corrinventlocationid,
	la.LOTTABLE06 as inventbatchid,
	la.LOTTABLE06 as corrinventbatchid,
	i.FROMID,
	i.TOID,
	i.TOLOC,
	i.ITRNKEY,
	i.LOTTABLE02 as inventserialid,
	i.LOTTABLE02 as corrinventserialid
into	#q	
from	WH2.TRANSMITLOG t
	join WH2.itrn i 
	    on t.key1 = i.itrnkey
	join WH2.LOTATTRIBUTE la
	    on la.LOT = i.LOT
	join #lo l 
	    on l.loc = i.toloc 
	join #lo l2 
	    on l2.loc = i.fromloc 
	left join wh2.WHTOZONE w 
	    on w.zone = l.putawayzone 
	left join wh2.WHTOZONE w2 
	    on w2.zone = l2.putawayzone
	--join WH2.LOT l3
	--    on l3.LOT = i.LOT
where	t.TRANSMITLOGKEY = @transmitlogkey
	--and w.sklad <> w2.sklad
	
	update r       --------=========== Обновление СД, при перемещение из ячеек приемки(Склад продаж) в зону СД ============-------------
		set r.inventlocationid = 'СД'
	from #q r
		join WH2.ITRN i on r.ITRNKEY=i.ITRNKEY
	join WH2.sku s on i.SKU=s.sku
	where i.fromloc in ('PRIEM','PRIEM_EA','PRIEM_PL') and s.FREIGHTCLASS='6'
	
	
--if exists (select 1 from #q where toloc in ('EA_IN','NETSERTIFICATA','BLOKFSN'))--не понял зачем вообще это
if exists (select 1 from #q where toloc in ('test'))
BEGIN
	
	select	@mess01 = t.MESSAGE01, @mess02 = t.MESSAGE02, @mastersystem = 0 -- @mastersystem = 'DAX'
	from	WH2.TASKDETAIL t
		join #q q
		    on t.STORERKEY = '001'
		    and t.SKU = q.SKU
		    and q.toloc = t.TOLOC
		    and q.inventbatchid = t.LOT
		    and q.fromid = t.FROMID
		    and q.toid = t.TOID
	where	t.TASKTYPE = 'MV'
		and t.ADDWHO = 'sklad_integr'
		
		
	insert into #resultall
	(
		dataareaid,
		inventjournalnameid,
		transdate,
		inventjournalid,
		inventjournaltype,
		mastersystem,
		sku,
		manufacturedatafrom,
		manufacturedatato,
		inventexpiredate,
		corrinventexpiredate,
		orderedqty,
		inventlocationid,
		corrinventlocationid,
		inventbatchid,
		corrinventbatchid,
		inventserialid,
		corrinventserialid
	)
	select	distinct
		dataareaid,
		@mess01 as inventjournalnameid,
		transdate,
		@mess02 as inventjournalid,
		inventjournaltype,
		@mastersystem,
		SKU,		
		manufacturedatafrom,
		manufacturedatato,
		inventexpiredate,
		corrinventexpiredate, 
		orderedqty,
		inventlocationid,
		corrinventlocationid,
		inventbatchid,
		corrinventbatchid,
		inventserialid,
		corrinventserialid
	from	#q
	
	
	insert into #resulthead
	(dataareaid,
	inventjournalnameid,
	transdate,
	inventjournalid,
	inventjournaltype,
	mastersystem)
	
	select	distinct
		dataareaid,
		@mess01 as inventjournalnameid,
		transdate,
		@mess02 as inventjournalid,
		inventjournaltype,
		@mastersystem
	from	#q
	
	
	insert into #resultdetail
	(
		dataareaid,
		inventjournalid,
		transdate,
		sku,
		manufacturedatafrom,
		manufacturedatato,
		inventexpiredate,
		corrinventexpiredate,
		orderedqty,
		inventlocationid,
		corrinventlocationid,
		inventbatchid,
		corrinventbatchid,
		inventserialid,
		corrinventserialid,
		mastersystem
	)
	select	distinct
		dataareaid,
		@mess02 as inventjournalid,
		transdate,	
		SKU,		
		manufacturedatafrom,
		manufacturedatato,
		inventexpiredate,
		corrinventexpiredate, 
		orderedqty,
		inventlocationid,
		corrinventlocationid,
		inventbatchid,
		corrinventbatchid,
		inventserialid,
		corrinventserialid,
		@mastersystem
	from	#q
	
	
END
else
	if exists (select 1 from #q where inventlocationid <> corrinventlocationid) --склады не равны
	BEGIN
		
		insert into #resultall
		(
			dataareaid,
			inventjournalnameid,
			transdate,
			inventjournalid,
			inventjournaltype,
			mastersystem,
			sku,
			manufacturedatafrom,
			manufacturedatato,
			inventexpiredate,
			corrinventexpiredate,
			orderedqty,
			inventlocationid,
			corrinventlocationid,
			inventbatchid,
			corrinventbatchid,
			inventserialid,
			corrinventserialid
		)
		select	distinct
			dataareaid,
			'' as inventjournalnameid,
			transdate,
			'' as inventjournalid,
			inventjournaltype,
--			'Infor' as mastersystem,
			1 as mastersystem,
			SKU,		
			manufacturedatafrom,
			manufacturedatato,
			inventexpiredate,
			corrinventexpiredate, 
			orderedqty,
			inventlocationid,
			corrinventlocationid,
			inventbatchid,
			corrinventbatchid,
			inventserialid,
			corrinventserialid
		from	#q
        	
        	
		insert into #resulthead
		(dataareaid,
		inventjournalnameid,
		transdate,
		inventjournalid,
		inventjournaltype,
		mastersystem)
        	
		select	distinct
			dataareaid,
			'' as inventjournalnameid,
			transdate,
			'' as inventjournalid,
			inventjournaltype,
--			'Infor' as mastersystem
			1 as mastersystem
		from	#q
        	
        	
		insert into #resultdetail
		(
			dataareaid,
			inventjournalid,
			transdate,
			sku,
			manufacturedatafrom,
			manufacturedatato,
			inventexpiredate,
			corrinventexpiredate,
			orderedqty,
			inventlocationid,
			corrinventlocationid,
			inventbatchid,
			corrinventbatchid,
			inventserialid,
			corrinventserialid,
			mastersystem
		)
		select	distinct
			dataareaid,
			'' as inventjournalid,
			transdate,	
			SKU,		
			manufacturedatafrom,
			manufacturedatato,
			inventexpiredate,
			corrinventexpiredate, 
			orderedqty,
			inventlocationid,
			corrinventlocationid,
			inventbatchid,
			corrinventbatchid,
			inventserialid,
			corrinventserialid,
--			'Infor' as mastersystem
			1 as mastersystem
		from	#q
	
	
	END
	else
		if exists (select 1 from #q where toloc = 'LOST' and inventlocationid <> corrinventlocationid) --перемещения в LOST
		BEGIN
        		
			insert into #resultall
			(
				dataareaid,
				inventjournalnameid,
				transdate,
				inventjournalid,
				inventjournaltype,
				mastersystem,
				sku,
				manufacturedatafrom,
				manufacturedatato,
				inventexpiredate,
				corrinventexpiredate,
				orderedqty,
				inventlocationid,
				corrinventlocationid,
				inventbatchid,
				corrinventbatchid,
				inventserialid,
				corrinventserialid
			)
			select	distinct
				dataareaid,
				'' as inventjournalnameid,
				transdate,
				'' as inventjournalid,
				inventjournaltype,
--				'Infor' as mastersystem,
				1 as mastersystem,
				SKU,		
				manufacturedatafrom,
				manufacturedatato,
				inventexpiredate,
				corrinventexpiredate, 
				orderedqty,
				inventlocationid,
				corrinventlocationid,
				inventbatchid,
				corrinventbatchid,
				inventserialid,
				corrinventserialid
			from	#q
                	
                	
			insert into #resulthead
			(dataareaid,
			inventjournalnameid,
			transdate,
			inventjournalid,
			inventjournaltype,
			mastersystem)
                	
			select	distinct
				dataareaid,
				'' as inventjournalnameid,
				transdate,
				'' as inventjournalid,
				inventjournaltype,
--				'Infor' as mastersystem
				1 as mastersystem
			from	#q
                	
                	
			insert into #resultdetail
			(
				dataareaid,
				inventjournalid,
				transdate,
				sku,
				manufacturedatafrom,
				manufacturedatato,
				inventexpiredate,
				corrinventexpiredate,
				orderedqty,
				inventlocationid,
				corrinventlocationid,
				inventbatchid,
				corrinventbatchid,
				inventserialid,
				corrinventserialid,
				mastersystem
			)
			select	distinct
				dataareaid,
				'' as inventjournalid,
				transdate,	
				SKU,		
				manufacturedatafrom,
				manufacturedatato,
				inventexpiredate,
				corrinventexpiredate, 
				orderedqty,
				inventlocationid,
				corrinventlocationid,
				inventbatchid,
				corrinventbatchid,
				inventserialid,
				corrinventserialid,
--				'Infor' as mastersystem
				1 as mastersystem
			from	#q
        	
        	
		END	
	
	
print 'запись в обменные таблицы DAX'	
	
declare @n bigint


select  @n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
from    [spb-sql1202].[DAX2009_1].[dbo].SZ_ImpInventjournal


insert into [spb-sql1202].[DAX2009_1].[dbo].SZ_ImpInventjournal
(DataAReaID, inventjournalnameid, transdate, inventjournalid, inventjournaltype,
 mastersystem,Status,RecID)


select  dataareaid,
	inventjournalnameid,
	transdate,
	'I'+ cast(@transmitlogkey as varchar(20)) as inventjournalid,
	inventjournaltype,
	mastersystem,
	'5',
	@n + 1 as recid
from    #resulthead

if @@ERROR = 0
begin	    
	    
    select  @n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
    from    [spb-sql1202].[DAX2009_1].[dbo].SZ_ImpInventjournaltrans


    insert into [spb-sql1202].[DAX2009_1].[dbo].SZ_ImpInventjournaltrans
    (DataAReaID, inventjournalid, transdate,ItemID, manufacturedatefrom,manufacturedateto,inventexpiredate,corrinventexpiredate,
    OrderedQty,inventlocationid,corrinventlocationid,
    InventBatchID,corrinventbatchid,InventSerialID,corrinventserialid,mastersystem,Status,RecID)

    select  dataareaid,
	   'I'+ cast(@transmitlogkey as varchar(20)) as inventjournalid,
	    transdate,
	    sku,
	    manufacturedatafrom,
	    manufacturedatato,
	    inventexpiredate,
	    corrinventexpiredate,
	    orderedqty,
	    inventlocationid,
	    corrinventlocationid,
	    inventbatchid,
	    corrinventbatchid,
	    case when inventserialid='' then 'бс' else inventserialid end,
	    case when corrinventserialid='' then 'бс' else corrinventserialid end,
	    mastersystem,
	    '5',
	    @n + 1 as recid	
    from    #resultdetail

end


															
print '2. передача результата'
select 	'MOVE' as filetype,
	dataareaid,
	inventjournalnameid,
	transdate,
	inventjournalid,
	inventjournaltype,
	mastersystem,
	sku,
	manufacturedatafrom,
	manufacturedatato,
	inventexpiredate,
	corrinventexpiredate,
	orderedqty,
	inventlocationid,
	corrinventlocationid,
	inventbatchid,
	corrinventbatchid,
	inventserialid,
	corrinventserialid
from	#resultall

IF OBJECT_ID('tempdb..#resultall') IS NOT NULL DROP TABLE #resultall
IF OBJECT_ID('tempdb..#resulthead') IS NOT NULL DROP TABLE #resulthead
IF OBJECT_ID('tempdb..#resultdetail') IS NOT NULL DROP TABLE #resultdetail



