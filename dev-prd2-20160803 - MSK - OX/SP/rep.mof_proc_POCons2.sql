--################################################################################################
-- ��������� ��������/��������� �� �� ���, � ���������� ������ ��
--################################################################################################
ALTER PROCEDURE [rep].[mof_proc_POCons2]
	@dateLow datetime,
	@dateHigh datetime,
    @tp varchar(55),
	@POkey varchar(10)='',		-- ����� ��
	@Receiptkey varchar(10)='<�����>', -- ����� ���
	@flag varchar(1)='',		-- ���� '-' ���������/'+' ��������/'' ��������
	@Storerkey varchar(15)='',	-- ������ ����������� �� ���������
	@activeReceipt varchar(10) OUTPUT
	AS
declare @txt_newRec varchar(10)
set @txt_newRec = '<�����>'

declare @newReceipt varchar(10),
		@status varchar(10),
		@alreadyIN varchar(10),
		@ReceiptStorer varchar(15),
		@POStorer varchar(15),
		@error varchar(1000)
	   
	   

set @newReceipt=@Receiptkey
select @status=status, @ReceiptStorer=storerkey from wh2.receipt
	where receiptkey=@Receiptkey and @Receiptkey<>'' and @Receiptkey<>@txt_newRec
select @alreadyIN=po.otherreference
		from wh2.po po join wh2.receipt r on po.otherreference=r.receiptkey
		where po.pokey=@POkey
select @POStorer=po.storerkey from wh2.po po 
		where po.pokey=@POkey

if (@flag='+' and @Receiptkey<>'' and @Receiptkey<>@txt_newRec and @POkey<>'' and ISNULL(@status,'0')='0'
	and isnull(@POStorer,'')=isnull(@ReceiptStorer,''))
begin
--��������� PO � ������������ ���
		--...����������� ����� ��� � PO
		begin try
			update wh2.po 	set otherreference=@newReceipt	where pokey=@POkey
			--...������������� ���
			exec wh2.app_Receipt @newReceipt
		end try 
		begin catch
			set @error = ERROR_MESSAGE()
			update wh2.po set otherreference='' where pokey=@POkey
		end catch
end

if (@flag='-' and @POkey<>'' and ISNULL(@status,'0')='0')
begin
--������� PO �� ������������� ���
		--...���������� ����� ���
		select @newReceipt=po.otherreference
		from wh2.po po join wh2.receipt r on po.otherreference=r.receiptkey
		where po.pokey=@POkey
		--...������� ����� ��� � PO
		begin try
			update wh2.po	set otherreference=''		where pokey=@POkey
			--...������������� ���
			if (isnull(@newReceipt,'')<>'') exec wh2.app_Receipt @newReceipt
		end try
		begin catch
			update wh2.po set otherreference=@newReceipt where pokey=@POkey
		end catch

-- ��������� - ���� ��� ��������� �� � ��� - ���������� ����� ���	   
if not exists(select 1 from wh2.PO where OTHERREFERENCE = @newReceipt)
set @newReceipt=@txt_newRec
		
		
end

if (@flag='+' and (@Receiptkey='' or @Receiptkey=@txt_newRec) and @POkey<>'' and isnull(@alreadyIN,'')='')
begin
--��������� PO � ����� ���
		--���������, ��� �� ��� �� ������� �� � ���� ���, � ������ � ���� ������ ������� �����. ����� ������ �� ������.
		if (select isnull(otherreference,'') from wh2.po where pokey=@POkey)=''
		begin
		  --�������� ����� ������ ���
		  exec dbo.DA_GetNewKey 'wh2','RECEIPT',@newReceipt output	
		  --...����������� ����� ��� � PO
		  begin try
			update wh2.po set otherreference=@newReceipt where pokey=@POkey
				INSERT INTO DA_InboundErrorsLog (source,msg_errdetails) 
				SELECT '����������� ����� ��� � PO', '��: ' +@POkey + ' ���: ' + @newReceipt
			
			
			--...������� ����� ���
			exec wh2.app_Receipt @newReceipt --@newReceipt -----------------------------------------
		  end try
		  begin catch
			update wh2.po set otherreference='' where pokey=@POkey
		  end catch

		end
end



set @activeReceipt=@newReceipt
set @Receiptkey = @activeReceipt
--���������� ������ ��� ������--------------------------------------------------------
select	@activeReceipt activereceipt,
		@Receiptkey receipkey_out,
		po.otherreference ASNnumber,
		po.podate,
		po.externpokey,
		po.pokey+'('+''+po.POTYPE+')' as pokey,
		po.storerkey,
		st.company storername,
		po.sellername sellerkey,
		st2.company sellername,
		po.susr4 externponumber,
		case
			when isnull(po.otherreference,'')='' 
				and isnull(r.status,'0')='0' 
				and (po.storerkey=@ReceiptStorer or isnull(@ReceiptStorer,'')='') 
			  then '+'
			when isnull(po.otherreference,'')<>'' 
				and isnull(r.status,'0')='0' 
			  then '-'
			else ''
		end operation,
		wh2.GetFromCODELKUP('RECSTATUS',isnull(r.status,po.status)) status,
		cast(isnull(r.status,'0') as int) statuscode,
		round(sum(pod.qtyordered*pod.unitprice),2) DOCSUM,
		round(sum(pod.qtyordered),2) DOCQTY,
		r.editdate,
		ck.DESCRIPTION tdesc,
		@error as error
into #Result
from wh2.po po
	left join wh2.storer st on (po.storerkey=st.storerkey)
	left join wh2.storer st2 on (po.sellername=st2.storerkey)
	left join wh2.receipt r on (po.otherreference=r.receiptkey)
	left join wh2.podetail pod on (po.pokey=pod.pokey)
	join wh2.CODELKUP ck on po.POTYPE=ck.CODE and LISTNAME='potype' and ck.CODE  in(0,1,2,3,4,5)
where 
 po.podate between isnull(@dateLow,'19900101') and isnull(@dateHigh,getdate()+2)
 and po.POTYPE like '%'+isnull(@tp,'')+'%' and
 (po.storerkey=@Storerkey or @Storerkey='' or @Storerkey is null)
group by	po.otherreference,
			po.podate,
			po.externpokey,
			po.pokey,
			po.storerkey,
			st.company,
			po.sellername,
			st2.company,
			po.susr4,
			po.otherreference,
			r.status,
			r.editdate,
			ck.DESCRIPTION,po.POTYPE,po.status
order by cast(isnull(r.status,'0') as int), po.podate

select * from #result order by statuscode, podate







