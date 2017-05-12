/*	Pick List для заказа */
ALTER PROCEDURE [dbo].[rep07F1_PickListByCARTONGROUP](
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
--			[BC_CASEID] [varchar](30) COLLATE Cyrillic_General_CI_AS NULL,
			[COMPANY] [varchar](45) COLLATE Cyrillic_General_CI_AS NULL,
			[REQUESTEDSHIPDATE] [datetime] NULL,
			[FROMLOC] [varchar](10) COLLATE Cyrillic_General_CI_AS NULL,
			[odoor] [varchar](10) COLLATE Cyrillic_General_CI_AS NOT NULL,
			[pdoor] [varchar](18) COLLATE Cyrillic_General_CI_AS NULL,
			[ORDERDATE] [datetime] NOT NULL,
			[QTY] [decimal](22, 5) NOT NULL,
			[STDCUBE] [decimal](22, 7) NOT NULL,
			[CASECNT] [float] NOT NULL,
			[PCNT] [int] NOT NULL,
			externorderkey varchar(18),
			ClientName varchar(100) null,
			SKU varchar(60),
			[CARTONGROUP] [varchar](10) null,			
			[DROPID] [varchar](18) null,
			TRANSPORTATIONSERVICE varchar(30) null,
			SUSR4 varchar(30) null,
			SUSR2 varchar(30) null,
			C_CITY varchar(45) null,
			C_ADDRESS1 varchar(45) null
		)
--select * from wh40.orders
		set @sql =
/*			'insert into #tmpt
			select  distinct P.ORDERKEY, 
			case when isnull(p.id,'''')='''' then P.CASEID else p.ID end CASEID , S.COMPANY,O.REQUESTEDSHIPDATE, P.FROMLOC, O.DOOR odoor,
				P.DOOR pdoor, O.ORDERDATE,P.QTY,PC.CASECNT, 0 as PCNT, o.externorderkey,
				cl.companyname ClientName
				,SK.DESCR SKU,
				P.CARTONGROUP, P.DROPID,
				O.TRANSPORTATIONSERVICE,
				O.SUSR4
			FROM '+@wh+'.PICKDETAIL AS P 
				 LEFT JOIN '+@wh+'.STORER AS S ON P.STORERKEY = S.STORERKEY 
				 LEFT JOIN '+@wh+'.SKU AS SK ON SK.STORERKEY = P.STORERKEY AND SK.SKU = P.SKU 
				 LEFT JOIN '+@wh+'.ORDERS AS O ON O.ORDERKEY = P.ORDERKEY 
				 LEFT JOIN '+@wh+'.PACK AS PC ON PC.PACKKEY = P.PACKKEY 
				 LEFT JOIN '+@wh+'.STORER cl on cl.storerkey = o.consigneekey
			WHERE      (P.STATUS<9) '+  */
			'insert into #tmpt
			select  distinct P.ORDERKEY, 
			P.CASEID CASEID , S.COMPANY,O.REQUESTEDSHIPDATE, P.FROMLOC, O.DOOR odoor,
				P.DOOR pdoor, O.ORDERDATE,
				P.QTY,(P.QTY*SK.STDCUBE) STDCUBE,
				PC.CASECNT, 0 as PCNT, o.externorderkey,
				cl.company ClientName
				,SK.DESCR SKU,
				P.CARTONGROUP, P.DROPID,
				O.TRANSPORTATIONSERVICE,
				O.SUSR4,
				O.SUSR2,
				O.C_CITY,
				O.C_ADDRESS1
			FROM '+@wh+'.PICKDETAIL AS P 
				 LEFT JOIN '+@wh+'.STORER AS S ON P.STORERKEY = S.STORERKEY 
				 LEFT JOIN '+@wh+'.SKU AS SK ON SK.STORERKEY = P.STORERKEY AND SK.SKU = P.SKU 
				 LEFT JOIN '+@wh+'.ORDERS AS O ON O.ORDERKEY = P.ORDERKEY 
				 LEFT JOIN '+@wh+'.PACK AS PC ON PC.PACKKEY = P.PACKKEY 
				 LEFT JOIN '+@wh+'.STORER cl on cl.storerkey = o.consigneekey
			WHERE      (P.STATUS<9) '+
			case when isnull(@orderkey,'')='' then '' else 'and (P.ORDERKEY='''+@orderkey+''') ' end+
			case when isnull(@wave,'')='' then '' else 'and P.ORDERKEY in (select ORDERKEY from '+@wh+'.WAVEDETAIL where WAVEKEY='''+@wave+''') ' end
print (@sql)
		exec (@sql)--LEFT JOIN '+@wh+'.STORER ON SK.STORERKEY = '+@wh+'.STORER.STORERKEY AND O.STORERKEY = '+@wh+'.STORER.STORERKEY
--select * from wh40.pickdetail where orderkey = '0000000670'

		update #tmpt set CASECNT=1 where isnull(CASECNT,0)=0

		select ORDERKEY,  dbo.GETEAN128(ORDERKEY) as BC_ORDERKEY, CASEID, dbo.GETEAN128(CASEID) as BC_CASEID,
				max(COMPANY) COMPANY, max(REQUESTEDSHIPDATE) REQUESTEDSHIPDATE, 
				max(FROMLOC) FROMLOC, max(oDOOR) DOOR,max(externorderkey) externorderkey,
				max(PDOOR) PDOOR, max(ORDERDATE) ORDERDATE,
				sum( QTY/CASECNT) RES, sum(STDCUBE) STDCUBE,
				count(distinct Caseid) pcnt,
				max(ClientName) ClientName,
				max(CARTONGROUP) CARTONGROUP, 
				max(DROPID) DROPID, 
				max(TRANSPORTATIONSERVICE) TRANSPORTATIONSERVICE, 
				dbo.GETEAN128(max(TRANSPORTATIONSERVICE)) as BC_TRANS,
				max(SUSR4) SUSR4,
				max(SUSR2) SUSR2,
				max(C_CITY) C_CITY,
				max(C_ADDRESS1) C_ADDRESS1
		from #tmpt
		group by  ORDERKEY,  CASEID
--					,COMPANY, REQUESTEDSHIPDATE, FROMLOC, ODOOR,
--							  PDOOR, ORDERDATE,externorderkey, ClientName,
--								CARTONGROUP, DROPID, TRANSPORTATIONSERVICE, SUSR4,
--					SUSR2,
--					C_CITY,
--					C_ADDRESS1
		order by CASEID

			drop table #tmpt
		END
print 'jr'

