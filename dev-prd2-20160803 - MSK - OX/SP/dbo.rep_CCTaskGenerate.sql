
ALTER PROCEDURE dbo.rep_CCTaskGenerate ( @storerkey varchar(20),					
 @sku varchar(20),
 @lot02 varchar(20)
 )
 AS

--declare @storerkey varchar(20)					
--declare @sku varchar(20)
--declare @lot02 varchar(20)

declare @numsku int
declare @taskID int
declare @currdate datetime
declare @who varchar(30)

set @who = 'report'
set @currdate = GETDATE()

if @lot02 = ''
	set @lot02 = null

select lli.serialkey into #lli from wh1.lotxlocxid lli
	join wh1.lotattribute la on la.lot = lli.lot
where lli.storerkey = @storerkey and  lli.sku = @sku
		and qtyallocated = 0 and qtypicked = 0 and qty > 0
		and (@lot02 is null or la.LOTTABLE02 = @lot02)
					
select @numsku = count(1) from #lli

print ' удалить все не выполненные по данному товару'
delete from wh1.taskdetail where TASKTYPE = 'CC' and STATUS = '0' and STORERKEY = @storerkey and SKU = @sku


print ' вставить записи в TASKDETAIL'

exec dbo.DA_GetNewKey 'wh1', 'TASKDETAILKEY', @taskID out, @numsku
					
if exists(select 1 from wh1.taskdetail where taskdetailkey = right('000000000'+cast((@taskID)as nvarchar),10))
	exec dbo.DA_GetNewKey 'wh1', 'TASKDETAILKEY', @taskID out, @numsku

INSERT INTO [wh1].[TASKDETAIL] (
	[TASKDETAILKEY], [WHSEID], [TASKTYPE], [STORERKEY], [SKU], 
	[LOT], [UOM], [UOMQTY], [QTY], [FROMLOC], 
	[LOGICALFROMLOC], [FROMID], [TOLOC], [LOGICALTOLOC], [TOID], 
	[CASEID], [PICKMETHOD], [STATUS], [STATUSMSG], [PRIORITY], 
	[SOURCEPRIORITY], [HOLDKEY], [USERKEY], [USERPOSITION], [USERKEYOVERRIDE], 
	[STARTTIME], [ENDTIME], [SOURCETYPE], [SOURCEKEY], [PICKDETAILKEY], 
	[ORDERKEY], [ORDERLINENUMBER], [LISTKEY], [WAVEKEY], [REASONKEY], 
	[MESSAGE01], [MESSAGE02], [MESSAGE03], [FINALTOLOC], [RELEASEDATE], 
	[OPTBATCHID], [OPTTASKSEQUENCE], [OPTREPLENISHMENTUOM], [OPTQTYLOCMINIMUM], [OPTLOCATIONTYPE], 
	[OPTQTYLOCLIMIT], [SEQNO], [ADDDATE], [ADDWHO], [EDITDATE], 
	[EDITWHO], [DOOR], [ROUTE], [STOP], [PUTAWAYZONE]

	)
SELECT right('000000000'+cast((@taskID+row_number() over (order by lli.serialkey) -1)as nvarchar),10),'WH1', 'CC', @storerkey, @sku /**/, 
	lli.lot, '6'/*@UOM - всегда EA(6)*/, 0.0, lli.QTY, lli.LOC, 
	l.logicallocation, lli.ID, '', '', '', 
	''/*@CASEID*/, ''/*@PICKMETHOD*/, '0'/*@STATUS*/, ''/*@STATUSMSG*/, '5'/*@PRIORITY*/,
	''/*@SOURCEPRIORITY*/, ''/*@HOLDKEY*/, ''/*@USERKEY*/, 1/*@USERPOSITION*/, ''/*@USERKEYOVERRIDE*/, 
	@currdate /*@STARTTIME*/, @currdate/*@ENDTIME*/, ''/*@SOURCETYPE*/, ''/*@SOURCEKEY*/, ''/*@PICKDETAILKEY*/, 
	''/*@ORDERKEY*/, ''/*@ORDERLINENUMBER*/, ''/*@LISTKEY*/, ''/*@WAVEKEY*/, ''/*@REASONKEY*/, 
	''/*@MESSAGE01*/, ''/*@MESSAGE02*/, ''/*@MESSAGE03*/, ''/*@FINALTOLOC*/, null/*@RELEASEDATE*/, 
	null/*@OPTBATCHID*/, null/*@OPTTASKSEQUENCE*/, null/*@OPTREPLENISHMENTUOM*/, null/*@OPTQTYLOCMINIMUM*/, null/*@OPTLOCATIONTYPE*/, 
	null/*@OPTQTYLOCLIMIT*/, 99999/*@SEQNO*/, @currdate/*@ADDDATE*/, @who/*@ADDWHO*/, @currdate/*@EDITDATE*/, 
	@who/*@EDITWHO*/, ''/*@DOOR*/, ''/*@ROUTE*/,'' /*@STOP*/, ''/*@PUTAWAYZONE*/ 

from wh1.lotxlocxid lli
	join wh1.loc l on lli.loc = l.loc
where lli.SERIALKEY in (select SERIALKEY from #lli)

select 'Создано задач: '+ CAST(@numsku as varchar) res
