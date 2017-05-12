-- =============================================
-- Author:		EV
-- Create date: <Create Date,,>
-- Description:	Отчет по срокам годности для Лебедяни
-- =============================================
ALTER PROCEDURE [dbo].[rep_SrokGodnostLeb]
  @wh varchar(10),
  @stkey varchar(15)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

Declare
  @sql varchar(max)


Set @sql='

  SELECT 
    L.SKU, 
    S.DESCR,
    Sum(L.QTY) as qty,
    T.LOTTABLE04 as DatIzg,
    T.LOTTABLE05 as SrokGod,
    DATEDIFF(day,getdate(),T.LOTTABLE05) as kolDay
  FROM  '+@wh+'.LOTXLOCXID L, 
		'+@wh+'.SKU S, 
		'+@wh+'.LOTATTRIBUTE T,
        '+@wh+'.loc loc '
  +' WHERE 
       S.SKU = L.SKU
       and L.LOT = T.LOT 
       and l.loc=Loc.loc 
       and (L.QTY > 0)  
       and Loc.LOCLEVEL>0
       and loc.PUTAWAYZONE not in 
          (select z.PUTAWAYZONE from '+@wh+'.hostzones z
                     where z.PUTAWAYZONE=Loc.PUTAWAYZONE and z.PUTAWAYZONE<>''BRAK_SIB'' )
	   AND (S.STORERKEY=  '''+@stkey+''')
group by
    L.SKU,
    S.DESCR,
    T.LOTTABLE04,
    T.LOTTABLE05 
Order by
  L.SKU,
  DATEDIFF(day,getdate(),T.LOTTABLE05)
 '

exec(@sql)

END

