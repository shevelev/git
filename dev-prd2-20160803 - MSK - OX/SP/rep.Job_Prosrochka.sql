ALTER PROCEDURE rep.Job_Prosrochka
--BEGIN TRANSACTION
AS
BEGIN
DECLARE 
	@datetm DATETIME =getdate(),
	@taskkey VARCHAR(10),
	@count int;

	delete from wh1.taskdetail where ADDWHO = 'PROSROCHKA'
	SELECT IDENTITY(int, 1,1) AS ID_Num,@datetm  AddDate ,'PROSROCHKA' AddWho,@datetm EditDate,'PROSROCHKA' EditWho,
		   @taskkey TaskDetailKey,'MV' TaskType,a.STORERKEY,
		   a.SKU,a.LOT,'6' UOM,
		   a.QTY UOMQty,a.qty qty,
		   a.LOC FromLoc,a.ID FromID, 'PROSROCHKA' ToLoc,'' ToID, '0' Status, '5' Priority,
		   ' ' Holdkey, ' ' UserKey, ' ' ListKey, ' ' StatusMsg, ' ' ReasonKey, ' ' CaseId, '1' UserPosition,
		   ' ' UserKeyOverride, '   ' OrderLineNumber, '   ' PickDetailKey, c.LOGICALLOCATION LogicalFromLoc, 'PROSROCHKA' LogicalToLoc, ' 'FinalToLoc
	into #temp_tbl
	FROM WH1.LOTXLOCXID a JOIN WH1.LOTATTRIBUTE b
	ON a.LOT = b.LOT AND a.SKU = b.SKU JOIN  WH1.LOC c
	ON a.LOC = c.LOC
	WHERE @datetm > b.LOTTABLE05 and a.QTY > 0
	
	SELECT @count = COUNT(*)
	FROM #temp_tbl
	
	while (@count <> 0)
	BEGIN
		EXECUTE dbo.DA_GetNewKey 'wh1','TASKDETAILKEY',@taskkey output		
		update  #temp_tbl
		SET TaskDetailKey = @taskkey
		WHERE ID_Num = @count
		set @count = @count - 1;			
	END
	
	INSERT INTO wh1.TaskDetail 
	(AddDate, AddWho, EditDate, EditWho, 
	TaskDetailKey, TaskType, Storerkey, 
	Sku, Lot, UOM, UOMQty, qty, FromLoc, FromID, ToLoc, ToID, Status, Priority, 
	Holdkey, UserKey, ListKey, StatusMsg, ReasonKey, CaseId, UserPosition, 
	UserKeyOverride, OrderLineNumber, PickDetailKey, LogicalFromLoc, LogicalToLoc, FinalToLoc )
	
	SELECT AddDate, AddWho, EditDate, EditWho, 
	TaskDetailKey, TaskType, Storerkey, 
	Sku, Lot, UOM, UOMQty, qty, FromLoc, FromID, ToLoc, ToID, Status, Priority, 
	Holdkey, UserKey, ListKey, StatusMsg, ReasonKey, CaseId, UserPosition, 
	UserKeyOverride, OrderLineNumber, PickDetailKey, LogicalFromLoc, LogicalToLoc, FinalToLoc
	FROM #temp_tbl

		
	drop table 	#temp_tbl

	
END

/*rollback
SELECT *
FROM WH1.TASKDETAIL
WHERE ADDDATE > '09.09.2014'*/



