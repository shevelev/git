-- =============================================
-- Автор:		Смехнов Антон
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 17.10.2009 (НОВЭКС)
-- =============================================
ALTER PROCEDURE [WH1].[novex_TRANZITLIST] (
@fil varchar(15)
)
AS
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--##############################################################################
create table #table_result (
		CUSTOMERKEY varchar(20) null, 
		CUSTOMER varchar(45) not null, 
		ROUTEDIRECTION varchar(30) null,
		CUBE float null,
		WEIGHT float null,
		QTY decimal(22,5) null,
		mixID varchar(15) null,
		ID varchar(20) not null,
		CURRENTLOC varchar(20) not null,
		VENDORKEY varchar(20) null, 
		VENDOR varchar(45) not null
)


declare @sql varchar(max)

set @sql='
insert into #table_result
select TR.CUSTOMERKEY, 
		isnull(st1.company,'''') CUSTOMER, 
		st1.susr2 ROUTEDIRECTION,
		round(isnull(CUBE,0),3) CUBE,
		round(isnull(WEIGHT,0)/1000,2) WEIGHT,
		cast(round(QTY,0) as int) QTY,
		dbo.func_return_general_dropid_from_caseid(containerid)  mixID,
		containerid ID,
		case when TR.CURRENTLOC=''''	then isnull(mixID.droploc,'''')
							else TR.CURRENTLOC
			end CURRENTLOC,
		TR.VENDORKEY, 
		isnull(st2.company,'''') VENDOR
from WH1.TRANSSHIP TR 
	left join wh1.storer st1 on (TR.CUSTOMERKEY=st1.storerkey)
	left join wh1.storer st2 on (TR.VENDORKEY=st2.storerkey)
	left join wh1.dropid mixID on (dbo.func_return_general_dropid_from_caseid(containerid)=mixID.dropid)
where TR.status=0 
		'+case when @fil<>'Любой' then 'and st1.storerkey='''+@fil+''''
				else ''
			end+'
order by isnull(st1.company,''''), isnull(st2.company,'''')
'
print (@sql)
exec (@sql)


select *
from #table_result

