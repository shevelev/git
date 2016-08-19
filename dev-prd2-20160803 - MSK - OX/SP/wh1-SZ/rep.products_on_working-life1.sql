-- =============================================
-- Автор:		Солдаткин Владимир
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 21.01.2010 (НОВЭКС)
-- Описание: Получение списка номеров документов из RECEIPTDETAIL.RECEIPTKEY
--	...
-- =============================================
ALTER PROCEDURE [rep].[products_on_working-life1] 
	@wh varchar(10),
	@datebegin datetime,
	@dateend datetime,
	@storer varchar(15)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
declare 
		@bdate varchar(10), 
		@edate varchar(10)

set @bdate=convert(varchar(10),@datebegin,112)
set @edate=convert(varchar(10),@dateend+1,112)


set dateformat dmy
declare @tbl table (RECEIPTKEY varchar(15))
insert into @tbl
select distinct RECEIPTKEY from WH1.RECEIPT
where RECEIPTDATE between @bdate and @edate
		and storerkey=@storer
order by RECEIPTKEY desc

select RECEIPTKEY from @tbl




END

