ALTER PROCEDURE [dbo].[rep40_ReplenishListByOrder1] (@ORDER varchar(30), @wh varchar(10))
--with encryption
as

create table #TMP  (
 LOCFROM   varchar(10) COLLATE Cyrillic_General_CI_AS null,
 IDFROM    varchar(10) COLLATE Cyrillic_General_CI_AS null,
 SKU       varchar (10) COLLATE Cyrillic_General_CI_AS null,
 DESCR     varchar(300) COLLATE Cyrillic_General_CI_AS null,
 LOCTO   varchar(10) COLLATE Cyrillic_General_CI_AS null)

CREATE TABLE [dbo].[#mycyrt](
	[LOC] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[SKU] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[DESCR] [varchar](60) COLLATE Cyrillic_General_CI_AS NULL)

CREATE TABLE [dbo].[#OrdCursorT](
	[SKU] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL)

CREATE TABLE [dbo].[#fromcurt](
	[LOC] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[ID] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL)

CREATE TABLE [dbo].[#holded](
	[loc] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL)

declare  @LOCFROM varchar(10) ,@IDFROM varchar(10), @SKU varchar (10),@DESCR varchar(300),
         @LOCTO   varchar(10),@SKUVAL varchar(10), @sql varchar (max)

set @sql = 
'insert into #OrdCursorT select distinct SKU 
        from '+@wh+'.ORDERDETAIL where ORDERKEY='''+@ORDER+''''
exec (@sql)

declare OrdCur cursor for 
select * from #OrdCursorT
--select distinct SKU 
--        from WH40.ORDERDETAIL where ORDERKEY=@ORDER 

open OrdCur
fetch next from Ordcur into @SKUVAL
while @@FETCH_STATUS<>-1 
   begin

set @sql =
'insert into #mycyrt select S.LOC, S.SKU,K.DESCR
	from '+@wh+'.SKUxLOC S 
             join '+@wh+'.LOC L on  S.LOC=L.LOC and L.LOCATIONTYPE=''CASE''
             join '+@wh+'.PUTAWAYZONE P on L.PUTAWAYZONE=P.PUTAWAYZONE 
             join '+@wh+'.SKU K on S.SKU=K.SKU and S.STORERKEY=K.STORERKEY 
      where  S.SKU='''+@skuval+''' and S.ReplenishmentPriority<P.Replenishment_hotLevel 
             and S.ALLOWREPLENISHFROMBULK=1'
exec (@sql)

      declare MyCur cursor for  
		select * from #mycyrt
--      select S.LOC, S.SKU,K.DESCR from WH40.SKUxLOC S 
--             join WH40.LOC L on  S.LOC=L.LOC and L.LOCATIONTYPE='CASE'
--             join WH40.PUTAWAYZONE P on L.PUTAWAYZONE=P.PUTAWAYZONE 
--             join WH40.SKU K on S.SKU=K.SKU and S.STORERKEY=K.STORERKEY
--      where  S.SKU=@SKUVAL and S.ReplenishmentPriority<P.Replenishment_hotLevel 
--             and S.ALLOWREPLENISHFROMBULK=1
      
      open myCur 

set @sql=
      'insert into #fromcurt 
		select S.LOC,S.ID 
		from '+@wh+'.LOTxLOCxID S 
      join '+@wh+'.LOC L on  S.LOC=L.LOC and L.LOCATIONTYPE=''OTHER''
      where  S.SKU='''+@SKUVAL+'''  and S.QTY>0 '
exec (@sql)


      declare FromCur cursor for  
	select * from #fromcurt
--      select S.LOC,S.ID 
--		from WH40.LOTxLOCxID S 
--      join WH40.LOC L on  S.LOC=L.LOC and L.LOCATIONTYPE='OTHER'
--      where  S.SKU=@SKUVAL  and S.QTY>0 

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

set @sql =
	'insert into #holded SELECT loc FROM '+@wh+'.loc where locationflag in (''HOLD'',''DAMAGE'')'
	exec (@sql)

	delete from #tmp where LOCTO in (select loc from #holded)
	delete from #tmp where LOCFROM in (select loc from #holded)
	
	--SELECT * FROM wh40.loc where loc like 'BRAK%'
	
select distinct * from #TMP

drop table #TMP
drop table #OrdCursorT
drop table #fromcurt
drop table #mycyrt

