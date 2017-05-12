-- =============================================
-- �����:		��������� ��������
-- ������:		������, �.�������
-- ���� ��������: 21.01.2010 (������)
-- ��������: ��������� ������ ������� ���������� �� RECEIPTDETAIL.RECEIPTKEY
--	...
-- =============================================
ALTER PROCEDURE [rep].[Product_allocation2] 
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


set dateformat dmy
declare @tbl table (RECEIPTKEY varchar(15))
insert into @tbl
select distinct RECEIPTKEY from WH1.RECEIPT
where RECEIPTDATE between @bdate and @edate
order by RECEIPTKEY desc

select RECEIPTKEY from @tbl

END

