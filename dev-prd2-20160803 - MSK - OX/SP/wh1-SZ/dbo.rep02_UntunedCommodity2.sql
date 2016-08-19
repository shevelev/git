ALTER PROCEDURE [dbo].[rep02_UntunedCommodity2] 
/*   02  Отчет о ненастроенных товарах   */
as

select  distinct s.sku, s.descr,s.BUSR2,	s.stdcube,s.stdgrosswgt, cast('' as varchar(8000)) errcode, 0 bad
into #sku2
from wh1.sku as s
join wh1.LOTXLOCXID as lxlx on s.SKU=lxlx.SKU and s.STORERKEY=lxlx.STORERKEY
where lxlx.QTY>0

update #sku2 set bad=1 where stdcube = 0 or stdgrosswgt = 0 

update #sku2 set errcode = errcode +  case when stdcube = 0 then 'Объем = 0;  ' else '' end+
case when stdgrosswgt = 0 then 'Вес нетто = 0; '  else '' end  
		
select * from #sku2 where bad > 0

drop table #sku2

