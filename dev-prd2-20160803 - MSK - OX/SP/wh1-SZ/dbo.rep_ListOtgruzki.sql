
-- =============================================
-- Author:		<Kruglov_Ivan>
-- Create date: <19.08.2010>
-- Description:	<List Otgruzki>
-- =============================================
ALTER PROCEDURE [dbo].[rep_ListOtgruzki]
	-- Add the parameters for the stored procedure here
	@dateLow datetime,
	@dateHight datetime,
	@wavekey varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	select
		pd.wavekey '� �����',
		pd.STORERKEY '��� ���������',
		pd.SKU '��� ������',
		sku.DESCR '������������ ������',
		pd.QTY '���-��',
		pd.STATUS '������',
		pd.ORDERKEY '� ������',
		pd.CASEID '� �����',
		pd.DROPID '� �������'
	from 
		WH1.PICKDETAIL pd
left join WH1.SKU sku on (pd.sku = sku.sku and pd.STORERKEY = sku.STORERKEY)
	where wavekey = @wavekey
		

END


