


/****************************************************************************************/


----- [SPB-DAXDEV] - test server
----- [SPB-SQL1210DBE\MSSQLDBE] - real server

ALTER PROCEDURE [WH2].[proc_DA_ReceiptConfirm]
	@wh varchar(30),
	@transmitlogkey varchar (10)

as
--############################################################### ПОДТВЕРЖДЕНИЕ ПУО
set nocount on

--return

--declare @sql varchar(max)
--, @wh varchar(30),
--@transmitlogkey varchar (10)

--set @wh = 'wmwhse1'
--set @transmitlogkey = '0000001020'

--declare	@Hours int = 5



print '-- выбор необработанного подтверждения о приемке, формирование выходного датасета'


	    
	    
CREATE TABLE [#rt](
	[filetype] [nvarchar](16) COLLATE Cyrillic_General_CI_AS NULL,	
	[EXTERNPOKEY] [nvarchar](32) COLLATE Cyrillic_General_CI_AS NULL,	
	[potype] [nvarchar](10) COLLATE Cyrillic_General_CI_AS NULL,	
	[SELLERNAME] [nvarchar](15) COLLATE Cyrillic_General_CI_AS NULL,
	[BUYERADDRESS4] [nvarchar](100) COLLATE Cyrillic_General_CI_AS NULL,	
	[susr2] [nvarchar](30) COLLATE Cyrillic_General_CI_AS NULL,	
	[sku] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[storerkey] [nvarchar](15) COLLATE Cyrillic_General_CI_AS NULL,		
	[EXTERNLINENO] [nvarchar](5) COLLATE Cyrillic_General_CI_AS NULL,
	[QTYORDERED] [nvarchar](20) COLLATE Cyrillic_General_CI_AS NULL,
	[qtyreceived] [nvarchar](20) COLLATE Cyrillic_General_CI_AS NULL,	
	[ALTSKU] [nvarchar](30) COLLATE Cyrillic_General_CI_AS NULL,
	[susr4] [nvarchar](30) COLLATE Cyrillic_General_CI_AS NULL,
	[LOTTABLE01] [nvarchar](40) COLLATE Cyrillic_General_CI_AS NULL,
	[LOTTABLE02] [nvarchar](40) COLLATE Cyrillic_General_CI_AS NULL,	
	[lottable04] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[lottable05] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[lottable06] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL	
	)
	
	    
CREATE TABLE [#rt2](
	[filetype] [nvarchar](16) COLLATE Cyrillic_General_CI_AS NULL,	
	[EXTERNPOKEY] [nvarchar](32) COLLATE Cyrillic_General_CI_AS NULL,	
	[potype] [nvarchar](10) COLLATE Cyrillic_General_CI_AS NULL,	
	[SELLERNAME] [nvarchar](15) COLLATE Cyrillic_General_CI_AS NULL,
	[BUYERADDRESS4] [nvarchar](100) COLLATE Cyrillic_General_CI_AS NULL,	
	[susr2] [nvarchar](30) COLLATE Cyrillic_General_CI_AS NULL	
	)
	
	    
CREATE TABLE [#rt3](
	[filetype] [nvarchar](16) COLLATE Cyrillic_General_CI_AS NULL,	
	[EXTERNPOKEY] [nvarchar](32) COLLATE Cyrillic_General_CI_AS NULL,		
	[sku] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[storerkey] [nvarchar](15) COLLATE Cyrillic_General_CI_AS NULL,		
	[EXTERNLINENO] [nvarchar](5) COLLATE Cyrillic_General_CI_AS NULL,
	[QTYORDERED] [nvarchar](20) COLLATE Cyrillic_General_CI_AS NULL,
	[qtyreceived] [nvarchar](20) COLLATE Cyrillic_General_CI_AS NULL,	
	[ALTSKU] [nvarchar](30) COLLATE Cyrillic_General_CI_AS NULL,
	[susr4] [nvarchar](30) COLLATE Cyrillic_General_CI_AS NULL,
	[LOTTABLE01] [nvarchar](40) COLLATE Cyrillic_General_CI_AS NULL,
	[LOTTABLE02] [nvarchar](40) COLLATE Cyrillic_General_CI_AS NULL,	
	[lottable04] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[lottable05] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[lottable06] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL	
	)			    


declare @receiptkey  varchar(15) = null,
		@error int = 0

select	*
into	#tl
from	WH2.transmitlog
where	tablename = 'asnclosed'


select	@receiptkey = t.key1 
from	#tl t
	left join #tl tt
	    on t.transmitlogkey = tt.transmitlogkey
	    and tt.key5 = '1'
where	t.transmitlogkey = @transmitlogkey
	and tt.transmitlogkey is null
	
	
if @receiptkey is not NULL
begin
DECLARE	@return_value1 int

EXEC	@return_value1 = [wh2].[proc_DA_ReceiptConfirm_attr]
 @receiptkey1 =@receiptkey
    CREATE TABLE [#receiptdetail](
	id int identity (1,1),	
	sku varchar(50),	
	storerkey varchar(15),
	descr varchar(60),
	packkey varchar(20),
	uom varchar(20),
	altsku varchar(30),
	lottable01 varchar(50),
	LOTTABLE02 varchar(50),
	lottable04 datetime,
	lottable05 datetime, 
	lottable06 varchar(50),
	sclad varchar(30),
	qtyreceived float,
	susr1 varchar(30)--,
	--tolot varchar(20)
    )

    CREATE TABLE [#podetail](
	    id int identity (1,1),	
	    pokey varchar(20),
	    potype varchar(5),
	    externpokey varchar(20),
	    externlinenum varchar(5),
	    sku varchar(50),
	    storerkey varchar(15),	
	    qtyordered float,
	    lottable01 varchar(50),
	    LOTTABLE02 varchar(50),
	    lottable04 datetime,
	    lottable05 datetime, 
	    lottable06 varchar(50)
    )

    CREATE TABLE [#pr](
	    id int,	
	    pokey varchar(20),
	    potype varchar(5),
	    externpokey varchar(20),
	    externlinenum varchar(5),
	    storerkey varchar(15),
	    sku varchar(50),	
	    qtyordered float,
	    descr varchar(60),
	    packkey varchar(20),
	    uom varchar(20),
	    altsku varchar(30),
	    lottable01 varchar(50),
	    LOTTABLE02 varchar(50),
	    lottable04 datetime,
	    lottable05 datetime, 
	    lottable06 varchar(50),
	    sclad varchar(30),
	    qtyreceived float,
	    susr1 varchar(30)--,
	    --tolot varchar(20)
    )

    CREATE TABLE [#pr_it](
	    id int,	
	    pokey varchar(20),
	    potype varchar(5),
	    externpokey varchar(20),
	    externlinenum varchar(5),
	    storerkey varchar(15),
	    sku varchar(50),	
	    qtyordered float,
	    descr varchar(60),
	    packkey varchar(20),
	    uom varchar(20),
	    altsku varchar(30),
	    lottable01 varchar(50),
	    LOTTABLE02 varchar(50),
	    lottable04 datetime,
	    lottable05 datetime, 
	    lottable06 varchar(50),
	    sclad varchar(30),
	    qtyreceived float,
	    susr1 varchar(30)--,
	    --tolot varchar(20)
    )


    create table #pokey (
	    pokey varchar(15),
	    potype varchar(10)
    )

	
	
    insert into #receiptdetail
    --(sku, storerkey, descr, packkey, uom, altsku, lottable01, LOTTABLE02, lottable04, lottable05, lottable06, sclad, qtyreceived, susr1, tolot)

    select  r.SKU,r.storerkey,left(s.DESCR,60) as descr,s.PACKKEY,s.RFDEFAULTUOM,r.ALTSKU, 
	    min(r.LOTTABLE01) as LOTTABLE01,							-- zaa 17/04/15 added to MIN
	    r.LOTTABLE02, r.LOTTABLE04, r.LOTTABLE05, r.LOTTABLE06,
	    case	when s.FREIGHTCLASS = '6' and r.TOLOC NOT IN ('BRAKPRIEM','LOSTPRIEM','OVERPRIEM','PRETENZ') then 'SD'
			    when r.TOLOC = 'BRAKPRIEM' then 'BRAKPRIEM'
			    when r.TOLOC = 'OVERPRIEM' then 'OVERPRIEM'
			    when r.TOLOC = 'LOSTPRIEM' then 'LOSTPRIEM'
			    when r.TOLOC = 'PRETENZ' then 'PRETENZ'
			    else 'GENERAL'
	    end as SCLAD,
	    sum(r.QTYRECEIVED) as sumqtyreceived,
	    r.SUSR1--,
	    --r.TOLOT
    --into	#q		
    from    WH2.RECEIPTDETAIL r
	    join WH2.sku s
		on s.SKU = r.SKU
		and s.STORERKEY = r.STORERKEY
    where   r.RECEIPTKEY = @receiptkey
	    and r.QTYRECEIVED <> 0
    group by r.storerkey,r.SKU, left(s.DESCR,60),s.PACKKEY,s.RFDEFAULTUOM, r.ALTSKU, --r.LOTTABLE01, 
	    r.LOTTABLE02, r.LOTTABLE04, r.LOTTABLE05, r.LOTTABLE06,
	    case	when s.FREIGHTCLASS = '6' and r.TOLOC NOT IN ('BRAKPRIEM','LOSTPRIEM','OVERPRIEM','PRETENZ') then 'SD'
			    when r.TOLOC = 'BRAKPRIEM' then 'BRAKPRIEM'
			    when r.TOLOC = 'OVERPRIEM' then 'OVERPRIEM'
			    when r.TOLOC = 'LOSTPRIEM' then 'LOSTPRIEM'
			    when r.TOLOC = 'PRETENZ' then 'PRETENZ'
			    else 'GENERAL'
	    end,
	    r.SUSR1--,
	    --r.TOLOT
    order by r.SKU	
    		
    		
    insert into #podetail
    --(pokey,potype,externpokey,EXTERNLINENO,sku,storerkey,qtyordered,lottable01,LOTTABLE02,lottable04,lottable05, lottable06)		

    select  p.POKEY, p.POTYPE,p.EXTERNPOKEY,pd.EXTERNLINENO,
	    pd.SKU,pd.STORERKEY,
	    sum(pd.QTYORDERED) as QTYORDERED,
	    pd.lottable01,pd.LOTTABLE02,pd.lottable04,pd.lottable05,pd.lottable06
    from    WH2.PO p
	    join WH2.PODETAIL pd
		    on pd.POKEY = p.POKEY
    where   p.OTHERREFERENCE =@receiptkey
    group by p.POKEY, p.POTYPE,p.EXTERNPOKEY,pd.EXTERNLINENO,
	    pd.SKU,pd.STORERKEY,
	    pd.lottable01,pd.LOTTABLE02,pd.lottable04,pd.lottable05,pd.lottable06
    order by p.POKEY,pd.SKU					


    declare @i int = 1,
	    @poid int = 0,
	    @receiptid int = 0,
	    @polinenumber int,
	    @receiptlinenumber int,
	    @pokey varchar(20),
	    @text nvarchar(4000) = ''
    declare @key nvarchar(18), @sku nvarchar(50), @qtyreceived decimal(22,0), @qtyordered decimal(22,0)
    declare @key1 nvarchar(18), @qtyreceived1 decimal(22,0), @qtyordered1 decimal(22,0)
    declare @delta decimal(22,0), @adj decimal(22,0),@sclad nvarchar(20),@sclad1 nvarchar(20)		

    if exists (select 1 from #receiptdetail where LOTTABLE06 <> 'NA' and SCLAD not in ('OVERPRIEM','PRETENZ'))
    begin	
    	
	    --while (@i <= (select COUNT(*) from #receiptdetail where LOTTABLE06 <> 'NA' and SCLAD not in ('OVERPRIEM','PRETENZ')))
	    --begin			
    		
		    --select	top 1 
			   -- @receiptid = id 
		    --from	#receiptdetail  
		    --where	LOTTABLE06 <> 'NA' 
			   -- and SCLAD not in ('OVERPRIEM','PRETENZ')
    				
    			
		    insert into #pr		
		    select  q.id,pd.POKEY, pd.POTYPE,pd.EXTERNPOKEY,pd.externlinenum,pd.STORERKEY,pd.SKU,pd.qtyordered,
			    q.descr,q.PACKKEY,q.UOM,q.ALTSKU, q.LOTTABLE01, q.LOTTABLE02, q.LOTTABLE04, q.LOTTABLE05, q.LOTTABLE06,
			    q.sclad,q.qtyreceived,q.susr1--,q.tolot
		    from    #receiptdetail q
			    join #podetail pd
				on q.SKU = pd.SKU
				and q.STORERKEY = pd.STORERKEY
				and q.LOTTABLE02 = pd.LOTTABLE02
				and q.LOTTABLE06 like  pd.LOTTABLE06+ '%'
				and pd.POTYPE <> '0'
		    where   --q.id = @receiptid
			    --and 
			    q.LOTTABLE06 <> 'NA' 
			    and q.SCLAD not in ('OVERPRIEM','PRETENZ')
    		
		    insert into #pr
		    select  q.id,pd.POKEY, pd.POTYPE,pd.EXTERNPOKEY,pd.externlinenum,q.STORERKEY,q.SKU,pd.qtyordered,
			    q.descr,q.PACKKEY,q.UOM,q.ALTSKU, q.LOTTABLE01, q.LOTTABLE02, q.LOTTABLE04, q.LOTTABLE05, q.LOTTABLE06,
			    q.sclad,q.qtyreceived,q.susr1--,q.tolot
		    from    #receiptdetail q
			    join #podetail pd
				on --q.SKU = pd.SKU
				pd.sku = case when q.susr1 = 'ORIGINAL' then q.sku when q.susr1 not IN ('ORIGINAL','NA') then q.susr1 else null end
				and q.STORERKEY = pd.STORERKEY						
				--and q.LOTTABLE06 = pd.LOTTABLE06
				and q.LOTTABLE06 like pd.LOTTABLE06+'%'
				and pd.POTYPE = '0'
		   where   q.LOTTABLE06 <> 'NA' 
			    and q.SCLAD not in ('OVERPRIEM','PRETENZ')		    
			    --q.id = @receiptid			
    		
    		
		    declare cur cursor local static for
		    select  pokey, sku,sclad,qtyreceived, qtyordered
		    from    #pr
		    where   qtyreceived > qtyordered
		    order by pokey, sku

		    open cur

		    fetch next from cur into @key, @sku,@sclad, @qtyreceived, @qtyordered
		    while @@FETCH_STATUS=0
		    BEGIN
			    set @delta = @qtyreceived - @qtyordered
    			
			    declare cur1 cursor local static for
			    select  pokey, sclad,qtyreceived, qtyordered
			    from    #pr
			    where   qtyreceived < qtyordered and sku = @sku and sclad = @sclad
			    order by pokey,sclad

			    open cur1

			    fetch next from cur1 into @key1,@sclad1,@qtyreceived1, @qtyordered1
			    while @@FETCH_STATUS=0 and @delta > 0
			    BEGIN
				    set @adj = @qtyordered1 - @qtyreceived1
    				
				    if @adj >= @delta
					    select @adj = @delta, @delta = 0
				    else
					    set @delta = @delta - @adj

				    update #pr
				    set qtyreceived = qtyreceived - @adj
				    where sku = @sku and pokey = @key and qtyordered = @qtyordered and sclad = @sclad
    				
				    update #pr
				    set qtyreceived = qtyreceived + @adj
				    where sku = @sku and pokey = @key1 and qtyordered = @qtyordered1 and sclad = @sclad1

				    fetch next from cur1 into @key1,@sclad1,@qtyreceived1, @qtyordered1
			    END
			    close cur1
			    deallocate cur1
    			
			    fetch next from cur into @key, @sku,@sclad,@qtyreceived, @qtyordered
		    END
		    close cur
		    deallocate cur
    		
    		
		    insert into #pr_it
		    select	*
		    from	#pr			
    		
		    --select @i = @i + 1
    		
		    delete 
		    from    #receiptdetail
		    from    #receiptdetail r
			    join #pr p
				    on r.id = p.id
		    --where	r.id = @receiptid
    		
		    delete from #pr
    	
	    --end	

    end

    if exists (select 1 from #receiptdetail --where (LOTTABLE06 = 'NA' or SCLAD in ('OVERPRIEM','PRETENZ'))
	    )
    begin				
    				
	   insert into #pr_it		
	    select  r.id,'' as POKEY, '' as POTYPE,'' as EXTERNPOKEY,pd.externlinenum,r.STORERKEY,r.SKU,0 as qtyordered,
		    r.descr,r.PACKKEY,r.UOM,r.ALTSKU, r.LOTTABLE01, r.LOTTABLE02, r.LOTTABLE04, r.LOTTABLE05, r.LOTTABLE06,
		    r.sclad,r.qtyreceived,r.susr1
	    from    #receiptdetail r
		    join #podetail pd
				on r.SKU = pd.SKU
				and r.STORERKEY = pd.STORERKEY
				--and r.LOTTABLE02 = pd.LOTTABLE02 --Шевелев, Излишки серия+партия не совпадают.
				--and r.LOTTABLE06 = pd.LOTTABLE06
				
				and pd.POTYPE <> '0'
				
				
	    insert into #pr_it		
	    select  r.id,'' as POKEY, '' as POTYPE,'' as EXTERNPOKEY,pd.externlinenum,r.STORERKEY,r.SKU,0 as qtyordered,
		    r.descr,r.PACKKEY,r.UOM,r.ALTSKU, r.LOTTABLE01, r.LOTTABLE02, r.LOTTABLE04, r.LOTTABLE05, r.LOTTABLE06,
		    r.sclad,r.qtyreceived,r.susr1
	    from    #receiptdetail r				
		    join #podetail pd
				on pd.sku =	case	when r.susr1 = 'ORIGINAL' then r.sku 
							--when r.susr1 not IN ('ORIGINAL','NA') then r.susr1 
							when r.susr1 not IN ('ORIGINAL') then r.susr1  --- убрал на.
							else null 
						end
				and r.STORERKEY = pd.STORERKEY						
				--and r.LOTTABLE06 = pd.LOTTABLE06
				and r.LOTTABLE06 like pd.LOTTABLE06+'%'
				and pd.POTYPE = '0' 
				
				/* Шевелев, если строчка вообще не ожидалась 04.03.2015 */
				
	    insert into #pr_it		
	    select  r.id,'' as POKEY, '' as POTYPE,'' as EXTERNPOKEY,r.id+100 as externlinenum,r.STORERKEY,r.SKU,0 as qtyordered,
		    r.descr,r.PACKKEY,r.UOM,r.ALTSKU, r.LOTTABLE01, r.LOTTABLE02, r.LOTTABLE04, r.LOTTABLE05, r.LOTTABLE06,
		    'OVERPRIEM' as sclad,r.qtyreceived,r.susr1
	    from    #receiptdetail r				
		    left join #podetail pd
				on pd.sku =	case	when r.susr1 = 'ORIGINAL' then r.sku 
							when r.susr1 not IN ('ORIGINAL','NA') then r.susr1 
							--when r.susr1 not IN ('ORIGINAL') then r.susr1  --- убрал на.
							else null 
						end
				and r.STORERKEY = pd.STORERKEY						
				--and r.LOTTABLE06 = pd.LOTTABLE06
				and r.LOTTABLE06 like pd.LOTTABLE06+'%'
				and pd.POTYPE = '0' 
		where r.susr1='NA'
			/* Шевелев, если строчка вообще не ожидалась 04.03.2015 */	
    	
    	--------------Вставка 09.06.2015 --------------
    	  if not exists (select 1 from #pr_it where pokey <> '')
	    begin
		
		update  #pr_it
		set	pokey = pp.pokey,
			potype = pp.potype,
			externpokey = pp.externpokey
		from    #pr_it p
			join (
	    			select distinct w.pokey,w.potype,w.externpokey
	    			from    #podetail w
	    				join (
	    				    select MAX(pokey) as pokey from #podetail where pokey <> ''
	    				    )ww
	    				    on ww.pokey = w.pokey
			) pp
				on p.pokey = '' 	    
	    
	    end	
    	--------------Вставка 09.06.2015 --------------
    	
	    delete 
	    from    #receiptdetail
	    from    #receiptdetail r
		    join #pr_it p
			on r.id = p.id
			--and (p.LOTTABLE06 = 'NA' or p.SCLAD in ('OVERPRIEM','PRETENZ'))

    end

    update  #pr_it
    set	pokey = pp.pokey,
	potype = pp.potype,
	externpokey = pp.externpokey
    from    #pr_it p
	    join (
	    	    select distinct w.pokey,w.potype,w.externpokey
	    	    from    #pr_it w
	    		    join (
	    			select MAX(pokey) as pokey from #pr_it where pokey <> ''
	    			)ww
	    			on ww.pokey = w.pokey
	    ) pp
		    on p.pokey = ''

    insert into #pokey
    select distinct pokey,potype from #pr_it
    
    begin tran
    print 'вставка результатов в ЗЗ1'
    while exists (select 1 from #pr_it)
    begin			
    	    print 'ЧТО-ТО ЕСТЬ'
    	    		
	    select  top 1 
		    @poid = id 
	    from    #pr_it
    	
    	
	    select  @polinenumber = MAX(cast(p.POLINENUMBER as int)) 
	    from    WH2.PODETAIL p
		    join (select pokey from #pr_it where id = @poid) pp
			    on pp.pokey = p.pokey
    				
    				
    				
	    insert into WH2.PODETAIL 
	    (WHSEID,pokey,EXTERNPOKEY,POLINENUMBER,EXTERNLINENO,QTYRECEIVED,SKU,SKUDESCRIPTION,STORERKEY,SUSR4,PACKKEY,UOM,ALTSKU,
	    lottable01, LOTTABLE02, lottable04, lottable05, lottable06,ADDWHO)
    	
    	
	    select  'WH2',pokey,externpokey,
		    REPLICATE('0',5 - LEN(@polinenumber+1)) + CAST(@polinenumber+1 as varchar(10)) as polinenumber,
		    --REPLICATE('0',5 - LEN(@polinenumber+1)) + CAST(@polinenumber+1 as varchar(10)) as EXTERNLINENO,
		    externlinenum,
		    qtyreceived,sku,descr,storerkey,sclad,packkey,uom,altsku,
		    lottable01, LOTTABLE02, lottable04, lottable05, lottable06,'asnclosed'
	    from    #pr_it
	    where   id = @poid
	    
	    if @@ERROR <> 0
	    begin	    
		print 'вставка результатов в ЗЗ не удалась'	
		set @error = 1
		goto endproc			
	    
	    end
    	
    	
	    delete from #pr_it where id = @poid					
    					
    end
    
    	

    if exists (select 1 from #pokey where potype = '0')
    begin
    	print 'анализ ЗЗ тип = 0'
    	    
    	    select  pd.POKEY,pd.EXTERNPOKEY,pd.EXTERNLINENO,pd.STORERKEY,pd.SKU, pd.QTYORDERED,
		    --sum(pd.QTYRECEIVED) as QTYRECEIVED,
		    pd.QTYRECEIVED,
		    pd.lottable01, pd.LOTTABLE02, pd.lottable04, pd.lottable05, pd.lottable06,
		    pd.SUSR4
	    into    #ned
	    from    WH2.PO p
		    join WH2.PODETAIL pd
			on pd.POKEY = p.POKEY
		    join #pokey po
			on po.pokey = p.POKEY
			and po.potype = '0'
		    join WH2.CODELKUP c 
			on c.CODE = p.potype 
			and C.LISTNAME = 'potype'
			--and c.NOTES like '1%'
			
			
	    select  IDENTITY(int,1,1) as id,
		    n.POKEY,n.EXTERNPOKEY,n.EXTERNLINENO,n.STORERKEY,n.SKU,n.QTYORDERED,nn.QTYRECEIVED,
		    nn.lottable01, nn.LOTTABLE02, nn.lottable04, nn.lottable05, nn.lottable06
	    into    #ned44
	    from    (	select	pokey,EXTERNPOKEY,EXTERNLINENO,STORERKEY,SKU,sum(QTYORDERED) as qtyordered,
				lottable01, LOTTABLE02, lottable04, lottable05, lottable06 
			from	#ned
			where	QTYORDERED > 0
			group by pokey,EXTERNPOKEY,EXTERNLINENO,STORERKEY,SKU,
				lottable01, LOTTABLE02, lottable04, lottable05, lottable06
		    ) n
		    join (  select  pokey,EXTERNPOKEY,STORERKEY,SKU,sum(QTYRECEIVED) as QTYRECEIVED,
				    --lottable01, LOTTABLE02, lottable04, lottable05, lottable06    --zaa 17/04/15 commented
				    min(lottable01) as lottable01, min(lottable02) as lottable02,   --zaa 17/04/15 added
				    min(lottable04) as lottable04, min(lottable05) as lottable05, 
				    min(lottable06) as lottable06  
			    from    #ned
			    where   SUSR4 in ('SD','GENERAL','BRAKPRIEM')			    
				    and QTYRECEIVED > 0
			    group by pokey,EXTERNPOKEY,STORERKEY,SKU--,
				    --lottable01, LOTTABLE02, lottable04, lottable05, lottable06    --zaa 17/04/15 commented
			) nn
			    on nn.POKEY = n.POKEY
			    and nn.STORERKEY = n.STORERKEY
			    and nn.SKU = n.SKU			   
			    and nn.lottable06 like n.lottable06	+'%'		 
	    where   n.QTYORDERED > nn.QTYRECEIVED	    --позиция не полностью принята и тип ПУО входит в codelkup.notes(поставить на балансы)
			
    			
	    select  IDENTITY(int,1,1) as id,
		    n.POKEY,n.EXTERNPOKEY,n.EXTERNLINENO,n.STORERKEY,n.SKU,n.QTYORDERED,nn.QTYRECEIVED,
		    n.lottable01, n.LOTTABLE02, n.lottable04, n.lottable05, n.lottable06
	    into    #ned55
	    from    (	select	pokey,EXTERNPOKEY,EXTERNLINENO,STORERKEY,SKU,sum(QTYORDERED) as qtyordered,
				lottable01, LOTTABLE02, lottable04, lottable05, lottable06 
			from	#ned
			where	QTYORDERED > 0
			group by pokey,EXTERNPOKEY,EXTERNLINENO,STORERKEY,SKU,
				lottable01, LOTTABLE02, lottable04, lottable05, lottable06
		    ) n
		    left join (	select	pokey,EXTERNPOKEY,STORERKEY,SKU,sum(QTYRECEIVED) as QTYRECEIVED,
					lottable01, LOTTABLE02, lottable04, lottable05, lottable06 
				from	#ned
				where	SUSR4 in ('SD','GENERAL','BRAKPRIEM')				    
					and QTYRECEIVED > 0
				group by pokey,EXTERNPOKEY,STORERKEY,SKU,
					lottable01, LOTTABLE02, lottable04, lottable05, lottable06
				    ) nn
			    on nn.POKEY = n.POKEY
			    and nn.STORERKEY = n.STORERKEY
			    and nn.SKU = n.SKU			    
			    and nn.lottable06 like n.lottable06	+'%'		 
	    where   nn.POKEY is null			--позиция вообще не принята и тип ПУО входит в codelkup.notes(поставить на балансы) 
	    
	    
	    while exists (select 1 from #ned44)
	    begin
    		--позиция не полностью принята и тип ПУО входит в codelkup.notes(поставить на балансы)   		
    		    print 'анализ ЗЗ тип = 0,позиция не полностью принята и тип ПУО входит в codelkup.notes(поставить на балансы)'
    		    update  WH2.RECEIPTDETAIL
    		    set	    STATUS = '9'
    		    where   RECEIPTKEY = @receiptkey
    			    and STATUS = '11'
    		    
    		    update  WH2.RECEIPT
    		    set	    STATUS = '9'
    		    where   RECEIPTKEY = @receiptkey
    			    and STATUS = '11'
		
		    select  top 1 
			    @poid = id 
		    from    #ned44
    	
		    select  @polinenumber = MAX(cast(p.POLINENUMBER as int))
		    from    WH2.PODETAIL p
			    join (select pokey from #ned44 where id = @poid) pp
				    on pp.pokey = p.pokey
    	
		    insert into WH2.PODETAIL 
		    (WHSEID,pokey,EXTERNPOKEY,POLINENUMBER,EXTERNLINENO,QTYRECEIVED,SKU,SKUDESCRIPTION,STORERKEY,SUSR4,PACKKEY,UOM,ALTSKU,
		    lottable01, LOTTABLE02, lottable04, lottable05, lottable06,ADDWHO)
    		
		    select  'WH2',n.pokey,externpokey,
			    REPLICATE('0',5 - LEN(@polinenumber+1)) + CAST(@polinenumber+1 as varchar(10)) as polinenumber,
			    n.EXTERNLINENO,
			    n.QTYORDERED - n.QTYRECEIVED as qtyreceived,n.sku,LEFT(s.DESCR,60) as descr,n.storerkey,'LOSTPRIEM' as sclad,s.packkey,
			    s.RFDEFAULTUOM,IsNull(r.ALTSKU,s.ALTSKU) as ALTSKU,
			    n.lottable01, n.LOTTABLE02, n.lottable04, n.lottable05, n.lottable06,'asnclosed'
		    from    #ned44 n
			    left join (
			    	    select sku,storerkey,max(ALTSKU) as ALTSKU
			    	    from WH2.RECEIPTDETAIL 
			    	    where RECEIPTKEY = @receiptkey
			    		   and IsNull(ALTSKU,'') <> '' 
			    	    group by sku,storerkey
				)r
				on n.sku = r.SKU 
			        and n.storerkey = r.storerkey			        	
			    join WH2.sku s 
			        on n.sku = s.SKU 
			        and n.storerkey = s.storerkey		        
		    where   n.id = @poid  		
		    
		    
		    if @@ERROR <> 0
		    begin	    
    			
			print 'анализ ЗЗ тип = 0,позиция не полностью принята и тип ПУО входит в codelkup.notes(поставить на балансы) - не вставили в podetail'
			set @error = 2
			goto endproc			
    	    
		    end	   
	    
		delete from #ned44 where id = @poid
		--delete from #t1					
    	
	    end
    	
	    while exists (select 1 from #ned55)
	    begin
    		--позиция вообще не принята и тип ПУО входит в codelkup.notes(поставить на балансы)
    		print 'анализ ЗЗ тип = 0,позиция вообще не принята и тип ПУО входит в codelkup.notes(поставить на балансы)'
    		    update  WH2.RECEIPTDETAIL
    		    set	    STATUS = '9'
    		    where   RECEIPTKEY = @receiptkey
    			    and STATUS = '11'
    		    
    		    update  WH2.RECEIPT
    		    set	    STATUS = '9'
    		    where   RECEIPTKEY = @receiptkey
    			    and STATUS = '11'
    			    
		    select  top 1 
			    @poid = id 
		    from    #ned55
    	
		    select  @polinenumber = MAX(cast(p.POLINENUMBER as int))
		    from    WH2.PODETAIL p
			    join (select pokey from #ned55 where id = @poid) pp
				    on pp.pokey = p.pokey
    	
		   insert into WH2.PODETAIL 
		    (WHSEID,pokey,EXTERNPOKEY,POLINENUMBER,EXTERNLINENO,QTYRECEIVED,SKU,SKUDESCRIPTION,STORERKEY,SUSR4,PACKKEY,UOM,ALTSKU,
		    lottable01, LOTTABLE02, lottable04, lottable05, lottable06,ADDWHO)
    		
		    select  'WH2',n.pokey,externpokey,
			    REPLICATE('0',5 - LEN(@polinenumber+1)) + CAST(@polinenumber+1 as varchar(10)) as polinenumber,
			    n.EXTERNLINENO,
			    n.QTYORDERED as qtyreceived,n.sku,LEFT(s.DESCR,60) as descr,n.storerkey,'LOSTPRIEM' as sclad,s.packkey,
			    s.RFDEFAULTUOM,IsNull(r.ALTSKU,s.ALTSKU) as ALTSKU,
--			    n.lottable01, n.LOTTABLE02, n.lottable04, n.lottable05, n.lottable06,'asnclosed'
			n.lottable01, 'НедовложенияПост', '18781218 00:00', '18781218 00:00', n.lottable06,'asnclosed'
		    from    #ned55 n
			    left join (
			    	    select  sku,storerkey,max(ALTSKU) as ALTSKU
			    	    from    WH2.RECEIPTDETAIL 
			    	    where   RECEIPTKEY = @receiptkey
			    		    and IsNull(ALTSKU,'') <> '' 
			    	    group by sku,storerkey
				)r
				on n.sku = r.SKU 
			        and n.storerkey = r.storerkey
			    join WH2.sku s 
			        on n.sku = s.SKU 
			        and n.storerkey = s.storerkey
		    where   n.id = @poid
		    
		    if @@ERROR <> 0
		    begin	    
    			print 'анализ ЗЗ тип = 0,позиция вообще не принята и тип ПУО входит в codelkup.notes(поставить на балансы) - не вставили в podetail'
			set @error = 2
			goto endproc			
    	    
		    end   		
    		
		    delete from #ned55 where id = @poid
		    --delete from #t1						
    	
	    end
    	
    	
	    /*select  pd.*
	    into    #ned
	    from    WH2.PO p
		    join WH2.PODETAIL pd
			on pd.POKEY = p.POKEY
		    join #pokey po
			on po.pokey = p.POKEY
			and po.potype = '0'
    	
	    --выбираем из podetail строчки, которые вообще не приняты			
	    select  IDENTITY(int,1,1) as id,
		    n.*
	    into    #ned2
	    from    #ned n
		    left join #ned nn
			on nn.POKEY = n.POKEY
			and nn.STORERKEY = n.STORERKEY
			and nn.SKU = n.SKU
			and nn.lottable02 = n.lottable02
			and nn.lottable06 = n.lottable06
			and nn.SUSR4 in ('SD','GENERAL','BRAKPRIEM')			
			and nn.QTYRECEIVED > 0
	    where   nn.POKEY is null
		    and n.QTYORDERED > 0
    	
	    while exists (select 1 from #ned2)
	    begin
    		
		    select  top 1 
			    @poid = id 
		    from    #ned2
    	
		    select  @polinenumber = MAX(cast(p.POLINENUMBER as int))
		    from    WH2.PODETAIL p
			    join (select pokey from #ned2 where id = @poid) pp
				    on pp.pokey = p.pokey
    	
		    insert into WH2.PODETAIL 
		    (WHSEID,pokey,EXTERNPOKEY,POLINENUMBER,EXTERNLINENO,QTYRECEIVED,SKU,SKUDESCRIPTION,STORERKEY,SUSR4,PACKKEY,UOM,ALTSKU,
		    lottable01, LOTTABLE02, lottable04, lottable05, lottable06,ADDWHO)
    		
		    select  'WH2',pokey,externpokey,
			    REPLICATE('0',5 - LEN(@polinenumber+1)) + CAST(@polinenumber+1 as varchar(10)) as polinenumber,
			    REPLICATE('0',5 - LEN(@polinenumber+1)) + CAST(@polinenumber+1 as varchar(10)) as EXTERNLINENO,
			    0 as qtyreceived,n.sku,LEFT(s.DESCR,60) as descr,n.storerkey,'GENERAL' as sclad,s.packkey,s.RFDEFAULTUOM,s.ALTSKU,
			    n.lottable01, n.LOTTABLE02, n.lottable04, n.lottable05, n.lottable06,'asnclosed'
		    from    #ned2 n
			    join WH2.sku s 
				on n.sku = s.SKU 
				and n.storerkey = s.storerkey
		    where   id = @poid
		    
		    if @@ERROR <> 0
		    begin	    
    			    print 'анализ ЗЗ тип = 0,ошибка'
			    set @error = 1
			    goto endproc			
    	    
		    end
    		
    		
		    delete from #ned2 where id = @poid					
    	
	    end*/

    end
    
    if @error = 0
    begin

	    commit tran

    end

    if exists (select 1 from #pokey where potype <> '0')    
    begin

	    select  pd.POKEY,pd.EXTERNPOKEY,pd.EXTERNLINENO,pd.STORERKEY,pd.SKU, pd.QTYORDERED,
		    --sum(pd.QTYRECEIVED) as QTYRECEIVED,
		    pd.QTYRECEIVED,
		    pd.lottable01, pd.LOTTABLE02, pd.lottable04, pd.lottable05, pd.lottable06,
		    pd.SUSR4,
		    case    when c.NOTES like '1' then 1
			    else 0
		    end as notes
	    into    #ned3
	    from    WH2.PO p
		    join WH2.PODETAIL pd
			on pd.POKEY = p.POKEY
		    join #pokey po
			on po.pokey = p.POKEY
			and po.potype <> '0'
		    join WH2.CODELKUP c 
			on c.CODE = p.potype 
			and C.LISTNAME = 'potype'
			--and c.NOTES like '1'
	    --where	pd.SUSR4 in ('SD','GENERAL','BRAKPRIEM')
	    --group by pd.POKEY,pd.EXTERNPOKEY,pd.STORERKEY,pd.SKU, pd.QTYORDERED,
	    --		 pd.lottable01, pd.LOTTABLE02, pd.lottable04, pd.lottable05, pd.lottable06
    	
    	
	    select  IDENTITY(int,1,1) as id,
		    n.POKEY,n.EXTERNPOKEY,n.EXTERNLINENO,n.STORERKEY,n.SKU,n.QTYORDERED,nn.QTYRECEIVED,
		    nn.lottable01, nn.LOTTABLE02, nn.lottable04, nn.lottable05, nn.lottable06
	    into    #ned4
	    from    (select pokey,EXTERNPOKEY,EXTERNLINENO,STORERKEY,SKU,sum(QTYORDERED) as qtyordered,
			    lottable01, LOTTABLE02, lottable04, lottable05, lottable06 
	             from   #ned3
	             where  notes = 1
	    		    and QTYORDERED > 0
		    group by pokey,EXTERNPOKEY,EXTERNLINENO,STORERKEY,SKU,
			    lottable01, LOTTABLE02, lottable04, lottable05, lottable06
		    ) n
		    join (select pokey,EXTERNPOKEY,STORERKEY,SKU,sum(QTYRECEIVED) as QTYRECEIVED,
				lottable01, LOTTABLE02, lottable04, lottable05, lottable06 
			from #ned3
			where SUSR4 in ('SD','GENERAL','BRAKPRIEM')
			    and notes = 1
			    and QTYRECEIVED > 0
			group by pokey,EXTERNPOKEY,STORERKEY,SKU,
				lottable01, LOTTABLE02, lottable04, lottable05, lottable06
			) nn
			    on nn.POKEY = n.POKEY
			    and nn.STORERKEY = n.STORERKEY
			    and nn.SKU = n.SKU
			    and nn.lottable02 = n.lottable02
			    and nn.lottable06 like n.lottable06	+'%'		 
	    where   n.QTYORDERED > nn.QTYRECEIVED	    --позиция не полностью принята и тип ПУО входит в codelkup.notes(поставить на балансы)
		    --and nn.QTYRECEIVED > 0
    			
    			
	    select  IDENTITY(int,1,1) as id,
		    n.POKEY,n.EXTERNPOKEY,n.EXTERNLINENO,n.STORERKEY,n.SKU,n.QTYORDERED,nn.QTYRECEIVED,
		    n.lottable01, n.LOTTABLE02, n.lottable04, n.lottable05, n.lottable06
	    into    #ned5
	    from    (select pokey,EXTERNPOKEY,EXTERNLINENO,STORERKEY,SKU,sum(QTYORDERED) as qtyordered,
			    lottable01, LOTTABLE02, lottable04, lottable05, lottable06 
	             from   #ned3
	             where  notes = 1
			    and QTYORDERED > 0
		    group by pokey,EXTERNPOKEY,EXTERNLINENO,STORERKEY,SKU,
			    lottable01, LOTTABLE02, lottable04, lottable05, lottable06
		    ) n
		    left join (select pokey,EXTERNPOKEY,STORERKEY,SKU,sum(QTYRECEIVED) as QTYRECEIVED,
				    lottable01, LOTTABLE02, lottable04, lottable05, lottable06 
				from #ned3
				where SUSR4 in ('SD','GENERAL','BRAKPRIEM')
				    and notes = 1
				    and QTYRECEIVED > 0
				group by pokey,EXTERNPOKEY,STORERKEY,SKU,
					lottable01, LOTTABLE02, lottable04, lottable05, lottable06
				    ) nn
			    on nn.POKEY = n.POKEY
			    and nn.STORERKEY = n.STORERKEY
			    and nn.SKU = n.SKU
			    and nn.lottable02 = n.lottable02
			    and nn.lottable06 like n.lottable06	+'%'		 
	    where   nn.POKEY is null			--позиция вообще не принята и тип ПУО входит в codelkup.notes(поставить на балансы)
    			
    				
	    /*select  IDENTITY(int,1,1) as id,
		    n.POKEY,n.EXTERNPOKEY,n.EXTERNLINENO,n.STORERKEY,n.SKU,n.QTYORDERED,nn.QTYRECEIVED,
		    n.lottable01, n.LOTTABLE02, n.lottable04, n.lottable05, n.lottable06
	    into    #ned6
	    from	(select pokey,EXTERNPOKEY,EXTERNLINENO,STORERKEY,SKU,sum(QTYORDERED) as qtyordered,
			    lottable01, LOTTABLE02, lottable04, lottable05, lottable06 
	        	 from	#ned3
	        	 where	notes = 0
				and QTYORDERED > 0
		    group by pokey,EXTERNPOKEY,EXTERNLINENO,STORERKEY,SKU,
			    lottable01, LOTTABLE02, lottable04, lottable05, lottable06
		    ) n
		    left join (select pokey,EXTERNPOKEY,STORERKEY,SKU,sum(QTYRECEIVED) as QTYRECEIVED,
				    lottable01, LOTTABLE02, lottable04, lottable05, lottable06 
				from #ned3
				where SUSR4 in ('SD','GENERAL','BRAKPRIEM')
				    and notes = 0
				     and QTYRECEIVED > 0
				group by pokey,EXTERNPOKEY,STORERKEY,SKU,
					lottable01, LOTTABLE02, lottable04, lottable05, lottable06
				    ) nn
			    on nn.POKEY = n.POKEY
			    and nn.STORERKEY = n.STORERKEY
			    and nn.SKU = n.SKU
			    and nn.lottable02 = n.lottable02
			    and nn.lottable06 = n.lottable06			 
	    where   nn.POKEY is null				--позиция вообще не принята и тип ПУО не входит в codelkup.notes
	    */
	    
	    /*select  IDENTITY(int,1,1) as id,
		    n.POKEY,n.EXTERNPOKEY,n.STORERKEY,n.SKU,nn.QTYORDERED,n.QTYRECEIVED,
		    nn.lottable01, nn.LOTTABLE02, nn.lottable04, nn.lottable05, nn.lottable06
	    into    #ned7
	    from    (
	    		select pokey,EXTERNPOKEY,STORERKEY,SKU,sum(QTYRECEIVED) as QTYRECEIVED,
			    lottable01, LOTTABLE02, lottable04, lottable05, lottable06 
			from #ned3
			where SUSR4 in ('SD','GENERAL','BRAKPRIEM')
			    and notes = 0
			    and QTYRECEIVED > 0
			group by pokey,EXTERNPOKEY,STORERKEY,SKU,
				lottable01, LOTTABLE02, lottable04, lottable05, lottable06
		    ) n
		    left join (				
				select pokey,EXTERNPOKEY,STORERKEY,SKU,sum(QTYORDERED) as qtyordered,
					lottable01, LOTTABLE02, lottable04, lottable05, lottable06 
				 from   #ned3
				 where  notes = 0
					and QTYORDERED > 0
				group by pokey,EXTERNPOKEY,STORERKEY,SKU,
					lottable01, LOTTABLE02, lottable04, lottable05, lottable06
				    ) nn
			    on nn.POKEY = n.POKEY
			    and nn.STORERKEY = n.STORERKEY
			    and nn.SKU = n.SKU
			    and nn.lottable02 = n.lottable02
			    and nn.lottable06 = n.lottable06			 
	    where   nn.POKEY is null				--позиция принята не с ожидаемыми атрибутами и тип ПУО не входит в codelkup.notes
	    
	    
    	*/
    	
    	    declare @storerkey varchar(20),
    		    --@sku varchar(50),
    		    @qty varchar(30),
    		    @toloc varchar(30),
    		    @tolot varchar(30),
    		    @toid varchar(30),
    		    @packkey varchar(30),
    		    @uom varchar(30),
    		    @lot01 varchar(50),
    		    @lot02 varchar(50),
    		    @lot04 varchar(50),
    		    @lot05 varchar(50),
    		    @lot06 varchar(50)
    		    
	    create table #t1
	    (mess varchar(max))
    	
	    while exists (select 1 from #ned4)
	    begin
    		--позиция не полностью принята и тип ПУО входит в codelkup.notes(поставить на балансы)   		
    		    print 'анализ ЗЗ тип <> 0,позиция не полностью принята и тип ПУО входит в codelkup.notes(поставить на балансы)'
    		    update  WH2.RECEIPTDETAIL
    		    set	    STATUS = '9'
    		    where   RECEIPTKEY = @receiptkey
    			    and STATUS = '11'
    		    
    		    update  WH2.RECEIPT
    		    set	    STATUS = '9'
    		    where   RECEIPTKEY = @receiptkey
    			    and STATUS = '11'
		
		    select  top 1 
			    @poid = id 
		    from    #ned4
    	
		    select  @polinenumber = MAX(cast(p.POLINENUMBER as int))
		    from    WH2.PODETAIL p
			    join (select pokey from #ned4 where id = @poid) pp
				    on pp.pokey = p.pokey
    	
		    insert into WH2.PODETAIL 
		    (WHSEID,pokey,EXTERNPOKEY,POLINENUMBER,EXTERNLINENO,QTYRECEIVED,SKU,SKUDESCRIPTION,STORERKEY,SUSR4,PACKKEY,UOM,ALTSKU,
		    lottable01, LOTTABLE02, lottable04, lottable05, lottable06,ADDWHO)
    		
		    select  'WH2',n.pokey,externpokey,
			    REPLICATE('0',5 - LEN(@polinenumber+1)) + CAST(@polinenumber+1 as varchar(10)) as polinenumber,
			    --REPLICATE('0',5 - LEN(@polinenumber+1)) + CAST(@polinenumber+1 as varchar(10)) as EXTERNLINENO,
			    n.EXTERNLINENO,
			    n.QTYORDERED - n.QTYRECEIVED as qtyreceived,n.sku,LEFT(s.DESCR,60) as descr,n.storerkey,'LOSTPRIEM' as sclad,s.packkey,
			    s.RFDEFAULTUOM,IsNull(r.ALTSKU,s.ALTSKU) as ALTSKU,
			    n.lottable01, n.LOTTABLE02, n.lottable04, n.lottable05, n.lottable06,'asnclosed'
		    from    #ned4 n
			    left join (
			    	    select sku,storerkey,max(ALTSKU) as ALTSKU
			    	    from WH2.RECEIPTDETAIL 
			    	    where RECEIPTKEY = @receiptkey
			    		   and IsNull(ALTSKU,'') <> '' 
			    	    group by sku,storerkey
				)r
				on n.sku = r.SKU 
			        and n.storerkey = r.storerkey			        	
			    join WH2.sku s 
			        on n.sku = s.SKU 
			        and n.storerkey = s.storerkey		        
		    where   n.id = @poid   		
		    
		    
		    if @@ERROR <> 0
		    begin	    
    			
			print 'анализ ЗЗ тип <> 0,позиция не полностью принята и тип ПУО входит в codelkup.notes(поставить на балансы) - не вставили в podetail'
			set @error = 2
			goto endproc			
    	    
		    end
		    
		    /*select  top 1			    
			    @storerkey = n.storerkey,@sku = n.sku,@pokey = 'NOPO',			
			    @qty = n.QTYORDERED - n.QTYRECEIVED,@toloc = 'LOSTPRIEM',
			    @tolot = r.TOLOT,@toid = '1_'+cast(n.id as varchar(5))+'_'+@receiptkey,
			    @packkey = s.packkey,@uom = s.RFDEFAULTUOM,
			    @lot01 = n.lottable01, @lot02 = n.LOTTABLE02, 
			    @lot04 = case   when n.lottable04 is null then ''
					    when n.lottable04 is not null then convert(varchar(15),n.lottable04,103)
					    else ''
				    end,				    
			    @lot05 = case   when n.lottable05 is null then ''
					    when n.lottable05 is not null then convert(varchar(15),n.lottable05,103)
					    else ''
				    end, 
			    @lot06 = n.lottable06
		    from    #ned4 n
			    join WH2.sku s 
				on n.sku = s.SKU 
				and n.storerkey = s.storerkey
			    left join (select STORERKEY,SKU,TOLOT,TOID,LOTTABLE02,LOTTABLE06 
				       from WH2.RECEIPTDETAIL 
				       where RECEIPTKEY = @receiptkey and QTYRECEIVED > 0) r
				    on r.STORERKEY = n.STORERKEY
				    and r.SKU = n.SKU
				    and r.LOTTABLE02 = n.LOTTABLE02
				    and r.LOTTABLE06 = n.LOTTABLE06
		    where   n.id = @poid
		    
		    select @text = 'java -classpath c:\DA_Axap\DKInforDA.jar -DconfigPath=c:\DA_Axap\DKInforDA.properties dke.da.trident.ExceedServerCall Receipt PRD2_WH2 asnclosed '+ @receiptkey+',001,'+@tolot+','+@receiptkey+','+@sku+','+@pokey+','+@qty+','+@uom+','+@packkey+','+@toloc+','+@toid+',,N,,'+@lot01+','+@lot02+',,'+@lot04+','+@lot05+','+@lot06+',,,,,,,,,,0,,0,,,,,,'
		   
		    print 'анализ ЗЗ тип <> 0,1 - поставить на балансы'
		    insert into #t1 
		    exec xp_cmdshell @text
		    --exec xp_cmdshell 'java -classpath c:\dataadapter\DKInforDA.jar -DconfigPath=c:\dataadapter\DKInforDA.properties dke.da.trident.ExceedServerCall Receipt PRD2_WH2 asnclosed @receiptkey,@storerkey,@tolot,@receiptkey,@sku,,@qtyreceived,@uom,@packkey,@toloc,@toid,,N,,@lot01,@lot02,,@lot04,@lot05,@lot06,,,,,,,,,,0,,0,,,,,,'
		    
		    print 'анализ ЗЗ тип <> 0,1 - вставка dbo.da_CloseASN'
		    
		    insert into dbo.da_CloseASN
		    (receiptkey,message)		     		    
		    select  @receiptkey,'1/ '+ mess 
		    from    #t1
		    
		    
		    if not EXISTS (select 1 from #t1 where mess like 'Receipt Result: NO ERROR%')
		    begin
		    	print '1_Receipt Result:ERROR'    			
			set @error = 2
			goto endproc			
    	    
		    end*/
		    
		    /*select  @receiptlinenumber = MAX(cast(RECEIPTLINENUMBER as int))
		    from    WH2.RECEIPTDETAIL
		    where   RECEIPTKEY = @receiptkey
    		
    		
		    insert into WH2.RECEIPTDETAIL
		    (WHSEID,RECEIPTKEY,RECEIPTLINENUMBER,STORERKEY,SKU,QTYRECEIVED,status,TOLOC,TOLOT,TOID,PACKKEY,UOM,
		    LOTTABLE01,LOTTABLE02,LOTTABLE04,LOTTABLE05,LOTTABLE06,ADDWHO)
    		
		    select  'WH2' as WHSEID,@receiptkey,
			    REPLICATE('0',5 - LEN(@receiptlinenumber+1)) + CAST(@receiptlinenumber+1 as varchar(10)) as RECEIPTLINENUMBER,
			    n.storerkey,n.sku,			
			    n.QTYORDERED - n.QTYRECEIVED as qtyreceived,'11' as status,'LOSTPRIEM' as toloc,r.TOLOT,r.TOID,
			    s.packkey,s.RFDEFAULTUOM,
			    n.lottable01, n.LOTTABLE02, n.lottable04, n.lottable05, n.lottable06,'asnclosed'
		    from    #ned4 n
			    join WH2.sku s 
				on n.sku = s.SKU 
				and n.storerkey = s.storerkey
			    left join (select STORERKEY,SKU,TOLOT,TOID,LOTTABLE02,LOTTABLE06 
				       from WH2.RECEIPTDETAIL 
				       where RECEIPTKEY = @receiptkey and QTYRECEIVED > 0) r
				    on r.STORERKEY = n.STORERKEY
				    and r.SKU = n.SKU
				    and r.LOTTABLE02 = n.LOTTABLE02
				    and r.LOTTABLE06 = n.LOTTABLE06
		    where   n.id = @poid
    		
    		if @@ERROR <> 0
		begin	    
			
			set @error = 1
			goto endproc			
	    
		end*/
	    
		delete from #ned4 where id = @poid
		delete from #t1					
    	
	    end
    	
	    while exists (select 1 from #ned5)
	    begin
    		--позиция вообще не принята и тип ПУО входит в codelkup.notes(поставить на балансы)
    		print 'анализ ЗЗ тип <> 0,позиция вообще не принята и тип ПУО входит в codelkup.notes(поставить на балансы)'
    		    update  WH2.RECEIPTDETAIL
    		    set	    STATUS = '9'
    		    where   RECEIPTKEY = @receiptkey
    			    and STATUS = '11'
    		    
    		    update  WH2.RECEIPT
    		    set	    STATUS = '9'
    		    where   RECEIPTKEY = @receiptkey
    			    and STATUS = '11'
    			    
		    select  top 1 
			    @poid = id 
		    from    #ned5
    	
		    select  @polinenumber = MAX(cast(p.POLINENUMBER as int))
		    from    WH2.PODETAIL p
			    join (select pokey from #ned5 where id = @poid) pp
				    on pp.pokey = p.pokey
    	
		    insert into WH2.PODETAIL 
		    (WHSEID,pokey,EXTERNPOKEY,POLINENUMBER,EXTERNLINENO,QTYRECEIVED,SKU,SKUDESCRIPTION,STORERKEY,SUSR4,PACKKEY,UOM,ALTSKU,
		    lottable01, LOTTABLE02, lottable04, lottable05, lottable06,ADDWHO)
    		
		    select  'WH2',n.pokey,externpokey,
			    REPLICATE('0',5 - LEN(@polinenumber+1)) + CAST(@polinenumber+1 as varchar(10)) as polinenumber,
			    --REPLICATE('0',5 - LEN(@polinenumber+1)) + CAST(@polinenumber+1 as varchar(10)) as EXTERNLINENO,
			    n.EXTERNLINENO,
			    n.QTYORDERED as qtyreceived,n.sku,LEFT(s.DESCR,60) as descr,n.storerkey,'LOSTPRIEM' as sclad,s.packkey,
			    s.RFDEFAULTUOM,IsNull(r.ALTSKU,s.ALTSKU) as ALTSKU,
			    n.lottable01, n.LOTTABLE02, n.lottable04, n.lottable05, n.lottable06,'asnclosed'
		    from    #ned5 n
			    left join (
			    	    select sku,storerkey,max(ALTSKU) as ALTSKU
			    	    from WH2.RECEIPTDETAIL 
			    	    where RECEIPTKEY = @receiptkey
			    		   and IsNull(ALTSKU,'') <> '' 
			    	    group by sku,storerkey
				)r
				on n.sku = r.SKU 
			        and n.storerkey = r.storerkey
			    join WH2.sku s 
			        on n.sku = s.SKU 
			        and n.storerkey = s.storerkey
		    where   n.id = @poid
		    
		    if @@ERROR <> 0
		    begin	    
    			print 'анализ ЗЗ тип <> 0,позиция вообще не принята и тип ПУО входит в codelkup.notes(поставить на балансы) - не вставили в podetail'
			set @error = 2
			goto endproc			
    	    
		    end
		    
		    /*select  top 1			    
			    @storerkey = n.storerkey,@sku = n.sku,@pokey = 'NOPO',			
			    @qty = n.QTYORDERED - n.QTYRECEIVED,@toloc = 'LOSTPRIEM',
			    @tolot = r.TOLOT,@toid = '2_'+cast(n.id as varchar(5))+'_'+@receiptkey,
			    @packkey = s.packkey,@uom = s.RFDEFAULTUOM,
			    @lot01 = n.lottable01, @lot02 = n.LOTTABLE02, 
			    @lot04 = case   when n.lottable04 is null then ''
					    when n.lottable04 is not null then convert(varchar(15),n.lottable04,103)
					    else ''
				    end, 
				    
			    @lot05 = case   when n.lottable05 is null then ''
					    when n.lottable05 is not null then convert(varchar(15),n.lottable05,103)
					    else ''
				    end, 
			    @lot06 = n.lottable06
		    from    #ned5 n
			    join WH2.sku s 
			        on n.sku = s.SKU 
			        and n.storerkey = s.storerkey
			    left join (select STORERKEY,SKU,TOLOT,TOID,LOTTABLE02,LOTTABLE06 
				       from WH2.RECEIPTDETAIL 
				       where RECEIPTKEY = @receiptkey and QTYRECEIVED > 0) r
			        on r.STORERKEY = n.STORERKEY
			        and r.SKU = n.SKU
			        and r.LOTTABLE02 = n.LOTTABLE02
			        and r.LOTTABLE06 = n.LOTTABLE06
		    where   n.id = @poid
		    
		    select @text = 'java -classpath c:\DA_Axap\DKInforDA.jar -DconfigPath=c:\DA_Axap\DKInforDA.properties dke.da.trident.ExceedServerCall Receipt PRD2_WH2 asnclosed '+ @receiptkey+',001,'+@tolot+','+@receiptkey+','+@sku+','+@pokey+','+@qty+','+@uom+','+@packkey+','+@toloc+','+@toid+',,N,,'+@lot01+','+@lot02+',,'+@lot04+','+@lot05+','+@lot06+',,,,,,,,,,0,,0,,,,,,'
	   
		    print 'анализ ЗЗ тип <> 0,2 - поставить на балансы'
		    insert into #t1 
		    exec xp_cmdshell @text
		    --exec xp_cmdshell 'java -classpath c:\dataadapter\DKInforDA.jar -DconfigPath=c:\dataadapter\DKInforDA.properties dke.da.trident.ExceedServerCall Receipt PRD2_WH2 asnclosed @receiptkey,@storerkey,@tolot,@receiptkey,@sku,,@qtyreceived,@uom,@packkey,@toloc,@toid,,N,,@lot01,@lot02,,@lot04,@lot05,@lot06,,,,,,,,,,0,,0,,,,,,'
		    
		    print 'анализ ЗЗ тип <> 0,2 - вставка dbo.da_CloseASN'
		    insert into dbo.da_CloseASN
		    (receiptkey,message)		     		    
		    select  @receiptkey,'2/ '+ mess 
		    from    #t1
		    
		    
		    if not EXISTS (select 1 from #t1 where mess like 'Receipt Result: NO ERROR%')
		    begin
		    	print '2_Receipt Result:ERROR'     			
			set @error = 2
			goto endproc			
    	    
		    end*/
    		
		    /*select  @receiptlinenumber = MAX(cast(RECEIPTLINENUMBER as int))
		    from    WH2.RECEIPTDETAIL
		    where   RECEIPTKEY = @receiptkey
    		
    		
		    insert into WH2.RECEIPTDETAIL
		    (WHSEID,RECEIPTKEY,RECEIPTLINENUMBER,STORERKEY,SKU,QTYRECEIVED,status,TOLOC,TOLOT,TOID,PACKKEY,UOM,
		    LOTTABLE01,LOTTABLE02,LOTTABLE04,LOTTABLE05,LOTTABLE06,ADDWHO)
    		
		    select  'WH2' as WHSEID,@receiptkey,
			    REPLICATE('0',5 - LEN(@receiptlinenumber+1)) + CAST(@receiptlinenumber+1 as varchar(10)) as RECEIPTLINENUMBER,
			    n.storerkey,n.sku,			
			    n.QTYORDERED as qtyreceived,'11' as status,'LOSTPRIEM' as toloc,r.TOLOT,r.TOID,
			    s.packkey,s.RFDEFAULTUOM,
			    n.lottable01, n.LOTTABLE02, n.lottable04, n.lottable05, n.lottable06,'asnclosed'
		    from    #ned5 n
			    join WH2.sku s 
			        on n.sku = s.SKU 
			        and n.storerkey = s.storerkey
			    left join (select STORERKEY,SKU,TOLOT,TOID,LOTTABLE02,LOTTABLE06 
				       from WH2.RECEIPTDETAIL 
				       where RECEIPTKEY = @receiptkey and QTYRECEIVED > 0) r
			        on r.STORERKEY = n.STORERKEY
			        and r.SKU = n.SKU
			        and r.LOTTABLE02 = n.LOTTABLE02
			        and r.LOTTABLE06 = n.LOTTABLE06
		    where   n.id = @poid
		    
		    if @@ERROR <> 0
		    begin	    
    			
			    set @error = 1
			    goto endproc			
    	    
		    end*/
    		
    		
		    delete from #ned5 where id = @poid
		    delete from #t1						
    	
	    end
    	
	    /*while exists (select 1 from #ned6)
	    begin
    		--позиция вообще не принята и тип ПУО не входит в codelkup.notes
    		print 'анализ ЗЗ тип <> 0,позиция вообще не принята и тип ПУО не входит в codelkup.notes'
		    select  top 1 
			    @poid = id 
		    from    #ned6
    	
		    select  @polinenumber = MAX(cast(p.POLINENUMBER as int))
		    from    WH2.PODETAIL p
			    join (select pokey from #ned6 where id = @poid) pp
				    on pp.pokey = p.pokey
    	
		    insert into WH2.PODETAIL 
		    (WHSEID,pokey,EXTERNPOKEY,POLINENUMBER,EXTERNLINENO,QTYRECEIVED,SKU,SKUDESCRIPTION,STORERKEY,SUSR4,PACKKEY,UOM,ALTSKU,
		    lottable01, LOTTABLE02, lottable04, lottable05, lottable06,ADDWHO)
    		
		    select  'WH2',pokey,externpokey,
			    REPLICATE('0',5 - LEN(@polinenumber+1)) + CAST(@polinenumber+1 as varchar(10)) as polinenumber,
			    REPLICATE('0',5 - LEN(@polinenumber+1)) + CAST(@polinenumber+1 as varchar(10)) as EXTERNLINENO,
			    0 as qtyreceived,n.sku,LEFT(s.DESCR,60) as descr,n.storerkey,'GENERAL' as sclad,s.packkey,
			    s.RFDEFAULTUOM,s.ALTSKU,
			    n.lottable01, n.LOTTABLE02, n.lottable04, n.lottable05, n.lottable06,'asnclosed'
		    from    #ned6 n
			    join WH2.sku s 
				on n.sku = s.SKU 
				and n.storerkey = s.storerkey
		    where   n.id = @poid	
    		
    		if @@ERROR <> 0
		begin
		    print 'анализ ЗЗ тип <> 0,позиция вообще не принята и тип ПУО не входит в codelkup.notes - не вставили в podetail'	    
		    set @error = 2
		    goto endproc	    
		end
		
		delete from #ned6 where id = @poid					
    	
	    end
	    */
	    
	   /* while exists (select 1 from #ned7)
	    begin
    		--позиция принята не с ожидаемыми атрибутами и тип ПУО не входит в codelkup.notes
		    select  top 1 
			    @poid = id 
		    from    #ned7
    	
		    select  @polinenumber = MAX(cast(p.POLINENUMBER as int))
		    from    WH2.PODETAIL p
			    join (select pokey from #ned7 where id = @poid) pp
				    on pp.pokey = p.pokey
    	
		    insert into WH2.PODETAIL 
		    (pokey,EXTERNPOKEY,POLINENUMBER,EXTERNLINENO,qtyordered,SKU,SKUDESCRIPTION,STORERKEY,SUSR4,PACKKEY,UOM,ALTSKU,
		    lottable01, LOTTABLE02, lottable04, lottable05, lottable06,ADDWHO)
    		
		    select  pokey,externpokey,
			    REPLICATE('0',5 - LEN(@polinenumber+1)) + CAST(@polinenumber+1 as varchar(10)) as polinenumber,
			    REPLICATE('0',5 - LEN(@polinenumber+1)) + CAST(@polinenumber+1 as varchar(10)) as EXTERNLINENO,
			    n.QTYORDERED as QTYORDERED,n.sku,LEFT(s.DESCR,60) as descr,n.storerkey,'GENERAL' as sclad,s.packkey,
			    s.RFDEFAULTUOM,s.ALTSKU,
			    n.lottable01, n.LOTTABLE02, n.lottable04, n.lottable05, n.lottable06,'asnclosed'
		    from    #ned7 n
			    join WH2.sku s 
			        on n.sku = s.SKU 
			        and n.storerkey = s.storerkey
		    where   n.id = @poid	
    		
    		if @@ERROR <> 0
			begin	    
				
				set @error = 1
				goto endproc			
		    
			end
    		
		    delete from #ned7 where id = @poid					
    	
	    end*/
    	
    	

    end
    				
    print 'Закрываем ЗЗ и ПУО'
    update  p
    set	    status = '11'
    from    WH2.PODETAIL p
	    join #pokey pp
		on pp.pokey = p.POKEY	    
    	    
    update  p
    set	    status = '11', EDITDATE=GETDATE()
    from    WH2.PO p
	    join #pokey pp
		on pp.pokey = p.POKEY
		and p.POTYPE = pp.potype		
		
    update  WH2.RECEIPTDETAIL
    set	    STATUS = '11'
    where   RECEIPTKEY = @receiptkey
	    and STATUS = '9'
    
    update  WH2.RECEIPT
    set	    STATUS = '11'
    where   RECEIPTKEY = @receiptkey
	    and STATUS = '9'		
    	    
    	    
    select  p.EXTERNPOKEY, p.POTYPE, p.SELLERNAME, p.BUYERADDRESS4, p.SUSR2,
	    p2.SKU,p2.STORERKEY,p2.EXTERNLINENO, p2.QTYORDERED, p2.QTYRECEIVED,
	    p2.ALTSKU,
	    --p2.SUSR4,
	    case    when  p2.SUSR4 = 'GENERAL' then 'MSK_СкладПродаж'
		    when  p2.SUSR4 = 'BRAKPRIEM' then 'MSK_ПТВПостащика'
		    when  p2.SUSR4 = 'PRETENZ' then 'MSK_ПеревложенияПост'
		    when  p2.SUSR4 = 'LOSTPRIEM' then 'MSK_НедовложенияПост'
		    when  p2.SUSR4 = 'OVERPRIEM' then 'MSK_ПеревложенияПост'
		    when  p2.SUSR4 = 'SD' then 'MSK_СД'
	    end as SUSR4,
	    p2.LOTTABLE01, p2.LOTTABLE02, p2.LOTTABLE04, p2.LOTTABLE05,
	    p2.LOTTABLE06,p2.ADDWHO
    into    #itog	
    from    WH2.PO p
	    join WH2.PODETAIL p2
		on p2.POKEY = p.POKEY
    where   p.OTHERREFERENCE = @receiptkey


    select  identity(int,1,1) as id,
	    EXTERNPOKEY,POTYPE, SELLERNAME, BUYERADDRESS4, SUSR2
    into    #ii		
    from    (select distinct EXTERNPOKEY,POTYPE, SELLERNAME, BUYERADDRESS4, SUSR2 from #itog)i


    select  identity(int,1,1) as id,
	    EXTERNPOKEY,SKU,STORERKEY,EXTERNLINENO,QTYORDERED,QTYRECEIVED,
	    ALTSKU,
	    SUSR4, LOTTABLE01, LOTTABLE02,LOTTABLE04, LOTTABLE05,
	    LOTTABLE06
    into    #i		
    from    (
    	
    		select  EXTERNPOKEY,
			SKU,STORERKEY,EXTERNLINENO,QTYORDERED,QTYRECEIVED,
			ALTSKU,
			SUSR4, LOTTABLE01, LOTTABLE02,LOTTABLE04, LOTTABLE05,
			LOTTABLE06	
		from    #itog
    		where	addwho = 'asnclosed'
	  --  select	p.EXTERNPOKEY,
		 --   p.SKU,p.STORERKEY,p.EXTERNLINENO, p.QTYORDERED, pp.QTYRECEIVED,
		 --   p.ALTSKU,
		 --   pp.SUSR4, pp.LOTTABLE01, pp.LOTTABLE02, pp.LOTTABLE04, pp.LOTTABLE05,
		 --   pp.LOTTABLE06
	  --  from	(
		 --   select	EXTERNPOKEY,
			--    SKU,STORERKEY,EXTERNLINENO,QTYORDERED,
			--    ALTSKU,
			--    SUSR4, LOTTABLE01, LOTTABLE02,LOTTABLE04, LOTTABLE05,
			--    LOTTABLE06	
		 --   from	#itog
		 --   where	QTYORDERED > 0	
		 --   ) p
		 --   join (
			--select  EXTERNPOKEY,
			--	SKU,STORERKEY,EXTERNLINENO,QTYRECEIVED,
			--	ALTSKU,
			--	SUSR4, LOTTABLE01, LOTTABLE02,LOTTABLE04, LOTTABLE05,
			--	LOTTABLE06	
			--from    #itog
			--where   QTYRECEIVED > 0	
		 --   ) pp
		 --   on p.EXTERNPOKEY = pp.EXTERNPOKEY
		 --   and p.storerkey = pp.storerkey
		 --   and p.sku = pp.sku
		 --   and p.LOTTABLE02 = pp.LOTTABLE02
		 --   and p.LOTTABLE06 = pp.LOTTABLE06

	  --  union all	
            	
	  --  select	p.EXTERNPOKEY,
		 --   p.SKU,p.STORERKEY,p.EXTERNLINENO, 0  as QTYORDERED, p.QTYRECEIVED,
		 --   p.ALTSKU,
		 --   p.SUSR4, p.LOTTABLE01, p.LOTTABLE02, p.LOTTABLE04, p.LOTTABLE05,
		 --   p.LOTTABLE06
	  --  from	(
		 --   select	EXTERNPOKEY,
			--    SKU,STORERKEY,EXTERNLINENO,QTYRECEIVED,
			--    ALTSKU,
			--    SUSR4, LOTTABLE01, LOTTABLE02,LOTTABLE04, LOTTABLE05,
			--    LOTTABLE06	
		 --   from	#itog
		 --   where	QTYRECEIVED > 0	
		 --   ) p
		 --   left join (
			--select  EXTERNPOKEY,
			--	SKU,STORERKEY,EXTERNLINENO,QTYORDERED,
			--	ALTSKU,
			--	SUSR4, LOTTABLE01, LOTTABLE02,LOTTABLE04, LOTTABLE05,
			--	LOTTABLE06	
			--from    #itog
			--where   QTYORDERED > 0	
		 --   ) pp
		 --   on p.EXTERNPOKEY = pp.EXTERNPOKEY
		 --   and p.storerkey = pp.storerkey
		 --   and p.sku = pp.sku
		 --   and p.LOTTABLE02 = pp.LOTTABLE02
		 --   and p.LOTTABLE06 = pp.LOTTABLE06
	  --  where	pp.EXTERNPOKEY is null
	    )i	
    	    	  
--if @error = 0
--begin

--	commit tran

--end	    
    	    
    print 'Пытаемся вставить в обменные таблы DAX'	    
    declare @n bigint


    select  @n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
    from    [spb-sql1202].[DAX2009_1].[dbo].SZ_ImpInputOrdersFromWMS


    insert into [spb-sql1202].[DAX2009_1].[dbo].SZ_ImpInputOrdersFromWMS
    (DataAReaID, DocID, DocType, VendAccount, Invoiceid,
     inventLocationID, 
     Status,RecID)


    select  'SZ',EXTERNPOKEY,POTYPE, SELLERNAME, BUYERADDRESS4, SUSR2,
	    '5',
	    @n + id as recid
    from    #ii
    
    if @@ERROR <> 0
    begin	    
    	    print 'Пытаемся вставить в обменные таблы DAX - голова Ошибка'
	    --set @error = 1
	    goto endproc			

    end

    select  @n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
    from    [spb-sql1202].[DAX2009_1].[dbo].SZ_ImpInputOrderLinesFromWMS


update #i set LOTTABLE02=null where LOTTABLE02='' --Шевелев 24.03.2015
print 'Пытаемся вставить в обменные таблы DAX - после апдейта'
    
    insert into [spb-sql1202].[DAX2009_1].[dbo].SZ_ImpInputOrderLinesFromWMS
    (DataAReaID, DocID, ItemID, LineNumber,PackNormQty,OrderedQty,Qty,BarCodeString,
    InventLocationID,InventBatchID,InventSerialID,InventExpireDate,InventSerialProdDate,Status,RecID)

    select  --top 1
	    'SZ',
	    EXTERNPOKEY,SKU,EXTERNLINENO,
	    --Ошибка, не преобразуется в число (тип PackNormQty = число) Охунов 28.09.2015
	    --case when IsNull(LOTTABLE01,'') = '' then '0' else LOTTABLE01 end as LOTTABLE01,
	   case when IsNull(LOTTABLE01,'') = ''
	   OR ISNUMERIC(LOTTABLE01)=0 then 0 
	   else convert (int,left(replace(LOTTABLE01,',','.'),
	   case when charindex('.',replace(LOTTABLE01,',','.'))-1<1 then len(replace(LOTTABLE01,',','.'))
	   else  charindex('.',replace(LOTTABLE01,',','.'))-1 end)) end as LOTTABLE01,
	    QTYORDERED,QTYRECEIVED,
	    Isnull(ALTSKU,'') as ALTSKU,
	    SUSR4,IsNull(LOTTABLE06,'') as LOTTABLE06,IsNull(LOTTABLE02,'бс') as LOTTABLE02,
	    IsNull(LOTTABLE05,'1900-01-01') as LOTTABLE05,IsNull(LOTTABLE04,'1900-01-01') as LOTTABLE04,'5',@n + id as recid	
    from    #i
    
    if @@ERROR <> 0
    begin   	
	    print 'Пытаемся вставить в обменные таблы DAX - детали Ошибка'
	    --set @error = 1
	    goto endproc
    end
    
    
    if exists (select 1 from #i)
    begin
	print 'Создаем выходной датасет для ДА'
	
	update WH2.TRANSMITLOG
	set KEY5 = '1'
	where TRANSMITLOGKEY = @transmitlogkey	
	
	insert into #rt
	select	'ASNCLOSED' filetype,
		EXTERNPOKEY, POTYPE, SELLERNAME, BUYERADDRESS4, SUSR2,
		SKU,STORERKEY,EXTERNLINENO, QTYORDERED, QTYRECEIVED,
		ALTSKU,
		SUSR4, LOTTABLE01, LOTTABLE02, LOTTABLE04, LOTTABLE05,
		LOTTABLE06
	from	#itog	
	
	
	insert into #rt2
	select	'ASNCLOSED' filetype,
		EXTERNPOKEY, POTYPE, SELLERNAME, BUYERADDRESS4, SUSR2
	from	#ii
	
	insert into #rt3
	select	'ASNCLOSED' filetype,
		EXTERNPOKEY, SKU,STORERKEY,EXTERNLINENO, QTYORDERED, QTYRECEIVED,
		ALTSKU,
		SUSR4, LOTTABLE01, LOTTABLE02, LOTTABLE04, LOTTABLE05,
		LOTTABLE06
	from	#i
    	
    
    end

ELSE
PRINT 'НЕ ЗАШЛИ'
end



select * from #rt

select * from #rt2

select * from #rt3


endproc:
if @error = 1
begin
	
	rollback tran
	
end
if @error = 2
begin
	
	delete 
	from	WH2.RECEIPTDETAIL 
	where	(ADDWHO = 'asnclosed' or EDITWHO = 'asnclosed') 
		and RECEIPTKEY = @receiptkey
		
		
	delete	
	from	WH2.PODETAIL 
	from	WH2.PODETAIL po
		join WH2.PO p
		    on p.POKEY = po.POKEY
	where	(po.ADDWHO = 'asnclosed' or po.EDITWHO = 'asnclosed')
		and  p.OTHERREFERENCE = @receiptkey
	
end
	

--update WH2.TRANSMITLOG set ADDWHO = 'proc_DA_ReceiptConfirm' where TRANSMITLOGKEY  = @transmitlogkey

IF OBJECT_ID('tempdb..#tl') IS NOT NULL DROP TABLE #tl
IF OBJECT_ID('tempdb..#i') IS NOT NULL DROP TABLE #i
IF OBJECT_ID('tempdb..#ii') IS NOT NULL DROP TABLE #ii
IF OBJECT_ID('tempdb..#itog') IS NOT NULL DROP TABLE #itog
IF OBJECT_ID('tempdb..#ned') IS NOT NULL DROP TABLE #ned
IF OBJECT_ID('tempdb..#ned2') IS NOT NULL DROP TABLE #ned2
IF OBJECT_ID('tempdb..#ned3') IS NOT NULL DROP TABLE #ned3
IF OBJECT_ID('tempdb..#ned4') IS NOT NULL DROP TABLE #ned4
IF OBJECT_ID('tempdb..#ned5') IS NOT NULL DROP TABLE #ned5
IF OBJECT_ID('tempdb..#ned6') IS NOT NULL DROP TABLE #ned6
IF OBJECT_ID('tempdb..#podetail') IS NOT NULL DROP TABLE #podetail
IF OBJECT_ID('tempdb..#ned7') IS NOT NULL DROP TABLE #ned7
IF OBJECT_ID('tempdb..#pokey') IS NOT NULL DROP TABLE #pokey
IF OBJECT_ID('tempdb..#pr') IS NOT NULL DROP TABLE #pr
IF OBJECT_ID('tempdb..#pr_it') IS NOT NULL DROP TABLE #pr_it
IF OBJECT_ID('tempdb..#podetail') IS NOT NULL DROP TABLE #pr_it
IF OBJECT_ID('tempdb..#receiptdetail') IS NOT NULL DROP TABLE #receiptdetail
IF OBJECT_ID('tempdb..#rt') IS NOT NULL DROP TABLE #rt
IF OBJECT_ID('tempdb..#rt2') IS NOT NULL DROP TABLE #rt2
IF OBJECT_ID('tempdb..#rt3') IS NOT NULL DROP TABLE #rt3
IF OBJECT_ID('tempdb..#t1') IS NOT NULL DROP TABLE #t1
		


