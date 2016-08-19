
ALTER PROCEDURE [dbo].[proc_DA_Barcode]
	@source varchar(500) = null
AS
-- Любая ошибка должна прерывать процедуру и передать исключение адаптеру
SET XACT_ABORT ON

declare @allowUpdate int
declare @id          int
declare @storerkey   varchar(15)
declare @sku         varchar(10)
declare @altsku      varchar(50)


print '1. определяем возможность обновления ШК'
	select @allowUpdate = allowUpdate from dbo.DA_MessageTypes where MessageKey = 'BarCode'

print '3. выполняем проверку входных данных'
print '3.1. проверка наличия обзятельных полей storerkey, sku  и altsku'
	if 0 < (select count(*) from DA_BARCODE 
			where (storerkey is null or rtrim(storerkey)='') or
				  (sku is null or rtrim(sku)='') or
				  (altsku is null or rtrim(altsku)=''))
	begin
		raiserror ('Не указан владелец (storer) или код товара (sku) или штрих-код (altsku)',16,1)
		return
	end

print '3.3. проверка наличия storer в справочнике storer'
	set @storerkey = null
	select top 1 @storerkey = b.storerkey 
	from DA_BARCODE b left join WH1.STORER s on b.storerkey=s.storerkey
	where s.serialkey is null

	if @storerkey is not null
	begin
		raiserror ('Владелец отсутствует в справочнике storer (STORERKEY=%s)',16,2,@storerkey)
		return		
	end

print '3.4. проверка наличия sku в справочнике sku'
	select @storerkey = null, @sku = null
	select top 1 @storerkey = b.storerkey, @sku = b.sku
	from DA_BARCODE b left join WH1.SKU s on b.storerkey=s.storerkey and b.sku=s.sku
	where s.serialkey is null

	if @storerkey is not null
	begin
		raiserror ('Товар отсутствует в справочнике sku (STORERKEY=%s, SKU=%s)',16,3,@storerkey,@sku)
		return		
	end

print '3.5. проверка длины ШК, не более 13'
	select @storerkey = null, @sku = null
	select top 1 @storerkey=storerkey, @sku=sku, @altsku=altsku from DA_BARCODE where len(altsku)>13

	if @storerkey is not null
	begin
		raiserror ('Длина штрих-кода превышает 13 символов (STORERKEY=%s, SKU=%s, ALTSKU=%s)',16,4,@storerkey,@sku,@altsku)
		return		
	end

print '4. Проверка наличия ШК в базе'
	declare @cnt int
	select @storerkey = null, @sku = null, @altsku=null, @cnt = 0
	select top 1 @storerkey=storerkey, @sku=sku, @altsku=altsku 
	from DA_BARCODE bc

	select @cnt = count(*)
	from wh1.altsku alt 
	where  @storerkey=alt.storerkey and @sku=alt.sku and @altsku=alt.altsku 
	
	-- ШК есть, 
	if @cnt > 0 
	begin
		if @allowupdate=0  -- обновление запрещено
			begin 
				raiserror ('Обновление запрещено. Такой штрихкод уже есть в базе.  (STORERKEY=%s, SKU=%s, ALTSKU=%s)',16,4,@storerkey,@sku,@altsku)
				return		
			end
		else
		-- ШК есть, обновление разрешено
		begin
			print '4.1 обновление штрих-кодов'
			update alt set 
				storerkey = bc.storerkey, 
				sku = bc.sku, 
				altsku = bc.altsku, 
				packkey = s.packkey, 
				defaultuom = s.rfdefaultuom
			from wh1.altsku alt
				join DA_barcode bc on bc.storerkey=alt.storerkey and bc.sku=alt.sku and bc.altsku=alt.altsku
				join wh1.sku s on  bc.storerkey=s.storerkey and bc.sku=s.sku
			select @@rowcount
			print '4.1 обновление штрих-кодов'
			update alt set 
				storerkey = bc.storerkey, 
				sku = bc.sku, 
				altsku = bc.altsku, 
				packkey = s.packkey, 
				defaultuom = s.rfdefaultuom
			from wh2.altsku alt
				join DA_barcode bc on bc.storerkey=alt.storerkey and bc.sku=alt.sku and bc.altsku=alt.altsku
				join wh2.sku s on  bc.storerkey=s.storerkey and bc.sku=s.sku
			select @@rowcount
		end
	end
	else
	begin
		print '4.2 добавление новых штрих-кодов'
		insert into wh1.altsku (storerkey, sku, altsku, packkey, defaultuom)
			select b.storerkey, b.sku, b.altsku, s.packkey, s.rfdefaultuom 
			from wh1.sku s, DA_BARCODE b 
				left join wh1.altsku b1 
			on (b.storerkey=b1.storerkey and b.sku=b1.sku and b.altsku=b1.altsku)		
			where b1.serialkey is null and b.sku=s.sku and b.storerkey=s.storerkey
		select @@rowcount
		print '4.2 добавление новых штрих-кодов'
		insert into wh2.altsku (storerkey, sku, altsku, packkey, defaultuom)
			select b.storerkey, b.sku, b.altsku, s.packkey, s.rfdefaultuom 
			from wh2.sku s, DA_BARCODE b 
				left join wh2.altsku b1 
			on (b.storerkey=b1.storerkey and b.sku=b1.sku and b.altsku=b1.altsku)		
			where b1.serialkey is null and b.sku=s.sku and b.storerkey=s.storerkey
		select @@rowcount
	end
delete from DA_BARCODE
