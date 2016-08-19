--#################################################################################### ПОДТВЕРЖДЕНИЕ КОРРЕКТИРОВКИ

ALTER PROCEDURE [dbo].[proc_InventoryOk] (
		@wh varchar (10),
		@skugroup varchar (10),
		@hostzone varchar (20),
		@storerkey varchar (15),
		@invkey varchar (10) = null -- номер инвентаризации
)

AS

declare 
--@wh varchar (15),
@sql varchar (max),
@ParmDefinition nvarchar(500),
@create datetime -- датавремя формирования утвержденной инвентаризации

select @wh = whseid from dbo.warehousestorer where storerkey = @storerkey

if @invkey is null 
	begin
		print 'режим отображения списка инвентризаций'
		select * from da_inventoryhead ih
		where /*ih.skugroup = @skugroup and*/ 
			ih.storerkey = @storerkey and ih.hostzone = @hostzone and whseid = @wh
		order by ih.inventorykey desc
	end

if @invkey is not null
	begin
		print 'режим подтверждения инвентризаци'
		if (select [status] from  da_inventoryhead where inventorykey = @invkey and whseid = @wh) != 0
			begin
				print 'попытка повторного проведения инвентаризации'
			end
		else
			begin
				print 'проводим инвентаризацию'
				update da_inventoryhead set [status] = 1 where inventorykey = @invkey and [status] = 0 and whseid = @wh

				delete from id
				from da_inventoryhead ih join da_inventorydetail id on ih.inventorykey = id.inventorykey and ih.whseid = id.whseid
					where ih.inventorykey != @invkey 
					--and  ih.skugroup = @skugroup 
					and ih.storerkey = @storerkey and ih.hostzone = @hostzone 
					and ih.status = 0 and ih.whseid = @wh

				delete from da_inventoryhead
					where inventorykey != @invkey 
					--and  skugroup = @skugroup 
					and storerkey = @storerkey and hostzone = @hostzone 
					and status = 0 and whseid = @wh

-- формирование события подтверждения инвентаризации в transmitlog 
				declare @eventlogkey varchar(10) -- номер события в transmitlog

				exec dbo.DA_GetNewKey @wh,'EVENTLOGKEY',@eventlogkey output
				set @sql =
				'insert into '+@wh+'.transmitlog
					(whseid,transmitlogkey,tablename, key1, key2) 
				values ('''+@wh+''', '''+@eventlogkey+''', ''inventoryok'', '''+@invkey+''', ''DA'')'
				
				exec (@sql)
			end

print 'вывод результатов в рекордсет'
		select * from da_inventoryhead ih
		where /*ih.skugroup = @skugroup and*/ ih.storerkey = @storerkey and ih.hostzone = @hostzone
		order by ih.inventorykey desc
	end
--	
--drop table #result
----drop table #result_1
--drop table #InventoryDetail

