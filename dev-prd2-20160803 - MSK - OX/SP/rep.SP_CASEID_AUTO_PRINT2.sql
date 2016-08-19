

/*
�����: �������������� ������ �������� caseID � ����������� �� ����� ��������.
�����: ������� �.�.
����: 12.05.2014
*/


ALTER PROCEDURE [rep].[SP_CASEID_AUTO_PRINT2] 
@caseid varchar(20)
AS

declare @sh varchar(20), @orderkey varchar(20), @extorderkey varchar(20),@company varchar(20),@printerid varchar(20),@route varchar(10),
		@adress varchar(200),@depart varchar(20),@box varchar(10), @result varchar(4000), @r2 int, @name varchar(20), @pole varchar(4000)


begin

select '������ �������� �� ����� ' + @caseid + ' ������������' PR

select distinct @caseid=pd.CASEID, 
				@sh=dbo.GetEAN128(pd.CASEID),
				@orderkey=pd.ORDERKEY,
				@extorderkey=o.EXTERNORDERKEY,
				@company=c.COMPANY,
				@adress=c.ADDRESS1 + c.ADDRESS2 + c.ADDRESS3,
				@depart=CONVERT(varchar, lh.DEPARTURETIME, 120),
				@route=o.route,
				@printerid =
					CASE (o.c_zip)
						WHEN '1' THEN '10.10.18.53' -- ����������� - zt230 �������� �����
						ELSE '10.10.18.6' --'10.10.18.6' -- ������-����� s4m �������� �����
					END,
				@box = sum(		ceiling(			case when pa.casecnt = 0
					then pd.qty / 1
					else pd.qty / pa.casecnt
				end
										)
							) 

from WH1.PICKDETAIL as pd
	join WH1.ORDERS as o on o.ORDERKEY = pd.ORDERKEY
	left join wh1.STORER c on o.CONSIGNEEKEY = c.STORERKEY
	left join WH1.LOADHDR as lh on o.LOADID = lh.LOADID
	join wh1.LOTATTRIBUTE la on pd.LOT = la.lot
	join wh1.PACK pa on la.LOTTABLE01 = pa.packkey
where pd.CASEID=@caseid
group by
	pd.CASEID,
	pd.STATUS,
	o.ROUTE,
	pd.ORDERKEY,
	o.EXTERNORDERKEY,
	o.C_ZIP,
	c.COMPANY,
	c.ADDRESS1,
	c.ADDRESS2,
	c.ADDRESS3,
	lh.DEPARTURETIME



set @name=@caseid+'.zpl'

--�������� ���.
insert into DA_InboundErrorsLog (source,msg_errdetails) 
values ('caseIDAUTO2','������ �������� ��� �����: caseid: '+@caseid+ ' orderkey: ' + @orderkey +' ��:'+ @sh + ' �������: '+@extorderkey+ ' ��������: '+ @company + ' box ' +@box + ' adres ' + @adress )

------------��������� ���� ������ � ������ � ������� ��� ��������.
insert into wh1.caseid_label (caseid, label,box)
select @caseid, '﻿CT~~CD,~CC^~CT~
^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ
^XA
^MMT
^PW799
^LL0400
^LS0
^FT32,216^A@N,34,33,TT0003M_^FH\^CI17^F8^FDCaseID:^FS^CI0
^FT583,224^A@N,28,29,TT0003M_^FB116,1,0,C^FH\^CI17^F8^FD������:^FS^CI0
^FT583,266^A@N,28,29,TT0003M_^FB116,1,0,C^FH\^CI17^F8^FD'+@box+'^FS^CI0
^FT578,143^A@N,23,22,TT0003M_^FB121,1,0,C^FH\^CI17^F8^FD� ������:^FS^CI0
^FT578,176^A@N,23,22,TT0003M_^FB121,1,0,C^FH\^CI17^F8^FD'+@orderkey+'^FS^CI0
^FT583,63^A@N,23,22,TT0003M_^FB110,1,0,C^FH\^CI17^F8^FD��.�����:^FS^CI0
^FT583,96^A@N,23,22,TT0003M_^FH\^CI17^F8^FD'+@extorderkey+'^FS^CI0
^FT32,325^A@N,23,22,TT0003M_^FH\^CI17^F8^FD������: '+@company+'^FS^CI0
^FT32,355^A@N,23,22,TT0003M_^FH\^CI17^F8^FD�����: '+@adress+'^FS^CI0
^FT34,295^A@N,23,22,TT0003M_^FH\^CI17^F8^FD�������: '+@route+', ����������� '+@depart+'^FS^CI0
^BY4,3,166^FT108,182^BCN,,Y,N
^FD>;'+@caseid+'^FS
^FO528,26^GB236,258,8^FS
^PQ1,0,1,Y^XZ', @box


set @pole='open '+@printerid+'
'

---8<---�������� ���������� �������� �� 50, ���� �� ���������� ������----
if (@box > 50) 
begin
	set @box=50
end
---8<---/�������� ���������� �������� �� 50, ���� �� ���������� ������----

while (@box >= 1)
	begin
	set @pole=@pole + '
put '+@name+' E:\label\'+@name
	print @box
 	set @box=@box-1	
	end
set @pole=@pole+ '
quit'


update wh1.caseid_label set [print] = @pole, label=[dbo].STR_1251_UTF8(label) where caseid=@caseid 


--��������� @caseid.zpl ��� ������---------------------------------------------
if @@rowcount <> 0 
begin
	
	
	
	print '������� ���� ��������'
	set @result = 'bcp "SELECT top 1 label FROM prd2.wh1.caseid_label where caseid='+@caseid+' order by id desc" queryout e:\label\'+@name+' -c -T -C RAW'
	exec @r2 = master..xp_cmdshell @result

IF (@r2 = 0)
begin
   PRINT '������� ���� � ����������� ��������'
	set @result = 'bcp "SELECT top 1 [print] FROM prd2.wh1.caseid_label where caseid='+@caseid+' order by id desc" queryout e:\label\print.ftp -c -T -C RAW'
	exec  master..xp_cmdshell @result
	
	EXEC master..xp_cmdshell 'e:\label\copy_ftp.bat'
end
ELSE
   PRINT '�� �������.'
end

delete wh1.caseid_label where caseid=@caseid
end
