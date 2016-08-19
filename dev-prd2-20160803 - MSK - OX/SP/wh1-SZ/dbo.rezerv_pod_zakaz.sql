ALTER PROCEDURE [dbo].[rezerv_pod_zakaz] (
@sku varchar(15)
)
AS

declare @sql varchar(max)

set @sql='select lxlx.LOC, pd.orderkey,lxlx.SKU, s.notes1,lxlx.QTY, lxlx.QTYALLOCATED, ck.DESCRIPTION, pd.adddate from wh1.lotxlocxid lxlx
join wh1.PICKDETAIL pd on pd.SKU=lxlx.SKU and pd.QTY=lxlx.QTYALLOCATED and pd.LOT=lxlx.lot and pd.LOC=lxlx.loc
join wh1.CODELKUP ck on ck.CODE=pd.status and ck.LISTNAME=''ordrstatus''
join wh1.SKU s on s.SKU=lxlx.sku
where lxlx.QTYALLOCATED>0' 
set @sql=@sql+ case when isnull(''+@sku+'','') = '' then '' else 'and lxlx.SKU='+@sku+'' end
set @sql=@sql+' order by lxlx.sku, pd.adddate'
exec(@sql)
