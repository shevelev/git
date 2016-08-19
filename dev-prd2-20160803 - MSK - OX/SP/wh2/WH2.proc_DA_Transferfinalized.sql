

/****************************************************************************************/


ALTER PROCEDURE [WH2].[proc_DA_Transferfinalized](
	@wh varchar(10),
	@transmitlogkey varchar (10)
	
)AS

/* ver 1.1.0 from 30/09/2011 */

--declare @transmitlogkey varchar (10)
--set @transmitlogkey = '0005986812'

set nocount on

create table #resulthead (
	dataareaid VARCHAR(5),
	inventjournalnameid varchar(20),
	transdate datetime,
	inventjournalid varchar(30),
	inventjournaltype varchar(3),
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


--declare @transmitlogkey varchar (50)
declare @transferkey varchar (50)

declare @fromseria varchar(20), @toseria varchar(20),
		@fromlot4 varchar(20), @tolot4 varchar(20),
		@fromlot5 varchar(20), @tolot5 varchar(20),
		@fromlot6 varchar(20), @tolot6 varchar(20)

--set @transmitlogkey = '0016603773'

insert into #resultall
	(
		dataareaid, 		inventjournalnameid, 		transdate,		inventjournalid,		inventjournaltype,
		mastersystem, 		sku, 		manufacturedatafrom, 		manufacturedatato,		
		inventexpiredate,		corrinventexpiredate, 		orderedqty,		inventlocationid, 	corrinventlocationid,
		inventbatchid, 		corrinventbatchid,		inventserialid, 		corrinventserialid
	)
select 
		'SZ','',getdate(),'',2,
		1, td.fromsku,
			isnull(lt.LOTTABLE04,'19000101') fromlot4, isnull(td.LOTTABLE04,'19000101') tolot4,
		isnull(lt.LOTTABLE05,'19000101') fromlot5, isnull(td.LOTTABLE05,'19000101') tolot5, td.TOQTY, zone1.sklad, zone2.sklad,
		lt.LOTTABLE06, td.LOTTABLE06, lt.LOTTABLE02, td.LOTTABLE02
	
		
		
		from WH2.transmitlog tl
			join WH2.transferdetail td on tl.key1 = td.transferkey
			join WH2.lotattribute lt on lt.lot = td.fromlot
			join WH2.loc l1 on l1.LOC=td.fromloc --склад откуда
			join WHTOZONE zone1 on zone1.zone=l1.PUTAWAYZONE
			join WH2.loc l2 on l2.LOC=td.toloc --склад куда
			join WHTOZONE zone2 on zone2.zone=l2.PUTAWAYZONE
		where tl.tablename = 'transferfinalized' and tl.transmitlogkey = @transmitlogkey


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
		from	#resultall
        	
        	
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
		from	#resultall


print 'запись в обменные таблицы DAX'	
	
declare @n bigint


select  @n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
from    [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventjournal


insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventjournal
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
    from    [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventjournaltrans


    insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventjournaltrans
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
select 	'transferfinalized' as filetype,
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

