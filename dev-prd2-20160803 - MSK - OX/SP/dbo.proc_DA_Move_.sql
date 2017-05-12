-- РАБОТА С БРАКОМ --

ALTER PROCEDURE [dbo].[proc_DA_Move](
	@wh varchar(10),
	@transmitlogkey varchar (10)
	
)AS

SET NOCOUNT ON

if @wh <> 'wh1'
begin
	raiserror('Недопустимая схема %s',16,1,@wh)
	return
end

CREATE TABLE #result(
    [externdockey] varchar(15) NULL,
	[date] varchar(15) NULL,
	[storerkey] varchar(15) NULL,
	[sku] varchar(50) NULL,
	[qty] decimal(19,10) NULL,
	[sourcezone] varchar(20) NULL,
	[destzone] varchar(20) NULL)

print	'1. перемещение норм. -> брак, брак -> норм. (кроме BRAKPRIEM)'
/*
	insert into #result
	select 
		convert(varchar(8),i.adddate,112), i.storerkey, i.sku, i.qty,
		case when hz2.hostzone is null then 'SKLAD' else hz2.hostzone end,
		case when hz.hostzone is null then 'SKLAD' else hz.hostzone end
	from wh1.transmitlog tl inner join wh1.itrn i on tl.key1 = i.itrnkey
		inner join wh1.loc l on l.loc = i.toloc
		inner join wh1.loc l2 on l2.loc = i.fromloc
		left join wh1.hostzones hz on hz.putawayzone = l.putawayzone and hz.storerkey = i.storerkey
		left join wh1.hostzones hz2 on hz2.putawayzone = l2.putawayzone and hz2.storerkey = i.storerkey
	where tl.transmitlogkey = @transmitlogkey
				and (i.toloc <> 'BRAKPRIEM')	and (i.fromloc <> 'BRAKPRIEM')
				and (   (l.putawayzone like 'BRAK%' and l2.putawayzone not like 'BRAK%')
				     or (l2.putawayzone like 'BRAK%' and l.putawayzone not like 'BRAK%') )
*/
	insert into #result
	select 
        i.itrnkey,
		convert(varchar(8),i.adddate,112), i.storerkey, i.sku, i.qty,
		case when hz2.hostzone is null then (select hostzone from wh1.hostzones where putawayzone='SKLAD' and storerkey=i.storerkey) else hz2.hostzone end,
		case when hz.hostzone is null then (select hostzone from wh1.hostzones where putawayzone='SKLAD' and storerkey=i.storerkey) else hz.hostzone end
	from wh1.transmitlog tl 
		inner join wh1.itrn i on tl.key1 = i.itrnkey
		inner join wh1.loc l on l.loc = i.toloc
		inner join wh1.loc l2 on l2.loc = i.fromloc
		left join wh1.hostzones hz on hz.putawayzone = l.putawayzone and hz.storerkey = i.storerkey
		left join wh1.hostzones hz2 on hz2.putawayzone = l2.putawayzone and hz2.storerkey = i.storerkey
	where tl.transmitlogkey = @transmitlogkey
				and (i.toloc <> 'BRAKPRIEM') and (i.fromloc <> 'BRAKPRIEM')
				and ( (l.putawayzone like 'BRAK%' and l2.putawayzone not like 'BRAK%')
				     or (l2.putawayzone like 'BRAK%' and l.putawayzone not like 'BRAK%') )
print '2. передача результата'
select 'MOVE' as filetype, r.* from #Result r

drop table #Result

