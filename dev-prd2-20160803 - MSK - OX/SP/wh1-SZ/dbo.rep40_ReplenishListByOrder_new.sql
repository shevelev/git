ALTER PROCEDURE [dbo].[rep40_ReplenishListByOrder_new] (@ORDER varchar(30), @wh varchar(10))
--with encryption
as

declare @sql varchar(max)
set @sql='
create table #TMP  (
 LOCFROM   varchar(10)  COLLATE Cyrillic_General_CI_AS NOT NULL,
 LOTFROM   varchar(10)  COLLATE Cyrillic_General_CI_AS NULL,
 IDFROM    varchar(10)  COLLATE Cyrillic_General_CI_AS NOT NULL,
 STORER    varchar(15)  COLLATE Cyrillic_General_CI_AS NULL,
 SKU       varchar (10)  COLLATE Cyrillic_General_CI_AS NOT NULL,
 DESCR     varchar(300)  COLLATE Cyrillic_General_CI_AS NOT NULL,
 LOCTO   varchar(10)  COLLATE Cyrillic_General_CI_AS NOT NULL,
 QTY   float  NULL
  )
declare  @LOCFROM varchar(10),@LOTFROM varchar(10),@IDFROM varchar(10), @STORER varchar(15), @SKU varchar (10),@DESCR varchar(300),
         @LOCTO   varchar(10),@SKUVAL varchar(10),@STORERVAL varchar(15), @QTY float

declare OrdCur cursor for 
select distinct STORERKEY STORER,SKU 
        from '+@wh+'.ORDERDETAIL where ORDERKEY='''+@ORDER+'''

open OrdCur
fetch next from Ordcur into @STORERVAL,@SKUVAL
while @@FETCH_STATUS<>-1 
   begin

      declare MyCur cursor for  
      select top 1 S.LOC, S.STORERKEY STORER, S.SKU,K.DESCR from '+@wh+'.SKUxLOC S 
             join '+@wh+'.LOC L on  S.LOC=L.LOC and L.LOCATIONTYPE=''PICK''
             join '+@wh+'.PUTAWAYZONE P on L.PUTAWAYZONE=P.PUTAWAYZONE 
             join '+@wh+'.SKU K on S.SKU=K.SKU and S.STORERKEY=K.STORERKEY
      where  S.SKU=@SKUVAL and S.STORERKEY=@STORERVAL and S.ReplenishmentPriority<P.Replenishment_hotLevel 
             and S.ALLOWREPLENISHFROMBULK=1 and S.QTY=0
      
      open myCur 

      declare FromCur cursor for  
      select top 1 S.LOC, S.LOT, S.ID, S.QTY from '+@wh+'.LOTxLOCxID S 
      join '+@wh+'.LOC L on  S.LOC=L.LOC and s.status=''OK''
      where  S.SKU=@SKUVAL and S.STORERKEY=@STORERVAL and S.QTY>0 and L.LOCATIONTYPE=''CASE'' and S.QTYALLOCATED=0
	  order by S.QTY desc

      open FromCur 

      fetch next from Fromcur into @LOCFROM,@LOTFROM,@IDFROM,@QTY
      
      fetch next from Mycur into @LOCTO,@STORER,@SKU,@DESCR
      
      while @@FETCH_STATUS<>-1 
         begin
           insert into #TMP (LOCTO, STORER, SKU, DESCR, LOCFROM, LOTFROM, IDFROM, QTY) values (@LOCTO, @STORER, @SKU, @DESCR, @LOCFROM, @LOTFROM, @IDFROM, @QTY) 
           fetch next from Fromcur into @LOCFROM,@LOTFROM,@IDFROM,@QTY
           fetch next from Mycur into @LOCTO,@STORER,@SKU,@DESCR
         end
      
      close MyCur 

      deallocate MyCur

      close FromCur 

      deallocate FromCur

      fetch next from Ordcur into @STORERVAL,@SKUVAL
    end

close OrdCur 
deallocate OrdCur

SELECT loc into #holded FROM '+@wh+'.loc where locationflag in (''HOLD'',''DAMAGE'')

delete from #tmp where LOCTO in (select loc from #holded)
delete from #tmp where LOCFROM in (select loc from #holded)
	
--update #TMP
--set #TMP.LOTFROM=lld.lot
--from #TMP left join '+@wh+'.lotxlocxid on (#TMP.LOCFROM 

select * from #TMP

drop table [#TMP]
'
exec (@sql)

