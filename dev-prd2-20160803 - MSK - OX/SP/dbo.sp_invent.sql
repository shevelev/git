ALTER PROCEDURE [dbo].[sp_invent]
as

declare @PLLI numeric, @CLLI numeric, @OLLI numeric, @ALLI numeric
declare @PL numeric, @CL numeric, @OL numeric, @AL numeric
declare @PP numeric, @CP numeric, @OP numeric, @AP numeric


select @ALLI=count(distinct lli.loc) from wh40.LOTxLOCxID lli
select @PLLI=count(distinct lli.loc) from wh40.LOTxLOCxID lli, wh40.loc l
where l.loc=lli.loc and l.LOCATIONTYPE='PICK'
select @CLLI=count(distinct lli.loc) from wh40.LOTxLOCxID lli, wh40.loc l
where l.loc=lli.loc and l.LOCATIONTYPE='CASE'
select @OLLI=count(distinct lli.loc) from wh40.LOTxLOCxID lli, wh40.loc l
where l.loc=lli.loc and l.LOCATIONTYPE='OTHER'

select @AL=count(distinct l.loc) from wh40.LOC l where LOCATIONTYPE IN ('OTHER','CASE','PICK')
select @PL=count(distinct l.loc) from  wh40.loc l
where l.LOCATIONTYPE='PICK'
select @CL=count(distinct l.loc) from  wh40.loc l
where l.LOCATIONTYPE='CASE'
select @OL=count(distinct l.loc) from  wh40.loc l
where l.LOCATIONTYPE='OTHER'

insert into invent (pall,ppick,pcase,ppallet,date,wall,wpick,wcase,wpallet,
                    swall,spick,scase,spallet) values
(round(@ALLI/@AL*100,2),round(@PLLI*100/@PL,2),round(@CLLI*100/@CL,2),round(@OLLI*100/@OL,2),getdate(),
@ALLI,@PLLI, @CLLI,@OLLI,@AL,@PL, @CL,@OL)

