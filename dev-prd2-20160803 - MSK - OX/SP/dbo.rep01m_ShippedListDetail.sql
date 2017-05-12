ALTER PROCEDURE [dbo].[rep01m_ShippedListDetail] (
	-- Add the parameters for the stored procedure here
	@wh varchar(10), 
	@order varchar(10)
)
AS
-- BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	-- SET NOCOUNT ON;

    -- Insert statements for procedure here
	  declare @sql varchar(max)
    create table #ORDERS (
      ORDERKEY varchar(10) collate Cyrillic_General_CI_AS,
      EXTERNORDERKEY varchar(32) collate Cyrillic_General_CI_AS,
      ORDERDATE datetime,
      REQUESTEDSHIPDATE datetime,
      CONSIGNEEKEY varchar(15) collate Cyrillic_General_CI_AS,
      CarrierCode varchar(15) collate Cyrillic_General_CI_AS
    )
    create table #PICKDETAIL (
      ORDERKEY varchar(10) collate Cyrillic_General_CI_AS,
      DROPID varchar(18) collate Cyrillic_General_CI_AS,
      [ROUTE] varchar(18) collate Cyrillic_General_CI_AS,
      DOOR varchar(18) collate Cyrillic_General_CI_AS,
      SKU varchar(50) collate Cyrillic_General_CI_AS,
      CASES int,
      QTYS decimal(22,5)
    )
    create table #RESULT (
      ORDERKEY varchar(10) collate Cyrillic_General_CI_AS,
      ORDERDATE varchar(10) collate Cyrillic_General_CI_AS,
      EXTERNORDERKEY varchar(32) collate Cyrillic_General_CI_AS,
      REQUESTEDSHIPDATE varchar(10) collate Cyrillic_General_CI_AS,
      [ROUTE] varchar(18) collate Cyrillic_General_CI_AS,
      DOOR varchar(18) collate Cyrillic_General_CI_AS,
      CLIENTNAME varchar(100) collate Cyrillic_General_CI_AS,
      DROPS varchar(10) collate Cyrillic_General_CI_AS,
      DROPID varchar(18) collate Cyrillic_General_CI_AS,
      SKU varchar(50) collate Cyrillic_General_CI_AS,
      DESCR varchar(60) collate Cyrillic_General_CI_AS,
      CASES int,
      QTYS decimal(22,5),
      EXPEDITOR varchar(100) collate Cyrillic_General_CI_AS
    )
    
    set @sql='
insert into #ORDERS (ORDERKEY,EXTERNORDERKEY,ORDERDATE,REQUESTEDSHIPDATE,CONSIGNEEKEY,CarrierCode)
select ORDERKEY,EXTERNORDERKEY,ORDERDATE,REQUESTEDSHIPDATE,CONSIGNEEKEY,CarrierCode
from '+@wh+'.ORDERS
where ORDERKEY like ''%'+@order+'''
'
    -- print (@sql)
    exec (@sql)

    set @sql='
insert into #PICKDETAIL (ORDERKEY,DROPID,[ROUTE],DOOR,SKU,CASES,QTYS)
select ORDERKEY,DROPID,[ROUTE],DOOR,SKU,count(distinct CASEID) CASES,sum(QTY) QTYS
from '+@wh+'.PICKDETAIL
where ORDERKEY like ''%'+@order+'''
  and STATUS<9
  and case when isnull(DROPID,'''')='''' then CASEID else DROPID end !=''''
group by ORDERKEY,DROPID,[ROUTE],DOOR,SKU
'
    -- print (@sql)
    exec (@sql)
    
    set @sql='
insert into #RESULT (ORDERKEY,ORDERDATE,
  EXTERNORDERKEY,REQUESTEDSHIPDATE,
  [ROUTE],DOOR,
  CLIENTNAME,DROPS,
  DROPID,SKU,DESCR,CASES,QTYS,EXPEDITOR)
select o.ORDERKEY,convert(varchar(10),o.ORDERDATE,104) ORDERDATE,
  o.EXTERNORDERKEY,convert(varchar(10),o.REQUESTEDSHIPDATE,104) REQUESTEDSHIPDATE,
  p.[ROUTE],p.DOOR,
  c.CompanyName CLIENTNAME,cast((select count(distinct DROPID) from #PICKDETAIL) as varchar) DROPS,
  p.DROPID,p.SKU,s.DESCR,p.CASES,p.QTYS,exp.COMPANY EXPEDITOR
from #PICKDETAIL p
inner join #ORDERS o on p.ORDERKEY=o.ORDERKEY
left join '+@wh+'.STORER exp on exp.STORERKEY = o.CarrierCode
left join '+@wh+'.STORER c on c.STORERKEY=o.CONSIGNEEKEY
left join '+@wh+'.SKU s on p.SKU=s.SKU
'
    -- print (@sql)
    exec (@sql)
    select ORDERKEY,ORDERDATE,EXTERNORDERKEY,REQUESTEDSHIPDATE,[ROUTE],DOOR,CLIENTNAME,DROPS,DROPID,SKU,DESCR,CASES,QTYS,EXPEDITOR from #RESULT
    
    drop table #ORDERS
    drop table #PICKDETAIL
    drop table #RESULT
	
-- END
-- GO

