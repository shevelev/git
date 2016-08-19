ALTER PROCEDURE [dbo].[NotRezerv] 
as
begin

declare @orderkey varchar(10), @sku varchar(10),@oqty int, @rqty int, @mess varchar(500)


select ORDERKEY, ORDERLINENUMBER, SKU, ORIGINALQTY, QTYALLOCATED 
into #test
from wh1.ORDERDETAIL 
where ORIGINALQTY > QTYALLOCATED 
		and (STATUS between '02' and '19') 
		and SHIPPEDQTY=0 and ADJUSTEDQTY=0 
		and QTYPICKED=0 and QTYALLOCATED!=0 and PACKKEY=1
		
		
if exists (select top 1 * from #test)
	begin
		select @mess=''
		select top 1 @orderkey=ORDERKEY, @sku=SKU, @oqty=ORIGINALQTY, @rqty=QTYALLOCATED  from #test
		print 'В заказе № ' + @orderkey + ' не полностью зарезервировался товар: ' + @sku
		set @mess = 'В заказе № ' + @orderkey + ' не полностью зарезервировался товар: ' + @sku
		exec dbo.sendmail 'vnedrenie3@sev-zap.ru', 'Не зарезервировался полностью товар', @mess
		delete from #test where orderkey = @orderkey and SKU=@sku
		
	end
	
drop table #test	

end




