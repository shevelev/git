ALTER PROCEDURE [WH1].[sendGLPI] 
AS

begin


declare @count int, -- ���-�� ������� �� ����
		@number_of_errors int = 0, -- ���-�� ������ �� ����
		@enter varchar(10)=char(13)+char(10), -- ������� ������
		@subj varchar(50), -- ��������� ������
		@body varchar(max), -- ���� ������
		@id int -- ������� ��� ���� ������

-- ��������� ���� �� �� ������� ���� ������ � �������
select @count = COUNT(*) from [WH1].[NGLPI] where adddate = CONVERT(date, GETDATE(), 101)

if @count = 0 
	begin
	
		INSERT INTO [PRD2].[WH1].[NGLPI] (KEYNAME,KEYCOUNT,ADDDATE)
           
           VALUES	('control',0,CONVERT(date, GETDATE(), 101)),
					('sku',0,CONVERT(date, GETDATE(), 101)),
					('move',0,CONVERT(date, GETDATE(), 101)),
					('asnclose',0,CONVERT(date, GETDATE(), 101)),
					('shorder',0,CONVERT(date, GETDATE(), 101)),
					('po',0,CONVERT(date, GETDATE(), 101)),
					('syserror',0,CONVERT(date, GETDATE(), 101)),
					('transfer',0,CONVERT(date, GETDATE(), 101)),
					('orders',0,CONVERT(date, GETDATE(), 101))
	end
else 
	begin
		print '������ �� ������� ���� ��� ���������'
	end
	
	print '���� ������'
----- �������� ���������� �� ���������� ����

select serialkey	,case    when  keyname = 'asnclose' then '�������� ���'
				when  keyname = 'control' then '����-��������'
				when  keyname = 'move' then '����-�����������'
				when  keyname = 'orders' then '��������-������ ����������'
				when  keyname = 'po' then '�������-������ ����������'
				when  keyname = 'shorder' then '�������� DAX'
				when  keyname= 'sku' then '������-������ ����������' 
				when  keyname= 'syserror' then '��������� ������'
				when  keyname= 'transfer' then '��������' end as keyname, keycount 
into #teplates_mail
from [WH1].[NGLPI] where adddate = CONVERT(date, DATEADD(d, -1, getdate()), 101)




-- ������������ ���-�� ������	

select @number_of_errors = SUM(keycount) from #teplates_mail

if (@number_of_errors = 0) 
	begin
		print '����� �� ��������� '
		RETURN
	end

-- ������� ��� 0 ������ �� �������
delete #teplates_mail where keycount=0 
-- ��������� ������
set @subj = '����������� ������ �� ' + CONVERT(varchar(30), DATEADD(d, -1, getdate()), 101)
set @body = '������: ' +  convert(varchar(20),@number_of_errors) + @enter + @enter

--select * from #teplates_mail

while ((select count(serialkey) from #teplates_mail) != 0)
	begin
		
		select top 1 @id = serialkey from #teplates_mail order by serialkey
		select @body = @body + convert(varchar(10),keycount) + ' - ' + keyname + @enter from #teplates_mail where serialkey=@id
		delete #teplates_mail where serialkey=@id
		
	end


select @subj, @body

exec dbo.SendMail 'support-wms@sev-zap.ru',@subj, @body
	
	
drop table #teplates_mail
	
	
	
	
	

end
