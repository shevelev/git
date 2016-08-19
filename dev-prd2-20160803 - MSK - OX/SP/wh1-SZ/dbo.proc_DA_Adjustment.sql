-- КОРРЕКТИРОВКИ

ALTER PROCEDURE [dbo].[proc_DA_Adjustment](
	@wh varchar(10),
	@transmitlogkey varchar (10) )
AS
declare @bs varchar(3) select @bs = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'
declare @bsanalit varchar(3) select @bsanalit = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bsanalit'

BEGIN TRY

	begin tran

--циклическая инвентаризация
	insert into DA_Adjustment (storerkey,sku,loc,editdate,deltaqty,zone)
		select i.storerkey, i.sku, i.toloc, i.editdate, i.qty, null 
		from wh1.transmitlog t join wh1.itrn i on i.itrnkey = t.key3
		where t.transmitlogkey = @transmitlogkey and 
			  i.sourcetype = 'ntrCCDetailAdd' 

-- полная инвентаризация
	insert into DA_Adjustment (whseid,storerkey,sku,loc,editdate,deltaqty,zone)
		select 'WH1', ad.storerkey, ad.sku, ad.loc, ad.editdate, ad.qty, null 
		from wh1.transmitlog t join 
			 wh1.itrn i on i.itrnkey = t.key3 join
			 wh1.adjustmentdetail ad on ad.adjustmentkey = t.key1 and ad.ADJUSTMENTLINENUMBER=t.key2
		where t.transmitlogkey = @transmitlogkey and 
			  i.sourcetype = 'ntrAdjustmentDetailAdd' and ad.reasoncode = 'Gen Adjust'

-- определение зоны склада
	update r set r.zone = hz.hostzone
		from DA_Adjustment r join 
			wh1.loc l on r.loc = l.loc join
			wh1.hostzones hz on l.putawayzone = hz.putawayzone and hz.storerkey = r.storerkey
		where r.zone is null
	
-- если не нашли, то поискать зону 'SKLAD'
	update r set r.zone = hz.hostzone
		from DA_Adjustment r join 
			wh1.hostzones hz on 'SKLAD' = hz.putawayzone and hz.storerkey = r.storerkey
		where r.zone is null

	commit tran

-- вывод пустого рекордсета
	select top 0 'ADJUSTMENT' filetype, storerkey, sku, deltaqty, editdate, zone 
	from DA_Adjustment

END TRY
BEGIN CATCH
	rollback tran

	declare @error_message nvarchar(4000)
	declare @error_severity int
	declare @error_state int
	
	set @error_message  = ERROR_MESSAGE()
	set @error_severity = ERROR_SEVERITY()
	set @error_state    = ERROR_STATE()

	raiserror (@error_message, @error_severity, @error_state)
END CATCH

