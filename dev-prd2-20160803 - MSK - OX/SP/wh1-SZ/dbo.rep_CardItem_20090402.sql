-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	карточка товара
-- =============================================
ALTER PROCEDURE [dbo].[rep_CardItem_20090402]
  @wh varchar(10),
  @stkey varchar(15),
  @DatB datetime,
  @DatE datetime,
  @Sku varchar(50)
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

declare 
  @sql varchar(max)


declare @OstOnB decimal(22,5)
select @OstOnB=
(select 
  sum(isnull(QTY,0)) as ost
from 
  wh1.vItrDoc
where
  SKU=@Sku
  and dat<@datB
  and STORERKEY=@stkey
)


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
exec(@sql)

-- изменяем консолидированные заказы
set
  @sql='
Declare 
  @Ord_id varchar(20),
  @s varchar(50),
  @DocNav varchar(32),
  @KolItemZak decimal(22,5)

DECLARE Ord_cursorWMS CURSOR
     FOR   
       Select
         Nomdoc,
         sku
       from
         #OstWMS
       where
         typ=2
         and ExtNomDoc=''consolidation''
OPEN Ord_cursorWMS

FETCH NEXT FROM Ord_cursorWMS INTO @Ord_id,@s
WHILE @@FETCH_STATUS= 0 
BEGIN
  DECLARE Ord_c_cur CURSOR
  FOR 
	select 
      EXTERNORDERKEY
 	from 
	 '+@wh+'.orderdetail_c det_c 
	where 
      det_c.orderkey=@Ord_id
	  and det_c.sku=@s
	order by id

  	open Ord_c_cur
	FETCH NEXT FROM Ord_c_cur INTO @DocNav
	WHILE @@FETCH_STATUS= 0 
	BEGIN
      update #OstWMS
      Set 
        ExtNomDoc=ExtNomDoc+'' ''+@DocNav
      where
        SOURCETYPE=''ntrPickDetailUpdate''
        and Nomdoc=@Ord_id
      FETCH NEXT FROM Ord_c_cur INTO @DocNav
    end
	CLOSE Ord_c_cur
	DEALLOCATE Ord_c_cur
    FETCH NEXT FROM Ord_cursorWMS INTO @Ord_id,@s
end
CLOSE Ord_cursorWMS
DEALLOCATE Ord_cursorWMS'  
exec(@sql)
 
-- считаем остатки на начало и конец операции
declare 
  --@Nom varchar(32),
  @kolE decimal(22,5),
  @kol decimal(22,5),
  @ITRNKEY varchar(10)

set @kolE=isnull(@OstOnB,0)
set @kol=0
DECLARE Ost_cursor CURSOR
FOR   
Select
  ITRNKEY,
  qty
from
  #OstWMS
order by
  ITRNKEY
OPEN Ost_cursor

FETCH NEXT FROM Ost_cursor INTO @ITRNKEY, @kol
WHILE @@FETCH_STATUS= 0 
BEGIN 
  Update #OstWMS
  set ostB=@kolE,
      ostE=@kolE+@kol
  where ITRNKEY=@ITRNKEY 
  set @kolE=@kolE+@kol
  FETCH NEXT FROM Ost_cursor INTO @ITRNKEY, @kol
end
CLOSE Ost_cursor
DEALLOCATE Ost_cursor


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
order by
  ITRNKEY
END

