-- =============================================
-- Author:		EV
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[rep37_InvalidItem]
	@wh varchar(10),
	@loc varchar(20) = null,
	@dateB smalldatetime,
	@dateE smalldatetime,
    @PUTAWAYZONE varchar(10)
AS
BEGIN

declare @sql varchar(max)
set dateformat dmy
set @sql='
	select 
      i.ADDDATE,
      i.FROMLOC as FROMLOC,
      i.TOLOC,
      i.SKU,
      s.DESCR,
      ''רע'' as edizm,
      sum(isnull(i.QTY,0)) as q,
      i.ADDWHO
    from '
      +@wh+'.ITRN i, '
      +@wh+'.SKU s '+
      case when @PUTAWAYZONE='ֻ‏באÿ' then '' else ', '+@wh+'.LOC l ' end + 
    ' where
        s.SKU=i.SKU
        and i.adddate between ''' + convert(varchar,@dateB,104)+''' and '''+convert(varchar,@dateE,104)+''''+
        case when @PUTAWAYZONE='ֻ‏באÿ' then '' else ' and l.PUTAWAYZONE='''+@PUTAWAYZONE+''' and l.loc=i.TOLOC ' end+
        case when @loc='' then '' else ' and i.toloc='''+@loc+'''' end+
   ' group by
      i.ADDDATE,
      i.FROMLOC,
      i.TOLOC,
      i.SKU,
      s.DESCR,
      i.ADDWHO
    order by
      i.ADDDATE,
      i.FROMLOC,
      i.TOLOC,
      i.SKU  
 ' 
    

exec(@sql)
   
END

