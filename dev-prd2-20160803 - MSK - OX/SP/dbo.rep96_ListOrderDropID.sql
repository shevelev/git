/* список товаров (кабель) которые невозможно отгрузить цельным куском */
ALTER PROCEDURE [dbo].[rep96_ListOrderDropID](
 	@wh  varchar (10),
	@Drop varchar(18),
	@vat  varchar(18)
) as
set nocount on
	create table #restab (
		orderkey varchar(10) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		externorderkey varchar(32) COLLATE Cyrillic_General_CI_AS DEFAULT (''),	
		vat varchar(32) COLLATE Cyrillic_General_CI_AS DEFAULT (''),	
		company  varchar(45) COLLATE Cyrillic_General_CI_AS DEFAULT (''),	
		deliveryadr varchar(200) COLLATE Cyrillic_General_CI_AS DEFAULT ('')	)

	declare
		@sql varchar(max)

/* список заказов ################################################################################### */
	set @sql = 
'insert into #restab 
select distinct pd.orderkey, os.externorderkey, st.vat, st.company, os.deliveryadr + '', '' + os.c_email1 + '', '' + os.c_email2 
from '+@wh+'.dropiddetail did join wh1.pickdetail pd on did.childid = pd.caseid
join '+@wh+'.orders os on pd.orderkey = os.orderkey 
join '+@wh+'.storer st on os.consigneekey = st.storerkey
where did.dropid like '''+@drop+'''' +
case when @vat is null then '' else ' and st.vat like '''+@vat+'''' end

	exec (@sql)
/* ################################################################################################## */

	select * from #restab

	drop table #restab

