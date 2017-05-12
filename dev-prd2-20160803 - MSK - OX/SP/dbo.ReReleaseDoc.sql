ALTER PROCEDURE [dbo].[ReReleaseDoc] 
	@typedoc varchar (15), -- ��� ���������
	-- ASN �������� ������� ���
	-- SOP �������� ��������/�������� ������ �� ��������
	-- SOS �������� �������� ������ �� ��������
	-- LD �������� ��������
	@numberdoc varchar (15) -- ����� ���������
AS

--declare @typedoc varchar (15)
--declare @numberdoc varchar (15)
--set @typedoc = 'SOP'
--set @numberdoc = '0000004377'


set nocount on

declare @msg varchar (max) set @msg = ''
declare @transmitlogkey varchar (20) set @transmitlogkey = null
declare @transmitflag9 varchar (50)	set @transmitflag9 = NULL
declare @transmiterror varchar (2000)	set @transmiterror = null


/*********************************************************************************************/
/* ��� ***************************************************************************************/
/*********************************************************************************************/
if @typedoc = 'ASN'
	begin
		print '�������� ���'
		if (select COUNT (serialkey) from wh1.RECEIPT where RECEIPTKEY = @numberdoc) != 1
			begin
				print '��� � ������� ' + @numberdoc + ' �� ����������.'
				set @msg = '��� � ������� ' + @numberdoc + ' �� ����������.'
				goto EndProc
			end		
		--if (select COUNT (serialkey) from wh1.receipt where RECEIPTKEY = @numberdoc and STATUS = '11') != 1
		--	begin
		--		print '��� ' + @numberdoc + '. �������� �� ������.'
		--		set @msg = '��� ' + @numberdoc + '. �������� �� ������.'
		--		goto EndProc
		--	end
			select top(1) @transmitlogkey = TRANSMITLOGKEY from wh1.TRANSMITLOG where key1 = @numberdoc and TABLENAME = 'CompositeASNClose'
		if isnull(@transmitlogkey,'') = ''
			begin
				print '�������� ��� ' + @numberdoc + ' ������. ������� � wh1.TRANSMITLOG �����������. ������� �������.'
				exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
				
				insert into wh1.TRANSMITLOG (whseid, transmitlogkey,			tablename,		key1, key2, key3, key4, key5, transmitflag, transmitflag2, transmitflag3, transmitflag4, transmitflag5, transmitflag6, transmitflag7, transmitflag8, transmitflag9, transmitbatch, eventstatus, eventfailurecount, eventcategory, message, adddate, addwho,	 editdate, editwho, error)
										select 'WH1', @transmitlogkey,'CompositeASNClose',@numberdoc,	'',		'','',		'',			'0',		null,			null,			null,			null,		null,			null,			null,		null,				'',			0,					0,			'E',	'',	GETDATE(),		'RR',	GETDATE(), 'RR',	''
			end
		else 
			begin
				print '������������� ������� � wh1.TRANSMITLOG.'
				update wh1.receipt set susr5='' where RECEIPTKEY = @numberdoc
				delete from pod 
					from wh1.PODETAIL pod join WH1.PO p on pod.POKEY = p.POKEY
					where pod.QTYORDERED = 0 and p.OTHERREFERENCE = @numberdoc	
				update wh1.TRANSMITLOG set transmitflag9 = null, EVENTFAILURECOUNT = EVENTFAILURECOUNT + 1 where TRANSMITLOGKEY = @transmitlogkey	
			end
		while (select transmitflag9 from wh1.TRANSMITLOG where tRANSMITLOGKEY = @transmitlogkey) is null
			begin
				print '������� ��������� ������� �������������'
				waitfor delay '00:00:01'
			end
		select @transmitflag9 = transmitflag9, @transmiterror = error from wh1.TRANSMITLOG where TRANSMITLOGKEY = @transmitlogkey
		if @transmitflag9 = 'OK'
			begin
				print '������������� ������� ��� '+@numberdoc+' ������� ���������.'
				set @msg = '������������� ������� ��� '+@numberdoc+' ������� ���������.'
			end
		else
			begin
				print '������. wh1.TRANSMITLOG.transmitflag9 = ' + @transmitflag9 + ' ������������� ������� ��� �� ���������.'
				print @transmiterror
				set @msg = '������. wh1.TRANSMITLOG.transmitflag9 = ' + @transmitflag9 + ' ������������� ������� ��� �� ���������.'			
			end
	end


/*********************************************************************************************/
/* ����� �� �������� �������� ****************************************************************/
/*********************************************************************************************/
if @typedoc = 'SOP'
	begin
		print '�������� ����� �� �������� ��������'
		if (select COUNT (serialkey) from wh1.ORDERS where orderkey = @numberdoc) != 1
			begin
				print '����� �� �������� � ������� ' + @numberdoc + ' �� ����������.'
				set @msg = '����� �� �������� � ������� ' + @numberdoc + ' �� ����������.'
				goto EndProc
			end	
		create table #case (
			orderkey varchar(20),
			caseid varchar (20),
			pickdetailkey varchar(20),
			locpd varchar (20) null,
			loci varchar (20) null,
			loc varchar (20) null,
			statuspd varchar (20) null,
			zone varchar(50) null,
			control varchar(50) null,
			status varchar(50) null,
			run_allocation int null,
			run_cc int null,
			contrdatetime datetime null,
			sku varchar(20) null
		)
			print '����� '+@numberdoc+' ����������������'
			select top(1) @transmitlogkey = TRANSMITLOGKEY from wh1.TRANSMITLOG where KEY1 = @numberdoc and (TABLENAME = 'customerorderlinepacked' or TABLENAME = 'customerorderpacked' or TABLENAME = 'pickcontrolcasecompleted')
			if isnull(@transmitlogkey,'') = ''
				begin 
					print '����� ' + @numberdoc + ' �������/��������. ������� � wh1.TRANSMITLOG �����������. ������� �������.'
					exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
						
					insert into wh1.TRANSMITLOG (whseid, transmitlogkey,			tablename,		key1, key2, key3, key4, key5, transmitflag, transmitflag2, transmitflag3, transmitflag4, transmitflag5, transmitflag6, transmitflag7, transmitflag8, transmitflag9, transmitbatch, eventstatus, eventfailurecount, eventcategory, message, adddate, addwho,	 editdate, editwho, error)
						select 'WH1', @transmitlogkey,'customerorderpacked',@numberdoc,	'',		'','',		'',			'0',		null,			null,			null,			null,		null,			null,			null,		null,				'',			0,					0,			'E',	'',	GETDATE(),		'RR',	GETDATE(), 'RR',	''
				end
			else
				begin
					print '���������� ������� ' + @transmitlogkey + '.' 
					update wh1.ORDERS set susr2 = '' where ORDERKEY = @numberdoc
					update wh1.TRANSMITLOG set transmitflag9 = null where TRANSMITLOGKEY = @transmitlogkey	
				end
			while (select transmitflag9 from wh1.TRANSMITLOG where tRANSMITLOGKEY = @transmitlogkey) is null
				begin
					print '������� ��������� ������� �������������'
					waitfor delay '00:00:01'
				end
			select @transmitflag9 = transmitflag9, @transmiterror = error from wh1.TRANSMITLOG where TRANSMITLOGKEY = @transmitlogkey
			if @transmitflag9 = 'OK'
				begin
					print '������������� ��������/�������� ������ '+@numberdoc+' ������� ���������.'
					set @msg = '������������� ��������/�������� ������ '+@numberdoc+' ������� ���������.'
				end
			else
				begin
					print '������. wh1.TRANSMITLOG.transmitflag9 = ' + @transmitflag9 + ' ������������� ��������/�������� ������ '+@numberdoc+' �� ���������.'
					print @transmiterror
					set @msg = '������. wh1.TRANSMITLOG.transmitflag9 = ' + @transmitflag9 + ' ������������� ��������/�������� ������ '+@numberdoc+' �� ���������.'			
				end
		drop table #case
	end

/*********************************************************************************************/
/* ����� �� �������� �������� ****************************************************************/
/*********************************************************************************************/
if @typedoc = 'SOS'
	begin
		print '�������� ����� �� ��������'
		if (select COUNT (serialkey) from wh1.ORDERS where orderkey = @numberdoc) != 1
			begin
				print '����� �� �������� � ������� ' + @numberdoc + ' �� ����������.'
				set @msg = '����� �� �������� � ������� ' + @numberdoc + ' �� ����������.'
				goto EndProc
			end	
		create table #case1 (
			orderkey varchar(20),
			caseid varchar (20),
			pickdetailkey varchar(20),
			locpd varchar (20) null,
			loci varchar (20) null,
			loc varchar (20) null,
			statuspd varchar (20) null,
			zone varchar(50) null,
			control varchar(50) null,
			status varchar(50) null,
			run_allocation int null,
			run_cc int null,
			contrdatetime datetime null,
			sku varchar(20) null
		)
				print '����� '+@numberdoc+' ����������������'
				select '����� '+@numberdoc+' ��������'
				select top(1) @transmitlogkey = TRANSMITLOGKEY from wh1.TRANSMITLOG where KEY1 = @numberdoc and (TABLENAME = 'CompositeASNClose')
				if isnull(@transmitlogkey,'') = ''
					begin 
						print '����� ' + @numberdoc + ' ��������. ������� � wh1.TRANSMITLOG �����������. ������� �������.'
						exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
	
						insert into wh1.TRANSMITLOG (whseid, transmitlogkey,			tablename,		key1, key2, key3, key4, key5, transmitflag, transmitflag2, transmitflag3, transmitflag4, transmitflag5, transmitflag6, transmitflag7, transmitflag8, transmitflag9, transmitbatch, eventstatus, eventfailurecount, eventcategory, message, adddate, addwho,	 editdate, editwho, error)
							select 'WH1', @transmitlogkey,'CompositeASNClose',@numberdoc,	'',		'','',		'',			'0',		null,			null,			null,			null,		null,			null,			null,		null,				'',			0,					0,			'E',	'',	GETDATE(),		'RR',	GETDATE(), 'RR',	''
					end
				else
					begin
						print '���������� �������.'
						update wh1.ORDERS set susr2 = '' where ORDERKEY = @numberdoc
						update wh1.TRANSMITLOG set transmitflag9 = null where TRANSMITLOGKEY = @transmitlogkey	
					end
				while (select transmitflag9 from wh1.TRANSMITLOG where tRANSMITLOGKEY = @transmitlogkey) is null
					begin
						print '������� ��������� ������� �������������'
						waitfor delay '00:00:01'
					end
				select @transmitflag9 = transmitflag9, @transmiterror = error from wh1.TRANSMITLOG where TRANSMITLOGKEY = @transmitlogkey
				if @transmitflag9 = 'OK'
					begin
						print '������������� �������� ������ '+@numberdoc+' ������� ���������.'
						set @msg = '������������� �������� ������ '+@numberdoc+' ������� ���������.'
					end
				else
					begin
						print '������. wh1.TRANSMITLOG.transmitflag9 = ' + @transmitflag9 + ' ������������� �������� ������ '+@numberdoc+' �� ���������.'
						print @transmiterror
						set @msg = '������. wh1.TRANSMITLOG.transmitflag9 = ' + @transmitflag9 + ' ������������� �������� ������ '+@numberdoc+' �� ���������.'			
					end
		drop table #case1
	end

/*********************************************************************************************/
/* �������� **********************************************************************************/
/*********************************************************************************************/
if @typedoc = 'LD'
	begin
		print '�������� ��������'
		if (select COUNT (serialkey) from wh1.LOADHDR where LOADID = @numberdoc) != 1
			begin
				print '�������� � ������� ' + @numberdoc + ' �� ����������.'
				set @msg = '�������� � ������� ' + @numberdoc + ' �� ����������.'
				goto EndProc				
			end
		select top(1) @transmitlogkey = transmitlogkey from wh1.TRANSMITLOG where KEY1 = @numberdoc and TABLENAME = 'tsshipped'	
		if isnull(@transmitlogkey,'') = ''
			begin
				print '�������� ' + @numberdoc + ' �������. ������� � wh1.TRANSMITLOG �����������. ������� �������.'
				exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
				
				insert into wh1.TRANSMITLOG (whseid, transmitlogkey,			tablename,		key1, key2, key3, key4, key5, transmitflag, transmitflag2, transmitflag3, transmitflag4, transmitflag5, transmitflag6, transmitflag7, transmitflag8, transmitflag9, transmitbatch, eventstatus, eventfailurecount, eventcategory, message, adddate, addwho,	 editdate, editwho, error)
										select 'WH1', @transmitlogkey,'tsshipped',@numberdoc,	'',		'','',		'',			'0',		null,			null,			null,			null,		null,			null,			null,		null,				'',			0,					0,			'E',	'',	GETDATE(),		'RR',	GETDATE(), 'RR',	''
			end
		else
			begin
				print '������������� ������� � wh1.TRANSMITLOG.'
				update wh1.receipt set susr5='' where RECEIPTKEY = @numberdoc
				delete from pod 
					from wh1.PODETAIL pod join WH1.PO p on pod.POKEY = p.POKEY
					where pod.QTYORDERED = 0 and p.OTHERREFERENCE = @numberdoc	
				update wh1.TRANSMITLOG set transmitflag9 = null, EVENTFAILURECOUNT = EVENTFAILURECOUNT + 1 where TRANSMITLOGKEY = @transmitlogkey					
			end
		while (select transmitflag9 from wh1.TRANSMITLOG where TRANSMITLOGKEY = @transmitlogkey	) is null
			begin
				--pause
				print '������� ��������� ������� �������������'
				waitfor delay '00:00:01'
			end
		select @transmitflag9 = transmitflag9, @transmiterror = error from wh1.TRANSMITLOG where TRANSMITLOGKEY = @transmitlogkey
		if @transmitflag9 = 'OK'
			begin
				print '������������� �������� �������� '+@numberdoc+' ������� ���������.'
				set @msg = '������������� �������� �������� '+@numberdoc+' ������� ���������.'
			end
		else
			begin
				print '������. wh1.TRANSMITLOG.transmitflag9 = ' + @transmitflag9 + ' ������������� �������� �������� �� ���������.'
				print @transmiterror
				set @msg = '������. wh1.TRANSMITLOG.transmitflag9 = ' + @transmitflag9 + ' ������������� �������� �������� �� ���������.'			
			end
	end
	

EndProc:
	select MSG = @msg, ERROR = @transmiterror
	

