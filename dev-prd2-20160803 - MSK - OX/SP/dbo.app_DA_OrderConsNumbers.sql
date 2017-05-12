--################################################################################################
--         процедура обновляет список внешних номеров заказов в объедененном заказе
--################################################################################################

ALTER PROCEDURE [dbo].[app_DA_OrderConsNumbers] 
	@orderkey varchar(10)
AS

declare @listexternorderkey varchar(max)
set @listexternorderkey = ''

print '>>> app_DA_OrderConsNumbers >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'

	print 'DAOCN.1.1. сохранение внешнего номера заказа в консолидированном заказе'
	print 'DAOCN.1.1.1. выбор списка внешних номеров документов из консолидирующего заказа ' + case when @orderkey is null then 'NULL' else @orderkey end
	select externorderkey into #listexternorderkey from wh1.orders_c where orderkey = @orderkey

	select @listexternorderkey = @listexternorderkey + externorderkey from #listexternorderkey

	print 'DAOCN.1.1.2. запись внешних номеров документов ' + case when @listexternorderkey is null then 'NULL' else @listexternorderkey end

	update wh1.orders
		set
			b_contact1 = substring(@listexternorderkey,1,30),
			b_address1 = substring(@listexternorderkey,31,45),
			b_address2 = substring(@listexternorderkey,76,45),
			b_city = substring(@listexternorderkey,121,45)
		where orderkey = @orderkey

drop table #listexternorderkey

print '<<< app_DA_OrderConsNumbers <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'

