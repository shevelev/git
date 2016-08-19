-- =============================================
-- Автор:		Тын Максим
-- Проект:		ЛЦ, г.Барнаул
-- Дата создания: 17.05.2010 (ЛЦ)
-- Описание: Изменение машины и водителя у ORDER для "Транс-Авто"
-- =============================================
ALTER PROCEDURE [dbo].[repF06_Auto_Order] ( 
	--@dateBegin varchar(25),		--начальная дата
	--@dateEnd varchar(25),		--конечная дата
	@OKEY as varchar(10),		--ордеркей
	@STKEYt as varchar(15),		--сторер автомобиль
	@STKEYv as varchar(15)		--сторер водитель	
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--declare @STKEYt as varchar(15), @STKEYv as varchar(15), @OKEY as varchar(10)
--set @stkeyt='T0002'
--set @stkeyv='V00012'
--set @okey='0000013554'
create table #MyTableVar(
    --EmpID int NOT NULL,
    carriercode varchar(15),
    oldcarriercode varchar(15),
    carriername varchar(45),
	oldcarriername varchar(45),
	trailernumber varchar(18),
	oldtrailernumber varchar(18),
	intermodalvehicle varchar(15),
	oldintermodalvehicle varchar(15),
	drivername varchar(45),
	olddrivername varchar(45)
	);

update wh1.orders
	set carriercode=@stkeyt, carriername=stt.company, trailernumber=stt.vat,
		intermodalvehicle=@stkeyv, drivername=stv.company
	output inserted.carriercode,
			deleted.carriercode,
			inserted.carriername,
			deleted.carriername,
			inserted.trailernumber,
			deleted.trailernumber,
			inserted.intermodalvehicle,
			deleted.intermodalvehicle,
			inserted.drivername,
			deleted.drivername
	into #MyTableVar
	from wh1.orders o
		join wh1.storer stt on stt.storerkey=@stkeyt
		join wh1.storer stv on stv.storerkey=@stkeyv
	where o.orderkey=@okey
    -- Insert statements for procedure here
--	SELECT <@Param1, sysname, @p1>, <@Param2, sysname, @p2>
select *
from #MyTableVar

drop table #MyTableVar

END

