ALTER PROCEDURE [dbo].[rep48_Cable] 
	@date1 datetime=null,
	@pallet varchar(15)=null,
	@wh varchar(10),
	@userName varchar(50),
	@opType int,
	@sku varchar (50),
	@descr varchar (60)
AS

--declare @date1 datetime,
--		--@date2 datetime,
--		@pallet varchar(15),
--		@wh varchar(15),@userName varchar(50),@opType int
--set @date1=null
--set	@pallet=null
--select @wh='WH40', @date1 = null,  @pallet = '',@userName ='',@opType =2

declare @date2 datetime

declare @sql varchar(max)
set	@date2 = dateadd(dy,1,@date2)	
set @sql=null


set @sql = 'select case when trantype = ''DP'' then i.toid else i.FROMID end toid, 
	i.ADDDATE, i.ADDWHO, i.LOT, i.QTY, i.FROMID, i.TRANTYPE, u.usr_name, 
case  
when trantype = ''MV'' and sourcetype = ''PICKING'' then ''ÎÒÌÎÒÊÀ''
when trantype = ''DP'' then ''ÏĞÈÅÌÊÀ''
end otype, s.sku, s.descr
from '+@wh+'.itrn i
	join '+@wh+'.sku s on s.sku=i.sku and s.storerkey=i.storerkey
	join ssaadmin.pl_usr u on u.usr_login = i.ADDWHO
where 1=1 and i.status = ''OK'' and s.lottablevalidationkey = ''02''
	'+ case when @date1 is null then '' else ' and i.adddate>='''+convert(varchar(10),@date1,112)+'''' end 
+ case when @date2 is null then '' else ' and i.adddate<'''+convert(varchar(10),@date2,112)+'''' end 
+ case when isnull(@pallet,'')='' then '' else 
	' and case when trantype = ''DP'' then i.toid else i.FROMID end like '''+@pallet+'''' end 
+ case when isnull(@userName,'')='' then '' else ' and u.usr_name like '''+@userName+'''' end 
+ case @opType when 0 then ' and (trantype=''DP'' or (trantype=''MV'' and  sourcetype = ''PICKING''))' 
+ case when isnull(@sku,'')='' then '' else ' and s.sku like '''+@sku+'''' end
+ case when isnull(@descr,'')='' then '' else ' and s.descr like '''+@descr+'''' end
	when 1 then ' and  trantype=''DP'' ' when 2 then ' and  trantype=''MV'' and  sourcetype = ''PICKING''' else '' end

--select * from wh40.itrn

print (@sql)
exec (@sql)

