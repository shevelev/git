
/*************************************************************************************************/



ALTER PROCEDURE [WH2].[proc_DA_CancelSO](
	@wh varchar(10),
	@transmitlogkey varchar (10)
)AS


	
create table #resulthead (	
	dataareaid VARCHAR(5),
	docid varchar(30),
	doctype varchar(10),
	operationtypeheader varchar(3),
	invoiceid varchar(30),
	salesidbase varchar(30),
	wmspickingrouteid varchar(30),
	demandshipdate datetime,
	consigneeAccount_ru varchar(10),
	inventlocationid varchar(30)
	)	

CREATE TABLE #resultdetail(
	serkey int IDENTITY(1,1),
	dataareaid VARCHAR(5),
	salesidbase varchar(30),
	docid varchar(30),
	itemid varchar(50),
	wmsrouteid varchar(30),
	operationtypeheader varchar(3),
	orderedqty int,
	inventlocationid varchar(30),
	inventbatchid varchar(40),
	inventserialid varchar(40),
	inventexpiredate datetime,
	inventserialproddate datetime
)

create table #resultall (
	dataareaid VARCHAR(5),
	docid varchar(30),
	doctype varchar(10),
	operationtypeheader varchar(3),
	invoiceid varchar(30),
	salesidbase varchar(30),
	wmspickingrouteid varchar(30),
	demandshipdate datetime,
	consigneeAccount_ru varchar(10),
	inventlocationid varchar(30),
	itemid varchar(50),
	--wmsrouteid varchar(30),
	orderedqty int,
	inventbatchid varchar(40),
	inventserialid varchar(40),
	inventexpiredate datetime,
	inventserialproddate datetime
	)

insert into #resultall
select	'SZ' as dataareaid,
	replace(o.EXTERNORDERKEY,'OLD','') as docid,
	o.TYPE as doctype,
	'1' as operationtypeheader,
	o.SUSR3 as invoiceid,
	o.C_CONTACT1 as salesidbase,
	o.SUSR2 as wmspickingrouteid,
	o.REQUESTEDSHIPDATE as demandshipdate,
	o.CONSIGNEEKEY as consigneeAccount_ru,
	o.SUSR1 as inventlocationid,
	o2.SKU as itemid,
	o2.OPENQTY as orderedqty,
	o2.LOTTABLE06 as inventbatchid,
	case when o2.LOTTABLE02 = '' then 'бс' else      o2.LOTTABLE02     end AS inventserialid,--o2.LOTTABLE02 as inventserialid,
	convert(varchar(12),ISNULL(o2.LOTTABLE05,'19000101'),112) as inventexpiredate, --o2.LOTTABLE05 as inventexpiredate,
	convert(varchar(12),ISNULL(o2.LOTTABLE04,'19000101'),112) as inventserialproddate --o2.LOTTABLE04 as inventserialproddate
	
from	WH2.TRANSMITLOG t
	join WH2.ORDERS o
	    on o.ORDERKEY = t.KEY1
	join WH2.ORDERDETAIL o2
	    on o2.ORDERKEY = o.ORDERKEY	
where	t.TRANSMITLOGKEY = @transmitlogkey

insert into #resulthead
    (dataareaid,
    docid,
    doctype,
    operationtypeheader,
    invoiceid,
    salesidbase,
    wmspickingrouteid,
    demandshipdate,
    consigneeAccount_ru,
    inventlocationid)

select	distinct
	dataareaid,
	docid,
	doctype,
	operationtypeheader,
	invoiceid,
	salesidbase,
	wmspickingrouteid,
	demandshipdate,
	consigneeAccount_ru,
	inventlocationid
from	#resultall


insert into #resultdetail
(	dataareaid,
	salesidbase,
	docid,
	itemid,
	wmsrouteid,
	operationtypeheader,
	orderedqty,
	inventlocationid,
	inventbatchid,
	inventserialid,
	inventexpiredate,
	inventserialproddate
)
select	dataareaid,
	salesidbase,
	docid,
	itemid,
	wmspickingrouteid,
	operationtypeheader,
	orderedqty,
	inventlocationid,
	inventbatchid,
	inventserialid,
	inventexpiredate,
	inventserialproddate
from	#resultall
	
	
	
print 'запись в обменные таблицы DAX'	
	
declare @n bigint


select  @n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
from    [spb-sql1202].[DAX2009_1].[dbo].SZ_ImpOutputUpdateOrders


insert into [spb-sql1202].[DAX2009_1].[dbo].SZ_ImpOutputUpdateOrders
(dataareaid, docid, doctype, operationtypeheader, invoiceid,
salesidbase,wmspickingrouteid, demandshipdate, consigneeAccount_ru,
inventlocationid,
status, recid)


select  dataareaid,
	docid,
	doctype,
	operationtypeheader,
	invoiceid,
	salesidbase,
	wmspickingrouteid,
	demandshipdate,
	consigneeAccount_ru,
	inventlocationid,
	'5',
	@n + 1 as recid
from    #resulthead

if @@ERROR = 0
begin	    
	    
    select  @n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
    from    [spb-sql1202].[DAX2009_1].[dbo].SZ_ImpOutputUpdOrderlines


    insert into [spb-sql1202].[DAX2009_1].[dbo].SZ_ImpOutputUpdOrderlines
    (dataareaid,salesidbase,docid,itemid,wmsrouteid,
    operationtypeheader,orderedqty,inventlocationid,
    inventbatchid,inventserialid,inventexpiredate,
    inventserialproddate,status,recid)

    select  dataareaid,
	    salesidbase,
	    docid,
	    itemid,
	    wmsrouteid,
	    operationtypeheader,
	    orderedqty,
	    inventlocationid,
	    inventbatchid,
	    inventserialid,
	    inventexpiredate,
	    inventserialproddate,
	    '5',
	    @n + serkey as recid	
    from    #resultdetail

end


															
print '2.передача результата'
select 	'CANCELSO' as filetype,
	dataareaid,
	docid,
	doctype,
	operationtypeheader,
	invoiceid,
	salesidbase,
	wmspickingrouteid,
	demandshipdate,
	consigneeAccount_ru,
	inventlocationid,
	itemid,	
	orderedqty,
	inventbatchid,
	inventserialid,
	inventexpiredate,
	inventserialproddate
from	#resultall

IF OBJECT_ID('tempdb..#resultall') IS NOT NULL DROP TABLE #resultall
IF OBJECT_ID('tempdb..#resulthead') IS NOT NULL DROP TABLE #resulthead
IF OBJECT_ID('tempdb..#resultdetail') IS NOT NULL DROP TABLE #resultdetail




