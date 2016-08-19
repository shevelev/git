ALTER PROCEDURE [dbo].[rep99_CaseID_old] (
	@wh varchar(30),
	@datebegin datetime,
	@dateend datetime,
	@wavekey varchar(10),
	@orderkey varchar (10),
	@st varchar(15)

)as

--declare @wh varchar(30),
--	@orderkey varchar (10)
--select @wh='wh40',  @orderkey='0000005208'

declare 
	@sql varchar(max)

CREATE TABLE [dbo].[#resulttable](
	[orderkey] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[WAVEKEY] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[CASEID] [nvarchar](128) COLLATE Cyrillic_General_CI_AS NULL,
	[CID] [varchar](20) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[CARTONTYPE] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[DOOR] [varchar] (30)  COLLATE Cyrillic_General_CI_AS NULL,	
	[company] [varchar](45) COLLATE Cyrillic_General_CI_AS NULL,
	[vat] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
	[externorderkey] [varchar](32) COLLATE Cyrillic_General_CI_AS NULL,
	[SUSR4] [varchar](30) collate Cyrillic_General_CI_AS NULL,
  [business] [varchar](45) collate Cyrillic_General_CI_AS NULL,
  [SUSR2] [varchar](30) collate Cyrillic_General_CI_AS NULL,
  [STDCUBE] float,
  [LOCATIONTYPE] [varchar](10) collate Cyrillic_General_CI_AS NULL,
	[CARTONGROUP] [varchar](10)  COLLATE Cyrillic_General_CI_AS NOT NULL
  )


-- EV <

set dateformat dmy
set @sql = '
declare @Ord_id varchar(10)
DECLARE Ord_cursor CURSOR
FOR 
SELECT distinct '+
	    'whpd.orderkey '+ 
	'FROM '+@wh+'.PICKDETAIL as whpd '+
			'join '+@wh+'.ORDERS as who on whpd.orderkey = who.orderkey '+
			'join '+@wh+'.WAVEDETAIL as wd on whpd.orderkey = wd.orderkey '+
			'join '+@wh+'.SKU sku on whpd.SKU=sku.SKU '+
			'join '+@wh+'.LOC loc on whpd.LOC=loc.LOC '+
			'left join '+@wh+'.storer as whs on who.b_company = whs.storerkey '+
			'left join '+@wh+'.storer as bus on who.storerkey=bus.storerkey '+
			'left join '+@wh+'.storer as pal on who.B_COMPANY=pal.storerkey '+
	'WHERE (whpd.STATUS < 5) AND (whpd.loc not like ''07%'') '+
	'and who.STORERKEY='''+@st+''' '+
	'and who.ORDERDATE between '''+convert(varchar,@datebegin,104)+''' and '''+convert(varchar,@dateend,104)+''' '+
	case when isnull(@wavekey,'')='' then '' else 'AND (whpd.ORDERKEY in (select ORDERKEY from '+@wh+'.WAVEDETAIL where WAVEKEY='''+@wavekey+''')) ' end+
	case when isnull(@orderkey,'')='' then '' else 'AND (whpd.ORDERKEY = '''+@orderkey+''') ' end+
	'
OPEN Ord_cursor
FETCH NEXT FROM Ord_cursor INTO @Ord_id
WHILE @@FETCH_STATUS= 0
BEGIN
  exec dbo.Up_pick @Ord_id  
  FETCH NEXT FROM Ord_cursor INTO  @Ord_id
END 
CLOSE Ord_cursor
DEALLOCATE Ord_cursor

'

exec(@sql)
-- EV >


set @sql =
'set dateformat dmy '+
'insert  into #resulttable '+
	'SELECT '+
	    'whpd.orderkey, '+ 
	    'wd.WAVEKEY, '+
			'dbo.GetEAN128(whpd.CASEID) CASEID, '+
			'whpd.CASEID as CID, '+
			'ISNULL ( whpd.CARTONTYPE , ''PALLET'') '+
			'AS CARTONTYPE, '+
			'who.TRANSPORTATIONSERVICE, ' +
			'whs.company, '+
			'whs.vat, '+
			'who.externorderkey, '+
			'who.SUSR4, '+
			'bus.company business, '+
			'pal.SUSR2, '+
			'cast(sum(ISNULL(whpd.QTY,0)*ISNULL(sku.STDCUBE,0)) as float) STDCUBE, '+
			'loc.LOCATIONTYPE, '+
			'sku.CARTONGROUP '+
	'FROM '+@wh+'.PICKDETAIL as whpd '+
			'join '+@wh+'.ORDERS as who on whpd.orderkey = who.orderkey '+
			'join '+@wh+'.WAVEDETAIL as wd on whpd.orderkey = wd.orderkey '+
			'join '+@wh+'.SKU sku on whpd.SKU=sku.SKU '+
			'join '+@wh+'.LOC loc on whpd.LOC=loc.LOC '+
			'left join '+@wh+'.storer as whs on who.b_company = whs.storerkey '+
			'left join '+@wh+'.storer as bus on who.storerkey=bus.storerkey '+
			'left join '+@wh+'.storer as pal on who.B_COMPANY=pal.storerkey '+
	'WHERE (whpd.STATUS < 5) AND (whpd.loc not like ''07%'') '+
	'and who.STORERKEY='''+@st+''' '+
	'/*and whpd.LOC in (select LOC from '+@wh+'.LOC where LOCATIONTYPE in (''CASE'',''PICK''))*/ '+
	'and who.ORDERDATE between '''+convert(varchar,@datebegin,104)+''' and '''+convert(varchar,@dateend,104)+''' '+
	case when isnull(@wavekey,'')='' then '' else 'AND (whpd.ORDERKEY in (select ORDERKEY from '+@wh+'.WAVEDETAIL where WAVEKEY='''+@wavekey+''')) ' end+
	case when isnull(@orderkey,'')='' then '' else 'AND (whpd.ORDERKEY = '''+@orderkey+''') ' end+
			--' and whpd.id = ''' + '''' +
	'group by '+		
	    'whpd.orderkey, '+ 
	    'wd.WAVEKEY, '+
			'dbo.GetEAN128(whpd.CASEID), '+
			'whpd.CASEID, '+
			'ISNULL ( whpd.CARTONTYPE , ''PALLET''), '+
			'who.TRANSPORTATIONSERVICE,' +			
			'whs.company, '+
			'whs.vat, '+
			'who.externorderkey, '+
			'who.SUSR4, '+
			'bus.company, '+
			'pal.SUSR2, '+
			'loc.LOCATIONTYPE, '+
			'sku.CARTONGROUP' +
		' order by whpd.caseID'
--select @sql
exec (@sql)
print(@sql)
if not exists (select * from #resulttable) 
	insert into #resulttable (orderkey,WAVEKEY,CASEID,CID,CARTONTYPE,DOOR,company,business,STDCUBE,LOCATIONTYPE,
								CARTONGROUP) values ('','','','нет данных','нет','нет','','',0.000,'','')
select * from #resulttable
drop table #resulttable



--select * from wh40.pickdetail where  orderkey='0000000622'

