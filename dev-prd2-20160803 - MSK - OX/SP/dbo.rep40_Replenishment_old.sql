ALTER PROCEDURE [dbo].[rep40_Replenishment_old] (
@wh varchar(10),
@externorderkey varchar (32),
@orderkey varchar(10),
@typereplenishment varchar (1))
as

declare @sql varchar(max)
declare @orderjoin varchar(max)
declare @orderwhere varchar(max)

--set @typereplenishment = '1' -- ���������� ����� �������� ������ �� ����� ����������� ������
--set @typereplenishment = '2' -- ���������� ����� ����������� ������ �� ����� ���������� ��������
--set @typereplenishment = '3' -- ���������� ����� �������� ������ �� ����� ����������� ������ � ���������� ��������

create table #result (
		descr varchar(60) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		sku varchar(50) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),
		storerkey varchar(15) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),	
--		descr varchar(60) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),	
		loc_in varchar(15) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),		-- ����������� ������
		loc_out varchar(15) COLLATE Cyrillic_General_CI_AS NOT NULL DEFAULT (''),		-- ����������� ������
		id_out varchar(15) COLLATE Cyrillic_General_CI_AS DEFAULT (''),					-- ����������� �������
		qtypick decimal(22, 5) NOT NULL DEFAULT (0),									-- ���������� ����
		qtycase decimal(22, 5) NOT NULL DEFAULT (0))									-- ���������� �������

-- ������������ ������ ������� �� ������
if (@orderkey  is not null) or (@externorderkey is not null)
	begin
		set @orderjoin =
			' join '+@wh+'.orderdetail od on od.sku = sl.sku and od.storerkey = sl.storerkey'
		set @orderwhere = 
			' and od.openqty > 0 and od.status <= 14' +
			case when @orderkey is null then '' else ' and od.orderkey = '''+@orderkey+'''' end +
			case when @externorderkey is null then '' else ' and od.externorderkey = '''+@externorderkey+''' ' end
	end
else
	begin
		set @orderjoin = ''
		set @orderwhere = ''
	end

-- ������ �������� ������ ��������� ���������� 
select sl.serialkey, s.descr, sl.sku, sl.storerkey, sl.loc, sl.qty, sl.qtylocationlimit, l.comminglesku, p.casecnt
into #pickneed
from wh1.skuxloc sl join WH1.loc l on sl.loc = l.loc
join wh1.sku s on s.sku = sl.sku and s.storerkey = sl.storerkey
left join wh1.pack p on p.packkey = s.packkey 
where 1=2

set @sql = 
'insert into #pickneed
select sl.serialkey, s.descr, sl.sku, sl.storerkey, sl.loc, sl.qty, sl.qtylocationlimit, l.comminglesku, p.casecnt
from '+@wh+'.skuxloc sl join '+@wh+'.loc l on sl.loc = l.loc
join '+@wh+'.sku s on s.sku = sl.sku and s.storerkey = sl.storerkey ' +
@orderjoin+
' left join '+@wh+'.pack p on p.packkey = s.packkey 
where sl.replenishmentpriority <= 4
and ' +
case @typereplenishment when '1' then '(l.locationtype = ''PICK'') ' 
						when '2' then '(l.locationtype = ''CASE'') '
						when '3' then '(l.locationtype = ''PICK'') '
end +
'and p.packkey != ''STD'' --and p.packkey != ''CABEL''
and (sl.loc != ''BRAK'' and sl.loc != ''BRAKPRIEM'' and sl.loc != ''NEIZVESTNO'' and 
		sl.loc != ''QC'' and sl.loc != ''LOST'' and sl.loc != ''NETSTRATEG'' and sl.loc != ''STAGE'' and sl.loc != ''BRAKPROG'')
and sl.qtylocationlimit > 0 -- ����������� ������ � ������� ������������ ���������� ����
and sl.qty < sl.qtylocationlimit -- ����������� ������ � �������� ������� ���������� ������ ������������� (�������� ������)
and not (l.comminglesku = ''0'' and sl.qty != 0) -- ����������� �� ������ ����� � ������ ������ ��������� ������
'+@orderwhere +
' order by sl.qtylocationlimit'
print @sql
exec (@sql)


--select '������ ��� ����������'
--select * from #pickneed order by sku

-- ������ ���������� �������� �� ������� ���������
select lli.serialkey ,lli.sku, lli.storerkey, sl.loc, lli.id,
 (lli.qty - lli.qtyallocated) qtyaccess, p.casecnt,
 p.packkey, l.comminglesku
into #palletaccess
from WH1.skuxloc sl join WH1.lotxlocxid lli on sl.loc = lli.loc and sl.sku = lli.sku and sl.storerkey = lli.storerkey
join WH1.sku s on s.sku = sl.sku and s.storerkey = sl.storerkey
join WH1.loc l on l.loc = sl.loc 
left join WH1.pack p on p.packkey = s.packkey
where 1=2

set @sql =
'insert into #palletaccess 
select lli.serialkey, lli.sku, lli.storerkey, sl.loc, lli.id,
 (lli.qty - lli.qtyallocated) qtyaccess, p.casecnt,
 p.packkey, l.comminglesku
from '+@wh+'.skuxloc sl join '+@wh+'.lotxlocxid lli on sl.loc = lli.loc and sl.sku = lli.sku and sl.storerkey = lli.storerkey
join '+@wh+'.sku s on s.sku = sl.sku and s.storerkey = sl.storerkey
join '+@wh+'.loc l on l.loc = sl.loc 
left join '+@wh+'.pack p on p.packkey = s.packkey
where 1=1 
--and sl.replenishmentpriority >= 8 -- ��������� ���������� ���� ���� ����� 8
and ' +
case @typereplenishment when '1' then '(l.locationtype = ''CASE'') '  -- �������� ������ ����������� ��������
						when '2' then '(l.locationtype = ''OTHER'' and ltrim(rtrim(lli.id)) != '''' ) ' -- �������� ������ ���������� ��������
						when '3' then '(l.locationtype = ''CASE'' or (l.locationtype = ''OTHER'' and ltrim(rtrim(lli.id)) != '''' )) ' -- �������� ������ ����������� � ���������� ��������
end + 
'and (l.loc != ''BRAK'' and l.loc != ''BRAKPRIEM'' and l.loc != ''NEIZVESTNO'' and 
		l.loc != ''QC'' and l.loc != ''LOST'' and l.loc != ''NETSTRATEG'' and l.loc != ''BRAKPROG'') -- ����������� ������ ������������ ������
and p.packkey != ''STD'' --and p.packkey != ''CABEL''
and lli.qty > 0 -- ����������� ������ � ������� �����������
and lli.qty - lli.qtyallocated > 0 -- ����������� ������ � ������� ��� ���������� ���������������
order by qtyaccess'

exec (@sql)

--select '����������� ������'
--select * from #palletaccess order by sku

declare @ski int, -- ���� �������
		@loc_in varchar(15), -- ����������� ������
		@sku varchar(50), -- �����
		@storerkey varchar(15), -- ��������
		@qty decimal(22, 5), -- ����������� ����������
		@qtylocationlimit decimal(22, 5), -- �������������������� ����������
		@comminglesku varchar(1), -- ���������/����������� ������ 1/0
		@descr varchar (60), -- ��������
		@casecnt decimal(22, 5), -- ���������� �� ��������

		@sko int, -- ���� �������
		@loc_out varchar(15), -- ����������� ������
		@id_out varchar(15), -- ����������� ������
		@qtyacc decimal(22, 5) -- ���������� �� ����������� �������


while ( (select count(serialkey) from #pickneed) > 0  )
	begin
		select top (1) @ski = serialkey, @descr = descr, @loc_in = loc, @sku = sku, @storerkey = storerkey, @qty = (qtylocationlimit - qty), @comminglesku = comminglesku, @casecnt = casecnt, @qtylocationlimit = qtylocationlimit from #pickneed
		delete from #pickneed where serialkey = @ski
		if @comminglesku = '1' -- ��������� ������
			begin
				while ((select count(serialkey) from #palletaccess where sku = @sku and storerkey = @storerkey) > 0 and @qty > 0) -- ���������� ����������� ������ ������� ���� �� ���������� ��� ���������� 
					begin
						select top(1) @sko = serialkey, @loc_out = loc, @id_out = id, @qtyacc = qtyaccess  
							from #palletaccess 
							where sku = @sku and storerkey = @storerkey 
							order by qtyaccess
						if @qty = @qtyacc -- ���������� ��� ���������� ����� ���������� �� ����������� �������
							begin
								set @qty = 0
								delete from #palletaccess where serialkey = @sko
								insert into #result (descr, sku, storerkey, loc_in, loc_out, id_out, qtypick, qtycase) 
											values (@descr, @sku, @storerkey, @loc_in, @loc_out, @id_out, @qtyacc, floor(@qtyacc/@casecnt))
							end
						else
							begin
								if @qty > @qtyacc
									begin
										set @qty = @qty - @qtyacc
										delete from #palletaccess where serialkey = @sko
										insert into #result (descr, sku, storerkey, loc_in, loc_out, id_out, qtypick, qtycase) 
													values (@descr, @sku, @storerkey, @loc_in, @loc_out, @id_out, @qtyacc, floor(@qtyacc/@casecnt))
									end
								else
									begin
										set @qtyacc = @qtyacc - @qty
										update #palletaccess set qtyaccess = @qtyacc where serialkey = @sko
										insert into #result (descr, sku, storerkey, loc_in, loc_out, id_out, qtypick, qtycase) 
													values (@descr, @sku, @storerkey, @loc_in, @loc_out, @id_out, @qty, floor(@qty/@casecnt))
										set @qty = 0
									end
							end
					end
			end
		if @comminglesku = '0' -- �� ��������� ������
			begin
				if (select count(serialkey) from #palletaccess where sku = @sku and storerkey = @storerkey) > 0
					begin
						select top(1) @sko = serialkey, @loc_out = loc, @id_out = id, @qtyacc = qtyaccess  from #palletaccess where sku = @sku and storerkey = @storerkey order by qtyaccess -- ��������� �������/������ � ���������� �����������
						if @qtylocationlimit < @qtyacc
							begin
								update #palletaccess set qtyaccess = (@qtyacc - @qty) where serialkey = @sko
								insert into #result (descr, sku, storerkey, loc_in, loc_out, id_out, qtypick, qtycase) 
											values (@descr, @sku, @storerkey, @loc_in, @loc_out, @id_out, @qty, floor(@qty/@casecnt))
							end
						else
							begin
								delete from #palletaccess where serialkey = @sko
								insert into #result (descr, sku, storerkey, loc_in, loc_out, id_out, qtypick, qtycase) 
											values (@descr, @sku, @storerkey, @loc_in, @loc_out, @id_out, @qtyacc, floor(@qtyacc/@casecnt))
							end
					end
				set @qty = 0
			end
	end

--select * from #result order by id_out
--select * from #palletaccess

select * from #result

drop table #palletaccess
drop table #pickneed
drop table #result

