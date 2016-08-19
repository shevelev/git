



-- =============================================
-- Author:		исправлена
-- Create date: 20.05.2008
-- Description:	Процедура для вывода этикеток для паллет по номеру ПУО
-- =============================================

ALTER PROCEDURE [dbo].[rep_QTYExpectedPallet]
	(@wh varchar(10),
    @ReceiptKey varchar(10) -- номер ПУО
)
	AS

--declare @ReceiptKey varchar(10) 

--set @ReceiptKey = '0000000072'


declare @sql varchar(max)

	create table #t
		(
		 id_num int IDENTITY(1,1),
		 PALL varchar(10) COLLATE Cyrillic_General_CI_AS NULL,
		 SKU varchar(50) COLLATE Cyrillic_General_CI_AS NULL,
		 DESCR varchar(max) COLLATE Cyrillic_General_CI_AS NULL,
		 storerkey varchar (15) COLLATE Cyrillic_General_CI_AS NULL
		)
	create table #tm 
		(
		 SKU varchar(50) COLLATE Cyrillic_General_CI_AS NULL,
		 Descr varchar(max) COLLATE Cyrillic_General_CI_AS NULL
		)

CREATE TABLE [dbo].[#Resulttable](
	[SKU] [nvarchar](128) COLLATE Cyrillic_General_CI_AS NULL,
	[Descr] [varchar](max) COLLATE SQL_Latin1_General_CP1251_CI_AS NULL,
	[SKUD] [varchar](10) COLLATE SQL_Latin1_General_CP1251_CI_AS NULL)

	set @sql = '
		insert into #t(PALL, SKU, DESCR, storerkey)
		select (cast(ceiling((rd.QTYEXPECTED - rd.QTYreceived)/ case when p.PALLET = 0 
						then 1 else p.PALLET end) as varchar(10))) as PALL, 
			rd.SKU, s.DESCR, rd.storerkey
		from '+@wh+'.RECEIPTDETAIL	rd
			JOIN '+@wh+'.PACK p ON rd.PACKKEY = p.PACKKEY
			JOIN '+@wh+'.SKU s ON s.SKU = rd.SKU and s.storerkey = rd.storerkey
		where s.PACKKEY <> ''STD'' 
					and rd.QTYEXPECTED > 0
					and rd.ReceiptKey='''+@ReceiptKey+''''
	exec (@sql)

	declare @i int,
			@j int,
			@sku varchar(10),
			@descr varchar (max),
			@storerkey varchar (15)
	set @i = 1
	while (exists(select id_num from #t where id_num = ''+@i+'' ))
	begin
			
		select @j = PALL, @sku = SKU, @descr = DESCR, @storerkey = storerkey from #t where id_num = ''+@i+''
		while (@j>0)
		begin
			insert into #tm(SKU, Descr) select @sku, @descr 
			set @sql = '
				insert into #tm(sku, Descr) select whs.sku, whs.descr
				 from '+@wh+'.billofmaterial bom 
					join '+@wh+'.sku whs on whs.sku = bom.componentsku
	 			where bom.sku = '''+@sku+''' and bom.storerkey = '''+@storerkey+''''
			exec(@sql)							
			set @j = @j -1
		end
		set @i = @i + 1
	end

	insert into #resulttable 
select dbo.GetEAN128(tmt.SKU) SKU, tmt.Descr, tmt.SKU as SKUD   from #tm as tmt

if not exists (select * from #resulttable) 
	insert into #resulttable (SKU, Descr, SKUD) values ('','нет данных','нет')
select * from #resulttable

	drop table #resulttable
	drop table #t
	drop table #tm




