ALTER PROCEDURE [rep].[mof_rep_shows_st_of_cases] (
	@dat1 datetime,
	@dat2 datetime,
	@zad int,
	@mar varchar(12),
	@polu4 varchar(20),
	@nanal varchar(20)
)
AS

declare @sql varchar(max)


	set @dat1= replace(upper(@dat1),';','')  -- удалить ; из строк задаваемых пользователем для увеличения безопасности.
	set @dat2= replace(upper(@dat2),';','') 

declare @date1 varchar(20),
			@date2 varchar(20)
	-- переносим значения дат во внутренние переменные.
	set @date1 = convert(varchar(20),@dat1,113)
	set @date2 = convert(varchar(20),dateadd(dy,1,@dat2),113)
	-- если даты не заданы задаем некие граничные даты, заведомо перекрывающие все время работы системы
	if @date1 is null set @date1 = convert(varchar(20), dateadd(yy,-1,getdate()),113) -- 1 янв 2000
	if @date2 is null set @date2 = convert(varchar(20), dateadd(yy,1,getdate()),113) -- тек. дата плюс год
	-- в случае если даты перепутаны местами восстанавливаем правильный порядок
	--declare @tmp varchar(20)
	--if @date2 < @date1 
	--begin
	--	select @tmp = @date2, @date2 = @date1
	--	select @date1 = @tmp
	--end
	
	if @zad is not null set @date1 = convert(varchar(20), dateadd(hh,-@zad,getdate()),113)



set @sql='
select pd.ADDDATE, pd.ROUTE, st.company, o.orderkey, o.externorderkey, pd.CASEID, ck.description descrC, pd.dropid,
pd.SKU, pd.QTY, s.DESCR descrT, la.LOTTABLE02, od.ORIGINALQTY, datediff(HH, cast(pd.adddate AS DateTime), GetDate()) AS Age

 from wh2.PICKDETAIL pd
join wh2.ORDERS o on o.ORDERKEY=pd.orderkey
join wh2.storer st on st.STORERKEY=o.b_company
join wh2.CODELKUP ck on ck.CODE=pd.STATUS and ck.LISTNAME=''ordrstatus''
join wh2.SKU s on s.SKU=pd.sku
join wh2.LOTATTRIBUTE la on la.LOT=pd.lot
join wh2.orderdetail od on od.orderkey=pd.ORDERKEY and od.ORDERLINENUMBER=pd.ORDERLINENUMBER
where (pd.adddate between '''+ @date1+''' and '''+@date2+''') /*Дата*/'

set @sql = @sql + 
	case when isnull(@mar,'')='' then ' ' else ' and (pd.route ='+@mar+') ' end

set @sql = @sql +'
and pd.status!=''9''
and st.COMPANY like ''%'+isnull(@polu4,'')+'%'' /*Получатель*/
and o.EXTERNORDERKEY like ''%'+isnull(@nanal,'')+'%'' /*Внешний номер Аналит*/

group by pd.ADDDATE, pd.ROUTE, st.company, o.orderkey, o.externorderkey, pd.CASEID, ck.description, pd.dropid, pd.SKU, pd.QTY, s.descr, la.LOTTABLE02, od.ORIGINALQTY

'
print @sql
exec(@sql)


