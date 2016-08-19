ALTER PROCEDURE [rep].[unspent_balance] (
@loc1 varchar(15),
@loc2 varchar(15),
@st varchar(10),
@u varchar(15)
)
AS

declare @sku varchar(20)
declare @altsku varchar(50)
declare @sql varchar(max)

create table #altsku2 (sku varchar(20), altsku varchar(50))
create table #vr_t (loc varchar(50), sku varchar(50), descrip varchar(200), busr2 varchar(50), busr5 varchar(50),
lo1 varchar(50),lo2 varchar(50),lo3 varchar(50),lo4 datetime,lo5 datetime,lo7 varchar(50),lo8 varchar(50),
qty varchar(30), st varchar(10))


set @sql ='insert into #vr_t select lli.loc,s.sku, case when s.NOTES1 is null then s.DESCR else s.NOTES1 end as skuName, s.BUSR2, s.BUSR5,
la.LOTTABLE01 ,la.LOTTABLE02,la.LOTTABLE03,la.LOTTABLE04,la.LOTTABLE05, la.LOTTABLE07,la.LOTTABLE08,
lli.qty, lli.storerkey
from wh1.lotxlocxid lli 
		left join wh1.lotAttribute la on lli.lot=la.lot and la.storerkey=lli.storerkey
		left join wh1.sku s on lli.sku=s.sku and lli.storerkey=s.storerkey
where lli.qty>0 and lli.STORERKEY= ''' +@st+ ''' and lli.loc between '''+@loc1+''' and '''+@loc2+''''+
case when @u='NULL' then '' else ' AND la.LOTTABLE01='''+@u+''' ' end +
	'order by lli.loc'
	exec(@sql)

--if @st is null set @st='001'

--insert into #vr_t select lli.loc,s.sku, case when s.NOTES1 is null then s.DESCR else s.NOTES1 end as skuName, s.BUSR2, s.BUSR5,
--la.LOTTABLE01 ,la.LOTTABLE02,la.LOTTABLE03,la.LOTTABLE04,la.LOTTABLE05, la.LOTTABLE07,la.LOTTABLE08,
--lli.qty, lli.storerkey
--from wh1.lotxlocxid lli 
--		left join wh1.lotAttribute la on lli.lot=la.lot and la.storerkey=lli.storerkey
--		left join wh1.sku s on lli.sku=s.sku and lli.storerkey=s.storerkey
--where lli.qty>0 and lli.loc between @loc1 and @loc2
--	and  (@u is NULL or la.LOTTABLE01=@u)
--	and lli.STORERKEY=@st
--	order by lli.loc




/* Создаем временную с товарами. */
select distinct sku into #d_sku from #vr_t



while (select COUNT(*) from #d_sku) != 0
	begin
		select top(1) @sku = sku from #d_sku
		print @sku
		insert into #altsku2 select top (1)sku, altsku from wh1.ALTSKU where SKU=@sku and STORERKEY=@st
			while (select COUNT(*) from #altsku2) != 0
				begin
					select top(1) @altsku=altsku from #altsku2
					print 'Обновляем ШК'+@altsku
					update #vr_t set descrip = descrip+ ' ШК: ' + @altsku
							where sku = @sku 
					
					delete from #altsku2 where ALTSKU=@altsku
				end
		delete from #d_sku where SKU=@sku
	end


select * from #vr_t

drop table #vr_t
drop table #d_sku
drop table #altsku2
