
ALTER PROCEDURE [dbo].[SP_CHECKSHIPMENT_CST0027]
@wh      varchar(10),
@action  varchar(10),
@dropid  varchar(18)
AS
BEGIN

SET NOCOUNT ON

-- ��������� ����������:
--	0 - ��������� ��������/�������� �����/��
--	1 - ��������� ��������/�������� �����/��

declare @nestlevel   int
declare @result      int

set @result = 0

-- ��� ����� � ��������� �����
create table #cases_drop (
	caseid varchar (20),
	nestlevel int
)

-- ��� ����� �� ���� ��������� �������
create table #cases_order (
	orderkey varchar(20),
	caseid varchar (20),
	pickdetailkey varchar(20),
	locpd varchar (20) null,
	loci varchar (20) null,
	loc varchar (20) null,
	statuspd varchar (20) null,
	zone varchar(50) null,
	control varchar(50) null,
	status varchar(50) null
)

-- ����� ��� �����, �������� � ��������� ���� (� �.�. �� ��� ��������� �����)
print '������� ���� ������ � �����'

------set @nestlevel = 1

------insert into  #cases_drop 
------	select CHILDID AS CASEID,  @nestlevel  AS NESTLEVEL from WH1.DROPIDDETAIL where DROPID = @dropid 

------WHILE @@ROWCOUNT > 0 
------BEGIN
------	select @nestlevel = @nestlevel + 1

------	insert into #cases_drop
------	select CHILDID AS CASEID, @nestlevel AS NESTLEVEL from WH1.DROPIDDETAIL 
------	where DROPID in (select CASEID from #cases_drop where NESTLEVEL = @nestlevel - 1)
------END

--------select * from wh1.DROPID where DROPID = 'TS00004506'
--------select * from wh1.dropiddetail

-------- �������� �������� ����
------insert into #cases_drop (CASEID, NESTLEVEL) values (@dropid, 0)

;WITH DropIE(dropID, childID, nestLevel) AS 
(
    SELECT d.dropid, childid, 0 AS nestLevel
    FROM wh1.dropid d 
		join wh1.dropiddetail dd on d.dropid = dd.dropid
	where d.dropid = @dropid --d.dropidtype='4' --
    UNION ALL
    SELECT die.dropid, dd.childid, die.nestLevel+1
    FROM wh1.dropid d 
		join wh1.dropiddetail dd on d.dropid = dd.dropid
        INNER JOIN DropIE die
        ON dd.dropid = die.childID
)
insert into #cases_drop SELECT childID, nestLevel-- into #t
FROM DropIE 

-- �������� ������ ����� (���, ������� � �����) - ������ � ������������ ������� �����������
select @nestlevel = max(NESTLEVEL) from #cases_drop
delete #cases_drop where nestlevel < @nestlevel

-- ����� ��� ������, � ������� ������ ���� �� ���� ���� �� ��������� �����, � ������� ��� ����� �� ���� ���� �������
print '������� ������� �� �������'

select distinct orderkey into #orders from wh1.pickdetail p join #cases_drop t on p.caseid  = t.caseid

insert into #cases_order
	select orderkey, caseid, PICKDETAILKEY, LOC,  null, null,status, null, null, null
	from wh1.PICKDETAIL where ORDERKEY in (select orderkey from #orders)

-- ���� ���� ������ � ITRN �� ��������� ������ ��
update C set loci = i.fromloc
	from #cases_order c left join wh1.ITRN i on i.SOURCEKEY = c.pickdetailkey
	where TRANTYPE = 'MV'

-- ��������� ������ ������
update C set c.loc = case when c.loci IS null then c.locpd else c.loci end
	from #cases_order c

-- ���������� ���� ��� �����
update C set c.zone = pz.PUTAWAYZONE, c.control = pz.CARTONIZEAREA
	from #cases_order c 
		join wh1.LOC l on c.loc = l.LOC
		join wh1.PUTAWAYZONE pz on pz.PUTAWAYZONE = l.PUTAWAYZONE

-- ������ ���������������������� �����.
update C set c.status = 
	case when (p.STATUS=1 and p.RUN_ALLOCATION=0 and p.RUN_CC=0) then '1' else '0' end 
	from #cases_order c left join wh1.pickcontrol p on c.caseid = p.caseid

print '�������� �������'
if (select COUNT(*) from #cases_order where control = 'K' and status != '1') != 0
begin
	print '���� ��� ��������� ������� �� ���������'
	set @result = 0
end
else
begin
	print '��� ������ ��������� ��� �������� �� ���������'

	if @action = 'LOAD' 
	begin
		if (select COUNT(*) from #cases_order where statuspd < '6') != 0
		begin
			print '���� ��� ��������� ������� �� ���������'
			set @result = 0
		end
		else
		begin
			print '��� ������ ���������'
			set @result = 1
		end
	end
	
	if @action = 'SHIP'		
	begin
		-- ��� ����� ��������� ������� ������ ���� ������ ��������� � ���� ��
		if (select COUNT(*) from #cases_order co left join #cases_drop cd on co.caseid = cd.caseid where (co.statuspd < '8') or (cd.caseid is null)) > 0
		begin
			print '���� ��� ��������� ������� �� ���������  ��������� � ��'
			set @result = 0
		end
		else
		begin
			print '��� ������ ��������� ��������� � ��'
			set @result = 1
		end		
	end		
end

drop table #cases_drop
drop table #cases_order

return @result

END

