-- =============================================
-- Author:		Dr.MoPo3ilo
-- Create date: 2008-12-19
-- Description:	Получение списка номеров документов из RECEIPTDETAIL.RECEIPTKEY
-- =============================================
ALTER PROCEDURE [rep].[ASNReceipt2] 
	-- Add the parameters for the stored procedure here
	@wh varchar(10),
	@receipttype varchar(10),
	@datebegin datetime,
	@dateend datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

set dateformat dmy
declare @tbl table (RECEIPTKEY varchar(15))
insert into @tbl values ('(ЛЮБОЙ)')
if(isnull(@receipttype,'')='') 
	insert into @tbl
	select distinct RECEIPTKEY from WH1.RECEIPT
	where RECEIPTDATE between convert(varchar,@datebegin,104) and convert(varchar,@dateend+1,104)
	order by RECEIPTKEY desc
else BEGIN
	insert into @tbl
	select distinct RECEIPTKEY from WH1.RECEIPT
	where RECEIPTDATE between convert(varchar,@datebegin,104) and convert(varchar,@dateend+1,104)
	and [TYPE]=@receipttype 
	order by RECEIPTKEY desc
end
	select RECEIPTKEY from @tbl
END

