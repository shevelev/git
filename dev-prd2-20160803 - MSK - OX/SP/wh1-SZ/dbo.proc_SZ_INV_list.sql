ALTER PROCEDURE [dbo].[proc_SZ_INV_list] (
		@ivr varchar(20)='1',
		@vr2 varchar(20)
)

AS
declare @sql varchar (max),
		@invkey varchar(10)

/* Генерим номер для вн.инвентарки. вставляем все поля во временную таблицу */

if @vr2 = '0'
	begin
		exec dbo.DA_GetNewKey 'wh1','INVVREM',@invkey output	
		insert wh1.physical_vr SELECT @invkey [SID],  WHSEID, TEAM, STORERKEY, SKU, LOC, LOT, ID, INVENTORYTAG, QTY, PACKKEY, UOM, STATUS, ADDDATE, ADDWHO, EDITDATE, EDITWHO
		FROM         WH1.PHYSICAL
		where STATUS = '0'
		
		insert wh1.ostatki_vr select @invkey [SID],SKU,LOT,LOC,qty 
		from wh1.lotxlocxid
		where QTY>0
		
		insert wh1.inv_nnn select @invkey [SID], GETDATE() date
	
		

select * from wh1.inv_nnn
order by date desc

	end
else
	begin
	select * from wh1.inv_nnn
	order by date desc
	end

