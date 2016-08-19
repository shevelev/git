ALTER PROCEDURE [dbo].[DK_BILLING] as

	declare @getdate varchar(10)
	set @getdate= convert(varchar(10),getdate(),112)-- '20081016' --         getdate()--'20071201'


declare @FillRemains int, @fillReceipt int, @fillOrders int

select	@FillRemains=1, 
		@fillReceipt=1, 
		@fillOrders=1

if @FillRemains =1 
begin
--#region создание таблиц для расчета остатков
	/********* создание таблиц для расчета остатков ********/
	if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[lochistory]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	create table lochistory (
		STORER varchar(50),
		SKU varchar(50),
		loc varchar(20) null,
		id varchar(20) null,
		lot varchar(10) null,
		qty numeric,
		qtypicked numeric,
		qtyallocated numeric,
		qtyexpected numeric,
		CASECNT numeric,
		PALLETCNT numeric,
		status varchar(10),
		dt_balans datetime,
		lottable01 varchar(100),
		lottable02 varchar(100),
		lottable03 varchar(100),
		lottable04 datetime,
		lottable05 datetime,
		lottable06 varchar(100),
		lottable07 varchar(100),
		lottable08 varchar(100),
		lottable09 varchar(100),
		lottable10 varchar(100)
	)

	if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[skuhistory]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	create table skuhistory (
		STORER varchar(50),
		SKU varchar(50),
		lot varchar(10) null,
		qty numeric,
		qtypicked numeric,
		qtyallocated numeric,
		qtyexpected numeric,
		CASECNT numeric,
		PALLETCNT numeric,
		status varchar(10),
		dt_balans datetime,
		lottable01 varchar(100),
		lottable02 varchar(100),
		lottable03 varchar(100),
		lottable04 datetime,
		lottable05 datetime,
		lottable06 varchar(100),
		lottable07 varchar(100),
		lottable08 varchar(100),
		lottable09 varchar(100),
		lottable10 varchar(100)
	)

--#endregion

--#region заполнение таблиц остатков
	/**** заполнение таблицы остатков по ячейкам  ***/
	-- удалить данные за сегодняшний день
	delete from lochistory where dt_balans=@getdate
	-- добавляем заново расчитанные данные
	insert into lochistory (STORER,SKU,loc,id,lot,qty,qtypicked,qtyallocated,qtyexpected,casecnt,palletcnt,status,dt_balans,
			lottable01,lottable02,lottable03,lottable04,lottable05,lottable06,lottable07,lottable08,lottable09,lottable10)
	select PARTY.storerkey,PARTY.sku,PARTY.loc,PARTY.id,PARTY.lot,sum(PARTY.qty),sum(PARTY.qtypicked),
			sum(PARTY.qtyallocated),sum(PARTY.qtyexpected),P.CASECNT,P.PALLET,PARTY.status,@getdate,
			l.lottable01,l.lottable02,l.lottable03,l.lottable04,l.lottable05,l.lottable06,l.lottable07,l.lottable08,l.lottable09,l.lottable10
	from wh1.lotxlocxid as PARTY
			left join wh1.lotattribute as L on l.LOT=PARTY.LOT
			join wh1.SKU as S on S.SKU=PARTY.SKU and S.STORERKEY=PARTY.STORERKEY
			join wh1.PACK P on S.packkey = P.packkey
	group by PARTY.storerkey,PARTY.sku,PARTY.loc,PARTY.id,PARTY.lot,
				P.CASECNT,P.PALLET,PARTY.status,
				l.lottable01,l.lottable02,l.lottable03,l.lottable04,l.lottable05,
				l.lottable06,l.lottable07,l.lottable08,l.lottable09,l.lottable10
	having sum(PARTY.qty)>0
	---select * from wh1.lochistory


	/****** заполнение таблицы остатков по товарам *******/
	-- удалить данные за сегодняшний день
	delete from skuhistory where convert(varchar(10),dt_balans,112)=@getdate
	-- добавляем заново расчитанные данные
	insert into skuhistory (STORER,SKU,lot,qty,qtypicked,qtyallocated,qtyexpected,casecnt,palletcnt,status,
			dt_balans,
			lottable01,lottable02,lottable03,lottable04,lottable05,
			lottable06,lottable07,lottable08,lottable09,lottable10)
	select PARTY.storerkey,PARTY.sku,
		PARTY.lot,sum(PARTY.qty),sum(PARTY.qtypicked),sum(PARTY.qtyallocated),sum(PARTY.qtyexpected),P.CASECNT,P.PALLET,PARTY.status,
		@getdate,
		lottable01,lottable02,lottable03,lottable04,lottable05,
		lottable06,lottable07,lottable08,lottable09,lottable10
	from wh1.lotxlocxid as PARTY
		join wh1.lotattribute as L on l.LOT=PARTY.LOT
		join wh1.SKU as S on S.SKU=PARTY.SKU and S.STORERKEY=PARTY.STORERKEY
		join wh1.PACK P on S.packkey = P.packkey
	group by PARTY.storerkey,PARTY.sku,PARTY.lot,P.CASECNT,P.PALLET,PARTY.status,
			l.lottable01,l.lottable02,l.lottable03,l.lottable04,l.lottable05,
			l.lottable06,l.lottable07,l.lottable08,l.lottable09,l.lottable10
	having sum(PARTY.qty)>0

--#endregion
end

if @fillReceipt =1 
begin
--#region Создание таблиц по приему данных
	/********   Создание таблиц по приему данных ********/
	if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[PRIEM]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	create table PRIEM (
		RECEIPTKEY varchar(10),
		EXTERNRECEIPTKEY varchar(20),
		DT_PRIEM datetime,
		DT_CLIENT datetime,
		STORERKEY varchar(15),
		TONNAG varchar(250),
		DOSTAVKA varchar(250),
		DOCUMENTS varchar(30)
	)

	if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[PRIEMDETAIL]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	create table PRIEMDETAIL (
		RECEIPTKEY varchar(10),
		RECEIPTLINENUMBER varchar(5),
		STORERKEY varchar(10),
		SKU varchar(50),
		LOT varchar(20),
		QTY numeric,
		UOM varchar(20),
		SUSR1 varchar(20),
		CASECNT numeric,
		PALLETCNT numeric,
		receiveDate datetime,
		Staged int,
		lottable01 varchar(100),
		lottable02 varchar(100),
		lottable03 varchar(100),
		lottable04 datetime,
		lottable05 datetime,
		lottable06 varchar(100),
		lottable07 varchar(100),
		lottable08 varchar(100),
		lottable09 varchar(100),
		lottable10 varchar(100)
	)

--#endregion

--#region заполнение таблиц по приему
	/******** заполнение таблицы шапки заявок на прием  *************/
	-- удаление старых данных за текущую дату
	delete from priem where convert(varchar(10),dt_priem,112)=@getdate 

	-- добавление вновь расчитанных данных
	insert into priem (RECEIPTKEY,EXTERNRECEIPTKEY,DT_PRIEM,DT_CLIENT,STORERKEY,TONNAG,DOSTAVKA,DOCUMENTS)
		select R.Receiptkey,R.externReceiptkey,
			convert(varchar(10),R.Receiptdate,112),
			convert(varchar(10),R.vehicledate,112),
			R.storerkey,C.DESCRIPTION,CD.DESCRIPTION,R.CONTAINERQTY
		from wh1.receipt as R
			join WH1.CODELKUP C on isnull(R.Transportationmode,'0')=C.CODE and C.LISTNAME='TRANSPMODE' 
			join WH1.CODELKUP CD on isnull(R.INCOTERMS,'0')=CD.CODE and CD.LISTNAME='INCOTERMS' 
		where convert(varchar(10),R.receiptdate,112)=@getdate



	/************* заполнение таблицы cо строками заявок на прием  ***************/
	-- удаление старых данных за текущую дату
	--delete from priemdetail where RECEIPTKEY in(select RECEIPTKEY from PRIEM where convert(varchar(10),dt_priem,112)=@getdate)
	delete from priemdetail where convert(varchar(10),receiveDate,112)=@getdate


	-- определение типа ячеек товаров принятых в STAGE
	select rd.serialkey, 
		case locationtype 
			when 'STAGED' then 1
			when 'PICKTO' then 2
			else 3
		end staged,-- 0 staged,
		case when min(trn.fromloc) is null then min(rd.datereceived) else min(trn.effectivedate) end datereceived
	into #moved
	from wh1.receiptdetail rd
			left join wh1.itrn trn on trn.fromid=rd.toid
			left join wh1.loc loc on loc.loc=isnull(trn.toloc,rd.toloc) 
	where isnull(trantype,'MV') = 'MV'  and qtyreceived > 0 
		and not (locationtype in ('PICKTO'))
		--and convert(varchar(10),Datereceived,112)=@getdate
	group by rd.serialkey, locationtype


	-- добавление вновь расчитанных данных
	insert into priemdetail (RECEIPTKEY, receiptlinenumber, STORERKEY,SKU,LOT,QTY,UOM,CASECNT,PALLETCNT,
			receiveDate, staged,
			lottable01,lottable02,lottable03,lottable04,lottable05,
			lottable06,lottable07,lottable08,lottable09,lottable10)
		select R.Receiptkey, receiptlinenumber, R.storerkey, R.sku, l.lot, sum(R.qtyreceived), R.SUSR1, PK.casecnt, PK.pallet,
			--r.datereceived, 0,
			convert(varchar(10),case when not staged is null then min(mv.datereceived) else r.datereceived end,112),
			isnull(staged,0),
			l.lottable01,l.lottable02,l.lottable03,l.lottable04,l.lottable05,
			l.lottable06,l.lottable07,l.lottable08,l.lottable09,l.lottable10 
		from wh1.Receiptdetail as R
			left join #moved mv on mv.serialkey=r.serialkey
			join wh1.PACK PK on R.packkey = PK.packkey
			join wh1.lotattribute as l on R.tolot = l.lot
		where convert(varchar(10),r.datereceived,112) = @getdate 
		group by R.Receiptkey,receiptlinenumber,R.storerkey,R.sku,R.SUSR1,r.uom,staged,
			PK.casecnt,PK.pallet,r.datereceived, l.lot,
			l.lottable01,l.lottable02,l.lottable03,l.lottable04,l.lottable05,
			l.lottable06,l.lottable07,l.lottable08,l.lottable09,l.lottable10 
	
	drop table #moved

--#endregion
END

if @fillOrders =1 
begin
--#region создание таблиц заявок на отгрузку
	/************* создание таблиц заявок на отгрузку  ***************/
	if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[RASHOD]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	create table RASHOD (
		ORDERKEY varchar(10),
		EXTERNORDERKEY varchar(10),
		DT_CLIENT datetime,
		DT_PRIEM datetime,
		STORERKEY varchar(10),
		TONNAG varchar(50),
		DOSTAVKA varchar(50),
		DOCUMENTS varchar(10),
		GOROD varchar(20),
		PROSTOY varchar(20),
		NUMPALLET varchar(20)
	)

	if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[RASHODDETAIL]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	create table RASHODDETAIL (
		ORDERKEY varchar(10),
		NOPOS varchar(5),
		STORERKEY varchar(10),
		SKU varchar(50),
		LOT varchar(20),
		QTY numeric,
		TYPOTGRUZKI varchar(20),
		CASECNT numeric,
		PALLETCNT numeric,
		OrderDate datetime,
		lottable01 varchar(100),
		lottable02 varchar(100),
		lottable03 varchar(100),
		lottable04 datetime,
		lottable05 datetime,
		lottable06 varchar(100),
		lottable07 varchar(100),
		lottable08 varchar(100),
		lottable09 varchar(100),
		lottable10 varchar(100)
	)

--#endregion

--#region заполнение таблиц на отгрузку
	/************* заполнение таблицы шапки заявок на отгрузку  ***************/
	-- удаление старых данных за текущую дату
	delete from rashod where convert(varchar(10),dt_priem,112) = @getdate
	-- добавление новых данных
	insert into rashod (orderkey,externorderkey,dt_client,dt_priem,storerkey,TONNAG,DOSTAVKA,DOCUMENTS,GOROD,PROSTOY,NUMPALLET)
		select R.orderkey,R.externorderkey, r.orderdate,
			convert(varchar(10),R.actualshipdate,112),
			R.storerkey, C.DESCRIPTION, CD.DESCRIPTION,R.CONTAINERQTY,C1.DESCRIPTION,R.TRANSPORTATIONSERVICE,R.DISCHARGEPLACE
		from wh1.orders as R
			join WH1.CODELKUP C on isnull(R.Transportationmode,'0')=C.CODE and C.LISTNAME='TRANSPMODE' 
			join WH1.CODELKUP CD on isnull(R.INCOTERM,'0')=CD.CODE and CD.LISTNAME='INCOTERMS' 
			join WH1.CODELKUP C1 on isnull(R.OHTYPE,'1')=C1.CODE and C1.LISTNAME='ORDHNDTYPE' 
		where R.status >90 and convert(varchar(10),R.actualshipdate,112)=@getdate



	/************* заполнение таблицы строк заявок на отгрузку  ***************/
	-- удаление старых данных за текущую дату
	delete from RASHODDETAIL where ORDERKEY in(select ORDERKEY	from RASHOD where convert(varchar(10),DT_PRIEM,112)=@getdate)

	-- добавление новых данных
	insert into RASHODDETAIL (ORDERKEY,NOPOS,STORERKEY,SKU,LOT,QTY,CASECNT,PALLETCNT,TYPOTGRUZKI,
		orderDate,
		lottable01,lottable02,lottable03,lottable04,lottable05,
		lottable06,lottable07,lottable08,lottable09,lottable10)
	select R.ORDERKEY,R.ORDERLINENUMBER,R.STORERKEY,R.SKU, l.lot, sum(R.QTY) as QTY, 
		P.CASECNT,P.PALLET, 
		case od.uom when 'PL' then 'Паллетная'
					when 'CS' then 'Коробочная'
					when 'EA' then 'Штучная' 
					else 'Неизвестно' end,
		convert(varchar(10),pk.actualshipdate,112),
		L.lottable01,L.lottable02,L.lottable03,L.lottable04,L.lottable05,
		L.lottable06,L.lottable07,L.lottable08,L.lottable09,L.lottable10
	from wh1.PICKdetail as R
		left join wh1.orderdetail od on r.orderkey=od.orderkey and r.orderlinenumber=od.orderlinenumber
		join WH1.PACK P on P.PACKKEY=R.PACKKEY
		join WH1.LOTATTRIBUTE L on L.LOT=R.LOT
		join WH1.ORDERS PK on PK.ORDERKEY=R.ORDERKEY
	where PK.status >90 
			--and R.orderkey in(select orderkey from rashod where convert(varchar(10),PK.actualshipdate,112)=@getdate)
		and convert(varchar(10),pk.actualshipdate,112) = @getdate
	group by R.Orderkey,R.Orderlinenumber,R.storerkey,R.sku,R.qty,p.casecnt,p.pallet,
			convert(varchar(10),pk.actualshipdate,112), l.lot, od.uom, 
			L.lottable01,L.lottable02,L.lottable03,L.lottable04,L.lottable05,
			L.lottable06,L.lottable07,L.lottable08,L.lottable09,L.lottable10

--#endregion

end

