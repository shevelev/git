-- =============================================
-- �����:		��������� ��������
-- ������:		������, �.�������
-- ���� ��������: 07.12.2009 (������)
-- ��������: ��������� ��������� ������� adminsPRD1.dbo.FT_ostatki �� �������� ������.
--	...
-- =============================================
ALTER PROCEDURE [dbo].[proc_V01_FT_ostatki]
AS
	declare @dtlast datetime
	declare @dttek datetime

--	set @dtlast='20091009'
	set @dttek=convert(datetime,convert(varchar(10),getdate(),101))
	set @dtlast=(select max(adminsPRD1.dbo.FT_ostatki.Date_CN) from adminsPRD1.dbo.FT_ostatki)+1

--	print @dttek
--	print @dtlast		

	while @dtlast<=@dttek
		begin
			insert into adminsPRD1.dbo.FT_ostatki
				select @dtlast-1 Date_CN, i.storerkey STORERKEY, i.sku SKU, sum(qty) QTY
				from wh1.itrn i
				where (i.adddate < @dtlast) 
						and (i.trantype='DP' 
							or i.trantype='WD' 
							or (i.trantype='AJ' and i.status='OK'))
				group by i.storerkey, i.sku
			set @dtlast=@dtlast+1
		end

--delete 
--from dbo.FT_ostatki

