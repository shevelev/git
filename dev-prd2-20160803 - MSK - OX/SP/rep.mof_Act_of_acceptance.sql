

ALTER PROCEDURE [rep].[mof_Act_of_acceptance](
--DECLARE
	@pk varchar(15)--='0000039958'
	--'0000030596'
	--'0000030573'
	--'0000030560'
	--'0000030575' BRAKPRIEM
	)
AS
/*
	Отчет: Приемный акт
	Автор: Шевелев С.С.
	Дата: 25.02.2015
	Модификация: 10.03.2015 -- Разделение на типы документов
	Модификация: 16.04.2015 -- Обработка Тип=0, по Принятому.
*/
CREATE TABLE [#rt](
	[SKU] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[SKUGROUP] [nvarchar](20) COLLATE Cyrillic_General_CI_AS NULL,	
	[DESCR] [nvarchar](300) COLLATE Cyrillic_General_CI_AS NULL, --Описание товара
	[EXTN] [nvarchar](15) COLLATE Cyrillic_General_CI_AS NULL,
	[POKEY] [nvarchar](20) COLLATE Cyrillic_General_CI_AS NULL,		
	[CompanyName] [nvarchar](100) COLLATE Cyrillic_General_CI_AS NULL,	
	[LOTTABLE01] [nvarchar](40) COLLATE Cyrillic_General_CI_AS NULL,
	[LOTTABLE02] [nvarchar](40) COLLATE Cyrillic_General_CI_AS NULL,	
	[LOTTABLE04] date,
	[LOTTABLE05] date,
	[LOTTABLE06] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[EFFECTIVEDATE] date,	
	[ud] [nvarchar](15) COLLATE Cyrillic_General_CI_AS NULL,		
	[FGr] [nvarchar](20) COLLATE Cyrillic_General_CI_AS NULL,		
	[nak] [nvarchar](150) COLLATE Cyrillic_General_CI_AS NULL,
	[dat] [nvarchar](15) COLLATE Cyrillic_General_CI_AS NULL,				
	[busr2] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[zak] int, --Заказанное кол-во
	[otgr]int, --Принятое кол-во
	[brak] int, --Брак
	[lostpriem] int, --Недостачи
	[overpriem] int, --Излишки
	[editdate] date) --Редактирование документа
	
	
CREATE TABLE [#ozhid] (
	[SKU] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[LOTTABLE02] [nvarchar](40) COLLATE Cyrillic_General_CI_AS NULL,	
	[LOTTABLE04] date,
	[LOTTABLE05] date,
	[LOTTABLE06] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[zak] int --Заказанное кол-во
)

CREATE TABLE [#prin] (
	[SKU] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[LOTTABLE02] [nvarchar](40) COLLATE Cyrillic_General_CI_AS NULL,	
	[LOTTABLE04] date,
	[LOTTABLE05] date,
	[LOTTABLE06] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[otgr] int --Принятое кол-во
)

CREATE TABLE [#prinBRLO] (
	[SKU] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[LOTTABLE02] [nvarchar](40) COLLATE Cyrillic_General_CI_AS NULL,	
	[LOTTABLE04] date,
	[LOTTABLE05] date,
	[LOTTABLE06] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL,
	[otgr] int, --Принятое кол-во
	[st] int, -- статус .
	[susr4] [nvarchar](50) COLLATE Cyrillic_General_CI_AS NULL
)

declare @td varchar(1) -- Тип документа (0)-без атрибутов, (1-5) с атрибутами.

select @td=potype from wh2.po where POKEY=@pk
/* ================================================================================= */
--if @td<>0
--begin
--	/* Формируем, то что ожидалось, по документам поставщика */
--	insert into #ozhid (SKU, LOTTABLE02,LOTTABLE04,LOTTABLE05,LOTTABLE06,zak)
--	select pd.SKU,pd.LOTTABLE02,pd.LOTTABLE04,pd.LOTTABLE05 ,pd.LOTTABLE06, pd.QTYORDERED
--	from wh2.PODETAIL pd
--	where pd.POKEY=@pk  and QTYORDERED>0
--end

if @td>=0
begin
	/* Формируем, то что ожидалось, без атрибутов */
	insert into #ozhid (SKU, LOTTABLE06,zak)
	select pd.SKU,pd.LOTTABLE06, pd.QTYORDERED
	from wh2.PODETAIL pd
	where pd.POKEY=@pk  and QTYORDERED>0
end

/* ================================================================================= */
/* Формируем, то что принято */
--if @td<>0
--	begin
--		insert into #prin (sku,LOTTABLE02,LOTTABLE04,LOTTABLE05,LOTTABLE06,otgr)
--		select pd.SKU,pd.LOTTABLE02,pd.LOTTABLE04,pd.LOTTABLE05, pd.LOTTABLE06, SUM(PD.QTYRECEIVED) qty
--		from wh2.PODETAIL pd
--		where pd.POKEY=@pk and pd.QTYRECEIVED>0 
--		group by pd.SKU,pd.LOTTABLE02,pd.LOTTABLE04,pd.LOTTABLE05, pd.LOTTABLE06
--	end

if @td>=0
	begin
		---Принято норм
		insert into #prin (sku,LOTTABLE02,LOTTABLE04,LOTTABLE05,LOTTABLE06,otgr)
		select SKU, LOTTABLE02,LOTTABLE04, LOTTABLE05, LOTTABLE06, sum(QTYRECEIVED) qty
		from wh2.PODETAIL
		where SUSR4 in ('GENERAL','SD') and POKEY=@pk 
		group by SKU, LOTTABLE02,LOTTABLE04, LOTTABLE05, LOTTABLE06
		
		---Принято БракЛост
		insert into #prinBRLO(sku,LOTTABLE02,LOTTABLE04,LOTTABLE05,LOTTABLE06,otgr,st,susr4)
		select SKU, LOTTABLE02,LOTTABLE04, LOTTABLE05, LOTTABLE06, sum(QTYRECEIVED) qty, '5',SUSR4
		from wh2.PODETAIL
		where SUSR4 in ('LOSTPRIEM','BRAKPRIEM','OVERPRIEM','PRETENZ') and POKEY=@pk 
		group by SKU, LOTTABLE02,LOTTABLE04, LOTTABLE05, LOTTABLE06,SUSR4
	
	end
/* ================================================================================= */
--if @td<>0
--	begin
--		insert into #rt (sku,zak, otgr, LOTTABLE02, lottable04, lottable05, lottable06)
--		select case when oz.SKU IS null then pr.SKU else oz.SKU end AS SKU, sum(oz.zak) as Ожидалось, sum(pr.otgr) as Принято, 
--		isnull(pr.LOTTABLE02,oz.LOTTABLE02), 
--		isnull(pr.LOTTABLE04,oz.LOTTABLE04), 
--		isnull(pr.LOTTABLE05,oz.LOTTABLE05), 
--		isnull(pr.LOTTABLE06,oz.LOTTABLE06)
--		from #ozhid oz
--		full join #prin pr on oz.SKU=pr.SKU and oz.LOTTABLE06=pr.LOTTABLE06 and oz.LOTTABLE02=pr.LOTTABLE02 and oz.LOTTABLE04=oz.LOTTABLE05
--		group by case when oz.SKU IS null then pr.SKU else oz.SKU end, isnull(pr.LOTTABLE02,oz.LOTTABLE02), isnull(pr.LOTTABLE04,oz.LOTTABLE04), 
--		isnull(pr.LOTTABLE05,oz.LOTTABLE05), isnull(pr.LOTTABLE06,oz.LOTTABLE06)
--	end

if @td>=0
	begin
		/* Соединяем ожидаемое+принятое. подтягиваем партию по принятому */
		--insert into #rt (sku,zak, otgr, LOTTABLE02, lottable04, lottable05, lottable06)
		--select case when oz.SKU IS null then pr.SKU else oz.SKU end AS SKU, oz.zak as Ожидалось, pr.otgr as Принято, la.LOTTABLE02, la.LOTTABLE04, la.LOTTABLE05, la.LOTTABLE06
		--from #ozhid oz
		--full join #prin pr on oz.SKU=pr.SKU and oz.LOTTABLE06=pr.LOTTABLE06
		--left join wh2.LOTATTRIBUTE la on la.SKU=pr.sku and la.LOTTABLE06=pr.LOTTABLE06
		--group by case when oz.SKU IS null then pr.SKU else oz.SKU end, oz.zak, pr.otgr , la.LOTTABLE02, la.LOTTABLE04, la.LOTTABLE05, la.LOTTABLE06
		--Закинули только то, что принято норм.
		insert into #rt (sku, zak,otgr, LOTTABLE02, lottable04, lottable05, lottable06)
		select SKU, otgr,otgr, LOTTABLE02, LOTTABLE04, LOTTABLE05, LOTTABLE06 from #prin

	end


--/* Поиск Брака-Излишков-Недостач */
	update brlo
	set st=10
	from #prinBRLO brlo
	join #prin pr on pr.SKU=brlo.SKU and pr.LOTTABLE02=brlo.LOTTABLE02 and pr.LOTTABLE05=brlo.LOTTABLE05 and pr.LOTTABLE04=brlo.LOTTABLE04 and pr.LOTTABLE06=brlo.LOTTABLE06
	
	
	
if (select COUNT(*) from #prinBRLO where st=10) >0
	begin
		print 'Обновленяем строчки'
		update pr       --------=========== LostPriem ============-------------
		set lostpriem = brlo.otgr, zak=zak+brlo.otgr
		from #rt pr
		join #prinBRLO brlo on pr.SKU=brlo.SKU and pr.LOTTABLE02=brlo.LOTTABLE02 and pr.LOTTABLE05=brlo.LOTTABLE05 and pr.LOTTABLE04=brlo.LOTTABLE04 and pr.LOTTABLE06=brlo.LOTTABLE06 
		where brlo.susr4='LOSTPRIEM' and brlo.st=10
	 
		update pr       --------=========== BrakPriem ============-------------
		set brak = brlo.otgr, zak=zak+brlo.otgr, pr.otgr=pr.otgr+brlo.otgr
		from #rt pr
		join #prinBRLO brlo on pr.SKU=brlo.SKU and pr.LOTTABLE02=brlo.LOTTABLE02 and pr.LOTTABLE05=brlo.LOTTABLE05 and pr.LOTTABLE04=brlo.LOTTABLE04 and pr.LOTTABLE06=brlo.LOTTABLE06 
		where brlo.susr4='BRAKPRIEM' and brlo.st=10
 	
		update pr       --------=========== OVERPRIEM ============-------------
		set overpriem  = brlo.otgr, pr.otgr=pr.otgr+brlo.otgr
		from #rt pr
		join #prinBRLO brlo on pr.SKU=brlo.SKU and pr.LOTTABLE02=brlo.LOTTABLE02 and pr.LOTTABLE05=brlo.LOTTABLE05 and pr.LOTTABLE04=brlo.LOTTABLE04 and pr.LOTTABLE06=brlo.LOTTABLE06 
		where brlo.susr4='OVERPRIEM' and brlo.st=10


		--update r       --------=========== Излишки ============-------------
		--set overpriem = otgr-isnull(zak,0)
		--from #rt r
		--where otgr>isnull(zak,0)
	end						

	if (select COUNT(*) from #prinBRLO where st=5) >0
		begin
		print 'add строчки'
		 --------=========== Добавляем БРАК ============-------------
		insert into #rt (sku, zak,otgr, LOTTABLE02, lottable04, lottable05, lottable06,brak)
		select SKU, otgr,otgr, LOTTABLE02, LOTTABLE04, LOTTABLE05, LOTTABLE06, otgr from #prinBRLO
		where st=5 and susr4='BRAKPRIEM'
		
		--------=========== Добавляем LOST ============-------------
		insert into #rt (sku, zak,otgr, LOTTABLE02, lottable04, lottable05, lottable06, lostpriem)
		select SKU, otgr,0, LOTTABLE02, LOTTABLE04, LOTTABLE05, LOTTABLE06,otgr from #prinBRLO
		where st=5 and susr4='LOSTPRIEM'
		
		--------=========== Добавляем Излишки ============-------------
		insert into #rt (sku,zak,otgr, LOTTABLE02, lottable04, lottable05, LOTTABLE06, overpriem)
		select SKU,0, otgr, LOTTABLE02, LOTTABLE04, LOTTABLE05, LOTTABLE06, otgr from #prinBRLO
		where st=5 and susr4='OVERPRIEM'
		
		--------=========== Добавляем Излишки(пересорт) ============-------------
		insert into #rt (sku, zak,otgr, LOTTABLE02, lottable04, lottable05, lottable06, overpriem)
		select SKU, 0,otgr, LOTTABLE02, LOTTABLE04, LOTTABLE05, LOTTABLE06, otgr from #prinBRLO
		where st=5 and susr4='PRETENZ'
		
		end					
	


				

update r       --------=========== Прописывание б\с для бессерийного товара ============-------------
set LOTTABLE02 = 'б\с'
from #rt r
where LOTTABLE02=''

/* Обновление из карточки товара */

update r
	set r.DESCR=case when s.NOTES1 is NULL then s.DESCR else s.NOTES1 end,
		r.busr2=s.BUSR2,
		r.ud=s.BUSR3,
		r.SKUGROUP=s.SKUGROUP,
		r.FGr= case when (s.SKUGROUP2 = 'Сильнодействующие') or (s.FREIGHTCLASS = '6') 			then 'Сильнодействующие'			else '1 Склад'		end
	from #rt r
	join wh2.sku s on r.SKU=s.sku

--/* Обновление из шапки PO */
update r
	set r.EXTN=po.EXTERNPOKEY, --внешний номер
		r.POKEY=po.POKEY, --номер ЗЗ
		r.nak=isnull(nullif(left(po.BUYERADDRESS4, len(po.BUYERADDRESS4) - charindex(' ',reverse(po.BUYERADDRESS4))),''),
		substring(po.BUYERSREFERENCE, 0, charindex(' ', po.BUYERSREFERENCE))), --№ накладной
		r.dat=isnull(nullif(ltrim(right(po.BUYERADDRESS4, charindex(' ',reverse(po.BUYERADDRESS4)))),''),
		substring(po.BUYERSREFERENCE,charindex(' ', po.BUYERSREFERENCE) + 1,len(po.BUYERSREFERENCE))), --дата накладной
		r.EFFECTIVEDATE=po.EFFECTIVEDATE,
		r.CompanyName=st.CompanyName,
		r.editdate=po.EDITDATE
	from #rt r
	join wh2.po po on po.POKEY=@pk
	left join wh2.storer st on po.SELLERNAME = st.storerkey	
	
	
	
	
	
select *
from #rt

drop table #ozhid
drop table #prin
drop table #rt
drop table #prinBRLO

