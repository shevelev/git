ALTER PROCEDURE [rep].[mof_Experience_with_cell](
		@wh varchar(10),
		@loc varchar(20),
		@sku varchar(10),
		@date1 smalldatetime,
		@date2 smalldatetime
)
--with encryption
AS

--Declare @loc varchar(20),
--		@date1 varchar(10),
--		@date2 varchar(10)
--select @loc = '08.02C03', @date1 = '20080101', @date2 = '20080619'

	declare	@sql varchar (max)

--#region Tables
	CREATE TABLE [dbo].[#loc](
		[loc] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL)

	CREATE TABLE [dbo].[#itrn](
		[SERIALKEY] [int] NOT NULL,
		[WHSEID] [varchar](30) COLLATE Cyrillic_General_CI_AS NULL,
		[ITRNKEY] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[ITRNSYSID] [int] NULL,
		[TRANTYPE] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[STORERKEY] [varchar](15) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[SKU] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[LOT] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[FROMLOC] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[FROMID] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[TOLOC] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[TOID] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[SOURCEKEY] [varchar](20) COLLATE Cyrillic_General_CI_AS NULL,
		[SOURCETYPE] [varchar](30) COLLATE Cyrillic_General_CI_AS NULL,
		[STATUS] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
		[LOTTABLE01] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[LOTTABLE02] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[LOTTABLE03] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[LOTTABLE04] [datetime] NULL,
		[LOTTABLE05] [datetime] NULL,
		[LOTTABLE06] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[LOTTABLE07] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[LOTTABLE08] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[LOTTABLE09] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[LOTTABLE10] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[CASECNT] [decimal](22, 5) NOT NULL,
		[INNERPACK] [decimal](22, 5) NOT NULL,
		[QTY] [decimal](22, 5) NOT NULL,
		[PALLET] [decimal](22, 5) NOT NULL,
		[CUBE] [float] NOT NULL,
		[GROSSWGT] [float] NOT NULL,
		[NETWGT] [float] NOT NULL,
		[OTHERUNIT1] [float] NOT NULL,
		[OTHERUNIT2] [float] NOT NULL,
		[PACKKEY] [varchar](50) COLLATE Cyrillic_General_CI_AS NULL,
		[UOM] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
		[UOMCALC] [int] NULL,
		[UOMQTY] [decimal](22, 5) NULL,
		[EFFECTIVEDATE] [datetime] NOT NULL,
		[RECEIPTKEY] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
		[RECEIPTLINENUMBER] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
		[ADDDATE] [datetime] NOT NULL,
		[ADDWHO] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[EDITDATE] [datetime] NOT NULL,
		[EDITWHO] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL)
--		[flag1] [int] NULL)

	CREATE TABLE [dbo].[#resulttable](
		[loc] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[trantype] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[trantypeDescr] [varchar](13) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[storerkey] [varchar](15) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[sku] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[descr] [varchar](80) COLLATE Cyrillic_General_CI_AS NULL,
		[lot] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[fromLoc] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[toLoc] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[fromID] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[toID] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[qty] [decimal](22, 5) NOT NULL,
		[adddate] [datetime] NOT NULL,
		[addwho] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
		[usr_name] [varchar](40) COLLATE Cyrillic_General_CI_AS NULL)

--#endregion
	--Declare @loc varchar(20),
	--		@date1 varchar(10),
	--		@date2 varchar(10)
	--select @loc = '08.02C03', @date1 = '20080101', @date2 = '20080619'

		set @sql =
		'insert into #loc select loc from '+@wh+'.loc where loc = '''+@loc+''''
		exec (@sql)

		--select usr_login userlogin, usr_name username into #users  from ssaadmin.pl_usr
		set @date2 = dateadd(dy, 1, @date2)

		set @sql = 
		'insert into #itrn select * from '+@wh+'.itrn where 1=1 ' + /*and trantype = 'DP'*/ 
			'and (toloc = ''' +@loc+ ''' or fromloc = '''+@loc+''')' +
			case when @date1 is null then '' else ' and adddate >= ''' + convert(varchar,@date1,112) + '''' end + 
			case when @date2 is null then '' else ' and adddate < ''' + convert(varchar,@date2,112) + '''' end + 
		' order by ADDdate'
		exec (@sql)
--select * from wh40.itrn
		select toloc loc, trantype, storerkey, sku, LOTTABLE02, fromloc, toloc, fromid, toid, qty, adddate, addwho
		into #movein 
		 from #itrn where trantype = 'MV' and toloc=@loc

		select fromloc loc, trantype, storerkey, sku, LOTTABLE02, fromloc, toloc, fromid, toid, qty, adddate, addwho
		into #moveout 
		 from #itrn where trantype = 'MV' and fromloc=@loc

		select toloc loc, trantype, storerkey, sku, LOTTABLE02, fromloc, toloc, fromid, toid, qty, adddate, addwho 
		into #in 
		from #itrn where trantype = 'DP'

		select toloc loc, trantype, storerkey, sku, LOTTABLE02, fromloc, toloc, fromid, toid, qty, adddate, addwho 
		into #out 
		from #itrn where trantype = 'WD'

		select toloc loc, trantype, storerkey, sku, LOTTABLE02, fromloc, toloc, fromid, toid, qty, adddate, addwho 
		into #adj 
		from #itrn where trantype = 'AJ'

		--select * 	from #loc l
		--select * into #res from 
			select * into #res from #in
			union
			select * from #movein
			union
			select * from #adj
			union
			select * from #moveout
			union
			select * from #out

	--select * from #res 
		update #res set qty=-qty, fromloc='' where loc=fromloc and trantype = 'MV'
		update #res set toloc='' where loc=toloc and trantype = 'MV'
		set @sql =
		'insert into #resulttable select rs.loc, trantype,
			case trantype
				when ''DP'' then ''Вложение''
				when ''MV'' then ''Перемещение''
				when ''AJ'' then ''Корректировка''
				when ''WD'' then ''Изъятие''
				else ''Неизвестно''
			end trantypeDescr,
			rs.storerkey, rs.sku, sku.descr, LOTTABLE02, 
			case when trantype=''MV'' then fromloc else '''' end fromLoc,
			case when trantype=''MV'' then toloc else '''' end toLoc,
			case when trantype=''MV'' or trantype=''WD'' then fromid else '''' end fromID,
			case when trantype=''MV'' or trantype=''DP'' then toid else '''' end toID, 
			qty, rs.adddate, rs.addwho, usr.usr_name 
		from #res rs 
			left join ssaadmin.pl_usr usr on usr.usr_login = rs.addwho
			left join '+@wh+'.sku sku on sku.storerkey=rs.storerkey and sku.sku=rs.sku
		where 1=1 '+ case when isnull(@sku,'')='' then '' else ' and sku.sku like '''+@sku+'''' end +
	' order by rs.adddate desc'
		exec (@sql)
		
	select * from #resulttable
	
	drop table #loc
	drop table #in
	drop table #out
	drop table #itrn
	drop table #adj
	drop table #movein
	drop table #moveout
	drop table #res


