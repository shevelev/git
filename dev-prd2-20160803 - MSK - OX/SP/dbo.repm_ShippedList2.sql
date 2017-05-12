-- =============================================
-- Author:		Dr.MoPo3ilo
-- Create date: 2009/01/21
-- Description:	Отргузочный лист для заказа
-- Добавлено поле клиент Солдаткин В.В
-- =============================================
ALTER PROCEDURE [dbo].[repm_ShippedList2] 
	@wh varchar(10), 
	@key varchar(12)
AS
BEGIN
	SET NOCOUNT ON;
	declare @sql varchar(max)
  set @sql='
declare @caseidtbl table(dropid varchar(18),caseid varchar(18))
declare @caseidtbltmp table(dropid varchar(18),childid varchar(18))
declare @dropids table(dropid varchar(18))

declare @dropid varchar(18), @childid varchar(18)

declare cur cursor for
select DROPID,CHILDID from '+@wh+'.DROPIDDETAIL
where DROPID in (select UNITID from '+@wh+'.LOADUNITDETAIL lud
  join '+@wh+'.LOADSTOP ls on lud.LOADSTOPID=ls.LOADSTOPID
  where ls.LOADID='''+@key+''')
  
open cur
fetch next from cur into @dropid,@childid
while @@fetch_status=0
begin
  delete from @caseidtbltmp
  
  insert into @caseidtbl
  select @dropid,childid from @caseidtbltmp
  where not childid in (select DROPID from '+@wh+'.DROPIDDETAIL)

  insert into @caseidtbltmp
  select DROPID,CHILDID from '+@wh+'.DROPIDDETAIL
  where DROPID=@childid
  
  if not exists(select * from @caseidtbltmp)
    insert into @caseidtbl select @dropid,@childid
  
  while exists(select * from @caseidtbltmp)
  begin
    insert into @caseidtbl
    select @dropid,childid from @caseidtbltmp
    where not childid in (select DROPID from '+@wh+'.DROPIDDETAIL)
    
    delete from @caseidtbltmp
    where not childid in (select DROPID from '+@wh+'.DROPIDDETAIL)
    
    delete from @dropids
    
    insert into @dropids
    select childid from @caseidtbltmp
    
    delete from @caseidtbltmp
    
    insert into @caseidtbltmp
    select DROPID,CHILDID from '+@wh+'.DROPIDDETAIL
    where DROPID in (select dropid from @dropids)
  end
fetch next from cur into @dropid,@childid
end
close cur
deallocate cur

select lud.UNITID DROPID, d.DROPLOC LOCID, paz.DESCR PUTAWAYZONE
  ,sum(floor(pd.QTY/p.CASECNT)) QTY_CASE,sum(pd.QTY-(floor(pd.QTY/p.CASECNT)*p.CASECNT)) QTY
  ,lh.LOADID,lh.DEPARTURETIME
  ,dbo.GetEAN128(lh.LOADID) LOADID_EAN,dbo.GetEAN128(''TS''+lh.LOADID) TS_EAN
  ,cr.COMPANY EXPTP,lh.DOOR,st.COMPANY STORER, o.C_COMPANY Klient, isnull(o.C_ADDRESS1,o.B_ADDRESS1) ADDRESS
from '+@wh+'.LOADUNITDETAIL lud
join '+@wh+'.DROPID d on lud.UNITID=d.DROPID
join '+@wh+'.LOC l on d.DROPLOC=l.LOC
join '+@wh+'.PUTAWAYZONE paz on l.PUTAWAYZONE=paz.PUTAWAYZONE
join '+@wh+'.LOADSTOP ls on lud.LOADSTOPID=ls.LOADSTOPID
join '+@wh+'.LOADHDR lh on ls.LOADID=lh.LOADID
join @caseidtbl cid on lud.UNITID=cid.dropid
join '+@wh+'.PICKDETAIL pd on cid.caseid=pd.CASEID
join '+@wh+'.STORER cr on lh.CARRIERID=cr.STORERKEY
join '+@wh+'.STORER st on pd.STORERKEY=st.STORERKEY
join '+@wh+'.SKU s on pd.SKU=s.SKU and pd.STORERKEY=s.STORERKEY
join '+@wh+'.PACK p on s.RFDEFAULTPACK=p.PACKKEY
join '+@wh+'.LOADORDERDETAIL lod on ls.LOADSTOPID=lod.LOADSTOPID
join '+@wh+'.ORDERS o on lod.SHIPMENTORDERID=o.ORDERKEY
--join '+@wh+'.STORER stk on o.B_COMPANY=stk.STORERKEY
where lh.LOADID='''+@key+'''
group by lud.UNITID, d.DROPLOC, paz.DESCR
  ,lh.LOADID,lh.DEPARTURETIME
  ,dbo.GetEAN128(lh.LOADID),dbo.GetEAN128(''TS''+lh.LOADID)
  ,cr.COMPANY,lh.DOOR,st.COMPANY,o.C_COMPANY,o.C_ADDRESS1,o.B_ADDRESS1
order by d.DROPLOC
'
  exec(@sql)
END

