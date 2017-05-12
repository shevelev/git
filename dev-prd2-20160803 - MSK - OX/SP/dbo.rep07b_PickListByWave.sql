CREATE proc [dbo].[rep07b_PickListByWave] (
	@wh varchar(10),
	@wavekey varchar(10)
)
AS

--BEGIN TRAN
--declare @wavekey varchar(10)
--select @wavekey = '0000003098'
select orderkey into #ordList from wh40.wavedetail where wavekey = @wavekey

select isnull(case when pls.tsid='' then null else pls.tsid end,pd.dropid) dropid,
	o.consigneekey, cl.CompanyName ClientName, cl.VAT ClientINN, o.DeliveryAdr, o.externorderkey
from wh40.pickdetail pd
	join WH40.PackLoadSend pls on pls.serialkey = pd.serialkey
	join wh40.orders o on o.orderkey = pd.orderkey
	join #ordList ol on o.orderkey = ol.orderkey
	left join wh40.storer cl on cl.storerkey = o.consigneekey

--ROLLBACK
--drop table #ordList

