ALTER PROCEDURE [dbo].[rep02_UntunedCommodity] (@wh varchar(30), @rc varchar(20) = null)
/*   02  Отчет о ненастроенных товарах   */
as

--declare @rc varchar(20), @wh varchar(30)
--select @rc='', @wh='WH1'

	set @wh = upper(@wh)
	set @rc= replace(upper(@rc),';','')  -- удалить ; из строк для увеличения безопасности.
	--set @rc= '%' + @rc 
	declare @sql varchar(max)

	select s.SUSR10 susr10, s.sku, s.descr, s.storerkey,st.company,
			s.packkey,	rfdefaultpack,	s.stdcube,
			s.stdgrosswgt,	s.skugroup,	s.skugroup2,
			s.putawaystrategykey,s.strategykey,s.putawayzone,
			cast('' as varchar(8000)) errcode, isnull(asku.ALTSKU,'0') ALTSKU, 0 bad
		into #sku
		from wh1.sku as s
		  left join (select distinct SKU, case when isnull(ALTSKU,'0')='0' then '0' else '1' end ALTSKU from WH1.ALTSKU) asku on s.SKU=asku.SKU
			left join WH1.receiptdetail as r on (r.sku = s.sku) and (r.storerkey = s.storerkey)
			join WH1.storer as st on (s.storerkey = st.storerkey) 
		where 1=2

	set @sql = 'insert into #sku select distinct s.SUSR10 susr10, s.sku, s.descr, s.storerkey,st.company,
		s.packkey,	rfdefaultpack,	s.stdcube,
		s.stdgrosswgt,	s.skugroup,	s.skugroup2,
		s.putawaystrategykey,s.strategykey,s.putawayzone,
		cast('''' as varchar(8000)) errcode, isnull(asku.ALTSKU,''0'') ALTSKU,0 bad
	from '+@wh+'.sku as s '+
	  'left join (select distinct SKU, case when isnull(ALTSKU,''0'')=''0'' then ''0'' else ''1'' end ALTSKU from '+@wh+'.ALTSKU) asku on s.SKU=asku.SKU '+
		case when @rc is null then '' else 'left join '+@wh+'.receiptdetail as r on (r.sku = s.sku) and (r.storerkey = s.storerkey)' end +
		' join '+@wh+'.storer as st on (s.storerkey = st.storerkey) '
	set @sql = @sql+ ' where 1=1 '+ case when isnull(@rc,'')='' then '' else ' and upper(r.receiptkey) like '''+@rc+''' ' end
	print @sql
exec (@sql)
--AND (stdcube = 0 or stdgrosswgt = 0 or packkey = 'STD' or rfdefaultpack='STD')

	update #sku set bad=1 where 
		packkey = 'STD' or rfdefaultpack = 'STD'
		or stdcube = 0 or stdgrosswgt = 0 
		or isnull(skugroup,'') = '' OR skugroup = 'STD' 
		or isnull(skugroup2, '') = ''
		or putawaystrategykey = 'STD'
		or strategykey is null OR strategykey = 'STD'
		or isnull(putawayzone,'') = '' OR putawayzone = 'BULK'
		or isnull(descr,'')='' or isnull(company,'') = ''
		or ALTSKU=0

	update #sku  set descr = case when isnull(descr,'')='' then 'НЕТ НАЗВАНИЯ ДЛЯ ТОВАРА: '+ sku else descr end,
					company = case when isnull(company,'') = '' then 'НЕТ НАЗВАНИЯ ДЛЯ ВЛАДЕЛЬЦА: ' + storerkey 
							else company end

	update #sku set errcode = errcode + case when packkey = 'STD' then 'Ключ упаковки = STD; ' else '' end +
		case when rfdefaultpack='STD' then 'Ключ упаковки RF = STD; ' else '' end +
		case when stdcube = 0 then 'Объем = 0;  ' else '' end+
		case when stdgrosswgt = 0 then 'Вес нетто = 0; '  else '' end  

	update #sku set errcode = errcode +
		case isnull(skugroup,'') when 'STD' then 'Товарная группа = STD; '
					when '' then 'Товарная группа = ПУСТАЯ; '	else ''	end  +
		case when isnull(skugroup2, '') = '' then 'Товарная группа2 ПУСТАЯ; '  else '' end

	update #sku set errcode = errcode +
		case when putawaystrategykey = 'STD' then 'Стратегия размещения = STD; '  else '' end +
		case when isnull(strategykey,'STD') = 'STD' then 'Стратегии резервирования = STD; ' else '' end +
		case isnull(putawayzone,'') when 'BULK' then 'Зона размещения = BULK; '
			when '' then 'Зона размещения = ПУСТАЯ; ' else '' end
			
	update #sku set errcode=errcode+'Не указан штрих-код товара; '
	where ALTSKU='0'
		
	select susr10, sku, descr, storerkey, company, errcode, bad from #sku where bad > 0
select * from #sku
	drop table #sku

