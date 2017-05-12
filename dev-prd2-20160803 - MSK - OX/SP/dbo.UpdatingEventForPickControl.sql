ALTER PROCEDURE [dbo].[UpdatingEventForPickControl]
AS      
DECLARE @Orders table (orderkey varchar(10));
DECLARE 
	@OrderKey varchar(10),
	@Completed int,
	@NotYet int;


INSERT INTO @Orders
SELECT ORDERKEY
FROM wh1.ORDERS 
WHERE STATUS=68


WHILE (EXISTS(SELECT top 1 orderkey from @Orders))
BEGIN
	SELECT top 1 @OrderKey=orderkey from @Orders	

	SELECT @Completed=COUNT(CASEID)
	FROM wh1.PICKDETAIL
	where ORDERKEY = @OrderKey AND LOC='PL_KONTR'
	
	SELECT  @Completed = @Completed + COUNT(LABEL), @NotYet = COUNT(CASE WHEN LABEL is NULL THEN 1 ELSE NULL END)
	FROM wh1.PICKCONTROL_LABEL pl
		join wh1.PICKDETAIL pd on pl.CASEID=pd.CASEID
	WHERE pd.loc not in ('PL_KONTR') AND pl.ORDERKEY =@OrderKey
	select @Completed, @NotYet
	
	IF(@Completed>0)
	begin
	--select '1',@OrderKey
	IF(@Completed=@Completed+@NotYet)
		begin
		--select @OrderKey
			UPDATE wh1.TRANSMITLOG
			SET TRANSMITFLAG9=NULL
			WHERE SERIALKEY = (	SELECT TOP 1 SERIALKEY 
								FROM wh1.TRANSMITLOG
								WHERE 
									KEY1 = @OrderKey 
									AND TABLENAME IN ('pickcontrolcasecompleted','customerorderlinepacked','customerorderpacked')
									AND 0 = (SELECT SUM(CASE WHEN KEY4='1' THEN 1 ELSE 0 END) FROM wh1.TRANSMITLOG
										WHERE KEY1 = @OrderKey AND TABLENAME IN ('pickcontrolcasecompleted','customerorderlinepacked','customerorderpacked'))
								ORDER BY ADDDATE DESC );

			IF (@@ROWCOUNT>0)	
				begin			
					exec app_DA_SendMail 'СКРИПТ - Авто Контроль: ', @OrderKey
					exec [wh1].[newGLPI] 'control'
					print 'пусто'
				end
		end
		
	end
	DELETE FROM @Orders
	WHERE orderkey=@OrderKey;
END;





