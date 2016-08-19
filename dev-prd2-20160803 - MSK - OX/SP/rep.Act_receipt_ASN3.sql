-- =============================================
-- Author:		Dr.MoPo3ilo
-- Create date: 2008-12-19
-- Description:	Получение списка номеров документов из RECEIPT.externreceiptkey
-- =============================================
ALTER PROCEDURE [rep].[Act_receipt_ASN3] 
	-- Add the parameters for the stored procedure here
	@wh varchar(10),
	@receipttype varchar(10)=null,
	@datebegin datetime,
	@dateend datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @sql varchar(max)
	
set dateformat dmy
declare @tbl table (externreceiptkey varchar(15))
insert into @tbl values ('(ЛЮБОЙ)')

if (isnull(@receipttype,'')='')
BEGIN
insert into @tbl
select distinct EXTERNRECEIPTKEY from WH1.RECEIPT
where RECEIPTDATE between convert(varchar,@datebegin,104) and convert(varchar,@dateend+1,104) 
order by EXTERNRECEIPTKEY desc
END
ELSE BEGIN 
insert into @tbl
select distinct EXTERNRECEIPTKEY from WH1.RECEIPT
where RECEIPTDATE between convert(varchar,@datebegin,104) and convert(varchar,@dateend+1,104) 
and [TYPE]=@receipttype
order by EXTERNRECEIPTKEY desc

END


select externreceiptkey from @tbl
 
END

