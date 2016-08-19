
-- СПРАВОЧНИК КОНТРАГЕНТОВ --

ALTER PROCEDURE [dbo].[proc_DA_Storer]
	@source varchar(500) = null
as  

--declare @source varchar(500)
declare @allowUpdate int
declare @send_error bit
declare @msg_errdetails varchar(max)
declare @msg_errdetails1 varchar(max)
declare @storerkey varchar(15)
declare @enter varchar(10),
	@sign int = 0 

set @send_error = 0
set @msg_errdetails = ''
set @enter = char(10)+char(13)

BEGIN TRY
	print ' определяем возможность обновления владельцев'
	select @allowUpdate = allowUpdate from dbo.DA_MessageTypes where MessageKey = 'StorerCard'

	while (exists (select id from da_storer))
		begin
			set @sign = 1
			
			print ' выбираем запись из обменной таблицы da_storer'
			select top(1) * into #da_storer from da_storer order by id desc

			print ' обновление NULL значений'
			update #da_storer 
			set
				storerkey = left(isnull(rtrim(ltrim(storerkey)),''),15),
				[type] = case	when left(isnull(rtrim(ltrim(type)),''),30) = '0' then '2'
								when left(isnull(rtrim(ltrim(type)),''),30) = '2' then '5'
								else left(isnull(rtrim(ltrim(type)),''),30)
						end,
				company = left(isnull(rtrim(ltrim(company)),''),45),
				companyname = left(isnull(rtrim(ltrim(companyname)),''),100),
				vat = left(isnull(rtrim(ltrim(vat)),''),18),				
				address = left(isnull(rtrim(ltrim(address)),''),180),				
				susr2 = left(isnull(rtrim(ltrim(susr2)),''),30),
				susr3 = left(isnull(rtrim(ltrim(susr3)),''),30)


			print 'удаляем двойные кавычки'
			update #da_storer set 
				company = replace(replace(company,'"','`'),'''','`'),
				companyname = replace(replace(companyname,'"','`'),'''','`'),
				address = replace(replace(address,'"','`'),'''','`')

			set @msg_errdetails1 =''
			print ' проверка входных данных'
			select 
				@msg_errdetails1 = @msg_errdetails1 --storerkey EMPTY
					+case when s.storerkey = ''
						then 'STORER. STORERkey=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --storer alloupdate = 0
					+case when (exists(select top(1) s.storerkey from wh1.storer ws join #da_storer s on ws.storerkey = s.storerkey)
							and @allowupdate = 0) 
						then 
							'STORER. STORERkey='+s.storerkey+'. Обновление запрещено.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --type empty
					+case when s.type = '' 
						then 'STORER. Storerkey='+s.storerkey+'. type=empty.'+@enter
						else ''
					end,
				@msg_errdetails1 = @msg_errdetails1 --company empty
					+case when s.company = '' 
						then 'STORER. Storerkey='+s.storerkey+'. Company=empty.'+@enter
						else ''
					 end--,
				--@msg_errdetails1 = @msg_errdetails1 --SUSR2 empty
				--	+case when s.susr2 = '' 
				--		then 'STORER. Storerkey='+s.storerkey+'. SUSR2=empty.'+@enter
				--		else ''
				--	 end,
				--@msg_errdetails1 = @msg_errdetails1 --SUSR3 empty
				--	+case when s.susr3 = '' 
				--		then 'STORER. Storerkey='+s.storerkey+'. SUSR3=empty.'+@enter
				--		else ''
				--	 end
--				@msg_errdetails1 = @msg_errdetails1 --vat empty
--					+case when ltrim(rtrim(s.vat)) = ''
--						then 'STORER. Storerkey='+s.storerkey+'. vat=empty.'+@enter
--						else ''
--					end,
--				@msg_errdetails1 = @msg_errdetails1 --address empty
--					+case when ltrim(rtrim(s.address)) = '' 
--						then 'STORER. STORERkey='+s.storerkey+'. address=empty.'+@enter
--						else '' 
--					end
			from #da_storer s
			
			if (@msg_errdetails1 = '')			
			begin
				print ' проверка на уникальность документов в обменной таблице'
				if ((select count (o.storerkey) from dbo.DA_Storer o join #da_storer do on o.storerkey = do.storerkey) != 1)
					set @msg_errdetails1 = 'STORER. STORERkey='+(select storerkey from #da_storer)+'. Не уникальный документ в обменной таблице.'+@enter
			end

			if (@msg_errdetails1 = '') 
				begin
					print ' контроль входных данных пройден успешно'
					print ' выбираем storerKEY'
					select @storerkey = storerkey from #da_storer

					print ' проверяем наличие storerkey='+@storerkey+' в базе'
					if (exists (select * from wh1.storer where storerkey = @storerkey))
						begin
							print 'storer='+@storerkey+' уже существует'
							if @allowUpdate = 1
							begin
								print 'обновляем WH1.storer='+@storerkey
								update s 
								set s.[type] = ds.[type], 
								    s.company = ds.company, 
								    s.companyname = ds.companyname, 
								    s.vat = ds.vat, 
								    s.address1 = substring(ds.address,1,45), 
								    s.address2 = substring(ds.address,46,45), 
								    s.address3 = substring(ds.address,91,45), 
								    s.address4 = substring(ds.address,136,45),
								    s.susr2 = ds.susr2, 
								    s.susr3 = ds.susr3
								from wh1.storer s 
								    join #da_storer ds 
									on s.storerkey = ds.storerkey

								print 'обновляем WH2.storer='+@storerkey
								update s 
								set s.[type] = ds.[type], 
								    s.company = ds.company, 
								    s.companyname = ds.companyname, 
								    s.vat = ds.vat, 
								    s.address1 = substring(ds.address,1,45), 
								    s.address2 = substring(ds.address,46,45), 
								    s.address3 = substring(ds.address,91,45), 
								    s.address4 = substring(ds.address,136,45),
								    s.susr2 = ds.susr2, 
								    s.susr3 = ds.susr3
								from wh2.storer s 
								    join #da_storer ds 
									on s.storerkey = ds.storerkey
							end
							--else
							--	begin
							--		print 'обновление storer='+@storerkey+' ЗАПРЕЩЕНО'
							--		delete from da_storer where storerkey = @storerkey
							--		delete from #da_storer
							--		set @send_error = 1
							--		set @msg_errdetails = @msg_errdetails+'STORER. STORERkey='+@storerkey+' существует в справочнике. Обновление сушествующих записей запрещено.'+char(10)+char(13)
							--	end
						end
					else
						begin
							print 'вставляем нового storer='+@storerkey
							insert into wh1.storer 
							(whseid, storerkey, [type], company, CompanyName,vat,
							address1, address2, address3, address4, 
							susr2, susr3, editwho,addwho)
--							
							select 'WH1', storerkey, [type], company, companyname,vat,  
								substring(address,1,45),substring(address,46,45),substring(address,91,45),substring(address,136,45),
								susr2, susr3,'dkadapter','dkadapter'
							from #da_storer
							
							insert into wh2.storer 
							(whseid, storerkey, [type], company, CompanyName,vat,
							address1, address2, address3, address4, 
							susr2, susr3, editwho,addwho)							
							select 'WH2', storerkey, [type], company, companyname,vat,  
								substring(address,1,45),substring(address,46,45),substring(address,91,45),substring(address,136,45),
								susr2, susr3,'dkadapter','dkadapter'
							from #da_storer

						end
				end
			else
				begin
					print ' контроль входных данных не пройден'
					set @msg_errdetails = @msg_errdetails + @msg_errdetails1 
					set @send_error = 1
				end
			delete from ds
				from da_storer ds join #da_storer s on (ds.storerkey = s.storerkey) or (ds.id = s.id)
			--drop table #da_storer
		end
END TRY
BEGIN CATCH
	declare @error_message nvarchar(4000)
	declare @error_severity int
	declare @error_state int
	
	set @error_message  = ERROR_MESSAGE()
	set @error_severity = ERROR_SEVERITY()
	set @error_state    = ERROR_STATE()

	set @send_error = 0
	--raiserror (@error_message, @error_severity, @error_state)
END CATCH

if @sign = 1
begin

	if @send_error = 1
	begin
		print 'Ставим документ в обменной таблице DAX в ошибку'
		
		update	s
		set	status = '15',
			error = @msg_errdetails
		from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpVendCustToWMS s
			join #DA_Storer d
				on d.storerkey = s.VendCustId
		where	s.status = '5'	
		
		
	--*************************************************************************

		update	s
		set	status = '15',
			error = @msg_errdetails
		from	[SQL-WMS].[PRD2].[dbo].DA_Storer_archive s
			join #DA_Storer d
				on d.storerkey = s.storerkey				
		where	s.status = '5'	
		


		print 'отправляем сообщение об ошибке по почте'
		print @msg_errdetails
		--raiserror (@msg_errdetails, 16, 1)
		
		--insert into DA_InboundErrorsLog (source,msg_errdetails) values (@source,@msg_errdetails)		
		--exec app_DA_SendMail @source, @msg_errdetails
	end
	else
	begin

		print 'Ставим статус документа в обменной таблице DAX в ОБРАБОТАН'
		
		update	s
		set	status = '10'
		from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ExpVendCustToWMS s
			join #DA_Storer d
				on d.storerkey = s.VendCustId
		where	s.status = '5'
		
	--*************************************************************************

		update	s
		set	status = '10'
		from	[SQL-WMS].[PRD2].[dbo].DA_Storer_archive s
			join #DA_Storer d
				on d.storerkey = s.storerkey				
		where	s.status = '5'


	end
end

IF OBJECT_ID('tempdb..#DA_Storer') IS NOT NULL DROP TABLE #DA_Storer


