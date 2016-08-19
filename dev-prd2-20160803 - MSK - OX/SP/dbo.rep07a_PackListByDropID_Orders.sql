ALTER PROCEDURE [dbo].[rep07a_PackListByDropID_Orders](
	@wh varchar(10),
	@datebegin datetime,
	@dateend datetime,
	@loadkey varchar(12)=null,
	@wave varchar(12)=null,
	@orderkey varchar(12)=null,
	@dropid varchar(18)=null
) 
AS

set dateformat dmy

declare @bdate varchar(10), @edate varchar(10)

set @bdate=convert(varchar(10),@datebegin,104)
set @edate=convert(varchar(10),@dateend,104)
	
	set @wh = upper(@wh)
	set @orderkey= replace(upper(@orderkey),';','')  -- удалить ; из строк задаваемых пользователем для увеличения безопасности.
	declare 
		@sql varchar(max)
		
set @sql = 
	'select distinct p.orderkey
	,oc.EXTERNORDERKEY oc_orderkey,oc.c_company
	,oc.c_address1 +'' ''+ oc.c_address2 +'' ''+ oc.c_address3 +'' ''+ oc.c_address4 c_address
	from '+@wh+'.pickdetail p
  left join '+@wh+'.orders_c oc on p.orderkey=oc.orderkey
	where p.orderkey in (select orderkey from '+@wh+'.orders where orderdate between '''+@bdate+''' and '''+@edate+''') '+
	case when isnull(@loadkey,'')='' then '' else 'and p.orderkey in (
	  select SHIPMENTORDERID
	  from '+@wh+'.LOADORDERDETAIL lod
	  join '+@wh+'.LOADSTOP ls on ls.LOADSTOPID=lod.LOADSTOPID
	  where ls.LOADID='''+@loadkey+'''
	) ' end+
	case when isnull(@wave,'')='' then '' else 'and p.orderkey in (select orderkey from '+@wh+'.wavedetail where wavekey='''+@wave+''') ' end+
	case when isnull(@orderkey,'')='' then '' else 'and p.orderkey = '''+@orderkey+''' ' end+
	case when isnull(@dropid,'')='' then '' else 'and p.caseid in (select caseid from dbo.func_return_caseid_from_dropid('''+@dropid+''')) ' end+
	' order by oc.EXTERNORDERKEY'
print @sql
exec (@sql)

