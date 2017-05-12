--################################################################################################
-- ��������� �������� � ��������� ����� ��� ��, � ������� ������� ��� �����
-- �������������� �� � ����� ��������������� ��������� ���� o.ORDERGROUP
---- � ���� o.INTERMODALVENCLE(����������) ������������ ��� ��������/�����������
---- � ���� o.LOADID( ������������ ��� ��������� ��������
---- � ���� o.... (�������) ������������ ��� �������� (������� "TS"+��� ��������� ��������)
---- � ���� o.... (...) ������������ ��������� �������� ����������� ��������
--################################################################################################
ALTER PROCEDURE [dbo].[app_Wave]
	@Wavekey	varchar(10)='', -- ����� �����
	@Driver		varchar(10)='',	-- ��� ��������
	@Car		varchar(10)='',	-- ����� ������
	@Route		varchar(20)=''	-- ������� (�����������)

AS

declare 
	@Orderkey varchar(18),
	@status int

print '>>> app_Wave >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
print '@Wavekey: '+ISNULL(@Wavekey,'null')
print '1. ��������� ������ ��� ����� �����'
print '...��������� ������ �����'
select	
--		@Storer=max(o.storerkey),
--		@Carrierkey=left(po.sellersreference,15),
--		@Carriername=st.company
		@status=max(cast ([status] as int))
from wh1.orders o
--		left join wh1.storer st on (o.storer=st.storerkey)
where o.ordergroup=isnull(@Wavekey,'') and isnull(@Wavekey,'')<>''
print '......status:'+cast(ISNULL(@status,'-1') as varchar) + ' (��� =<9 �� ��������������)'

--print '...������� ����� ���������� ������ ������ ��� �����'
--select @sumQTY=sum(pd.qtyordered)
--from wh1.po po
--	join wh1.podetail pd on (po.pokey=pd.pokey)
--where
--	po.otherreference=@Receiptkey
--	and po.storerkey=@Storer
--	and po.sellersreference=@Carrierkey
--group by pd.whseid, pd.storerkey, pd.sku


print '...��������� ������� �� ��� ��������� ����� � ������ �����'
if	(isnull(@Wavekey,'')<>'')
	and
	(ISNULL(@status,100)<10)
begin

print '2. ��������� ������������� �����: '+@Wavekey
if (select Wavekey from wh1.Wave where Wavekey=@Wavekey) is null
begin
	print '...2.1. ���������� ����� �����: '+@Wavekey
	print '......��������� ����� ����� �����: Wavekey='+@Wavekey
	insert into wh1.Wave
				(whseid,
				 wavekey,
				 externalwavekey,
				 descr)
		select	'WH1',
				@Wavekey,
				@Driver,
				@Route
end
else
begin
	print '...2.2. ������� ������� ������������ �����: Wavekey='+@Wavekey
	print '......��������� ������ �� ��� ����� � ���� �� ����, �� ������� ������ �����'
	if (@status is not null)
	begin
		print '......������� ������ �����'
		delete	from wh1.wavedetail
				from wh1.wavedetail wd
					join wh1.orders o on (wd.orderkey=o.orderkey)
		where wd.wavekey=@Wavekey and cast(o.status as int)<10
	end
	else
	begin
		print '......������� ������ �����'
		delete	from wh1.wavedetail
				from wh1.wavedetail wd
					join wh1.orders o on (wd.orderkey=o.orderkey)
		where wavekey=@Wavekey and cast(o.status as int)<10
		print '......������� ������ �����'
		delete	from wh1.wave
				from wh1.wave w
					left join wh1.wavedetail wd on (w.wavekey=wd.wavekey)
		where w.wavekey=@Wavekey and (wd.wavekey is null)
	end
end
--
print '3. �������� � ����� ������ ��, ������������� � ���'
print '...������� ������ ��������� ������� ��� ������� �����'
CREATE TABLE #wavedetail (
	[id] [int] IDENTITY(1,1) NOT NULL,
	[whseid] [varchar](3) NULL,
	[wavedetailkey] [varchar](10) NULL,
	[wavekey] [varchar](10) NULL,
	[orderkey] [varchar](10) NULL
)
print '...��������� ��������� ������� � �������� �����'
insert into #wavedetail
select	o.whseid whseid,
		'' wavedetailkey,
		@Wavekey receiptkey,
		o.orderkey orderkey
from wh1.orders o
where
	o.ordergroup=@Wavekey
print '...����������� ������ ����� �����'
update #wavedetail
set wavedetailkey=replicate('0',10-len(cast(id as varchar(5))))+cast(id as varchar(5))
----
--select *
--from #wavedetail
print '...��������� �� �� ���� ����'
delete from wh1.wavedetail
where orderkey in (select orderkey from #wavedetail)
--
print '...��������� ������� wavedetail'
insert into wh1.wavedetail
	(whseid,
	 wavedetailkey,
	 wavekey,
	 orderkey)
	select	whseid,
			wavedetailkey,
			wavekey,
			orderkey
	from #wavedetail
print '...������� ��������� �������'
drop table #wavedetail

end

print '<<< app_Wave <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'

