/* Детализация ЗЗ */
ALTER PROCEDURE [dbo].[rep51_PODetails](
 	@pk  varchar (50),
 	@extn varchar (50)
)
AS

SELECT		p.EXTERNPOKEY,
			p.POKEY, 
			pd.POLINENUMBER,
			pd.SKU, 
			pd.SKUDESCRIPTION, 
			pd.QTYORDERED, 
			pd.QTYRECEIVED, 
			pd.QTYREJECTED,
            ck.DESCRIPTION, 
            pd.UOM, 
            pd.SKU_CUBE, 
            pd.SKU_WGT
FROM         wh1.po p
		join WH1.PODETAIL pd on pd.POKEY = p.pokey 
		jOIN WH1.CODELKUP ck ON pd.STATUS = ck.CODE and ck.LISTNAME = 'postatus'
where (p.POKEY like '%'+isnull(@pk,'')+'%' and p.EXTERNPOKEY like '%'+isnull(@extn,'')+'%')




