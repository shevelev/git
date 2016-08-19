create proc dbo.SaveFile
	@sFileDir varchar(8000) = 'e:\Test\',
	@sFileName varchar(255),
	@sFileText varchar(max)
as
begin
/*
	exec sp_configure 'show advanced options', '1'
	reconfigure
	exec sp_configure 'Ole Automation Procedures', '1'
	reconfigure
	exec sp_configure 'show advanced options', '0'
	reconfigure
*/

	declare
		@FS int,
		@FileID int,
		@hr int,
		@OLEResult int,
		 
		@source varchar(30),
		@desc varchar (200),
		@bFolder bit
	 
	---------------------------------------------------------------------------------------
	 
	--функци€ sp_OACreate создаЄт OLE объект 'Scripting.FileSystemObject'------------------
	EXECUTE @OLEResult = sp_OACreate 'Scripting.FileSystemObject', @FS OUTPUT
	 
	--об€зательно обработать ошибочные ситуации--------------------------------------------
	IF @OLEResult <> 0
	BEGIN
	GOTO Error_Handler
	END
	
	
	if right(@sFileDir,1) <> '\' set @sFileDir = @sFileDir + '\'
	set @sFileName = @sFileDir + @sFileName
	set @sFileText = @sFileText + char(0)
	 
	 
/*
	у Scripting.FileSystemObject есть много интересных методов дл€ работы с файлами
	и директори€ми, подробнее их можно подсмотреть, например, в MSDN.
*/
	 
	--проверить - существует ли заданна€ директори€, дл€ этого вызовем функцию 'FolderExists'
	--ранее созданого OLE объекта--------------------------------------------------------
	execute @OLEResult = sp_OAMethod @FS,'FolderExists',@bFolder OUT, @sFileDir
	IF @OLEResult <> 0 Or @bFolder = 0
	BEGIN
		--а если не существует - то создать еЄ--------------------------------------------
		execute @OLEResult = sp_OAMethod @FS,'CreateFolder',@bFolder OUT, @sFileDir
		IF @OLEResult <> 0 And @bFolder = 0
		BEGIN
			GOTO Error_Handler    
		END
	END
	 
	 
	--создать файл----------------------------------------------------------------------
	execute @OLEResult = sp_OAMethod @FS,'CreateTextFile',@FileID OUTPUT,@sFileName
	IF @OLEResult <> 0
	BEGIN
		GOTO Error_Handler
	END
	 
	-----------------записать строку в файл---------------------------------------------
	execute @OLEResult = sp_OAMethod @FileID, 'WriteLine', NULL, @sFileText
	IF @OLEResult <> 0
	BEGIN
		GOTO Error_Handler
	END
	 
	goto Done
	 
	Error_Handler:  --обработаем ошибку-------------------------------------------------
	EXEC @hr = sp_OAGetErrorInfo null, @source OUT, @desc OUT
	 
	Done:    
	--очистим за собой вс€ческий OLE-мусор----------------------------------------------
	EXECUTE @OLEResult = sp_OADestroy @FileID
	EXECUTE @OLEResult = sp_OADestroy @FS

end

