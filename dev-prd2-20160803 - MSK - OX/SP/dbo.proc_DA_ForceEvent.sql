-- ====================================================
-- Повторная выгрузка сообщения из Infor в host-систему
-- ====================================================
ALTER PROCEDURE [dbo].[proc_DA_ForceEvent]
	@wh    varchar(10), -- схема
	@event varchar(50), -- событие: orderpacked, ordershipped, asnclosed
	@key   varchar(10)  -- номер заказа
AS
BEGIN
	SET NOCOUNT ON	

	declare @tlkey varchar(10)
	declare @result as varchar
	declare @new_event bit	-- требуется создание события (только ordershipped)

	set @new_event = 0

	if(@wh <> 'wh1' or @event not in ('orderpacked','ordershipped','asnclosed'))
	begin
		set @result='Неверно указано событие или схема'
		print @result
		select @result
		return
	end

	select top 1 @tlkey = transmitlogkey from wh1.transmitlog 
	where tablename=@event and key1=@key and whseid = @wh
	order by serialkey desc

	--Если часть отборов удалили, то ДА не мог сгенерировать событие ordershipped.
	--Пробуем найти последнее событие частичной отгрузки и повторить его.
	--При его повторной обработке ДА сможет создать событие ordershipped.
	if(@tlkey is null and @event = 'ordershipped')
	begin
		select top 1 @tlkey = transmitlogkey from wh1.transmitlog 
		where tablename='partialshipment' and key1=@key and whseid = @wh
		order by serialkey desc
		
		if(@tlkey is not null)
			set @new_event = 1			
	end

	if(@tlkey is null)
	begin
		set @result='Указанное событие по данному документу не найдено в TRANSMITLOG'
		print @result
		select @result
		return
	end

	if(@event = 'asnclosed')
		update wh1.receipt set susr5 = null where receiptkey = @key

	update wh1.transmitlog set transmitflag9 = null where transmitlogkey = @tlkey

	if(@event = 'ordershipped' and @new_event = 1)
		select 'Событие "'+@event+'" по документу № '+@key+' в схеме '+@wh+' не найдено. Дата-адаптеру отправлена команда на создание события в TRANSMITLOG.'
	else	
		select 'Событие "'+@event+'" по документу № '+@key+' в схеме '+@wh+' найдено (transmitlogkey='+cast(@tlkey as varchar)+') и выгружено повторно...'
	
END

