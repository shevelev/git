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
	 
	--������� sp_OACreate ������ OLE ������ 'Scripting.FileSystemObject'------------------
	EXECUTE @OLEResult = sp_OACreate 'Scripting.FileSystemObject', @FS OUTPUT
	 
	--����������� ���������� ��������� ��������--------------------------------------------
	IF @OLEResult <> 0
	BEGIN
	GOTO Error_Handler
	END
	
	
	if right(@sFileDir,1) <> '\' set @sFileDir = @sFileDir + '\'
	set @sFileName = @sFileDir + @sFileName
	set @sFileText = @sFileText + char(0)
	 
	 
/*
	� Scripting.FileSystemObject ���� ����� ���������� ������� ��� ������ � �������
	� ������������, ��������� �� ����� �����������, ��������, � MSDN.
*/
	 
	--��������� - ���������� �� �������� ����������, ��� ����� ������� ������� 'FolderExists'
	--����� ��������� OLE �������--------------------------------------------------------
	execute @OLEResult = sp_OAMethod @FS,'FolderExists',@bFolder OUT, @sFileDir
	IF @OLEResult <> 0 Or @bFolder = 0
	BEGIN
		--� ���� �� ���������� - �� ������� �--------------------------------------------
		execute @OLEResult = sp_OAMethod @FS,'CreateFolder',@bFolder OUT, @sFileDir
		IF @OLEResult <> 0 And @bFolder = 0
		BEGIN
			GOTO Error_Handler    
		END
	END
	 
	 
	--������� ����----------------------------------------------------------------------
	execute @OLEResult = sp_OAMethod @FS,'CreateTextFile',@FileID OUTPUT,@sFileName
	IF @OLEResult <> 0
	BEGIN
		GOTO Error_Handler
	END
	 
	-----------------�������� ������ � ����---------------------------------------------
	execute @OLEResult = sp_OAMethod @FileID, 'WriteLine', NULL, @sFileText
	IF @OLEResult <> 0
	BEGIN
		GOTO Error_Handler
	END
	 
	goto Done
	 
	Error_Handler:  --���������� ������-------------------------------------------------
	EXEC @hr = sp_OAGetErrorInfo null, @source OUT, @desc OUT
	 
	Done:    
	--������� �� ����� ��������� OLE-�����----------------------------------------------
	EXECUTE @OLEResult = sp_OADestroy @FileID
	EXECUTE @OLEResult = sp_OADestroy @FS

end

