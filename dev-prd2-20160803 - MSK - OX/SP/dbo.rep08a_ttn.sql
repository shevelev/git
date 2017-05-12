ALTER PROCEDURE [dbo].[rep08a_ttn] (
	@wh varchar(30),
	@orderkey varchar(15),
	@NumOfPlaces varchar (10) = null,
	@TS varchar(10) = ''
)
as

--declare 
--	@wh varchar(30),
--	@orderkey varchar(15),
--	@NumOfPlaces varchar (10),
--	@TS varchar(10)
--select 	@wh ='wh40',	@orderkey ='0000002475',	@NumOfPlaces = null,	@TS = 'TS00001081'


CREATE TABLE [#ttn](
	[EditDate] [datetime] NULL,
	[ORDERKEY] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[DESCR] [varchar](60) COLLATE Cyrillic_General_CI_AS NULL,
	[SKU] [varchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[shippedqty] [decimal](38, 5) NULL,
	[price] [decimal](38, 4) NULL,
	[cost] [decimal](38, 6) NULL,
	[Storer] [varchar](349) COLLATE Cyrillic_General_CI_AS NULL,
	[DeliveryAdr] [varchar](311) COLLATE Cyrillic_General_CI_AS NULL,
	[CLIENT] [varchar](349) COLLATE Cyrillic_General_CI_AS NOT NULL,
	[grossWeightTonn] [float] NULL,
	[netWeightTonn] [float] NULL,
	[NumOfPlaces] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL)

declare @sql varchar(max)
set @sql =

'insert into #ttn
SELECT     
	CONVERT(datetime, CONVERT(varchar(10), ord.EDITDATE, 104), 104) AS EditDate, 
	od.ORDERKEY, s.DESCR, s.SKU, SUM(od.QTY) AS shippedqty, 
	SUM(ISNULL(s.PRICE, 0)) AS price, 
	SUM(ISNULL(s.PRICE, 0) * od.QTY) AS cost,
    (SELECT     ISNULL(COMPANY, '''') + '', »ÕÕ '' + ISNULL(VAT, '''') + '', '' 
			+ ISNULL(ADDRESS1, '''') + '' '' + ISNULL(ADDRESS2, '''') + '' '' + ISNULL(ADDRESS3, '''')+ '' '' + ISNULL(ADDRESS4, '''')
			+ '', '' + ISNULL(PHONE1, '''') + '', '' + ISNULL(FAX1, '''') AS Expr1
        FROM '+@wh+'.STORER
        WHERE (STORERKEY = ''ST6661018350'')) AS Storer, 
ISNULL(st.COMPANY, '''') + '', »ÕÕ '' + ISNULL(st.VAT, '''') + '', '' + ord.DeliveryAdr
        + '', '' + ISNULL(st.PHONE1, '''') 
        + '', '' + ISNULL(st.FAX1, '''')  DeliveryAdr,
    ISNULL(st.COMPANY, '''') + '', »ÕÕ '' + ISNULL(st.VAT, '''') + '', '' + ISNULL(st.ADDRESS1, '''') 
        + '' '' + ISNULL(st.ADDRESS2, '''') + '' '' + ISNULL(st.ADDRESS3, '''') + '' '' + ISNULL(st.ADDRESS4, '''') 
        + '', '' + ISNULL(st.PHONE1, '''') 
        + '', '' + ISNULL(st.FAX1, '''') AS CLIENT,
    sum(od.QTY*s.stdgrosswgt)/1000 grossWeightTonn,
    sum(od.QTY*s.stdnetwgt)/1000 netWeightTonn,' +
    case when @NumOfPlaces is null then '''''' else  '''' + cast(@NumOfPlaces as varchar(10)) + '''' end + ' NumOfPlaces
FROM '+@wh+'.pickDETAIL AS od
	join '+@wh+'.PackLoadSend pls on pls.serialkey = od.serialkey 
	left JOIN '+@wh+'.SKU AS s ON s.SKU = od.SKU AND s.STORERKEY = od.STORERKEY 
	left JOIN '+@wh+'.ORDERS AS ord ON ord.ORDERKEY = od.ORDERKEY
	left JOIN '+@wh+'.STORER AS st ON st.STORERKEY = ord.consigneeKEY 
WHERE  1=1 '+
--	+case when isnull(@orderkey,'')='' then '' else ' and (od.ORDERKEY = '''+@orderkey+''') 
	' and od.status=9 '
	+CASE  WHEN isnull(@ts,'')='' then '' else ' and pls.TSID = ''' + @ts + '''' end+'
GROUP BY CONVERT(datetime, CONVERT(varchar(10), ord.EDITDATE, 104), 104), 
	od.ORDERKEY, st.COMPANY, od.ORDERKEY, s.DESCR, s.SKU, st.COMPANY,  ord.DeliveryAdr,
	st.VAT, st.ADDRESS1, st.ADDRESS2, st.ADDRESS3, st.ADDRESS4, st.PHONE1, st.FAX1
ORDER BY s.DESCR'

exec (@sql)

select sum(grossWeightTonn)totalGross, sum(netWeightTonn)totalNet into #total from #ttn

select editdate into #dt from ttninfo where objectkey in (select orderkey from #ttn)

select *, '' editdate from #ttn, #total

drop table #ttn
drop table #total
drop table #dt

