--drop proc dbo.rep03_ASNDifferences_DS1
--GO
ALTER PROCEDURE [dbo].[test] (
	/*   03 Акт расхождений при приемке DS1   */

	@wh VARCHAR(30) = "wh40",
	@dat1 datetime = '2008/04/04',
	@dat2 datetime = '2008/05/08',
	@key int = 0 -- 0 - для отчета "Акт расхождений при приемке"
				--  1 - для отчета "Акт отбраковки при приемке"
)AS

--	declare	@wh VARCHAR(30),
--		@dat1 datetime,
--		@dat2 datetime
--	select @wh='wh40', @dat1 = '20080101', @dat2=getdate()

	set @wh = upper(@wh)
	--set @rc= replace(upper(@rc),';','')  -- удалить ; из строк задаваемых пользователем для увеличения безопасности.
	declare @sql varchar(max)


	select r.receiptkey as k,	convert(datetime,convert(varchar(10),r.receiptdate,104),104) as d,
		rd.sku as sku,	rd.packkey as pk,	rd.qtyexpected as zqty, rd.qtyreceived as fqty
	into #tmp1
	from wh40.receipt as r,	wh40.receiptdetail as rd
	where 1=2

	set @sql = 'insert into #tmp1
		select r.receiptkey as k,
			convert(datetime,convert(varchar(10),r.receiptdate,104),104) as d,
			rd.sku as sku,
			rd.packkey as pk,
			sum(rd.qtyexpected) as zqty,
			sum(rd.qtyreceived) as fqty

		from '+@WH+'.receipt as r,
			'+@WH+'.receiptdetail as rd

		where r.receiptkey=rd.receiptkey
			and (r.receiptdate>='''+convert(varchar, @dat1, 112)+' 00:00:00'')
			and (r.receiptdate<='''+convert(varchar, @dat2, 112)+' 23:59:59'')

	group by r.receiptkey,
		convert(datetime,convert(varchar(10),r.receiptdate,104),104),
		rd.sku,
		rd.packkey'

	set @sql = @sql + ' having '+
		case @key when 1 then 'sum(rd.qtyreceived)>0 '
					else 'sum(rd.qtyexpected)<>sum(rd.qtyreceived) ' end
	exec (@sql)


	select distinct k as nomer
		from #tmp1
	order by nomer

	drop table #tmp1

