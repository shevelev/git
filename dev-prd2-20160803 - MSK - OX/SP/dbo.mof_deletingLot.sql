
ALTER PROCEDURE [dbo].[mof_deletingLot]
	@lot VARCHAR(10)--='0000082479';
AS
DECLARE 
	@sum int
IF NOT EXISTS (SELECT 1 FROM wh2.lot WHERE LOT = @lot)
BEGIN
	SELECT 'Ћота '''+ @lot+ ''' не существует'
	RETURN;
END

SELECT @sum = SUM(qty)
FROM (
	SELECT sum(qty) qty
	FROM wh2.lotxlocxid
	WHERE lot = @lot
	
	UNION ALL
	
	SELECT SUM(qty)
	FROM wh2.lot
	WHERE lot = @lot) as a

IF @sum > 0
	SELECT 'Ќа партии есть остатки'
ELSE
BEGIN
	
	DELETE FROM wh2.lotxlocxid
	FROM wh2.lotxlocxid l 
		JOIN wh2.LOT l2 ON l2.LOT = l.LOT
	WHERE  l2.LOT = @lot -- AND l2.QTY = 0
	
	IF @@ERROR = 0
	BEGIN
		--print 'удаление старых партий из lot'
		DELETE FROM wh2.lot
		WHERE  lot = @lot --and QTY = 0
	END
		
	IF @@ERROR = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM wh2.LOT where LOT = @lot)
		BEGIN
		--print 'удаление старых партий из LOTATTRIBUTE'
			DELETE FROM wh2.LOTATTRIBUTE                                                                                                                                                                                                   
			WHERE lot = @lot
		END
	END
		
	INSERT INTO DA_InboundErrorsLog (source,msg_errdetails) 
	SELECT 'deletingLot', 'удал€ем лот: ' + @lot
	
	SELECT '”даление партии ''' + @lot +''' успешно завершено'
END
	









--select * from wh2.lotxlocxid where lot='0000082479'
--select * from wh2.lot where lot='0000082479'
--select * from wh2.LOTATTRIBUTE where lot='0000091656'


--Select *
--from wh2.lot
--where qty!=0;
