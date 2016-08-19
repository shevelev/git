ALTER PROCEDURE [rep].[mof_List_of_ASN] (
/*      	18 Список ПУО          */
		@wh varchar(30),
		@dateSt datetime = null,
		@dateEnd datetime=null,
		@storer varchar(10)=null,
		@receiptkey varchar(10)=null,
		@status varchar(10)= null,
		@carrier varchar(12)= null,
		@sortOrder int = 1, 
		@sortDirection int = 0,
		@susr5 varchar(30),
		@EXTERNRECEIPTKEY varchar(20)
)
 
AS
/********  Input parameters (for testing)  ************/
--declare @dateSt varchar(10),
--		@dateEnd varchar(10),
--		@storer varchar(10),
--		@EXTERNRECEIPTKEY varchar(20),
--		@susr5 varchar(30),
--		@receiptkey varchar(10),
--		@status varchar(10),
--		@carrier varchar(12),
--		@WH varchar(30)
--select @dateSt = null,
--		@dateEnd = null,
--		@storer = null,
--		@receiptkey = '0000011005',
--		@status = null,
--		@carrier = null
--declare @sortOrder int, @sortDirection int
--select @sortOrder = 1, @sortDirection=0, @WH='WH40'
/********  -------------------------------------  ************/

	set @wh = upper(@wh)
	set @dateSt= replace(upper(@dateSt),';','')  -- удалить ; из строк задаваемых пользователем для увеличения безопасности.
	set @dateEnd= replace(upper(@dateEnd),';','') 
	set @storer= replace(upper(@storer),';','') 
	set @receiptkey= replace(upper(@receiptkey),';','') 
	set @status= replace(upper(@status),';','') 
	set @carrier= replace(upper(@carrier),';','') 



declare @sql varchar(max)
set nocount on
	declare @PlaceVol decimal(10,3)
	set @placeVol = 1.6*0.8*1.2
	declare @date1 varchar(10),
			@date2 varchar(10)
	-- переносим значения дат во внутренние переменные.
	set @date1 = convert(varchar(10),@dateSt,112)
	set @date2 = convert(varchar(10),dateadd(dy,1,@dateEnd),112)
	-- если даты не заданы задаем некие граничные даты, заведомо перекрывающие все время работы системы
	if @date1 is null set @date1 = '20000101' -- 1 янв 2000
	if @date2 is null set @date2 = convert(varchar(10), dateadd(yy,1,getdate()),112) -- тек. дата плюс год
	-- в случае если даты перепутаны местами восстанавливаем правильный порядок
	declare @tmp varchar(10)
	if @date2 < @date1 
	begin
		select @tmp = @date2, @date2 = @date1
		select @date1 = @tmp
	end
	-- получаем список владельцев по заданному коду владельца. если null - весь список
	create table #storer (storerkey varchar(15)COLLATE Cyrillic_General_CI_AS, 
							company varchar(45))
	set @sql = 'INSERT INTO #storer select storerkey, company 
		from '+@WH+'.storer where 1=1 AND [type] = 1	' +
		case when @storer is null then ' ' else ' and (storerkey = '+cast(@storer as varchar)+') ' end 
	exec (@sql)
	print 1
	-- получаем список документов по приходу
	create table #receipt (receiptkey varchar(10)COLLATE Cyrillic_General_CI_AS, 
		company varchar(45), 
		expectedreceiptdate datetime,
		editdate datetime, 
		datereceipt datetime,
		status varchar(10), 
		statusDescr varchar(250), 
		carrierkey varchar(15),
		carrierName varchar(45),
		TransMode varchar(250),
		susr1 varchar(30),
		susr5 varchar(30),
		externreceiptkey varchar(20))
	set @sql = 'insert into #receipt (receiptkey, company, expectedreceiptdate,editdate,datereceipt, status, 
			statusDescr, carrierkey, carrierName, TransMode, susr1, susr5, EXTERNRECEIPTKEY)'
	set @sql = @sql + ' select r.receiptkey, st.company, expectedreceiptdate, r.editdate, 
			(select min(adddate) from '+@WH+'.receiptdetail where  receiptkey = r.receiptkey and qtyreceived>0),
			status, ck1.Description statusDescr, carrierkey, carrierName,
			ck.Description TransMode, r.susr1, r.susr5, r.EXTERNRECEIPTKEY'   
	set @sql = @sql + ' from '+@WH+'.receipt r' + 
		' join #storer st on r.storerkey = st.storerkey ' + -- отфильтровали по владельцу
		' left join '+@WH+'.codelkup ck on r.transportationmode = ck.code AND ck.LISTNAME like ''TRANSPMODE''' + -- расшифровка транспорта
		' left join '+@WH+'.codelkup ck1 on r.status = ck1.code AND ck1.LISTNAME like ''RECSTATUS'' '-- расшифровка статуса
	set @sql = @sql + 'where 1=1 ' +
		case when @receiptkey is null then ' ' else ' and (receiptkey like ''' + @receiptkey+''')' end + -- отфильтровали по коду документа
		case when @status is null then ' ' else ' and (status = ''' + @status + ''')' end + -- отфильтровали по статусу
		case when @carrier is null then ' ' else ' and (carrierkey like ''' + @carrier + ''')' end + -- отфильтровали по поставщику
		case when @susr5 is null then ' ' else ' and (susr5 like ''%' + ltrim(rtrim(@susr5)) + '%'')' end + -- отфильтровали по поставщику
		case when @EXTERNRECEIPTKEY is null then ' ' else ' and (EXTERNRECEIPTKEY like ''%' + ltrim(rtrim(@EXTERNRECEIPTKEY)) + '%'')' end + -- отфильтровали по поставщику
		' and (expectedreceiptdate between '''+ @date1+''' and '''+@date2+''' )'-- отфильтровали по ожидаемой дате получения

	exec (@sql)
	
	
	create table #receiptDet (receiptkey varchar(10)COLLATE Cyrillic_General_CI_AS,
		expectedQTY decimal(22,5),expPalQTY decimal(22,5),receivedQTY decimal(22,5),ErrInPack int)

	set @sql = 'insert into #receiptDet (receiptkey,expectedQTY,expPalQTY,receivedQTY,ErrInPack)'
	set @sql = @sql+ ' select receiptkey, 
			sum(ceiling((qtyexpected+qtyadjusted)/case pk.pallet when 0 then 1 else pk.pallet end )) expectedQTY, 
			sum(ceiling(sku.stdcube*(qtyexpected+qtyadjusted)/'+cast(@PlaceVol as varchar)+')) expPalQTY,
			sum(ceiling(qtyreceived/case pk.pallet when 0 then 1 else pk.pallet end )) receivedQTY,
			sum(case isnull(pk.pallet,0) when 0 then 1 else 0 end ) ErrInPack '
	set @sql = @sql+ '	from '+@WH+'.receiptdetail rd
		left join '+@WH+'.sku sku on rd.sku=sku.sku and rd.storerkey = sku.storerkey
		left join '+@WH+'.pack pk on pk.packkey = sku.rfdefaultpack
	where receiptkey in (select receiptkey from #receipt)
	group by receiptkey'
	exec(@sql)

	print 3
	set @sql = 'select r.*, expectedQTY,expPalQTY,ErrInPack
	from #receipt r
	join #receiptDet rd on r.Receiptkey = rd.receiptkey' 
	+ case when isnull(@sortOrder,0) > 0 then
	' order by '  
	+ case isnull(@sortOrder,0)
		when 1 then 'r.receiptKey' 
		when 2 then 'r.company' 
		when 3 then 'r.expectedreceiptdate'
		when 4 then 'r.status' 
		else 'r.receiptKey' 
	end + ' ' 
	+ case isnull(@sortDirection,0)
		when 0 then 'asc'
		else 'desc'
	end else '' end
	exec (@sql)

set nocount off
drop table #storer
drop table #receipt
drop table #receiptDet

