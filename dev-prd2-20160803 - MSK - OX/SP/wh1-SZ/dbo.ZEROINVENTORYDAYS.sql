--################################################################################################
--         процедура создает волну для заказа и (@type = 'new')
--                   добавляет детали			(@type = 'detail')
--################################################################################################
ALTER PROCEDURE [dbo].[ZEROINVENTORYDAYS]

-- очистка устаревшей информации об операциях с товаром
AS

declare @arch_date int
select @arch_date = nsqlvalue from wh1.nsqlconfig where configkey = 'ZEROINVENTORYDAYS'

DELETE
FROM WH1.LOTxLOCxID
WHERE Qty = 0
AND QtyAllocated = 0
AND QtyPicked = 0
AND QtyExpected = 0
AND QtyPickInProcess = 0
AND PendingMoveIn = 0
AND EditDate <= getdate () - @arch_date;

DELETE
FROM WH1.SKUxLOC
WHERE Qty = 0
AND QtyAllocated = 0
AND QtyPicked = 0
AND QtyExpected = 0
AND QtyLocationLimit = 0
AND QtyLocationMinimum = 0
AND EditDate <= getdate () - @arch_date;

