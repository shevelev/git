ALTER PROCEDURE [dbo].[rep59_WhoPackShipOrder] (
	@wh varchar(10),
	@orderkey varchar(10)=null,
	@dropid varchar(10)=null
)AS

--declare @orderkey varchar(10), @dropid varchar(10), @wh varchar(20)
--select @orderkey = '0000005700',@dropid='D000007171', @wh = 'wh40'

	declare @sql varchar(max)
	
	--set @sql = ' select distinct pd.orderkey, o.externorderkey, pls.dropid pdudf1, pls.tsid pdudf3, 
	  set @sql = ' select distinct pd.orderkey, o.externorderkey, 
		pd.status, pd.dropid, 
		d1.adddate packdate, d1.addwho packwho, us1.usr_name packwhoName,
		d2.editdate shipdate, d2.editwho shipwho, us2.usr_name shipwhoName
	from '+@wh+'.pickdetail pd
	--	join '+@wh+'.PackLoadSend pls on pls.serialkey = pd.serialkey
	--	join '+@wh+'.dropid d1 on d1.dropid = pls.dropid
	--	left join '+@wh+'.dropid d2 on d2.dropid = pls.tsid
		left join ssaadmin.pl_usr us1 on us1.usr_login = d1.addwho
		left join ssaadmin.pl_usr us2 on us2.usr_login = d2.editwho
			 join '+@wh+'.orders o on pd.orderkey = o.orderkey
	where 1=1 ' +
		+ case when isnull(@orderkey,'')='' then '' else ' and pd.orderkey = '''+@orderkey+''' ' end
	--	+ case when isnull(@dropid,'')='' then '' else ' and pls.dropid = '''+@dropid+''' ' end
		+ case when isnull(@dropid,'')='' then '' end
	+' order by pd.orderkey desc'
exec (@sql)

--select * from wh40.dropid--detail
--select * from WH40.PackLoadSend
--select * from WH40.pickdetail

