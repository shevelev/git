ALTER PROCEDURE [dbo].[rep40_ReplenishListByOrder] (@ORDER varchar(30), @wh varchar(10))
--with encryption
as

declare @sql varchar(max)
set @sql='
create table #TMP  (
 LOCFROM   varchar(10)  COLLATE Cyrillic_General_CI_AS NOT NULL,
 IDFROM    varchar(10)  COLLATE Cyrillic_General_CI_AS NOT NULL,
 SKU       varchar (10)  COLLATE Cyrillic_General_CI_AS NOT NULL,
 DESCR     varchar(300)  COLLATE Cyrillic_General_CI_AS NOT NULL,
 LOCTO   varchar(10)  COLLATE Cyrillic_General_CI_AS NOT NULL
  )
declare  @LOCFROM varchar(10) ,@IDFROM varchar(10), @SKU varchar (10),@DESCR varchar(300),
         @LOCTO   varchar(10),@SKUVAL varchar(10)

declare OrdCur cursor for 

select distinct SKU 
        from '+@wh+'.ORDERDETAIL where ORDERKEY='''+@ORDER+'''

open OrdCur
fetch next from Ordcur into @SKUVAL
while @@FETCH_STATUS<>-1 
   begin

      declare MyCur cursor for  
      select S.LOC, S.SKU,K.DESCR from '+@wh+'.SKUxLOC S 
             join '+@wh+'.LOC L on  S.LOC=L.LOC and L.LOCATIONTYPE=''PICK''
             join '+@wh+'.PUTAWAYZONE P on L.PUTAWAYZONE=P.PUTAWAYZONE 
             join '+@wh+'.SKU K on S.SKU=K.SKU and S.STORERKEY=K.STORERKEY
      where  S.SKU=@SKUVAL and S.ReplenishmentPriority<P.Replenishment_hotLevel 
             and S.ALLOWREPLENISHFROMBULK=1
      
      open myCur 

      declare FromCur cursor for  
      select S.LOC,S.ID from '+@wh+'.LOTxLOCxID S 
      join '+@wh+'.LOC L on  S.LOC=L.LOC and s.status=''OK''
      where  S.SKU=@SKUVAL  and S.QTY>0 

      open FromCur 

      fetch next from Fromcur into @LOCFROM,@IDFROM
      
      fetch next from Mycur into @LOCTO,@SKU,@DESCR
      
      while @@FETCH_STATUS<>-1 
         begin
           insert into #TMP (LOCTO, SKU, DESCR, LOCFROM, IDFROM) values (@LOCTO, @SKU, @DESCR, @LOCFROM, @IDFROM) 
           fetch next from Fromcur into @LOCFROM,@IDFROM
           fetch next from Mycur into @LOCTO,@SKU,@DESCR
         end
      
      close MyCur 

      deallocate MyCur

      close FromCur 

      deallocate FromCur

      fetch next from Ordcur into @SKUVAL
    end

close OrdCur 
deallocate OrdCur

SELECT loc into #holded FROM '+@wh+'.loc where locationflag in (''HOLD'',''DAMAGE'')

delete from #tmp where LOCTO in (select loc from #holded)
delete from #tmp where LOCFROM in (select loc from #holded)
	
select * from #TMP

drop table [#TMP]
'
exec (@sql)

