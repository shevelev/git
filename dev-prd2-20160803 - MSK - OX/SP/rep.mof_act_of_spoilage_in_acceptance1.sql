ALTER PROCEDURE [rep].[mof_act_of_spoilage_in_acceptance1](
/*      	04 Акт отбраковки при приемке DSmain          */
	@wh varchar(30),
	@nomer varchar(10)
)AS

--declare @wh varchar(10), @nomer varchar(10)
--set @nomer='0000011218'
--set @wh =  'wh40'

	set @wh = upper(@wh)
	set @nomer= replace(upper(@nomer),';','')  -- удалить ; из строк задаваемых пользователем для увеличения безопасности.
	declare @sql varchar(max)

CREATE TABLE [#resulttable](
	[sku] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[descr] [varchar](60) COLLATE Cyrillic_General_CI_AS NULL,
	[description] [varchar](250) COLLATE Cyrillic_General_CI_AS NULL,
	[qty] [decimal](22, 5),-- NOT NULL,
	externreceiptkey [varchar](15) COLLATE Cyrillic_General_CI_AS NULL,
	CARRIERKEY [varchar](15) null, --добавил Макс Тын
	CARRIERNAME [varchar](45) null, --добавил Макс Тын
	COMPANY [varchar](45) null, --добавил Макс Тын
	reasoncode varchar(20) null
	
	)


SET @sql = 'insert #resulttable select REC.SKU, S.DESCR, ''Штуки'' DESCRIPTION, 
					REC.QTYRECEIVED, 
					r.externreceiptkey,
					r.CARRIERKEY,
					r.CARRIERNAME,
					st.COMPANY,
					rec.reasoncode
				from '+@wh+'.receiptdetail REC
					left JOIN '+@wh+'.LOC L ON (REC.TOLOC = L.LOC)
					left JOIN '+@wh+'.SKU S ON (REC.SKU = S.SKU and REC.STORERKEY = S.STORERKEY)
					left JOIN '+@wh+'.RECEIPT r on (r.receiptkey = REC.receiptkey)
					left JOIN '+@wh+'.storer st on (s.STORERKEY=st.storerkey)
				where REC.RECEIPTKEY like ''%'+@nomer+''' 
				AND
					REC.TOLOC LIKE ''%BRAK%'''

print @sql
exec (@sql)

--select * from wh40.codelkup where listname = 'INVHOLD'

	 select (rt.sku) sku, (rt.descr) descr, (rt.description) description,  (rt.qty) qty, 
			(rt.externreceiptkey) extkey, (rt.CARRIERKEY) carrKey, (rt.CARRIERNAME) carrName, 
			(rt.COMPANY) company, reasoncode
	from #resulttable rt
--		group by rt.susr10, rt.sku, rt.descr, rt.description, brakReason, externreceiptkey

	drop table #resulttable

