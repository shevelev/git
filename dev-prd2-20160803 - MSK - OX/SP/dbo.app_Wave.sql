--################################################################################################
-- Процедура включает в указанную Волну все ЗО, в которых указана эта Волна
-- Принадлежность ЗО к Волне устанавливается значением поля o.ORDERGROUP
---- в поле o.INTERMODALVENCLE(Перевозчик) записывается код Водителя/Экспедитора
---- в поле o.LOADID( записывается код документа Загрузка
---- в поле o.... (Маршрут) записывается код маршрута (префикс "TS"+код документа загрузка)
---- в поле o.... (...) записывается текстовое описание направления доставки
--################################################################################################
ALTER PROCEDURE [dbo].[app_Wave]
	@Wavekey	varchar(10)='', -- номер Волны
	@Driver		varchar(10)='',	-- код Водителя
	@Car		varchar(10)='',	-- номер машины
	@Route		varchar(20)=''	-- маршрут (направление)

AS

declare 
	@Orderkey varchar(18),
	@status int

print '>>> app_Wave >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
print '@Wavekey: '+ISNULL(@Wavekey,'null')
print '1. Извлекаем данные для шапки Волны'
print '...Извлекаем статус Волны'
select	
--		@Storer=max(o.storerkey),
--		@Carrierkey=left(po.sellersreference,15),
--		@Carriername=st.company
		@status=max(cast ([status] as int))
from wh1.orders o
--		left join wh1.storer st on (o.storer=st.storerkey)
where o.ordergroup=isnull(@Wavekey,'') and isnull(@Wavekey,'')<>''
print '......status:'+cast(ISNULL(@status,'-1') as varchar) + ' (при =<9 не зарезервирован)'

--print '...считаем общее количество единиц товара для Волны'
--select @sumQTY=sum(pd.qtyordered)
--from wh1.po po
--	join wh1.podetail pd on (po.pokey=pd.pokey)
--where
--	po.otherreference=@Receiptkey
--	and po.storerkey=@Storer
--	and po.sellersreference=@Carrierkey
--group by pd.whseid, pd.storerkey, pd.sku


print '...проверяем наличие ЗО для указанной Волны и статус Волны'
if	(isnull(@Wavekey,'')<>'')
	and
	(ISNULL(@status,100)<10)
begin

print '2. Проверяем существование Волны: '+@Wavekey
if (select Wavekey from wh1.Wave where Wavekey=@Wavekey) is null
begin
	print '...2.1. Добавление новой Волны: '+@Wavekey
	print '......Добавляем шапку новой Волны: Wavekey='+@Wavekey
	insert into wh1.Wave
				(whseid,
				 wavekey,
				 externalwavekey,
				 descr)
		select	'WH1',
				@Wavekey,
				@Driver,
				@Route
end
else
begin
	print '...2.2. Очистка деталей существующей Волны: Wavekey='+@Wavekey
	print '......Проверяем список ЗО для Волны и если он пуст, то удаляем пустую Волну'
	if (@status is not null)
	begin
		print '......Удаляем детали Волны'
		delete	from wh1.wavedetail
				from wh1.wavedetail wd
					join wh1.orders o on (wd.orderkey=o.orderkey)
		where wd.wavekey=@Wavekey and cast(o.status as int)<10
	end
	else
	begin
		print '......Удаляем детали Волны'
		delete	from wh1.wavedetail
				from wh1.wavedetail wd
					join wh1.orders o on (wd.orderkey=o.orderkey)
		where wavekey=@Wavekey and cast(o.status as int)<10
		print '......Удаляем пустую Волну'
		delete	from wh1.wave
				from wh1.wave w
					left join wh1.wavedetail wd on (w.wavekey=wd.wavekey)
		where w.wavekey=@Wavekey and (wd.wavekey is null)
	end
end
--
print '3. Включаем в Волну список ЗО, прикрепленных к ней'
print '...Создаем пустую временную таблицу для деталей Волны'
CREATE TABLE #wavedetail (
	[id] [int] IDENTITY(1,1) NOT NULL,
	[whseid] [varchar](3) NULL,
	[wavedetailkey] [varchar](10) NULL,
	[wavekey] [varchar](10) NULL,
	[orderkey] [varchar](10) NULL
)
print '...Заполняем временную таблицу с деталями Волны'
insert into #wavedetail
select	o.whseid whseid,
		'' wavedetailkey,
		@Wavekey receiptkey,
		o.orderkey orderkey
from wh1.orders o
where
	o.ordergroup=@Wavekey
print '...Проставляем номера строк Волны'
update #wavedetail
set wavedetailkey=replicate('0',10-len(cast(id as varchar(5))))+cast(id as varchar(5))
----
--select *
--from #wavedetail
print '...Исключаем ЗО из всех Волн'
delete from wh1.wavedetail
where orderkey in (select orderkey from #wavedetail)
--
print '...Заполняем таблицу wavedetail'
insert into wh1.wavedetail
	(whseid,
	 wavedetailkey,
	 wavekey,
	 orderkey)
	select	whseid,
			wavedetailkey,
			wavekey,
			orderkey
	from #wavedetail
print '...Удаляем временную таблицу'
drop table #wavedetail

end

print '<<< app_Wave <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'

