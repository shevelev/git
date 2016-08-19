-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 17.12.2009 (НОВЭКС)
-- Описание: Детализация работы и оплаты персонала
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV05_Rabota_Personala_Detail] ( 
									
	@wh varchar(30),
	@storer varchar(20),
	@datebegin datetime,
	@dateend datetime,
	@who varchar (20)

)

as
create table #table_oper (
		Storer varchar(15) not null, -- Владелец
		Company varchar(45) null,
		Sku varchar(50) not null, -- Код товара
		CARTONGROUP varchar(10) not null,
		Infor_login varchar(18) not null, -- Login
		FIO varchar(40) null, -- Фамилия, Имя
		Type_oper varchar(10) not null, -- Операция (Код операции)
		Descr_oper varchar(30) null, -- Описание операции
		Kol int not null, -- Кол-во операций
		Rub decimal(22,2) not null, -- Тарифф
		Qty decimal (22,5) not null, -- Кол-во товара
		Summ decimal(22,2) not null -- Сумма
)

create table #table_tariff (
		Storer varchar(15) not null, -- Владелец
		Sku varchar(50) not null, -- Код товара
		Type_oper varchar(10) not null, -- Код операции
		Rub decimal(22,2) not null -- Тарифф
)

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(10)

set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(10),@dateend+1,112)

/*Создание таблицы операции
В данной таблице собираются данные о том, какие операции выполнил тот или иной пользователь
..объединение таблиц ITRN и PL_USR (по всем пользователям которые есть в обеих базах),
для выявления фамилии и имени пользователя
*/
set @sql='
insert into #table_oper
select  i.storerkey Storer,
		st.company Company,
		i.sku Sku,
		sk.CARTONGROUP CARTONGROUP,
		i.addwho Infor_Login,
		u. usr_name FIO, 
		i.trantype Type_oper, 
		i.sourcetype Descr_oper, 
		count(i.serialkey) Kol,
		0,
		sum(i.qty) Qty,
		0
from '+@wh+'.ITRN i 
		join ssaadmin.pl_usr u on i.addwho = u.usr_login
		join '+@wh+'.STORER st on i.storerkey = st.storerkey
		left join '+@wh+'.SKU sk on i.sku=sk.sku and i.storerkey=sk.storerkey
where 1=1 '+case when @storer ='Любой' then 'and (i.storerkey=''000000001''
													or i.storerkey=''219''
													or i.storerkey=''5854''
													or i.storerkey=''6845''
													or i.storerkey=''92'')' 
												else 'and i.storerkey='''+@storer+'''' end + '
			and (i.editdate between '''+@bdate+''' and '''+@edate+''')
			and i.addwho = '''+@who+'''
			and i.sourcetype != ''SHORTPICK''
group by i.storerkey, st.company, i.sku, sk.CARTONGROUP, i.addwho, u. usr_name, i.trantype, i.sourcetype
order by i.storerkey, st.company, i.sku, sk.CARTONGROUP, i.addwho, u. usr_name, i.trantype, i.sourcetype
'

print (@sql)
exec (@sql)


/*Обновление таблицы операции.
 простановка кода операций*/
update #table_oper 
set	Type_oper = 
	case Type_oper
		--when 'WD' then '6'--'Отгрузка'
		when 'AJ' then
			case Descr_oper 
				when 'ntrAdjustmentDetailAdd' then '4'--'Корректировка'
				when 'ntrAdjustmentDetailUnreceive' then '6'--'-Неизвестная операция'
				else '6'--'-Неизвестная операция'
			end
		when 'DP' then
			case Descr_oper 
				when 'ntrReceiptDetailAdd' then '1'--'Приемка'
				when 'ntrTransferDetailAdd' then '6'--'-Неизвестная операция'
				else '6'--'-Неизвестная операция'
			end
		when 'MV' then 
			case Descr_oper 
				when 'NSPRFPA02' then '2'--'Размещение'
				when 'NSPRFRL01' then '3'--'Перемещение'
				when 'nspRFTRP01' then '5'--'Пополнение'
				when 'ntrTaskDetailUpdate' then '2'--'Размещение'
				when 'PICKING' then 'HO'
				when '' then '3'--'Перемещение'
				else '6'--'-Неизвестная операция'
			end
			else '6'--'-Неизвестная операция'
		end

--select *
--from #table_oper

/*Создание таблицы тарифы
В данной таблице собираются данные по тарифам за все операции
..объединение таблиц SKU и TARIFFDETAIL (по описанию тарифа)
*/
set @sql='
insert into #table_tariff
select  sk.storerkey Storer,
		sk.sku Sku,
		isnull(td.chargetype,'' '') Type_oper,
		isnull(td.rate, 0) Rub
from '+@wh+'.sku sk
	left join '+@wh+'.tariffdetail td on sk.busr3=td.descrip 
											or sk.busr2=td.descrip 
											or sk.busr1=td.descrip
	where 1=1 '+case when @storer ='Любой' then 'and (sk.storerkey=''000000001''
													or sk.storerkey=''219''
													or sk.storerkey=''5854''
													or sk.storerkey=''6845''
													or sk.storerkey=''92'')' 
												else 'and sk.storerkey='''+@storer+'''' end + '

order by sk.storerkey, sk.sku
'

print (@sql)
exec (@sql)

--select *
--from #table_tariff

/*Обновление таблицы операции.
 простановка тариффа и суммы за операции*/
update rt1 set rt1.Rub = rt2.Rub,
				rt1.Summ = rt1.Kol * rt2.Rub
	from #table_tariff rt2 
		join #table_oper rt1 on rt2.Storer = rt1.Storer 
							and rt2.Sku=rt1.Sku 
							and rt2.Type_oper=rt1.Type_oper

select Storer,
		Company,
		Sku,
		CARTONGROUP,
		Infor_login,
		FIO,
		Type_oper,
		--Descr_oper,
		Kol,
		Rub,
		Qty,
		Summ
from #table_oper
order by Type_oper, CARTONGROUP, Company, Sku


drop table #table_oper
drop table #table_tariff

