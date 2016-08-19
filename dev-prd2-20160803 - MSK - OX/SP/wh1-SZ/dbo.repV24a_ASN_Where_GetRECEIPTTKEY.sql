-- =============================================
-- �����:		��������� ��������
-- ������:		������, �.�������
-- ���� ��������: 21.01.2010 (������)
-- ��������: ��������� ������ ������� ���������� �� RECEIPTDETAIL.RECEIPTKEY
--	...
-- =============================================
ALTER PROCEDURE [dbo].[repV24a_ASN_Where_GetRECEIPTTKEY] 
	@wh varchar(10),
	@datebegin datetime,
	@dateend datetime
AS
BEGIN
	SET NOCOUNT ON;

declare @sql varchar(max),
		@bdate varchar(10), 
		@edate varchar(10)

set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(10),@dateend+1,112)

set @sql='
set dateformat dmy
declare @tbl table (RECEIPTKEY varchar(15))
insert into @tbl
select distinct RECEIPTKEY from '+@wh+'.RECEIPT
where RECEIPTDATE between '''+@bdate+''' and '''+@edate+'''
order by RECEIPTKEY desc

select RECEIPTKEY from @tbl'

print(@sql)
exec (@sql)

END

