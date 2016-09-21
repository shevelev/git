--################################################################################################
-- Процедура включает в указанное ПУО все ЗЗ, в которых указан этот ПУО
--################################################################################################
ALTER PROCEDURE [WH2].[app_Receipt]
	@Receiptkey varchar(10)='' -- номер ПУО

AS
--declare @Receiptkey varchar(10)
--set @Receiptkey='0000000056'

declare 
	@POkey varchar(18),
	@Storer varchar(15),
	@Carrierkey varchar(15),
	@Carriername varchar(45),
	@polist_line1 varchar(45),
	@polist_line2 varchar(45),
	@polist_line3 varchar(45),
	@polist_line4 varchar(18),
	@POlist varchar(max),
	@sumQTY float,
	@status varchar(10),
	@allowModify int -- разрешать модификацию ПУО (1) или нет(0).

print '...Создаем пустую временную таблицу для деталей ПУО'
CREATE TABLE #receiptdetail (
	[id] [int] IDENTITY(1,1) NOT NULL,
	[whseid] [varchar](3) NULL,
	[receiptkey] [varchar](10) NULL,
	[receiptlinenumber] [varchar](5) NULL,
	[storerkey] [varchar](15) NULL,
	[sku] [varchar](50) NULL,
	[qtyexpected] [decimal](22, 5) NULL,
	[uom] [varchar](10) NULL,
	[packkey] [varchar](50) NULL,
	[cube] [float] NULL,
	[grosswgt] [float] NULL,
	[toloc] [varchar] (10) NULL,
	[Lottable01][varchar] (40) NULL,
	[Lottable02][varchar] (40) NULL,
	[Lottable04][datetime]  NULL,
	[Lottable05][datetime]  NULL,
	[Lottable06][varchar] (40) NULL
	
) ON [PRIMARY]

		INSERT INTO DA_InboundErrorsLog (source,msg_errdetails) 
	SELECT 'ОБъеденение ЗЗ', 'ЗЗ: ' +@Receiptkey 

print '>>> app_Receipt >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
print '@Receiptkey: '+ISNULL(@Receiptkey,'null')
print 'app_Receipt.1. Извлекаем данные для шапки ПУО'
print '...Извлекаем контрагентов'

	select	@Storer=po.storerkey,
		@Carrierkey=left(po.sellersreference,15),
		@Carriername=st.company
	from wh2.po po
		left join wh2.storer st on (po.sellersreference=st.storerkey)
	where po.otherreference=@Receiptkey
	
print '...готовим список ЗЗ для шапки ПУО'
	set @POlist=''
	declare @zerotypes int, @othertypes int
	set @zerotypes = 0 
	set @othertypes = 0

	select @POlist=left(@POlist+po.pokey+',',45+45+45+18),
		@zerotypes = @zerotypes + case when po.potype = '0' then 1 else 0 end,
		@othertypes = @othertypes + case when po.potype != '0' then 1 else 0 end
	from wh2.po po
	where po.otherreference=@Receiptkey

	if @zerotypes > 0 and @othertypes > 0
	begin
		raiserror ('Ошибка: Нельзя добавить ЗЗ в ПУО %s (недопустимая комбинация типов ЗЗ в ПУО).',16,1,@receiptkey)
		return -1
	end

	set @polist_line1=ISNULL(left(@POlist,44),'')
	set @polist_line2=ISNULL(substring(@POlist,45,44),'')
	set @polist_line3=ISNULL(substring(@POlist,89,44),'')
	set @polist_line4=ISNULL(substring(@POlist,133,150),'')

print '...считаем общее количество единиц товара для ПУО'
	select @sumQTY=sum(pd.qtyordered)
	from wh2.po po
		join wh2.podetail pd on (po.pokey=pd.pokey)
	where
		po.otherreference=@Receiptkey
		and po.storerkey=@Storer
		and po.sellersreference=@Carrierkey
	group by pd.whseid, pd.storerkey, pd.sku
	
print '...извлекаем статус указанного ПУО'
select @status=status from wh2.receipt
	where receiptkey=@Receiptkey and @Receiptkey<>'' and @Receiptkey<>'<новый>'



print '...проверяем наличие ЗЗ для указанного ПУО и статус ПУО'
if	((@Storer is not null) 
			or
		 (select Receiptkey from wh2.Receipt where Receiptkey=@Receiptkey) is not null )
	and
	(@Receiptkey<>'')
	and
	(ISNULL(@status,'0')='0')
begin

print '...Заполняем временную таблицу с деталями ПУО'
print 'app_Receipt.3. Включаем в ПУО детали всех ЗЗ, в прикрепленных к ПУО'
insert into #receiptdetail
select	pd.whseid whseid,
		@Receiptkey receiptkey,
		'' receiptlinenumber,
		pd.storerkey storerkey,
		pd.sku sku,
		sum(pd.qtyordered) qtyexpected,
		min(s.rfdefaultuom) uom,
		min(s.rfdefaultpack) packkey,
		sum(pd.qtyordered*s.stdcube) cube,
		sum(pd.qtyordered*s.stdgrosswgt) grosswgt,
		min(st.defaultreturnsloc) toloc,
		pd.Lottable01,
		pd.Lottable02,
		pd.Lottable04,
		pd.Lottable05,
		pd.Lottable06
		
from wh2.po po
	join wh2.podetail pd on (po.pokey=pd.pokey)
	join wh2.sku s on (pd.sku=s.sku and pd.storerkey=s.storerkey)
	join wh2.storer st on (pd.storerkey=st.storerkey)
where
	po.otherreference=@Receiptkey
	and po.storerkey=@Storer
	and po.sellersreference=@Carrierkey
group by pd.whseid, pd.storerkey, pd.sku,
		pd.Lottable01,	pd.Lottable02,	pd.Lottable04,	pd.Lottable05,	pd.Lottable06
		
print '...Проставляем номера строк деталей'
update #receiptdetail
set receiptlinenumber=replicate('0',5-len(cast(id as varchar(5))))+cast(id as varchar(5))

-- проверка на наличие товаров с разным 6м атрибутом
-----------------------------разрешить вставлять 1 и тот же товар с разными сериями и партиями дакса-----------------------------------------
--if @othertypes=0 
--begin

if exists(select 1 from #receiptdetail r1
				join #receiptdetail r2 on 
						r1.storerkey = r2.storerkey 
					and r1.sku =r2.sku 
					and r1.id < r2.id 
					and r1.LOTTABLE06 != r2.LOTTABLE06 )
begin
raiserror ('Ошибка: Нельзя добавить одно ПУО (%s) одинаковые товары с различным атрибутом 6.',16,1,@receiptkey)
return -1
end

--end 
----------------------------------------------------------------------
print 'app_Receipt.2. Проверям существование ПУО: '+@Receiptkey
if (select Receiptkey from wh2.Receipt where Receiptkey=@Receiptkey) is null
begin
	print '...app_Receipt.2.1. Добавление нового ПУО: '+@Receiptkey
	print '......Добавляем шапку нового ПУО: receiptkey='+@Receiptkey+' storerkey='+@Storer+' carrierkey='+@Carrierkey+' carriername='+@Carriername
	insert into wh2.Receipt
				(whseid,
				 receiptkey,
				 storerkey,
				 carrierkey,
				 carriername,
				 carrieraddress1,
				 carrieraddress2,
				 carriercity,
				 carrierzip,
				 openqty,
				 [type])
		select	'WH2',
				@Receiptkey,
				@Storer,
				@Carrierkey,
				@Carriername,
				@polist_line1,
				@polist_line2,
				@polist_line3,
				@polist_line4,
				@sumQTY,
				'1'
				
				-- 
				
end
else
begin
	print '...app_Receipt.2.2. Очистка деталей существующего ПУО: Receiptkey='+@Receiptkey
	print '......Проверяем список ЗЗ для ПУО'
	if (@Storer is not null)
	begin
		print '......Обновляем список ЗЗ в шапке ПУО'
		update wh2.receipt
		set	receiptkey=@Receiptkey,
			storerkey=@Storer,
			carrierkey=@Carrierkey,
			carriername=@Carriername,
			carrieraddress1=@polist_line1,
			carrieraddress2=@polist_line2,
			carriercity=@polist_line3,
			carrierzip=@polist_line4,
			openqty=@sumQTY
		where Receiptkey=@Receiptkey
		print '......Удаляем детали ПУО'
		delete from wh2.receiptdetail
		where receiptkey=@Receiptkey and [status]='0'
	end
	else
	begin
		print '......Удаляем детали ПУО'
		delete from wh2.receiptdetail
		where receiptkey=@Receiptkey and [status]='0'
		print '......Удаляем пустое ПУО'
		delete from wh2.receipt
		where receiptkey=@Receiptkey and [status]='0'
	end
end

--
----
--select *
--from #receiptdetail
--
print '...Заполняем таблицу receiptdetail'
insert into wh2.receiptdetail
	(whseid,
	 receiptkey,
	 receiptlinenumber,
	 storerkey,
	 sku,
	 qtyexpected,
	 uom,
	 packkey,
	 cube,
	 grosswgt,
	 toloc,
	 lottable01,
	 LOTTABLE02,
	 lottable04,
	 lottable05,
	 lottable06,
	 [type])
	select	whseid,
			receiptkey,
			receiptlinenumber,
			storerkey,
			sku,
			qtyexpected,
			uom,
			packkey, 
			cube,
			grosswgt,
			toloc,
			-- uom, замена на lottable01
			isnull(lottable01,''),
			isnull(lottable02,''),
			lottable04,
			lottable05,
			isnull(lottable06,''),
			'1'
	from #receiptdetail
print '...Удаляем временную таблицу'
drop table #receiptdetail

end

print '<<< app_Receipt <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'


