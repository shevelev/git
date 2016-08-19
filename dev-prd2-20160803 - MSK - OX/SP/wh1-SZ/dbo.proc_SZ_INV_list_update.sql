ALTER PROCEDURE [dbo].[proc_SZ_INV_list_update] (
		@tvr varchar(20)='1',
		@tvr2 varchar(20),
		@invNN varchar(20)
)

AS
declare @sql varchar (max),
		@invkey varchar(10)

/* ��������� ������� �� ��������� ������� � ���.������� */
if @tvr2 = '0'
	begin
		insert wh1.physical SELECT WHSEID, TEAM, STORERKEY, SKU, LOC, LOT, ID, INVENTORYTAG, QTY, PACKKEY, UOM, STATUS, ADDDATE, ADDWHO, EDITDATE, EDITWHO
		FROM         WH1.PHYSICAL_vr
		where [SID]=@invNN and [status] = '0'
/* ��������� ��������� ������� ����� ��� ���������� ���� � ����� */
		UPDATE wh1.physical_vr SET [status] = 'x'
		WHERE [status] = '0'
		
		select * from wh1.physical WHERE [status] = '0'
	--	delete from wh1.physical_vr
	end
else
	begin
		select * from wh1.physical WHERE [status] = '0'
	end

