-- =============================================
-- Author:		<KIR, Logicon.Ekaterinburg>
-- Create date: <21.12.2015>
-- =============================================
-- Ўаг ноль подготовить копию физикл с максимальными инвентари и статусом = 0 
--  
-- =============================================
ALTER PROCEDURE [WH1].[compare_Step_0]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


declare @iP int, @iD int, @i int			-- кол-во записей в таблицах по условию в физикл, дакс и временна€.
declare @sku varchar(50), @L02 varchar(50), @L04 varchar(50),@L05 varchar(50), @skl varchar(50), @stp varchar(1)
-- WH1.PHYSICAL - первоначальна€ таблица.
-- WH1.PHYSICAL_ORIGINAL - копию изначальных записей в физикл.
-- PHYSICALtmp - временна€ таблица.
-- PHYSICAL_DAX - обменна€ таблица дл€ дакс.

--! проверить сколько записий в физикл без пол€ лот!
select @i = COUNT(*) from prd2.wh1.PHYSICAL where LOT = ''

--print convert(varchar(20),@i)

if @i = 0
begin

--1 сделать копию изначальных записей в физикл.
--if object_id('prd2.wh1.PHYSICAL_ORIGINAL') is not null drop table prd2.wh1.PHYSICAL_ORIGINAL
--select * into prd2.wh1.PHYSICAL_ORIGINAL from [prd2].[WH1].[PHYSICAL]

--2 временна€ таблица дл€ учета макс инвентаритэг
if object_id('tempdb..#tmpMaxInvent') is not null drop table #tmpMaxInvent

CREATE TABLE #tmpMaxInvent(
	[INVENT] [varchar](18) NOT NULL,
	[tSKU] [varchar](50) NOT NULL,
	[tLOT] [varchar](10) NULL,
	[tLOC] [varchar](10) NULL)

-- наполнение макс инвентаритэг
insert into #tmpMaxInvent
select MAX(INVENTORYTAG), sku, lot, loc
from prd2.wh1.PHYSICAL 
where status = 0
group by sku, lot, loc

--3 скопировать в условно временную таблицу записи с макс инвентари.
if object_id('prd2.wh1.PHYSICALtmp') is not null drop table prd2.wh1.PHYSICALtmp

select WHSEID,TEAM,STORERKEY,SKU,LOC,LOT,ID,INVENTORYTAG,QTY,PACKKEY,
		UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
		SUSR7,SUSR8,SUSR9,SUSR10 
into prd2.wh1.PHYSICALtmp
from prd2.wh1.PHYSICAL
 join #tmpMaxInvent on INVENTORYTAG = INVENT and SKU = tSKU and LOT =tLOT and LOC = tloc 

ALTER TABLE [prd2].[WH1].[PHYSICALtmp] ADD LOT06 VARCHAR(40) NULL
ALTER TABLE [prd2].[WH1].[PHYSICALtmp] ADD skld VARCHAR(20) NULL
ALTER TABLE [prd2].[WH1].[PHYSICALtmp] ADD Step VARCHAR(500) NULL

-- заполн€ем поле склад
UPDATE prd2.wh1.PHYSICALtmp 
SET SKLD = SKLAD 
FROM prd2.wh1.PHYSICALtmp AS P
 join wh1.LOC loc on loc.LOC =p.loc
 join dbo.WHTOZONE w on w.zone = loc.PUTAWAYZONE
where len(p.loc)>0	

-- теперь есть таблица физикл с максимальными инвентари, статусами 0. 
-- »з этой таблицы будем отбирать поэтапно записи и копировать в таблицу физикл дл€ постировани€

-------delete from prd2.wh1.PHYSICAL

--выберем все записи где qty =0 и перенесем их в физикл дл€ постировани€.
update prd2.wh1.PHYSICALtmp
set Step = 'Step 0'
where QTY = 0

-- перенесем в физикл дл€ постировани€.
--insert into prd2.wh1.PHYSICAL (WHSEID,TEAM,STORERKEY,SKU,LOC,LOT,ID,INVENTORYTAG,QTY,PACKKEY,
--		UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
--		SUSR7,SUSR8,SUSR9,SUSR10)
--select WHSEID,TEAM,STORERKEY,SKU,LOC,LOT,ID,INVENTORYTAG,QTY,PACKKEY,
--		UOM,STATUS,ADDDATE,ADDWHO,EDITDATE,EDITWHO,SUSR1,SUSR2,SUSR3,SUSR4,SUSR5,SUSR6,
--		SUSR7,SUSR8,SUSR9,SUSR10
--from prd2.wh1.PHYSICALtmp	
--where Step = 'Step 0'

-- проставим кака€ запись к какому шагу относитс€.
/*ќбъ€вл€ем курсор*/
DECLARE curCURSOR CURSOR READ_ONLY
/*«аполн€ем курсор*/
FOR
select sku, susr1, susr4, susr5, skld from prd2.wh1.PHYSICALtmp
where QTY > 0 --and sku ='10120'
group by sku, susr1, susr4, susr5, skld
/*ќткрываем курсор*/
OPEN curCURSOR
/*¬ыбираем первую строку*/
FETCH NEXT FROM curCURSOR INTO @sku, @L02, @L04, @L05, @skl
/*¬ыполн€ем в цикле перебор строк*/
WHILE @@FETCH_STATUS = 0
  BEGIN

--print 'в курсоре'
--print '		SKU =' + @sku + ' @L02 ='+ @L02 +' @L04 = '+@L04+' @L05 = '+@L05+' skld = '+@skl+' loc = '

	-- определ€ем кол-во записей  по таблицам.
	SELECT @iP = COUNT(*) FROM prd2.wh1.PHYSICALtmp 
	where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl 
	SELECT @iD = COUNT(*) FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].[SZ_ImpInventSumFromWMSPrev]
	where itemid = @sku and (INVENTSERIALID = @L02 or INVENTSERIALID = 'бс') and (MANUFACTUREDATE = @L04 or MANUFACTUREDATE = '19000101') 
	and (EXPIREDATE = @L05 or EXPIREDATE = '19000101') and INVENTLOCATIONID = @skl

--print '@iP = ' + convert(varchar(50),@ip) + ' @iD = ' + convert(varchar(50),@iD)

	if @iP > 0 and @iD = 0 set @stp = '1'
	if @iP = 1 and @iD = 1 set @stp = '2'
	if @iP = 1 and @iD > 1 set @stp = '3'
	if @iP > 1 and @iD = 1 set @stp = '4'
	if @iP > 1 and @iD > 1 set @stp = '5'

--print '@stp = ' + @stp

	update prd2.wh1.PHYSICALtmp
	set Step = 'Step ' + @stp
	from prd2.wh1.PHYSICALtmp
	where SKU = @sku and susr1 = @L02 and (SUSR4 = @L04 or SUSR4 is null) and (SUSR5 = @L05 or SUSR5 is null) and skld = @skl
	
	FETCH NEXT FROM curCURSOR INTO @sku, @L02, @L04, @L05, @skl
  END
CLOSE curCURSOR
DEALLOCATE curCURSOR -- удалить из пам€ти  

if object_id('prd2.wh1.PHYSICAL_DAX') is not null drop table prd2.wh1.PHYSICAL_DAX  
-- сосздадим таблицу обмена дл€ дакс.
CREATE TABLE prd2.wh1.PHYSICAL_DAX(
	[SERIALKEY] [int] IDENTITY(1,1) NOT NULL,
	[WHSEID] [varchar](30) NULL,
	[TEAM] [varchar](1) NOT NULL,
	[STORERKEY] [varchar](15) NOT NULL,
	[SKU] [varchar](50) NOT NULL,
	[LOC] [varchar](10) NOT NULL,
	[LOT] [varchar](10) NOT NULL,
	[ID] [varchar](18) NOT NULL,
	[INVENTORYTAG] [varchar](18) NOT NULL,
	[QTY] [decimal](22, 5) NOT NULL,
	[PACKKEY] [varchar](50) NULL,
	[UOM] [varchar](10) NULL,
	[STATUS] [varchar](1) NULL,
	[ADDDATE] [datetime] NOT NULL,
	[ADDWHO] [varchar](18) NOT NULL,
	[EDITDATE] [datetime] NOT NULL,
	[EDITWHO] [varchar](18) NOT NULL,
	[SUSR1] [varchar](30) NULL,
	[SUSR2] [varchar](30) NULL,
	[SUSR3] [varchar](30) NULL,
	[SUSR4] [datetime] NULL,
	[SUSR5] [datetime] NULL,
	[SUSR6] [varchar](30) NULL,
	[SUSR7] [varchar](30) NULL,
	[SUSR8] [varchar](30) NULL,
	[SUSR9] [varchar](30) NULL,
	[SUSR10] [varchar](30) NULL,
	[skld] [varchar](20) NULL,
	LOT06 [varchar](40) NULL,
	Step [varchar](500) NULL)
  
end
END

