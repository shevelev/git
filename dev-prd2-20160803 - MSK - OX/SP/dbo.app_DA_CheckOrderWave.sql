--set ANSI_NULLS ON
--set QUOTED_IDENTIFIER ON
--go
--
--
--################################################################################################
--         процедура определяет наличие волны для заказа
--################################################################################################
ALTER PROCEDURE [dbo].[app_DA_CheckOrderWave] 
	@orderkey varchar (15), 
	@wavekey varchar (10) output, -- номер волны
	@wavedescr varchar (15) output, -- наименование волны
	@status varchar(5) output -- статус волны (с учетом статусов заказов в волне) 
							-- 0 - заказ не в волне, 
							-- 1 - заказ в незапущенной волне
							-- 2 - заказ в запущенной волне (или есть запущенные заказы в волне)
							-- 3 - заказ в нескольких волнах

AS
print '>>> app_DA_CheckOrderWave >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
print '@Orderkey: ' + case when @orderkey is null then 'null' else @orderkey end + '.'
declare
	@count int

select @count = count (w.serialkey) from wh1.wave w join wh1.wavedetail wd on w.wavekey = wd.wavekey where wd.orderkey = @orderkey

	if @count > 1
		begin
			print 'DACOW.1. заказ более чем в одной волне'
			set @status = '3' set @wavekey = '' set @wavedescr = ''
		end
	else
		begin
			if @count = 0
				begin
					print 'DACOW.1. заказ не в волне'
					set @status = '0' set @wavekey = '' set @wavedescr = ''
				end
			else
				begin
					print 'DACOW.1. заказ в одной волне'
					select @wavekey = wd.wavekey from wh1.wavedetail wd where wd.orderkey = @orderkey
					if (select count (w.serialkey)
						from wh1.wave w join wh1.wavedetail wd on w.wavekey = wd.wavekey
							join wh1.orders o on wd.orderkey = o.orderkey
						where w.wavekey = @wavekey
						group by w.wavekey, w.descr
						having max (o.status) <= '11') is null -- проверка наличия запущенных заказов	
						begin
							print 'DACOW.2. в волне есть запущенные заказы'
							set @status = '2' set @wavekey = '' set @wavedescr = ''
						end
					else
						begin
							print 'DACOW.2. волна незапущена'
							select @wavedescr = descr, @status = '1' from wh1.wave where wavekey = @wavekey
						end
				end
		end

--select @status
print '<<< app_DA_CheckOrderWave <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'

