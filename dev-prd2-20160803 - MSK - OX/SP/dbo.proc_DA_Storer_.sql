-- СПРАВОЧНИК КОНТРАГЕНТОВ --

ALTER PROCEDURE [dbo].[proc_DA_Storer]
	@source varchar(500) = null
as  
-- Любая ошибка должна прерывать процедуру и передать исключение адаптеру
SET XACT_ABORT ON

declare @allowUpdate int
declare @id int
declare @storerkey varchar(15)
declare @type int

update DA_Storer set 
	susr1  = substring(isnull(susr1,''),1,30),
	susr2  = substring(isnull(susr2,''),1,30),
	susr3  = substring(isnull(susr3,''),1,30),
	susr4  = substring(isnull(susr4,''),1,30),
	susr5  = substring(isnull(susr5,''),1,30),
	susr6  = substring(isnull(susr6,''),1,30)

update DA_Storer set [type] = '2' where [type]='' or [type] is null

print '1. определяем возможность обновления владельцев'
	select @allowUpdate = allowUpdate from dbo.DA_MessageTypes where MessageKey = 'StorerCard'



while 1 = 1
begin
	--выбрать наиболее раннюю запись (минимальный id)
	select @id = min(id) from DA_Storer	
	if @id is null break
	select @storerkey = storerkey, @type = [type] from DA_Storer where id = @id

	if @type = 1 
	begin
		raiserror ('Обновление контрагента (STORERKEY=%s) запрещено (type=1)',16,1,@storerkey)
		return
	end

	if @type = 7 
	begin
		raiserror ('Обновление контрагента (STORERKEY=%s) запрещено (type=7)',16,1,@storerkey)
		return
	end
	
	if exists (select storerkey from wh1.storer where storerkey = @storerkey)
	begin
		print '3. обновляем существующего контрагента'

		if @allowupdate = 0
		begin
			raiserror ('Обновление контрагента (STORERKEY=%s) запрещено (allowUpdate=0)',16,2,@storerkey)
			return
		end
					
		update s set 
			s.[type] = t.[type], 
			s.company = t.company, 
			s.companyname = t.companyname,
			s.vat = t.vat,
			s.address1 = substring(t.address,1,45),
			s.address2 = substring(t.address,46,45),
			s.address3 = substring(t.address,91,45),
			s.address4 = substring(t.address,136,45),
			s.city = t.city,
			s.zip = t.zip,
			s.phone1 = substring(t.phone,1,18),
			s.phone2 = substring(t.phone,19,18),			
			s.susr1 = t.susr1,
			s.susr2 = t.susr2,
			s.susr3 = t.susr3,
			s.susr4 = t.susr4,
			s.susr5 = t.susr5,
			s.susr6 = t.susr6,
			s.notes1 = t.notes1,
			s.notes2 = t.notes2
			from wh1.storer s join DA_Storer t on s.storerkey = t.storerkey
			where t.id = @id
	end
	else
	begin
		print '3. добавляем нового контрагента'
		insert into wh1.storer 
			(storerkey, [type], company, companyname, vat, address1, address2, address3, address4, city, zip, phone1, phone2, susr1, susr2, susr3, susr4, susr5, susr6, notes1, notes2)
			select storerkey, [type], company, companyname, vat, substring(address,1,45), substring(address,46,45), substring(address,91,45), substring(address,136,45), city, zip, substring(phone,1,18), substring(phone,19,18), susr1, susr2, susr3, susr4, susr5, susr6, notes1, notes2
			from DA_Storer where id = @id
	end
    
	delete DA_Storer where id = @id
end

