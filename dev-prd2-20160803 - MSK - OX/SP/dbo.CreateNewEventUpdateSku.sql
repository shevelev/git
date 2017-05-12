ALTER PROCEDURE [dbo].[CreateNewEventUpdateSku]

AS

declare @dateFROM datetime
declare @dateTo datetime
declare @sku varchar(10)

set @dateFROM = DATEADD(mi, -100, getdate())
set @dateTo = DATEADD(mi, -1, getdate())



select sku  into #sku from wh1.sku where EDITDATE between @dateFROM and @dateTo
	union all
select sku  from wh1.ALTSKU where EDITDATE between @dateFROM and @dateTo


select top 1  @sku=sku from #sku

if @sku is not null
	begin

			select * from wh1.TRANSMITLOG where tablename='commodityupdated' and key1=@sku and  EDITDATE between @dateFROM and @dateTo

			if @@ROWCOUNT != 0
				begin
					 print '���� ������ � ��, ������ �� ������'
				end
			else
				begin
					print '��� ������ � ��, ���������� ������� � �� � ����������� ������'
					
					declare @transmitlogkey varchar(10)
					exec dbo.DA_GetNewKey 'wh1','eventlogkey',@transmitlogkey output
		
					--�������� ������ � �������, ��� ���������� �������� ������.
					insert wh1.transmitlog (whseid, transmitlogkey, tablename, ADDWHO,KEY1,key2) 
					values ('WH1', @transmitlogkey, 'commodityupdated',  'commodityupdatedA',@sku,'001')
				end
	end
	
else 
 begin
	print '��� ������� �� ��������� 40 ����� ��� ���������'
 end



drop table #sku

