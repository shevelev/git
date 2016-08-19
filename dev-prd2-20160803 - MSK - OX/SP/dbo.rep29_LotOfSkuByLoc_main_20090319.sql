ALTER PROCEDURE [dbo].[rep29_LotOfSkuByLoc_main_20090319] (
--	-- Add the parameters for the stored procedure here
@wh varchar(10),
@lot varchar (10),
@loc varchar (10),
@sortOrder int,
@carrierName varchar (45),
@sortDirection int

)
AS

--declare	@wh varchar (10),	@lot varchar (10),	@loc varchar (10),
--	@sortOrder varchar (30),	@carrierName varchar (45),	@sortDirection varchar (30)
--select @lot='0000002618'
--set @wh='wh40'
--set @loc=null
--set @sortOrder=1
--set @carrierName=null
--set @sortDirection=0



declare @sql varchar (max)


CREATE TABLE #result(
	[lot] [varchar](15) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[loc] [varchar](15) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[ID] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[status] [varchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[statusName] [varchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[statusCode] [int] NOT NULL,
	[qty] [decimal](22, 5) NOT NULL,
	[qtyAllocated] [decimal](22, 5) NOT NULL,
	[qtyAvailable] [decimal](23, 5) NULL,
	[CarrierName] [varchar](100) COLLATE Cyrillic_General_CI_AS NULL,
	[company] [varchar](100) COLLATE Cyrillic_General_CI_AS NULL,
	[sku] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
	[descr] [varchar](100) COLLATE Cyrillic_General_CI_AS NULL

)


set @sql = 'insert into #result
select lli.lot, loc, ID, lli.status,
		case lli.status 
			when ''OK'' then lli.status
			when ''HOLD'' then ''Áëîêèðîâàí''
			else ''!!ÎØÈÁÊÀ!!''
		end statusName,
		case lli.status 
			when ''OK'' then 0
			when ''HOLD'' then 1
			else -1
		end statusCode,
		qty,
		qtyAllocated,
		case when lli.status=''OK'' then qty - qtyAllocated else 0 end qtyAvailable,
		s.Company CarrierName,
		s2.Company,
		sk.sku,
		sk.descr
		
	from '+@wh+'.lotxlocxid lli
		left join '+@wh+'.LOTATTRIBUTE la on la.lot=lli.lot
		left join '+@wh+'.receipt r on la.lottable06=r.receiptkey
		left join '+@wh+'.storer s on s.storerkey=r.carrierkey
			 join '+@wh+'.storer s2 on s2.storerkey=lli.storerkey
			 join '+@wh+'.sku sk on sk.sku = lli.sku and sk.storerkey=lli.storerkey		
	where 1=1 ' +
		case when isnull(@carrierName,'')=''  then '' else ' and (s.Company like ''' + @carrierName + ''')' end +
		case when isnull(@lot,'')=''  then '' else '  and (lli.lot like ''' + @lot + ''') ' end +
		case when isnull(@loc,'')=''  then '' else ' and (loc like ''' + @loc + ''')' end +
		' and  (qty > 0)'



exec (@sql)

	set @sql = ' select * from #result'
		+ case when isnull(@sortOrder,0) > 0 then
		' order by '  
		+ case isnull(@sortOrder,0)
			when 1 then 'lot' 
			when 2 then 'loc'
			when 3 then 'ID' 
			when 4 then 'CarrierName' 
			else 'lot' 
		end + ' ' 
		+ case isnull(@sortDirection,0)	when 0 then 'asc' else 'desc'
		end else '' end
		exec (@sql)



drop table #result

