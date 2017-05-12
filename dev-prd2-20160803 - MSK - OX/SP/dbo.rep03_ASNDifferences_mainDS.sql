ALTER PROCEDURE [dbo].[rep03_ASNDifferences_mainDS] (
	/*   03 ��� ����������� ��� ������� mainDS*/
	@wh VARCHAR(30),
	@nomer varchar(15)
)AS

--	declare @wh VARCHAR(30), @nomer varchar(15)
--	select @wh='WH40', @nomer = '0000000608'


	set @wh = upper(@wh)
	set @nomer= replace(upper(@nomer),';','')  -- ������� ; �� ����� ���������� ������������� ��� ���������� ������������.
	-- KSV
	set @nomer= '%' + case when @nomer='(�����)' then '' else @nomer end
    -- KSV END
	declare @sql varchar(max)
    

	set @sql = 'select t.SUSR10 SUSR10, r.receiptkey as k,
		r.storerkey as sk,
		r.CARRIERKEY as carrKey,
		r.CARRIERNAME as carrName,
		st.company as vlad,
		rd.sku as sku,
		t.descr as opisanie,''������ ''+isnull(r.EXTERNRECEIPTKEY,'''') as ihnomer,
		max(rd.packkey) as pk,
		isnull(r.EXTERNRECEIPTKEY,'''')EXTERNRECEIPTKEY,
		sum(rd.qtyexpected) as zqty,
		sum(rd.qtyreceived) as fqty,
		case when sum(rd.qtyexpected)-sum(rd.qtyreceived)>0 
				then sum(rd.qtyexpected)-sum(rd.qtyreceived) 
			else 0 
		end as ned,
		case 
			when sum(rd.qtyexpected)-sum(rd.qtyreceived)<0 
			then sum(rd.qtyreceived)-sum(rd.qtyexpected)
			else 0 
		end as izl
		from '+@WH+'.receipt as r
			left join '+@WH+'.receiptdetail as rd on r.receiptkey=rd.receiptkey
			left join '+@WH+'.storer as st on r.storerkey=st.storerkey
			left join '+@WH+'.sku as t on rd.storerkey=t.storerkey and rd.sku=t.sku
		where r.receiptkey like '''+@nomer+'''
		group by 
			t.SUSR10,
			r.receiptdate,
			r.receiptkey,
			r.storerkey,
			st.company,
			rd.sku,
			t.descr,
			r.susr1,
			r.EXTERNRECEIPTKEY,
			r.CARRIERKEY,
			r.CARRIERNAME
		having sum(rd.qtyexpected)<>sum(rd.qtyreceived)
		order by k'
	exec (@sql)
	
--select * from wh40.receiptdetail where receiptkey = '0000000531'

