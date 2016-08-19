-- =============================================
-- Author:		����� �����
-- Create date: 15.06.2008
-- Description:	��� ������, ������� ���������� ����� ������
-- ����� ����� �� 8 ������, � ����� ���.
-- =============================================
ALTER PROCEDURE [dbo].[rep_ZHaveOrNotHaveSkuAngar8] 
	@wh VarChar(10)
  , @datestart VarChar(10)
  , @dateend VarChar(10)
  , @flag VarChar(1) --����� 1 ���� ���� �������� ������ ���������� ����� �� ������ 8, 2 � ��������� ������
AS
BEGIN
	declare @sql VarChar(max)
    set @wh = upper(@wh)
    if (@flag = 1) 
       begin
-- ����� ���� � ������ 8
         set @sql = '
select o.orderkey, o.EXTERNORDERKEY, st.VAT, st.company      
from '+@wh+'.orders o left join '+@wh+'.storer st
  on o.consigneekey = st.storerkey
where (RFIDFLAG = 0
  or  OHTYPE = 1)
   '+case when @datestart is not null then
             case when @dateend is not null 
                  then 'and o.requestedshipdate >= convert(DateTime,'''+@datestart+''',104) and o.requestedshipdate <= convert(DateTime,'''+@dateend+''',104)'
                  else 'and o.requestedshipdate >= convert(DateTime,'''+@datestart+''',104)'
             end
             else case when @dateend is not null
                       then 'and o.requestedshipdate <= convert(DateTime,'''+@dateend+''',104)'
                       else ' '
                  end 
        end + '
  and EXISTS(select odsku.sku
               from (select od.sku
                       from '+@wh+'.orderdetail od 
                       where od.orderkey = o.orderkey) as odsku
                     inner join '+@wh+'.sku
                  on odsku.sku = '+@wh+'.sku.sku
               where '+@wh+'.sku.putawaystrategykey in (''ST_BITSVET'', ''ST_CVTECH''
                                , ''ST_DRL'', ''ST_LUMLAMP''
                                , ''ST_LUMSVET'', ''ST_NAKLAMP'', ''ST_NAROSV'', ''ST_PRACK''
                                , ''ST_REZERV'', ''ST_SCH''))'
         exec (@sql)
       end
    else
      begin
--������ ��� � 8 ������
         set @sql = '
select o.orderkey, o.EXTERNORDERKEY, st.VAT, st.company      
from '+@wh+'.orders o left join '+@wh+'.storer st
  on o.consigneekey = st.storerkey
where (RFIDFLAG = 0
  or  OHTYPE = 1)
  '+case when @datestart is not null then
             case when @dateend is not null 
                  then 'and o.requestedshipdate >= convert(DateTime,'''+@datestart+''',104) and o.requestedshipdate <= convert(DateTime,'''+@dateend+''',104)'
                  else 'and o.requestedshipdate >= convert(DateTime,'''+@datestart+''',104)'
             end
             else case when @dateend is not null
                       then 'and o.requestedshipdate <= convert(DateTime,'''+@dateend+''',104)'
                       else ' '
                  end 
        end + '
  and NOT EXISTS(select odsku.sku
               from (select od.sku
                       from '+@wh+'.orderdetail od 
                       where od.orderkey = o.orderkey) as odsku
                     inner join '+@wh+'.sku
                  on odsku.sku = '+@wh+'.sku.sku
               where '+@wh+'.sku.putawaystrategykey in (''ST_BITSVET'', ''ST_CVTECH''
                                , ''ST_DRL'', ''ST_LUMLAMP''
                                , ''ST_LUMSVET'', ''ST_NAKLAMP'', ''ST_NAROSV'', ''ST_PRACK''
                                , ''ST_REZERV'', ''ST_SCH''))'
         exec (@sql)
      end
END

