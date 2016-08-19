-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 21.01.2010 (НОВЭКС)
-- Описание: Получение списка номеров документов из RECEIPTDETAIL.RECEIPTKEY
--	...
-- =============================================
ALTER PROCEDURE [rep].[Product_allocation2] 
	@wh varchar(10),
	@datebegin datetime,
	@dateend datetime,
	@st varchar(10)
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
where RECEIPTDATE between @bdate and @edate and STORERKEY=@st
order by RECEIPTKEY desc

select RECEIPTKEY from @tbl

END

