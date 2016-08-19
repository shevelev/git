-- =============================================
-- Author:		Dr.MoPo3ilo
-- Create date: 2008-12-19
-- Description:	Получение списка номеров документов из RECEIPT.externreceiptkey
-- =============================================
ALTER PROCEDURE [dbo].[rep01b_ASNReceipt_Getexternreceiptkey] 
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
	set @sql='
set dateformat dmy
declare @tbl table (externreceiptkey varchar(15))
insert into @tbl values (''(ЛЮБОЙ)'')
insert into @tbl
select distinct EXTERNRECEIPTKEY from '+@wh+'.RECEIPT
where RECEIPTDATE between '''+convert(varchar,@datebegin,104)+''' and '''+convert(varchar,@dateend+1,104)+''' '+
case when isnull(@receipttype,'')='' then '' else 'and [TYPE]='''+@receipttype+''' ' end+
'order by EXTERNRECEIPTKEY desc

select externreceiptkey from @tbl'
  print(@sql)
	exec (@sql)
END

