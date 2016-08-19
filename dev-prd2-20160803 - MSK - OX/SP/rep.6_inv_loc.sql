/* Расхождения по ячейкам */
ALTER PROCEDURE [rep].[6_inv_loc] (
	@sku varchar(20),
	@lot02 varchar(20),
	@lot04 datetime,
	@lot05 datetime,
	@skld varchar(20)
)
AS

--declare @sku varchar(20)='14645'
--declare @lot02 varchar(20)='501306'
--declare @@skld varchar(20)='СкладПродаж'

select loc,SKU, SUSR1,SUSR4, susr5, max(inventorytag) mig
into #test
from wh1.physical 
where STATUS='0' and SKU=@sku and SUSR1=@lot02 and SUSR4=@lot04 and SUSR5=@lot05
group by loc,SKU, SUSR1,SUSR4, susr5

select w.sklad, p.loc,t.SKU, t.SUSR1,t.SUSR4,t.SUSR5,  p.QTY 
from #test t
join wh1.physical p on t.LOC=p.LOC and t.SKU=p.SKU and t.mig=p.INVENTORYTAG and p.QTY>0 
join wh1.LOC loc on loc.LOC =p.loc
 join dbo.WHTOZONE w on w.zone = loc.PUTAWAYZONE and w.sklad=@skld

drop table #test



