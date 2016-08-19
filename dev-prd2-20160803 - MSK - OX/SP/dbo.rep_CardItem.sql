-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	карточка товара
-- =============================================
ALTER PROCEDURE [dbo].[rep_CardItem]
  @wh varchar(10),
  @stkey varchar(15),
  @DatB datetime,
  @DatE datetime,
  @Sku varchar(50),
  @PUTAWAYZONE varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

set dateformat dmy
   Create Table #OstWMS(
     ostB decimal(22,5),
     ostE decimal(22,5),
     qty decimal(22,5),
     Nomdoc varchar(10),
     ExtNomDoc varchar(255), 
     typ int,
     sku varchar(50),
     SOURCETYPE varchar(100),
     ITRNKEY varchar(10),
     dat datetime)

   Create Table #OstWMS_Cons(
     qty decimal(22,5),
     Nomdoc varchar(10),
     ExtNomDoc varchar(255), 
     sku varchar(50),
     ITRNKEY varchar(10),
     dat datetime)

declare 
  @sql varchar(max)

if @PUTAWAYZONE='SKLAD' 
set @sql = '
  insert into #OstWMS
  ( qty,Nomdoc ,ExtNomDoc ,typ,sku, SOURCETYPE,ITRNKEY,dat)
select
    sum(QTY) as qty,
    isnull(Nomdoc,ITRNKEY) as Nomdoc,
    zakN,
    Case 
      When sum(QTY)>0 then 1
      When sum(QTY)<0 then 2
    end as t,
    SKU,
    SOURCETYPE,
    ITRNKEY,
    dat
  from 
     '+@wh+'.vItrDoc
  where
    SKU='''+@Sku+'''
    and dat between '''+ convert(varchar(10),@datB,104)+''' and '''+ convert(varchar(10),@datE,104)+'''
    and STORERKEY='''+@stkey+''' 
  group by
    SOURCETYPE,
    Nomdoc,
    zakN,
    ITRNKEY,
    SKU,
    dat
  order by
    ITRNKEY 
    
'
else
set @sql = '
  insert into #OstWMS
  ( qty,Nomdoc ,ExtNomDoc ,typ,sku, SOURCETYPE,ITRNKEY,dat)
select
    sum(QTY) as qty,
    isnull(Nomdoc,ITRNKEY) as Nomdoc,
    zakN,
    Case 
      When sum(QTY)>0 then 1
      When sum(QTY)<0 then 2
    end as t,
    SKU,
    SOURCETYPE,
    ITRNKEY,
    dat
  from '
     +@wh+'.vItrDocZona
  where
    SKU='''+@Sku+'''
    and PUTAWAYZONE='''+@PUTAWAYZONE+'''
    and dat between '''+ convert(varchar(10),@datB,104)+''' and '''+ convert(varchar(10),@datE,104)+'''
    and STORERKEY='''+@stkey+''' 
  group by
    SOURCETYPE,
    Nomdoc,
    zakN,
    ITRNKEY,
    SKU,
    dat
  order by
    ITRNKEY 
'
exec(@sql)

-- обрабатываем консолидированные заказы
Set @sql='
insert into #OstWMS_Cons
(Nomdoc, ExtNomDoc, sku, ITRNKEY, dat )
Select
  d.Nomdoc ,
  det_c.EXTERNORDERKEY ,
  d.sku,
  min(d.ITRNKEY),
  d.dat
from
  #OstWMS as d,
  '+@wh+'.orderdetail_c det_c 
where
  det_c.orderkey=d.Nomdoc
  and d.ExtNomDoc=''consolidation''
group by 
  d.Nomdoc ,
  det_c.EXTERNORDERKEY ,
  d.sku,
  d.dat
'
exec(@sql)



set
  @sql='
Declare 
  @Ord_id varchar(20),
  @OrdNav varchar(32),
  @DocNav varchar(32),
  @KolItemZak decimal(22,5),
  @kolShip decimal(22,5)

DECLARE Ord_cursorWMS CURSOR
     FOR   
  Select distinct
    ordDet.ORDERKEY,
    sum(ordDet.SHIPPEDQTY)
  from '
    +@wh+'.ORDERS ord left join '
    +@wh+'.ORDERDETAIL ordDet on ord.ORDERKEY=ordDet.ORDERKEY 
 where  
   ord.ORDERKEY in (select distinct Nomdoc from #OstWMS_Cons)
   and Ord.EXTERNORDERKEY=''consolidation'' 
   and OrdDet.SKU='''+@Sku+'''
 group by
   ordDet.ORDERKEY
order by
  ordDet.ORDERKEY

OPEN Ord_cursorWMS

FETCH NEXT FROM Ord_cursorWMS INTO @Ord_id, @kolShip
WHILE @@FETCH_STATUS= 0 
BEGIN
  DECLARE Ord_c_cur CURSOR
  FOR 
	select 
       EXTERNORDERKEY,
	   sum(isnull(openQty,0))
	from 
	  '+@wh+'.orderdetail_c det_c 
	where 
      det_c.orderkey=@Ord_id
	  and det_c.sku='''+@sku+'''
	group by EXTERNORDERKEY,id
	order by id

  	open Ord_c_cur
	FETCH NEXT FROM Ord_c_cur INTO @OrdNav, @KolItemZak
	WHILE @@FETCH_STATUS= 0 
	BEGIN
		if @kolShip>=@KolItemZak
		begin
			Update #OstWMS_Cons
			Set
				qty=isnull(qty,0)+@KolItemZak
			where 
				ExtNomDoc=@OrdNav and nomdoc=@Ord_id
			set @kolShip=@kolShip-@KolItemZak
		end
		else
		begin
			Update #OstWMS_Cons
			Set
				qty=isnull(qty,0)+@kolShip
			where 
				ExtNomDoc=@OrdNav and nomdoc=@Ord_id
			set @kolShip=0
        end
		FETCH NEXT FROM Ord_c_cur INTO @OrdNav, @KolItemZak
    end
	CLOSE Ord_c_cur
	DEALLOCATE Ord_c_cur
    set @kolShip=0
    FETCH NEXT FROM Ord_cursorWMS INTO @Ord_id, @kolShip
end
CLOSE Ord_cursorWMS
DEALLOCATE Ord_cursorWMS'  
exec(@sql)

Delete from 
  #OstWMS
where
  ExtNomDoc='consolidation'

insert into #OstWMS
 ( qty,Nomdoc ,ExtNomDoc ,typ,sku, SOURCETYPE,ITRNKEY,dat)
(select 
   (-1)*qty,
   Nomdoc,
   ExtNomDoc, 
   2,
   sku,
   'ntrPickDetailUpdate',
   ITRNKEY,
   dat
 from #OstWMS_Cons
)



if @PUTAWAYZONE='SKLAD' 
 Set @sql='
  declare @OstOnB decimal(22,5)
  select @OstOnB=
   (select 
      sum(isnull(QTY,0)) as ost
    from '
      +@wh+'.vItrDoc
    where
      SKU='''+@Sku+'''
      and dat<'''+convert(varchar(10),@datB,104)+'''
      and STORERKEY='''+@stkey+'''
   ) '
else
 Set @sql=' 
 declare @OstOnB decimal(22,5) 
 select @OstOnB=
   (select 
      sum(isnull(QTY,0)) as ost
    from '
      +@wh+'.vItrDocZona
    where
      SKU='''+@Sku+'''
      and PUTAWAYZONE='''+@PUTAWAYZONE+'''
      and dat<'''+convert(varchar(10),@datB,104)+'''
      and STORERKEY='''+@stkey+'''
   ) '
 
 
-- считаем остатки на начало и конец операции

set @sql=@sql+'
 declare 
  @Nom varchar(32),
  @kolE decimal(22,5),
  @kol decimal(22,5),
  @ITRNKEY varchar(10)

set @kolE=isnull(@OstOnB,0)
set @kol=0
DECLARE Ost_cursor CURSOR
FOR   
Select
  ITRNKEY,
  qty, 
  ExtNomDoc
from
  #OstWMS
where 
  qty is not null
order by
  ITRNKEY
OPEN Ost_cursor

FETCH NEXT FROM Ost_cursor INTO @ITRNKEY, @kol,@Nom
WHILE @@FETCH_STATUS= 0 
BEGIN 
  Update #OstWMS
  set ostB=@kolE,
      ostE=@kolE+@kol
  where ITRNKEY=@ITRNKEY  and ExtNomDoc=@Nom
  set @kolE=@kolE+@kol
  FETCH NEXT FROM Ost_cursor INTO @ITRNKEY, @kol,@Nom
end
CLOSE Ost_cursor
DEALLOCATE Ost_cursor '
exec(@sql)


select
  ostB,
  ostE,
  abs(qty) as q,
  (case 
   when Nomdoc='' then ITRNKEY else Nomdoc end) as Nomdoc,
  ExtNomDoc, 
  case 
   when Nomdoc='' then ITRNKEY+'\'+ExtNomDoc else Nomdoc+'\'+ExtNomDoc end as doc,
  typ,
  sku,
  SOURCETYPE,
  ITRNKEY,
  case
   when typ=1 then abs(qty) else 0 end as p,
  case
   when typ=2 then abs(qty) else 0 end as r,
  dat 
from 
  #OstWMS
where 
  qty is not null
order by
  ITRNKEY
END

