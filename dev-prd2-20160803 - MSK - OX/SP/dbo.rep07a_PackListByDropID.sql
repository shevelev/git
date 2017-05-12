ALTER PROCEDURE [dbo].[rep07a_PackListByDropID](
	@wh varchar(10),
	@datebegin datetime,
	@dateend datetime,
	@loadkey varchar(12)=null,
	@wave varchar(12)=null,
	@orderkey varchar(12)=null,
	@dropid varchar(18)=null
) 
--with encryption
AS

--declare @wh varchar(10),
--		@orderkey varchar(12)
--	select @wh='wh40', @orderkey='0000001211'
set dateformat dmy

declare @bdate varchar(10), @edate varchar(10)

set @bdate=convert(varchar(10),@datebegin,104)
set @edate=convert(varchar(10),@dateend,104)
	
	set @wh = upper(@wh)
	set @orderkey= replace(upper(@orderkey),';','')  -- удалить ; из строк задаваемых пользователем для увеличения безопасности.
    --// KSV
   -- set @orderkey= '%' + @orderkey

    --// KSV END
	declare 
		@sql varchar(max)
		
CREATE TABLE [dbo].[#tpack](
	[orderkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	--[dropid] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[caseid] [varchar](20) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[qty] [decimal](38, 5) NULL,
	[storerkey] [varchar](15) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[sku] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[packkey] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL)

--CREATE TABLE [dbo].[#resulttable](
--	[orderkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[dropid] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[caseid] [varchar](20) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[qty] [decimal](38, 5) NULL,
--	[storerkey] [varchar](15) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[sku] [varchar](50) COLLATE Cyrillic_General_CI_AS NOT NULL,
--	[CompanyName] [varchar](100) COLLATE Cyrillic_General_CI_AS NULL,
--	[descr] [varchar](60) COLLATE Cyrillic_General_CI_AS NULL,
--	[orderdate] [datetime] NULL,
--	[requestedshipdate] [datetime] NULL,
--	externorderkey varchar(18) null,
--	[StorerName] [varchar](45) COLLATE Cyrillic_General_CI_AS NULL,
--	[ClientName] [varchar](100) COLLATE Cyrillic_General_CI_AS NULL,
--	[ClientCode] [varchar](15) COLLATE Cyrillic_General_CI_AS NULL,
--	[ClientAddr] [varchar](238) COLLATE Cyrillic_General_CI_AS NULL
--)

set @sql = 
	'insert into #tpack 
	select orderkey,
	caseid, sum(qty) qty, storerkey, sku,packkey 
	from '+@wh+'.pickdetail 
	where orderkey in (select orderkey from '+@wh+'.orders where orderdate between '''+@bdate+''' and '''+@edate+''') '+
	case when isnull(@loadkey,'')='' then '' else 'and orderkey in (
	  select SHIPMENTORDERID
	  from '+@wh+'.LOADORDERDETAIL lod
	  join '+@wh+'.LOADSTOP ls on ls.LOADSTOPID=lod.LOADSTOPID
	  where ls.LOADID='''+@loadkey+'''
	) ' end+
	case when isnull(@wave,'')='' then '' else 'and orderkey in (select orderkey from '+@wh+'.wavedetail where wavekey='''+@wave+''') ' end+
	case when isnull(@orderkey,'')='' then '' else 'and orderkey = '''+@orderkey+''' ' end+
	case when isnull(@dropid,'')='' then '' else 'and caseid in (select caseid from dbo.func_return_caseid_from_dropid('''+@dropid+''')) ' end+
	' group by orderkey, caseid, storerkey, sku,packkey'
print @sql
exec (@sql)	

create table #tablecaseidxdropid (caseid varchar(12),dropid varchar(12))
set @sql='
  insert into #tablecaseidxdropid(caseid)
  select distinct caseid
  from #tpack
  where not caseid is null
  
  update #tablecaseidxdropid
  set dropid=dbo.func_return_general_dropid_from_caseid(caseid)
'
print(@sql)
exec(@sql)

--insert into #resulttable
set @sql =	'
		select p.*, st.CompanyName, s.descr, o.orderdate, o.requestedshipdate, o.externorderkey,
		st.company StorerName, cl.CompanyName ClientName, cl.storerkey ClientCode,
		cl.address1 +'' ''+ cl.address2 +'' ''+ cl.address3 +'' ''+ cl.address4 ClientAddr,
		(o.C_Address1+o.C_Address2+o.C_Address3+o.C_Address4) DeliveryAdr, cl.vat clientINN, isnull(s.susr4, ''шт.'') baseMeasure,
		pk.casecnt, o.door
  	,tcd.dropid
  	,dbo.GetEAN128(tcd.dropid) bcDropID
	from #tpack p
		left join '+@wh+'.sku s on s.sku=p.sku and s.storerkey=p.storerkey
		left join '+@wh+'.storer st on st.storerkey = p.storerkey
		left join '+@wh+'.orders o on o.orderkey=p.orderkey
		left join '+@wh+'.storer cl on cl.storerkey = o.consigneekey
    left join '+@wh+'.pack pk on p.packkey=pk.packkey
    left join #tablecaseidxdropid tcd on p.caseid=tcd.caseid
	order by tcd.dropid, p.caseid
	'
print @sql
exec (@sql)

--select * from #resulttable order by dropid, caseid

drop table #tpack
drop table #tablecaseidxdropid
--drop table #resulttable

/*
select p.*, st.CompanyName, s.descr, o.orderdate, o.requestedshipdate, o.externorderkey,
		st.company StorerName, cl.CompanyName ClientName, cl.storerkey ClientCode,
		cl.address1 , cl.address2 , cl.address3 ,
		cl.address4 ,--ClientAddr,
		o.DeliveryAdr, 
		cl.vat clientINN, 
		isnull(s.susr4, 'шт.') baseMeasure, 
		--dbo.GetEAN128(p.dropid) bcDropID,
		o.door
	from #tpack p
		left join WH40.sku s on s.sku=p.sku and s.storerkey=p.storerkey
		left join WH40.storer st on st.storerkey = p.storerkey
		left join WH40.orders o on o.orderkey=p.orderkey
		left join WH40.storer cl on cl.storerkey = o.consigneekey
	order by dropid, caseid





*/

