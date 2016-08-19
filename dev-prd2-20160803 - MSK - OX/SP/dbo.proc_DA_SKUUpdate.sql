
-- обновление карточки товара

ALTER PROCEDURE [dbo].[proc_DA_SKUUpdate]
	@wh varchar(10),
	@transmitlogkey varchar (10)
AS

--declare @transmitlogkey varchar (10)
declare @sku varchar(50)
declare @storerkey varchar(50)
declare @altsku varchar (50)

	select @sku = tl.key1,
		@storerkey = tl.KEY2
	from wh1.transmitlog tl
	where tl.transmitlogkey = @transmitlogkey
	-- выбор самого
	select top(1) @altsku = altsku
	from wh1.ALTSKU
	where sku = @sku
		and storerkey = @storerkey
	order by
		EDITDATE 
	
	select
		'COMMODITYUPDATE' as filetype,
		SKU,
		@altsku bar,
		STORERKEY,
		convert(varchar(20),convert(decimal(20,12), stdcube)) stdcube,
		convert(varchar(20),convert(decimal(20,12), STDGROSSWGT)) stdgrosswgt
	from wh1.SKU
	where SKU = @sku
		and STORERKEY = @storerkey

