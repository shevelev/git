
ALTER PROCEDURE [dbo].[proc_SZ_INV_list2](
 	@sid  varchar(20)
)
AS

select pvr.SKU, pvr.LOT, pvr.LOC, pvr.QTY, ovr.qty qf, SUM(pvr.QTY-ovr.qty) razn from wh1.physical_vr pvr
join wh1.ostatki_vr ovr on ovr.SID=pvr.SID and ovr.LOT=pvr.LOT and ovr.SKU=pvr.SKU and ovr.LOC=pvr.loc
where pvr.SID = @sid
group by pvr.SKU, pvr.LOT, pvr.LOC, pvr.QTY, ovr.qty
