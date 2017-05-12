--set ANSI_NULLS ON
--set QUOTED_IDENTIFIER ON
--go
--
--
--################################################################################################
--         ��������� ���������� ������� ����� ��� ������
--################################################################################################
ALTER PROCEDURE [dbo].[app_DA_CheckOrderWave] 
	@orderkey varchar (15), 
	@wavekey varchar (10) output, -- ����� �����
	@wavedescr varchar (15) output, -- ������������ �����
	@status varchar(5) output -- ������ ����� (� ������ �������� ������� � �����) 
							-- 0 - ����� �� � �����, 
							-- 1 - ����� � ������������ �����
							-- 2 - ����� � ���������� ����� (��� ���� ���������� ������ � �����)
							-- 3 - ����� � ���������� ������

AS
print '>>> app_DA_CheckOrderWave >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
print '@Orderkey: ' + case when @orderkey is null then 'null' else @orderkey end + '.'
declare
	@count int

select @count = count (w.serialkey) from wh1.wave w join wh1.wavedetail wd on w.wavekey = wd.wavekey where wd.orderkey = @orderkey

	if @count > 1
		begin
			print 'DACOW.1. ����� ����� ��� � ����� �����'
			set @status = '3' set @wavekey = '' set @wavedescr = ''
		end
	else
		begin
			if @count = 0
				begin
					print 'DACOW.1. ����� �� � �����'
					set @status = '0' set @wavekey = '' set @wavedescr = ''
				end
			else
				begin
					print 'DACOW.1. ����� � ����� �����'
					select @wavekey = wd.wavekey from wh1.wavedetail wd where wd.orderkey = @orderkey
					if (select count (w.serialkey)
						from wh1.wave w join wh1.wavedetail wd on w.wavekey = wd.wavekey
							join wh1.orders o on wd.orderkey = o.orderkey
						where w.wavekey = @wavekey
						group by w.wavekey, w.descr
						having max (o.status) <= '11') is null -- �������� ������� ���������� �������	
						begin
							print 'DACOW.2. � ����� ���� ���������� ������'
							set @status = '2' set @wavekey = '' set @wavedescr = ''
						end
					else
						begin
							print 'DACOW.2. ����� ����������'
							select @wavedescr = descr, @status = '1' from wh1.wave where wavekey = @wavekey
						end
				end
		end

--select @status
print '<<< app_DA_CheckOrderWave <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'

