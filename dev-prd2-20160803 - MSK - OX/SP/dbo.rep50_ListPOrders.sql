/* ������ �� � ������ */
ALTER PROCEDURE [dbo].[rep50_ListPOrders](
 	@dat1  datetime,
 	@dat2  datetime,
 	@tin   varchar (50),
 	@tex    varchar (50),
 	@supp   varchar (50),
 	@stz varchar(10)=null
)
AS

	set @dat1= replace(upper(@dat1),';','')  -- ������� ; �� ����� ���������� ������������� ��� ���������� ������������.
	set @dat2= replace(upper(@dat2),';','') 

declare @date1 varchar(10),
			@date2 varchar(10)
	-- ��������� �������� ��� �� ���������� ����������.
	set @date1 = convert(varchar(10),@dat1,112)
	set @date2 = convert(varchar(10),dateadd(dy,1,@dat2),112)
	-- ���� ���� �� ������ ������ ����� ��������� ����, �������� ������������� ��� ����� ������ �������
	if @date1 is null set @date1 = '20000101' -- 1 ��� 2000
	if @date2 is null set @date2 = convert(varchar(10), dateadd(yy,1,getdate()),112) -- ���. ���� ���� ���
	-- � ������ ���� ���� ���������� ������� ��������������� ���������� �������
	declare @tmp varchar(10)
	if @date2 < @date1 
	begin
		select @tmp = @date2, @date2 = @date1
		select @date1 = @tmp
	end


--declare @tex varchar(50)
--declare @tin varchar(50)
--declare @supp varchar(50)
--declare @stz varchar(50)

SELECT     
distinct p.POKEY pk, p.externpokey ex, ck.DESCRIPTION d,  p.EFFECTIVEDATE pod,st.COMPANY c, '0' q1
into #vrpo
FROM         WH1.PO p
JOIN                     WH1.PODETAIL AS pd ON p.POKEY = pd.POKEY 
JOIN                     WH1.CODELKUP AS ck on ck.CODE = p.status and ck.LISTNAME = 'postatus' 
left JOIN                     WH1.STORER AS ST ON p.SELLERNAME = st.STORERKEY  and st.COMPANY like '%'+isnull(@supp,'')+'%'
 
WHERE     (p.externpokey like '%'+isnull(@tex,'')+'%' 
and P.POKEY like '%'+isnull(@tin,'')+'%'  
and p.STATUS like '%'+isnull(@stz,'')+'%')
and (p.EFFECTIVEDATE between ''+ @date1+'' and ''+@date2+'' )

update vr
set vr.q1 = '1'
from wh1.PODETAIL pd, #vrpo vr where pd.pokey=vr.pk and pd.qtyrejected != '0'

select * from #vrpo

drop table #vrpo


