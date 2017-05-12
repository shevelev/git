ALTER PROCEDURE [dbo].[rep32_CargoPlaces] (@wh varchar(10))
AS

--declare 
--	@wh varchar(10)
--select @wh='wh40'

declare
	@sql varchar (max)

CREATE TABLE [dbo].[#gruz](
	[loc] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[lot] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[adddate] [datetime] NOT NULL,
	[id] [varchar](18) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[dd] [int] NOT NULL,
	[hh] [int] NOT NULL,
	[mm] [int] NOT NULL,
	[InMinutes] [int] NOT NULL)

	set @sql = 
		'insert into #gruz select distinct lli.loc, lli.lot, lli.adddate, lli.id, 0 dd,0 hh,0 mm, 0 InMinutes
		from '+@wh+'.lotxlocxid lli
			join '+@wh+'.lotattribute la on. lli.lot = la.lot
			join '+@wh+'.receiptdetail rd on la.sku=rd.sku and rd.receiptkey=la.lottable06
		where lli.sku like ''GRUZ'' and qty >0'
exec (@sql)

		update #gruz set InMinutes = datediff(mi,adddate,getdate())
		
		update #gruz set dd= floor(InMinutes/(24*60))
		
		update #gruz set hh=floor(InMinutes - dd*24*60)/60
		--update #gruz set InMinutes=floor((InMinutes-floor(InMinutes/(24*60)))/60)
		
		--update #gruz set mm=InMinutes
		update #gruz set mm= (InMinutes-dd*24*60 - hh*60)
		
		--update #gruz set hh=floor(InMinutes/60)
		--update #gruz set InMinutes=InMinutes-floor(InMinutes/60)

		select *,case when dd=0 then '' else
		cast (dd as varchar) + 
				case right(cast (dd as varchar),1)
					when 0 then ' дней ' 
					when 1 then ' день ' 
					when 2 then ' дня ' 
					when 3 then ' дня ' 
					when 4 then ' дня ' 
					when 5 then ' дней ' 
					when 6 then ' дней ' 
					when 7 then ' дней ' 
					when 8 then ' дней ' 
					when 9 then ' дней ' 
					else 'дн.'
				end end + case when hh < 10 then '0' else '' end+
				cast(hh as varchar)+':'+case when mm < 10 then '0' else '' end+
				cast(mm as varchar) AwayTime
		 from #gruz

		drop table #gruz

