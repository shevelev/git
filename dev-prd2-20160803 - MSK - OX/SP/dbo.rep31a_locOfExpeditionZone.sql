ALTER PROCEDURE [dbo].[rep31a_locOfExpeditionZone](
 	@wh  varchar (10),
 	@externorderkey  varchar (10),
	@dropid  varchar (18),
	@orderkey  varchar (32),
	@vat varchar (20)=NULL,
	@company varchar (50)=NULL
) as

/*--------------TEST----------------*/
--declare @externorderkey varchar (10),
--	@dropid  varchar (18),
--	@orderkey  varchar (32),
--	@vat varchar (20),
--	@company varchar (50),
--	@wh varchar(10)
--set @wh = 'wh40'
/*----------------------------------*/

--	select * from #loc
declare 
@sql varchar (max)

  create table #LOC (
    LOC varchar(10) collate Cyrillic_General_CI_AS
  )

set @sql='select LOC into #LOC from '+@wh+'.LOC where PUTAWAYZONE like ''PODOBRANO%'''
	exec (@sql)

set @sql = 
	'select l.LOC, pd.dropid, o.orderkey, o.externorderkey, o.c_company, st.vat, sum(pd.qty*s.stdcube) vol
	from #LOC l
		left join '+@wh+'.pickdetail pd on pd.toloc = l.LOC
		left join '+@wh+'.orders o on o.orderkey = pd.orderkey
		left join '+@wh+'.storer st on st.storerkey = o.consigneekey
		left join '+@wh+'.sku s on s.sku = pd.sku and s.storerkey = pd.storerkey
	where ((pd.status >=5 and pd.status < 9 ) or pd.status is null )' +
case when @externorderkey is null then '' else ' and o.externorderkey = '''+@externorderkey+'''' end  +
case when @dropid is null then '' else ' and pd.dropid = '''+@dropid+'''' end +
case when @orderkey is null then '' else ' and o.orderkey = '''+@orderkey+'''' end +
case when @vat is null then '' else ' and st.vat = '''+@vat+'''' end +
case when @company is null then '' else ' and o.c_company like '''+@company+'''' end +	
	' Group by l.loc, pd.dropid, o.orderkey, o.externorderkey, o.c_company, st.vat'
exec (@sql)

--select * from #loc

	drop table #loc

