-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[StartStatistic01] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select	pz.putawayzone	Zone,
		pz.descr		ZoneName,
		count(l.loc)	TotalLocCount
into #TotalLocCount
from wh1.loc l
join wh1.putawayzone pz on (l.putawayzone=pz.putawayzone)
group by pz.putawayzone, pz.descr

--select	pz.putawayzone	Zone,
--		pz.descr		ZoneName,
--		cast(month(lld.editdate) as varchar)+'/'
--			+ cast(day(lld.editdate) as varchar)+' '
--			+ cast(datepart(hour,lld.editdate) as varchar)+':'
--			+ cast(round((datepart(minute,lld.editdate))/30,0)*30 as varchar)	CheckTime,
--		lld.editwho		CheckBy,
--		count(lld.loc)	CheckedLocCount
--into #CheckedLocCount
--from wh1.loc l
--join wh1.putawayzone pz on (l.putawayzone=pz.putawayzone)
--join wh1.lotxlocxid lld on (l.loc=lld.loc)
--where lld.qty>0
--group by	pz.putawayzone,
--			pz.descr,
--			cast(month(lld.editdate) as varchar)+'/'
--			+ cast(day(lld.editdate) as varchar)+' '
--			+ cast(datepart(hour,lld.editdate) as varchar)+':'
--			+ cast(round((datepart(minute,lld.editdate))/30,0)*30 as varchar),
--			lld.editwho

select	pz.putawayzone	Zone,
		pz.descr		ZoneName,
		--replicate('0',2-len(...))+(...)
		replicate('0',2-len(cast(month(lld.editdate) as varchar)))+(cast(month(lld.editdate) as varchar))
			+'/'
			+ replicate('0',2-len(cast(day(lld.editdate) as varchar)))+(cast(day(lld.editdate) as varchar))
			+' '
			+ replicate('0',2-len(cast(datepart(hour,lld.editdate) as varchar)))+(cast(datepart(hour,lld.editdate) as varchar))
			+':'
			+ replicate('0',2-len(cast(round((datepart(minute,lld.editdate))/30,0)*30 as varchar)))+(cast(round((datepart(minute,lld.editdate))/30,0)*30 as varchar))
			CheckTime,
		lld.editwho		CheckBy,
		lld.loc			Loc,
		count(lld.sku) SkuCount
into #CheckedLoc
from wh1.loc l
join wh1.putawayzone pz on (l.putawayzone=pz.putawayzone)
join wh1.lotxlocxid lld on (l.loc=lld.loc)
where lld.qty>0
group by	pz.putawayzone,
			pz.descr,
--			cast(month(lld.editdate) as varchar)+'/'
--			+ cast(day(lld.editdate) as varchar)+' '
--			+ cast(datepart(hour,lld.editdate) as varchar)+':'
--			+ cast(round((datepart(minute,lld.editdate))/30,0)*30 as varchar),
			replicate('0',2-len(cast(month(lld.editdate) as varchar)))+(cast(month(lld.editdate) as varchar))
			+'/'
			+ replicate('0',2-len(cast(day(lld.editdate) as varchar)))+(cast(day(lld.editdate) as varchar))
			+' '
			+ replicate('0',2-len(cast(datepart(hour,lld.editdate) as varchar)))+(cast(datepart(hour,lld.editdate) as varchar))
			+':'
			+ replicate('0',2-len(cast(round((datepart(minute,lld.editdate))/30,0)*30 as varchar)))+(cast(round((datepart(minute,lld.editdate))/30,0)*30 as varchar)),
			lld.loc,
			lld.editwho
			

select Zone, ZoneName, CheckTime, CheckBy, count(Loc) CheckedLocCount, sum(SkuCount) SkuCount, 0 accumulateCheckCount  into #CheckedLocCount from #CheckedLoc group by Zone, ZoneName, CheckTime, CheckBy

update #CheckedLocCount
set accumulateCheckCount=(select isnull(sum(CL2.CheckedLocCount),0)
							from #CheckedLocCount CL2
							where CL2.CheckTime<=#CheckedLocCount.CheckTime
									and CL2.Zone=#CheckedLocCount.Zone
									and CL2.CheckBy=#CheckedLocCount.CheckBy)


select TL.*, CL.CheckTime, CL.CheckBy, CL.CheckedLocCount, CL.SkuCount, CL.accumulateCheckCount
from #TotalLocCount TL join #CheckedLocCount CL on (TL.zone=CL.zone)



END

