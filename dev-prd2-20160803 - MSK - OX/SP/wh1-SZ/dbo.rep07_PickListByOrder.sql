/*	Pick List для заказа */
ALTER PROCEDURE [dbo].[rep07_PickListByOrder](
	@wh varchar(30)=null,
	@wave varchar(10)=null,
	@orderkey varchar(10)=null
)
--with encryption
AS

--declare @wh varchar(30),
--		@orderkey varchar(10)
--select @wh='wh40', @orderkey = '0000000901'
--// KSV
-- KSV END
		declare 
			@sql varchar(max)

		BEGIN

		CREATE TABLE [dbo].[#tmpt](
			[ORDERKEY] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
			[CASEID] [varchar](20) COLLATE Cyrillic_General_CI_AS NOT NULL,
			[COMPANY] [varchar](45) COLLATE Cyrillic_General_CI_AS NULL,
			[REQUESTEDSHIPDATE] [datetime] NULL,
			[FROMLOC] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
			[odoor] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
			[pdoor] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
			[ORDERDATE] [datetime] NOT NULL,
			[QTY] [decimal](22, 5) NOT NULL,
			[CASECNT] [float] NOT NULL,
			[PCNT] [int] NOT NULL,
			externorderkey varchar(18),
			ClientName varchar(100) null 
			,SKU varchar(60)
		)
--select * from wh40.orders
		set @sql =
			'insert into #tmpt
			select  distinct P.ORDERKEY, case when isnull(p.id,'''')='''' then P.CASEID else p.ID end CASEID , S.COMPANY,O.REQUESTEDSHIPDATE, P.FROMLOC, O.DOOR odoor,
				P.DOOR pdoor, O.ORDERDATE,P.QTY,PC.CASECNT, 0 as PCNT, o.externorderkey,
				cl.companyname ClientName
				,SK.DESCR SKU
			FROM '+@wh+'.PICKDETAIL AS P 
				 LEFT JOIN '+@wh+'.STORER AS S ON P.STORERKEY = S.STORERKEY 
				 LEFT JOIN '+@wh+'.SKU AS SK ON SK.STORERKEY = P.STORERKEY AND SK.SKU = P.SKU 
				 LEFT JOIN '+@wh+'.ORDERS AS O ON O.ORDERKEY = P.ORDERKEY 
				 LEFT JOIN '+@wh+'.PACK AS PC ON PC.PACKKEY = P.PACKKEY 
				 LEFT JOIN '+@wh+'.STORER cl on cl.storerkey = o.consigneekey
			WHERE      (P.STATUS<9) '+
			case when isnull(@orderkey,'')='' then '' else 'and (P.ORDERKEY='''+@orderkey+''') ' end+
			case when isnull(@wave,'')='' then '' else 'and P.ORDERKEY in (select ORDERKEY from '+@wh+'.WAVEDETAIL where WAVEKEY='''+@wave+''') ' end

		exec (@sql)--LEFT JOIN '+@wh+'.STORER ON SK.STORERKEY = '+@wh+'.STORER.STORERKEY AND O.STORERKEY = '+@wh+'.STORER.STORERKEY
--select * from wh40.pickdetail where orderkey = '0000000670'

		update #tmpt set CASECNT=1 where isnull(CASECNT,0)=0

		select ORDERKEY,  CASEID,COMPANY, REQUESTEDSHIPDATE, FROMLOC, oDOOR DOOR,externorderkey,
				PDOOR, ORDERDATE,sum( QTY/CASECNT) RES, count(distinct Caseid) pcnt,
				ClientName			  
		from #tmpt
		group by  ORDERKEY,  CASEID,COMPANY, REQUESTEDSHIPDATE, FROMLOC, ODOOR,
							  PDOOR, ORDERDATE,externorderkey, ClientName
		order by CASEID

			drop table #tmpt
		END

