-- ÎÒÏÐÀÂÊÀ ÎÁÚÅÄÈÍÅÍÍÎÉ ÊÎÐÐÅÊÒÈÐÎÂÊÈ Â ÕÎÑÒ-ÑÈÑÒÅÌÓ

ALTER PROCEDURE [dbo].[proc_DA_AdjustmentBatchReady](
	@wh varchar(10),
	@transmitlogkey varchar (10) )
AS

SET NOCOUNT ON

declare @batchkey varchar(10)

declare @storerkey varchar(15)
declare @zone varchar(50)

declare @storers table (num int identity(1,1), storerkey varchar(15))
declare @zones table (num int identity(1,1), zone varchar(50))

declare @i_storer int
declare @i_zone   int
declare @i_zone2  int

create table #result
(
  storerkey varchar(15),
  sku varchar(10),
  deltaqty decimal(22,5),
  editdate varchar(10),
  zone varchar(50)
)
-- íîìåð ïàêåòà êîððåêòèðîâîê
select @batchkey = key1 from wh1.transmitlog where transmitlogkey = @transmitlogkey

insert @storers (storerkey)
    select distinct storerkey 
    from DA_Adjustment da 
    where da.whseid = @wh and da.batchkey = @batchkey
set @i_storer = @@ROWCOUNT

insert @zones (zone)
    select distinct zone
    from DA_Adjustment da
    where da.whseid = @wh and da.batchkey = @batchkey
set @i_zone = @@ROWCOUNT

-- ñôîðìèðîâàòü ðåçóëüòàòû
while(@i_storer > 0)
begin      
   select @storerkey = storerkey from @storers where num = @i_storer
   set @i_storer = @i_storer - 1

   set @i_zone2 = @i_zone

   while(@i_zone2 > 0)
   begin      
      select @zone = zone from @zones where num = @i_zone2
      set @i_zone2 = @i_zone2 - 1

      insert #result (storerkey,sku,deltaqty,editdate,zone)
        select storerkey, sku, sum(deltaqty) deltaqty, convert(varchar(10),max(da.editdate),112) as editdate, zone 
        from DA_Adjustment da 
        where da.whseid = @wh and da.batchkey = @batchkey and da.zone = @zone and da.storerkey = @storerkey
        group by storerkey, sku, zone 
        having sum(deltaqty) < 0

      if @@ROWCOUNT > 0 
      begin  
        select 'ADJUSTMENT' filetype, @batchkey externdockey, r.* from #result r
        delete #result
      end

      insert #result (storerkey,sku,deltaqty,editdate,zone)
        select storerkey, sku, sum(deltaqty) deltaqty, convert(varchar(10),max(da.editdate),112) as editdate, zone 
        from DA_Adjustment da 
        where da.whseid = @wh and da.batchkey = @batchkey and da.zone = @zone and da.storerkey = @storerkey
        group by storerkey, sku, zone 
        having sum(deltaqty) > 0

      if @@ROWCOUNT > 0 
      begin        
        select 'ADJUSTMENT' filetype, @batchkey externdockey, r.* from #result r
        delete #result
      end      
   end   
end

drop table #result

