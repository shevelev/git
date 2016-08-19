-- =============================================
-- �����:		������� �����
-- ������:		������, �.�������
-- ���� ��������: 15.10.2009 (������)
-- ��������: �������� ����������� ���������� ����� ������
--			������� ���������� ���������� ����� ������, ������� ����� ��������� ��� ������
-- =============================================
ALTER FUNCTION [WH1].[novex_checkNeedSetPickLoc] 
	(@Storer as varchar(15),
	 @SkuName as varchar(50))
RETURNS int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	-- SET NOCOUNT ON;
--##############################################################################

--declare @Storer as varchar(15), @SkuName as varchar(50)
--set @Storer='92'
--set @SkuName='00020'
declare @ZONE as varchar(10)
declare @countLOC as int
declare @needLOC as int

--set @needLOC=0

--print '>>> �������� ����������� ���������� ������ ������ ��� ������ STORERKEY='+isnull(@Storer,'<NULL>')+' SKU='+isnull(@SkuName,'<NULL>')
--print '1.0. �������� ����������� � ���������� ������ ������'
--print '...1.1. ���� ���� ��� ���������� ����� ������...'
--���������� ����, ��������� � �������� ������. ��������� 2 ������� ���� ���������� �� "EA"
--�������������� ��� ���� ����������� �������� ����� �������� "CS", � �������� "EA"
select @ZONE=left(s.putawayzone,len(s.putawayzone)-2)+'EA'
from sku s
where s.storerkey=@Storer and s.sku=@SkuName
--������ ����������
and
(s.putawayzone in		-- ������������ ������ ���� � ������� ���� ���������� �� ������� � ���������� �����
	(
	select pz.putawayzone
	from putawayzone pz
	join putawayzone pzEA on (left(pz.putawayzone,len(pz.putawayzone)-2)+'EA'=pzEA.putawayzone)
	join putawayzone pzCS on (left(pz.putawayzone,len(pz.putawayzone)-2)+'CS'=pzCS.putawayzone)
	)
 and
 (s.putawayzone not like 'BRAK%')	-- ��������� ������ �����
 and
 (s.storerkey<>'000000001')			-- ��������� ��������� ��������� �-�����
 and									-- ������������ ������ ���� ����������� �������� ��� ��������� �����
 (select top 1 loc from loc l where l.putawayzone=left(s.putawayzone,len(s.putawayzone)-2)+'EA') like '[1-9]___.[1-9].[1-9]'
  and									-- ��������� ���� � �������� ���������������� ������
 (select top 1 isnull(cubiccapacity,0) from loc l where l.putawayzone=left(s.putawayzone,len(s.putawayzone)-2)+'EA')>0
)
--print '......������� ����: '+isnull(@ZONE,'<NULL>')

if (@ZONE is not null) 
begin
-- print '...1.2. ��������� ������� ����������� ����� ������...'
 select @countLOC=isnull(count(sxl.sku),0)
		from
		skuxloc sxl join loc l on (sxl.loc=l.loc)
		where
--�������� ������������ ����������� ������ ������ ��������� ���� ���������� ���������
--		(l.putawayzone=@ZONE)
--		and
		(sxl.storerkey=@Storer and sxl.sku=@SkuName)
		and
		( (	sxl.locationtype='PICK'
			and
			sxl.qtylocationminimum>0
			and
			sxl.qtylocationlimit>0
			and
			sxl.allowreplenishfromcasepick=1)
		)
 --print '...1.3. ������� '+cast(@countLOC as varchar)+' �����'
 --������������� ���������� ����� ������ ��������� ��� ������
 --06.11.2009 ���������� �� 1 ����� - 1 ������ ������
 select @needLOC=
	(case
--	 when s.shelflifeindicator='Y' and @countLOC>1	then 0
--	 when s.shelflifeindicator='Y' and @countLOC<2	then 2-@countLOC
--	 when s.shelflifeindicator='N' and @countLOC>0	then 0
--	 when s.shelflifeindicator='N' and @countLOC=0	then 1
	 when @countLOC>0								then 0
													else 1
	 end)
from sku s
where s.storerkey=@Storer and s.sku=@SkuName
-- if @needLOC>0
--	print '...��� ������� ������ ��������� ��������� '+cast(@countLOC as varchar)+' ����� ������'
-- else
--	print '...��� ������� ������ �� ��������� ���������� ����� ������. ������ ��� ���������.'

end
else
begin
 set @needLOC=-1
-- print '...��� ������� ������ �� ��������� ���������� ����� ������. ���� ���������� �� ������� ���������� �����.'
end

RETURN @needLOC
END

