


ALTER PROCEDURE [rep].[act_of_differences_in_acceptance2] (
	/*   03 Акт расхождений при приемке DS1   */

	@wh VARCHAR(30)='WH1',
	@dat1 datetime,
	@dat2 datetime
	 -- 0 - для отчета "Акт расхождений при приемке"
				--  1 - для отчета "Акт отбраковки при приемке"
)AS
Declare 
@key int = 0
--	declare	@wh VARCHAR(30),
--		@dat1 datetime,
--		@dat2 datetime
--	select @wh='wh40', @dat1 = '20080101', @dat2=getdate()

	
	--set @rc= replace(upper(@rc),';','')  -- удалить ; из строк задаваемых пользователем для увеличения безопасности.
	

	
	  select r.receiptkey as k,	convert(datetime,convert(varchar(10),r.receiptdate,104),104) as d,
		  rd.sku as sku,	rd.packkey as pk,	rd.qtyexpected as zqty, rd.qtyreceived as fqty
	  into #tmp1
	  from WH1.receipt as r,	WH1.receiptdetail as rd
	  where 1=2
	
	  insert into #tmp1
		select r.receiptkey as k,
			convert(datetime,convert(varchar(10),r.receiptdate,104),104) as d,
			rd.sku as sku,
			rd.packkey as pk,
			sum(rd.qtyexpected) as zqty,
			sum(rd.qtyreceived) as fqty

		from WH1.receipt as r,
			WH1.receiptdetail as rd

		where r.receiptkey=rd.receiptkey
			and (r.receiptdate>=convert(varchar, @dat1, 112)+' 00:00:00')
			and (r.receiptdate<=convert(varchar, @dat2, 112)+' 23:59:59')

	group by r.receiptkey,
		convert(datetime,convert(varchar(10),r.receiptdate,104),104),
		rd.sku,
		rd.packkey

	 having 
		
					sum(rd.qtyexpected)<>sum(rd.qtyreceived) 
		


	select distinct k as nomer
		from #tmp1
	order by nomer

	drop table #tmp1



