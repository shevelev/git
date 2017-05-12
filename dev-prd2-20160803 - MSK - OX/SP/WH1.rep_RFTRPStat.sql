-- =============================================
-- Автор:		Смехнов Антон
-- Проект:		НОВЭКС, г.Барнаул
-- Дата создания: 20.11.2009 (НОВЭКС)
-- Описание: Статистика по пополнениям за неделю
-- =============================================
ALTER PROCEDURE [WH1].[rep_RFTRPStat] 
	@street	as varchar(20)=''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--##############################################################################
select i.storerkey, i.sku, i.toloc, count(serialkey) RPcount, avg(qty) avgQTY
into #RPcount
from wh1.itrn i
where 
i.SOURCETYPE like 'nspRFTRP%'
and i.editdate between (getdate()-7) and getdate()
group by i.storerkey, i.sku, i.toloc


select R.*, cast(s.notes1 as varchar(255)) notes1, s.cartongroup, s.abc, st.company, R.avgQTY/(case when p.casecnt=0 then 1 else p.casecnt end) avgCNT
from #RPcount R 
join wh1.sku s on (R.storerkey=s.storerkey and R.sku=s.sku)
join wh1.storer st on (R.storerkey=st.storerkey)
join wh1.pack p on (s.packkey=p.packkey)
where (isnull(@street,'')='' or isnull(@street,'')=s.cartongroup)
order by R.RPcount desc, R.toloc, s.descr

END

