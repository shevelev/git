-- =============================================
-- �����:		��������� ��������
-- ������:		������, �.�������
-- ���� ��������: 07.12.2009 (������)
-- ��������: ����� �� ��������� �������
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV02_Loc] ( 
									
	@wh varchar(30),
	@Vzone varchar(10)
)

as
create table #result_table (
		Putzone varchar(10) not null,
		PutDescr varchar(60) not null,
		Loc varchar(10) not null,
		Qty decimal(22,5) not null
)

declare @sql varchar(max)

/*����������� ������� ������ � �������� ������� � �������� �������� ���
� ��������� ���-�� ������ � ������

����� �� ������ � ��������*/		
set @sql='

insert into #result_table
select  locB.putawayzone Putzone,
		put.Descr PutDescr,
		locB.loc Loc,
		sum(isnull(lotx.qty,0)) Qty
from '+@wh+'.LOC locB
	/*����� ���� ��������� ����� � ������������� ���-�� ������ � ���, �� �������*/
	left join '+@wh+'.LOTXLOCXID lotx on locB.loc=lotx.loc
	/*����� ����� �� ������*/
	left join '+@wh+'.PUTAWAYZONE Put on locB.PUTAWAYZONE=Put.PUTAWAYZONE
	/*����� ����� �������� � ������*/
where '+
			case when @Vzone='ALL'  then 'LocB.locationtype in (''CASE'',''PICK'')'
				 when @Vzone='PICK'  then 'LocB.locationtype in (''PICK'')' 
				 when @Vzone='CASE'  then 'LocB.locationtype in (''CASE'')'					
			end +
			'
		and (LocB.loc not like ''%.0.0'' or LocB.loc like ''_S__.0.0'')
		and LocB.locationflag=''NONE''

group by locB.loc,
		 locB.putawayzone,
		 put.Descr
order by locB.loc
'

print (@sql)
exec (@sql)

/*����� ������� � ������� ���-��� ������*/
select Putzone,
	   PutDescr,
	   Loc
from #result_table rt
where rt.Qty=0


drop table #result_table

