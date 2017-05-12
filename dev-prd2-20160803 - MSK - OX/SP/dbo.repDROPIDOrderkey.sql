-- =============================================
-- Author:		Сандаков В.В.
-- Create date: 10.06.2008
-- Description:	по DROPID найти список заказов которые упакованы на этот DROPID и ячейку к которой этот DROPID
--				приписан 
-- =============================================
ALTER PROCEDURE [dbo].[repDROPIDOrderkey] 
	@wh varchar(30),
	@dropid varchar(10)=null
AS
	
--declare @wh varchar(30),
--	@dropid varchar(10)
--
--set @dropid = 'TS00000299'

create table #t1 (dropid varchar(15) collate Cyrillic_General_CI_AS)
create table #t2 (dropid varchar(15) collate Cyrillic_General_CI_AS)
create table #result (child varchar(15) collate Cyrillic_General_CI_AS)

declare @sql varchar(max)

set @sql = 'insert into #t1
	select childid
	from '+@wh+'.dropiddetail d
	where d.DROPID = '''+@dropid+''''
exec(@sql)
--select * from #t1

set @sql = 'while (exists (select #t1.dropid from #t1))
	begin
		insert into #t2
			select d.CHILDID from '+@wh+'.DROPIDDETAIL d
			join #t1 on #t1.dropid = d.DROPID
		insert into #result
			select #t1.dropid from #t1
			where not #t1.dropid in (select d.DROPID from '+@wh+'.DROPIDDETAIL d WHERE d.CHILDID in (select #t2.dropid from #t2))
		delete #t1
		insert into #t1 
			select #t2.dropid from #t2
		delete #t2
	end'
exec(@sql)
--select * from #t2
--select * from #result

set @sql = 'select pd.orderkey, o.EXTERNORDERKEY, pd.sku, s.descr, pd.qty, pd.dropid, pd.caseid, d.droploc
from '+@wh+'.pickdetail pd
	join '+@wh+'.orders o on o.orderkey = pd.orderkey
	join '+@wh+'.sku s on s.sku = pd.sku
	join '+@wh+'.dropid d on d.dropid = pd.dropid 
where pd.caseid in (select * from #result)' 

exec(@sql)

drop table #t1		
drop table #t2		
drop table #result

