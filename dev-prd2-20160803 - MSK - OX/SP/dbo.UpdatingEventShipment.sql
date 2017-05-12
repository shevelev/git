ALTER PROCEDURE [dbo].[UpdatingEventShipment]
AS      

select top 1 o.ORDERKEY [Infor], o.EXTERNORDERKEY [�������], o.ADDDATE [�������� � Infor] ,max(oss.ADDDATE) [�������� �� INfor], ax.createddatetime+'03:00' [�������� � DAX],
 case ax.status when null then '�� ���������'
	when 5 then '������'
	when 10 then '����������'
	when 15 then '������' end [������ DAX],
  ax.error
  into #test
from wh1.orders o
join wh1.ORDERSTATUSHISTORY oss on o.ORDERKEY=oss.ORDERKEY and oss.STATUS in ('92','95')
left join [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].InforIntegrationTable_Shipment ax on o.EXTERNORDERKEY=ax.docid
where o.STATUS in ('92','95') and o.EDITDATE > DATEADD(d, -4, getdate()) and ax.createddatetime is null
group by o.ORDERKEY, o.EXTERNORDERKEY,  o.ADDDATE, ax.createddatetime, ax.status, ax.error
order by 4 desc

declare @orderkey varchar(10)
declare @tkey varchar(10)
select @orderkey=Infor   from #test
 select @orderkey from #test


if (select [status] from wh1.orders where ORDERKEY=@orderkey)=95
	begin
		update wh1.PICKDETAIL set PDUDF2=6 where  ORDERKEY=@orderkey
		select top 1 @tkey=SERIALKEY from wh1.TRANSMITLOG where KEY1=@orderkey and TABLENAME in ('ordershipped','partialshipment') order by ADDDATE desc
		update wh1.TRANSMITLOG set TRANSMITFLAG9=null, error='' where SERIALKEY=@tkey
		exec app_DA_SendMail '������ - ���� ��������-DAX: ', @OrderKey
		exec [wh1].[newGLPI] 'shorder'
	end
else 
	begin
	print '������ ��������'
	end

drop table #test



